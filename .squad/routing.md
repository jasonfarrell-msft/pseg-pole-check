# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Scope, architecture, trade-offs | Ripley | Project structure, design decisions, review gates, cross-cutting changes |
| React/Vite frontend | Dallas | Upload workflow, result components, Bootstrap styling, frontend service integration |
| Static report UI | Dallas | `PoleImageReport/static/js/*`, dashboard/report pages, client-side behavior |
| .NET API | Parker | ASP.NET Core endpoints, API contracts, Azure Storage integration, configuration |
| AI vision workflow | Ash | Azure Vision/OpenAI SDK usage, image analysis behavior, validation logic |
| Console vision tooling | Ash | `ObjectColorDetect`, custom vision experiments, local image analysis output |
| Code review | Ripley | Review PRs, check quality, enforce architecture and handoffs |
| Testing | Lambert | Write tests, find edge cases, verify fixes, validate builds |
| Scope & priorities | Ripley | What to build next, trade-offs, decisions |
| Session logging | Scribe | Automatic — never needs routing |
| Backlog monitoring | Ralph | Check assigned issues, PRs, CI state, and next work |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Lead |
| `squad:ripley` | Architecture, triage, review gates | Ripley |
| `squad:dallas` | Frontend or static report UI work | Dallas |
| `squad:parker` | .NET API/backend work | Parker |
| `squad:ash` | AI vision/image analysis work | Ash |
| `squad:lambert` | Testing and validation work | Lambert |
| `squad:ralph` | Backlog monitoring and work queue follow-up | Ralph |
| `squad:{name}` | Pick up issue and complete the work | Named member |

### How Issue Assignment Works

1. When a GitHub issue gets the `squad` label, the **Lead** triages it — analyzing content, assigning the right `squad:{member}` label, and commenting with triage notes.
2. When a `squad:{member}` label is applied, that member picks up the issue in their next session.
3. Members can reassign by removing their label and adding another member's label.
4. The `squad` label is the "inbox" — untriaged issues waiting for Lead review.

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn an agent for "what port does the server run on?"
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** If a feature is being built, spawn the tester to write test cases from requirements simultaneously.
7. **Issue-labeled work** — when a `squad:{member}` label is applied to an issue, route to that member. The Lead handles all `squad` (base label) triage.
