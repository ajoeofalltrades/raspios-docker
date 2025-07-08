| # | Checkpoint | Why it matters |
| - | --- | --- |
| 1 | **Acceptance criteria met** (all user-story bullet points or tests pass) | This is the canonical “it works” gate; a DoD must reflect the Increment reaching the agreed quality bar |
| 2 | **All automated tests green** in local run *and* CI (unit + integration as applicable) | Shared understanding of “done” includes technical quality, not just functionality |
| 3 | **Static analysis / linters / type-checkers clean** | Prevents hidden defects that LLMs may miss or introduce )                                                   |
| 4 | **Security scan shows no new critical issues** (e.g., Bandit, Cargo-audit, PHPStan) | AI-generated code is prone to insecure patterns; this gate enforces review |
| 5 | **Performance budget respected** (benchmarks unchanged ± X %) | Guards against silent regressions an LLM refactor might cause |
| 6 | **Docs updated** (README, in-code docstrings, changelog) | The Scrum Guide stresses transparency; docs convey that shared understanding |
| 7 | **Branch merged via PR after human review** (diff approved by you) | Solo≠no review—in an LLM pair-programming setup you are the senior reviewer |