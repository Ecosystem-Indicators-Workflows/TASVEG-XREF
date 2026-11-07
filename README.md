
## Fair Check
<!-- FAIR:START -->
## FAIR assessment

[![FAIR checklist badge](https://fairsoftwarechecklist.net/badge.svg)](https://fairsoftwarechecklist.net/v0.2?f=21&a=30110&i=30000&r=010) ![EIW FAIR score](https://img.shields.io/badge/EIW%20FAIR-12%2F33-orange)

**12 / 33 points · 5 / 15 questions at EIW target** · not yet at EIW minimum

| Principle | Score | EIW target |
|---|---|---|
| Findable | 3 / 4 (75%) | 4 / 4 |
| Accessible | 5 / 10 (50%) | 10 / 10 |
| Interoperable | 3 / 12 (25%) | 12 / 12 |
| Reusable | 1 / 7 (14%) | 6 / 7 |

<details><summary>Gaps to close (10)</summary>

- **f:q0 Indexed by search engines** (2 / 3): No web page with SEO (Quarto site / WorkflowHub)
- **a:q1 Persistent identifier (DOI)** (0 / 2): No DOI: a GitHub URL can move or vanish
- **a:q4 Identifier in metadata** (0 / 3): No workflow name or ID in metadata (no CITATION.cff)
- **i:q1 Versioning scheme** (0 / 2): No git tags or version numbers
- **i:q2 Dependencies specified** (0 / 3): No dependency file (renv.lock / requirements.txt)
- **i:q3 Links to related software** (0 / 2): No links to related software (CITATION.cff references)
- **i:q4 Links to related data** (0 / 2): No links to related data
- **r:q0 Executable** (0 / 1): Missing: README run steps, pinned dependencies, input data
- **r:q1 Source + documentation** (1 / 2): README too short to document the workflow
- **r:q2 Licence** (0 / 3): No LICENSE file

</details>

![FAIR scores per question](fair/fair-scores.png)

<sub>Updated 2026-11-07 from commit `23c2f04` by `.fair/fair_check.R`. Edit `.fair/fair-checklist.yml`, not this block.</sub>
<!-- FAIR:END -->
