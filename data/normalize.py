from datetime import datetime, timezone   # tools for dates, times and time zones

# ---------- Adapters: one per dialect, each returns the canonical shape ----------

def _excavator(e):                                   # translates the excavator dialect
    return {
        "serial": e["sn"],                           # excavator calls its serial "sn"
        "ts_utc": datetime.fromisoformat(e["time"])  # read time; it carries +05:30
                  .astimezone(timezone.utc)          # convert that moment to UTC
                  .isoformat(),                      # write it as standard text
        "metric": "engine_temp",                     # canonical metric name
        "value": round((e["engTempF"] - 32) * 5 / 9, 1),  # Fahrenheit -> Celsius, 1 decimal
        "unit": "C",                                 # canonical unit
    }

def _truck(e):                                       # translates the truck dialect
    return {
        "serial": e["serialNo"],                     # truck calls its serial "serialNo"
        "ts_utc": datetime.fromtimestamp(e["epoch"], tz=timezone.utc)  # epoch seconds are UTC by definition
                  .isoformat(),                      # write it as standard text
        "metric": "tyre_pressure",                   # canonical metric name
        "value": e["tyre_kpa"],                      # already in kPa, no conversion
        "unit": "kPa",                               # canonical unit
    }

def _generator(e):                                   # translates the generator dialect
    return {
        "serial": e["id"],                           # generator calls its serial "id"
        # ASSUMPTION: this source sends UTC without an offset (the trap we discussed)
        "ts_utc": datetime.strptime(e["ts"], "%Y-%m-%d %H:%M:%S")  # parse "2026-10-22 03:30:00"
                  .replace(tzinfo=timezone.utc)      # LABEL it UTC (no conversion happens)
                  .isoformat(),                      # write it as standard text
        "metric": "load",                            # canonical metric name
        "value": e["load_pct"],                      # already a percentage
        "unit": "%",                                 # canonical unit
    }

def _dozer(e):                                   # translates the dozer dialect
    return {
        "serial": e["machine"],                           # dozer calls its serial "machine"
        "ts_utc": datetime.fromisoformat(e["ts"])  # read time; it carries +05:30
                  .astimezone(timezone.utc)          # convert that moment to UTC
                  .isoformat(),                      # write it as standard text
        "metric": "hydraulic_pressure",                        # canonical metric name
        "value": round(e["hyd_psi"] * 6.89476, 1),  
        "unit": "kPa",                                 # canonical unit
    }

ADAPTERS = {"excavator": _excavator, "truck": _truck, "generator": _generator, "dozer": _dozer}  # type -> adapter lookup

def normalize(raw: dict) -> dict:                    # the one function the caller uses
    adapter = ADAPTERS.get(raw.get("type"))          # find the adapter for this machine type
    if adapter is None:                              # no adapter = unknown dialect
        raise ValueError(f"unknown source type: {raw.get('type')}")  # caller must quarantine it
    out = adapter(raw)                               # translate to canonical shape
    out["source"] = raw["type"]                      # remember which dialect it came from
    out["id"] = f"{out['serial']}:{out['metric']}"   # Cosmos id: one document per machine+metric
    return out                                       # the canonical event

# ---------- Contextualize: reference data turns a number into a decision ----------

THRESHOLDS = {"engine_temp": 105, "tyre_pressure": 620, "load": 95}  # lab: dict; real: reference data store

def needs_action(evt: dict) -> bool:                 # True if someone must act
    limit = THRESHOLDS.get(evt["metric"])            # look up this metric's limit
    if evt["metric"] == "tyre_pressure":             # tyres: LOW is dangerous
        return evt["value"] < limit                  # below 620 kPa -> act
    return limit is not None and evt["value"] > limit  # others: HIGH is dangerous