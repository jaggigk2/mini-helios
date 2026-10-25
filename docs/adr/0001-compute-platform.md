# ADR-0001: Compute platform for platform services
Status: Accepted | Date: 2026-10-25

## Context
- 3 services to start: machine-api (Java API), telemetry-ingest (Java background worker), ai-assist (Python API); more as product teams onboard.
- Platform team: 5 engineers, no Kubernetes experts.
- Traffic: low and spiky today, growing with adoption.
- Cost: course budget ~USD 10/month; spend must track adoption.
- Top quality attributes for this decision: 1) cost, 2) operability.

## Options
- A: Azure Container Apps (managed containers, scales to zero)
- B: AKS (managed Kubernetes; we run the worker machines, pay for them 24/7)
- C: App Service (hosted web apps; always-on plan, weaker fit for background workers)

## Decision
A: Azure Container Apps. Near-zero idle cost and Azure runs the machinery, so a 5-person team without Kubernetes skills can operate it. Handles both APIs and background workers.

## Consequences
- Easier: low cost, fast start, little ops work, focus stays on product teams.
- Harder: less low-level control (custom networking, special machine types).
- Door: two-way. Same container images can move to AKS or AWS later.
- Revisit when: ~30+ services, a dedicated ops team exists, or steady traffic makes always-on AKS nodes cheaper than pay-per-use.