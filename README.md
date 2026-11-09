# Cross-referencing Tasmanian Terrestrial Ecosystems (TASVEG-XREF)
A reproducible workflow that cross-references the 159 mapping units of TASVEG 5.0, Tasmania’s vegetation map, to the ecosystem functional groups of the IUCN Global Ecosystem Typology (GET).

Five expert interpreters assigned each TASVEG unit to IUCN GET units over two rounds. This workflow cleans and validates their membership tables, measures how well the interpreters agree and how uncertain each assignment is, then summarises and maps the results. The whole workflow is written as a Quarto book.

It is a joint output of the ARDC Ecosystem Indicators Workflows (EIW) project and the ARC Industry Laureate Fellowship Foundations for leading the nature positive ecosystem conservation agenda (IL240100030).
## Keywords
`#tasmania`, `#tasveg`, `#ecosystem-classification`, `#quarto`, `#r`, `#expert-elicitation`, `#ardc`.

## Requirements
- R ≥ 4.3, Quarto ≥ 1.4, and Jupyter with the R kernel (IRkernel) for the .ipynb chapters
- CRAN packages: here dplyr tidyr readr readxl stringr tibble rlang ggplot2 cowplot DT foreign sf terra fasterize units foreach IRkernel
- ecoSynthesis, installed with remotes::install_github("Ecosystem-Indicators-Workflows/ecoSynthesis")

## Input data

The expert membership tables are included in xrefdata/. TASVEG 5.0 is not included. Download it from theLIST open data (© State of Tasmania) and put these files in a gisdata/ folder at the repository root:

- TASVEG_5_0.shp, plus its .dbf, .shx and .prj files
- TASVEG_5_0_Fire_Attributes_LUT.dbf

The workflow writes its outputs to output-XREFs/. That folder, along with gisdata/, is ignored by git.

## Running the workflow
```
git clone https://github.com/Ecosystem-Indicators-Workflows/TASVEG-XREF.git
cd TASVEG-XREF
quarto render
```
The rendered book is written to _book/; open _book/index.html in a browser. Chapters build on outputs from earlier ones, so run them in the order listed in _quarto.yml.

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
