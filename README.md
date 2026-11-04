
## Fair Check
<!-- FAIR:START -->
## FAIR assessment

[![FAIR checklist badge](https://fairsoftwarechecklist.net/badge.svg)](https://fairsoftwarechecklist.net/v0.2?f=01&a=00110&i=20000&r=010) ![EIW FAIR score](https://img.shields.io/badge/EIW%20FAIR-6%2F33-orange)

**6 / 33 points · 3 / 15 questions at EIW target** · not yet at EIW minimum

| Principle | Score | EIW target |
|---|---|---|
| Findable | 1 / 4 (25%) | 4 / 4 |
| Accessible | 2 / 10 (20%) | 10 / 10 |
| Interoperable | 2 / 12 (17%) | 12 / 12 |
| Reusable | 1 / 7 (14%) | 6 / 7 |

<details><summary>Gaps to close (12)</summary>

- **f:q0 Indexed by search engines** (0 / 3): Not public and no machine-readable metadata
- **a:q0 Identifier gives a copy** (0 / 3): Repo is private: others cannot download it
- **a:q1 Persistent identifier (DOI)** (0 / 2): No DOI: a GitHub URL can move or vanish
- **a:q4 Identifier in metadata** (0 / 3): No workflow name or ID in metadata (no CITATION.cff)
- **i:q0 Open, domain-common formats** (2 / 3): No open geospatial formats (GeoTIFF/COG, GeoPackage)
- **i:q1 Versioning scheme** (0 / 2): No git tags or version numbers
- **i:q2 Dependencies specified** (0 / 3): No dependency file (renv.lock / requirements.txt)
- **i:q3 Links to related software** (0 / 2): No links to related software (CITATION.cff references)
- **i:q4 Links to related data** (0 / 2): No links to related data
- **r:q0 Executable** (0 / 1): Missing: README run steps, pinned dependencies, input data
- **r:q1 Source + documentation** (1 / 2): README too short to document the workflow
- **r:q2 Licence** (0 / 3): No LICENSE file

</details>

![FAIR scores per question](fair/fair-scores.png)

<sub>Updated 2026-11-04 from commit `8e9bf14` by `.fair/fair_check.R`. Edit `.fair/fair-checklist.yml`, not this block.</sub>
<!-- FAIR:END -->
