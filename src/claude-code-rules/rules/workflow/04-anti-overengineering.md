# Anti-Over-Engineering — STRICT

**No gamified abstractions. No speculative futures. No academic-validation-seeking.**

## Seven Principles

Violating any one is grounds for rejection.

### 1. Ground in Physical Reality

Systems tracking value/cost/incentive must be denominated in something physically real: actual currency, delivered features, fixed bugs, or shipped deployments.

**Forbidden:** Abstract token economies, floating exchange rates, "credit" systems with no external anchor, market mechanics in internal communication.

### 2. Solve Current Failures, Not Hypothetical Futures

Every feature must answer: "What concrete, current failure does this prevent?" If nothing breaks without it, don't build it.

**Forbidden:** Features justified by "we'll need this when..." or "future agents will need..." or "the literature says this matters."

### 3. Measure Outcomes, Not Activity

Value is attributed to delivered outcomes only. Proxy metrics are forbidden as value measures.

**Forbidden:** Crediting posts, label generation, meeting attendance, channel activity, or any process behavior as economic value.

**Test:** "Can this metric increase without anything useful happening?" If yes, it's activity, not value.

### 4. No Academic-Validation-Seeking

Features must be justified by operational need, not literature citations.

**Forbidden:** "The RL literature says X, therefore we need Y" without demonstrating that Y solves a concrete current problem.

### 5. Design for Current Capabilities

Architecture must match what the system can actually do today. Don't build taxonomies, evaluation layers, or feedback loops that presume capabilities that don't exist yet.

**Forbidden:** Labeling systems tracking "reflection quality" when agents can't reflect. Evaluation pipelines requiring LLM-as-judge when no such judge is deployed.

### 6. Trust Upward, Don't Punish Downward

Systems should enable growth through positive contribution. Penalty-based systems are forbidden.

**Forbidden:** Negligence multipliers, error cost tables with punitive scaling, "strike" systems, reputation scoring that can only decrease, adversarial audit mechanics.

**Replace with:** Progressive trust — earn more by doing better work.

### 7. Complexity Carries a Maintenance Tax

Every abstraction, layer, label, and mechanism has a carrying cost. The proponent must account for: who maintains it, what breaks when it changes, how it's tested, and what the migration path is.

**Forbidden:** "We'll figure out maintenance later." Features with no test plan. Architectures where maintenance burden exceeds the problem being solved.

## Enforcement

- Violating any single principle is sufficient for rejection.
- The question is always: "What problem does this solve right now?" If there's no answer, there's no feature.
- When in doubt, prefer the simpler design.
