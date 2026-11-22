# Mini-Helios — Org plan (Module 9)

Brief: grow the platform organization from 25 to ~60 engineers in 12 months, while the platform keeps running.

## 1. Teams at ~60 (Team Topologies)

| Team | Type | Size | Mission |
| --- | --- | --- | --- |
| Telemetry | Stream-aligned | 8 | Owns the machine data path end to end: telemetry-ingest → Event Hubs → normalizer → Cosmos DB, plus its pager |
| Machine data | Stream-aligned | 8 | Owns machine-api and its v1 contract |
| AI | Stream-aligned | 8 | Owns ai-assist: guardrails, evals, token log |
| Data | Stream-aligned | 8 | Owns the cold path: lake bronze → silver → gold for Fleet Analytics |
| Delivery platform | Platform | 8 | Paved road: Terraform, CI/CD golden path, APIM gateway |
| Observability & FinOps platform | Platform | 7 | Self-service SLO dashboards, alerts as code, incident process, per-team cost showback (builds tools, never takes other teams' pagers) |
| Enabling | Enabling | 3 | Coaches teams to adopt new practices (e.g. evals), then moves on |
| Leadership layer | — | ~9 | 6 engineering managers (one per team) + 2–3 principal engineers |

Rules: one owner per service (Conway's law), teams of 6–9, every stream-aligned team runs its own pager.
Not now: a separate machine-onboarding team. Trigger: dialects grow from 4 to 20+ or adapter work exceeds ~50% of Telemetry's capacity for 2 quarters.

## 2. Hiring and growth order

1. Month 1, zero hiring: redraw ownership into 4 owner groups (Telemetry, Machine data, AI, Platform), each with its own pager rota. Metric: pages per engineer per week ↓ (healthy ≤ 2 per shift).
2. Month 1: promote 2 senior engineers to acting EM / tech lead, so the org can absorb ~3 joiners a month.
3. Hire 2 senior platform engineers first (golden path, alerts and SLOs as code), so every later joiner is productive in days.
4. Start EM and principal searches in month 1 (they take 3–6 months); engineers join in waves of ~3 a month from month 4.

Order logic: ownership (free) → coaches → paved road → volume.

## 3. Leadership bench (grow 3 leads)

| Person | Strength | Grow into | Ready when |
| --- | --- | --- | --- |
| Senior X | Broad codebase knowledge across all groups | Tech lead, Machine data | Runs the team's design reviews; other engineers' PRs and ADRs get better |
| Senior Y | Leads incidents end to end | Architect / incident-lead track (EM only if people signals appear) | Leads incidents and writes postmortems that change the design |
| Senior Z | Observability and FinOps; improved incident management for others | Tech lead, Observability & FinOps platform | Already improving things for other teams |

For all: ask whether they want the role, and rehearse it with a 2–3 month stretch assignment before promotion. Target: every EM has a named successor, reviewed quarterly.

## 4. Outcome roadmap (re-prioritized quarterly with global stakeholders)

| Horizon | Outcome | Metric (from → to) | Guardrail | Bet | Owner |
| --- | --- | --- | --- | --- | --- |
| Now (Q1) | Teams onboard without tickets | Time to first API call: ~10 days → < 1 day | — | Self-service portal + golden path | Delivery platform |
| Next (Q2) | Maintenance acts on machine alerts faster | Alert → correct operator action: ~1 h → 10 min | Advice correct ≥ 95%; evals 5/5 on every release | Threshold breach → Service Bus command → consumer calls ai-assist → advice pushed to operators | Telemetry + AI |
| Later (H2) | Fleet Analytics gets insight sooner | Time to insight: 1 day → 4 h | Quarantine rate low; no missing hour | Hourly bronze → silver → gold pipeline | Data |

Story: adoption → action → insight.

## 5. Stakeholder map

| Stakeholder | Needs from me | I need from them | Cadence |
| --- | --- | --- | --- |
| Global platform head ★ | Outcomes vs roadmap, risks early, no surprises | Priorities, budget, air cover | Weekly 1:1 + monthly one-pager |
| Principal engineers (global) | ADRs; one-way doors brought early | Fast review of one-way doors; alignment with global standards | Monthly architecture sync + ad hoc |
| Product leads ★ (Fleet Analytics, Maintenance, Dealer Portal) | Outcomes, SLOs, onboarding time | Business value to prioritize by | Every 2 weeks + quarterly prioritization |
| Security | Identity, Key Vault, least-privilege service principals per enterprise guidelines | Guidelines, timely vulnerability notices, migration plans | Before every go-live + quarterly |
| Enterprise architecture | ADRs and tech stack | Architecture guidelines; supported tools, libraries, OSS and licences | Monthly |
| Finance | Monthly spend, forecast vs actual, per-team showback | Budget constraints, approval for growth | Monthly |

★ Earn trust first:
- Global platform head: funds the platform and vouches for its value. First one-pager in week 4 with a baseline.
- Product leads: adoption is the platform's success measure. One quick win for one team in the first 60 days.

Governance: golden path + ADR by default; architecture review only for one-way doors.
