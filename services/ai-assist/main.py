import os, time                                                         # read settings from env vars; measure call time
from fastapi import FastAPI, HTTPException, Header                      # web framework, error replies, read request headers
from pydantic import BaseModel                                          # request shape checking (wrong/missing field -> automatic 422)
from openai import AzureOpenAI, OpenAI                                  # Azure client; plain client for the local Ollama fallback
from azure.identity import DefaultAzureCredential, get_bearer_token_provider  # keyless sign-in helpers

app = FastAPI(title="ai-assist", version="1.0")                         # the web app; /docs page is generated from this file

if os.getenv("USE_LOCAL") == "1":                                       # fallback switch: free local model instead of Azure
    client = OpenAI(base_url="http://localhost:11434/v1", api_key="ollama")   # Ollama speaks the same API; "ollama" is a dummy value
    MODEL = os.getenv("LOCAL_MODEL", "llama3.2")                        # local model name
else:
    token = get_bearer_token_provider(DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default")  # laptop: your az login; Azure: managed identity
    client = AzureOpenAI(azure_endpoint=os.environ["AOAI_ENDPOINT"],    # which OpenAI account (from Terraform output)
                         azure_ad_token_provider=token,                 # Entra token, refreshed automatically; no key anywhere
                         api_version="2024-10-21")                      # API version that worked in our curl test
    MODEL = os.environ["AOAI_DEPLOYMENT"]                               # deployment name: a model swap = change this setting only

# Approved knowledge (lab version of RAG): one manual line per metric
MANUALS = {
    "engine_temp": "Engine temperature above 105 C: stop under load, check coolant level and radiator fins.",
    "tyre_pressure": "Tyre pressure below 620 kPa: reduce speed, inspect for leaks, inflate to spec before next shift.",
    "load": "Generator load above 95%: shed non-critical loads; sustained overload shortens alternator life.",
}

class Ask(BaseModel):                                                   # the request must look like this
    serial: str                                                         # machine serial, e.g. EX-101
    metric: str                                                         # e.g. engine_temp
    value: float                                                        # the reading
    unit: str                                                           # e.g. C

@app.post("/v1/explain")                                                # route: POST /v1/explain runs this function
def explain(q: Ask, x_team: str | None = Header(default=None)):         # team comes from the X-Team header (APIM stamps it), never the body
    team = x_team or "unknown"                                          # local tests have no APIM, so no header
    context = MANUALS.get(q.metric)                                     # retrieve the approved snippet
    if context is None:                                                 # guardrail: no approved knowledge...
        raise HTTPException(422, "no approved knowledge for this metric")   # ...refuse BEFORE calling the model (0 tokens)
    started = time.time()                                               # start the timer
    resp = client.chat.completions.create(
        model=MODEL,                                                    # which deployment
        temperature=0,                                                  # repeatable answers -> meaningful evals
        max_tokens=120,                                                 # cap the reply length (cost guardrail)
        messages=[
            {"role": "system", "content": "You help heavy-equipment operators. Answer ONLY from the context. "
                                          "If the context does not cover it, say 'Not covered, escalate to a technician.' "
                                          "Reply in at most 3 short sentences."},   # standing rules = grounding
            {"role": "user", "content": f"Context: {context}\nMachine {q.serial}: {q.metric} = {q.value} {q.unit}. "
                                        "What should the operator do?"},            # this call's question + snippet
        ],
    )
    u = resp.usage                                                      # token counts reported by the model
    print(f"TOKENS team={team} model={MODEL} in={u.prompt_tokens} out={u.completion_tokens} "
          f"ms={int((time.time() - started) * 1000)}", flush=True)     # token log per team: one line per call
    return {"serial": q.serial, "advice": resp.choices[0].message.content, "grounded_on": q.metric}  # JSON reply