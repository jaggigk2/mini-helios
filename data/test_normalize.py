from normalize import normalize, needs_action      # the code under test

def test_generator():                               # pytest runs every function named test_*
    raw = {"type": "generator", "id": "GN-3",       # sample in the generator dialect
           "ts": "2026-10-22 03:30:00", "load_pct": 97}
    evt = normalize(raw)                            # translate to canonical shape
    assert evt["serial"] == "GN-3"                  # serial pulled from "id"
    assert evt["ts_utc"] == "2026-10-22T03:30:00+00:00"  # UTC with explicit offset
    assert evt["metric"] == "load"                  # canonical metric name
    assert evt["value"] == 97 and evt["unit"] == "%"     # value and canonical unit
    assert evt["id"] == "GN-3:load"                 # one Cosmos doc per machine+metric
    assert needs_action(evt) is True                # 97 > 95 -> act

# YOUR TURN: write test_excavator() and test_truck() the same way

def test_excavator():                               # pytest runs every function named test_*
    raw = {"type": "excavator", "sn": "EX-101", 
           "time": "2026-10-22T09:00:00+05:30", "engTempF": 221}
    evt = normalize(raw)                            # translate to canonical shape
    assert evt["serial"] == "EX-101"                  # serial pulled from "id"
    assert evt["ts_utc"] == "2026-10-22T03:30:00+00:00"  # UTC with explicit offset
    assert evt["metric"] == "engine_temp"                  # canonical metric name
    assert evt["value"] == 105 and evt["unit"] == "C"     # value and canonical unit
    assert evt["id"] == "EX-101:engine_temp"                 # one Cosmos doc per machine+metric
    assert needs_action(evt) is False                # 

def test_truck():                                   # truck dialect: epoch seconds + kPa
    raw = {"type": "truck", "serialNo": "TR-7",     # truck calls its serial "serialNo"
           "epoch": 1792656000, "tyre_kpa": 690}    # epoch = seconds since 1970-01-01 UTC
    evt = normalize(raw)                            # translate to canonical shape
    assert evt["serial"] == "TR-7"                  # serial pulled from "serialNo"
    assert evt["ts_utc"] == "2026-10-22T08:00:00+00:00"  # epoch is UTC by definition, no guess
    assert evt["metric"] == "tyre_pressure"         # canonical metric name
    assert evt["value"] == 690 and evt["unit"] == "kPa"  # no conversion needed
    assert evt["id"] == "TR-7:tyre_pressure"        # one Cosmos doc per machine+metric
    assert needs_action(evt) is False               # 690 is not below 620 -> safe

def test_unknown_type_raises():                     # quarantine path: unknown dialect
    import pytest                                   # needed for pytest.raises
    with pytest.raises(ValueError):                 # test passes only if ValueError is raised
        normalize({"type": "dozer", "machine": "DZ-9"})  # no dozer adapter yet