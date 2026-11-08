## The purpose of this script is to create a spatial vector output (GeoPackage)
## for a single target Ecosystem Functional Group: IUCN GET TF1.7 (Boreal and
## temperate fens), including all TASVEG 5.0 polygons whose VEGCODE was assigned
## to TF1.7 by at least one interpreter in Round 2.
##
## Source classification and spatial data (units):
## > TASVEG 5.0 (vegetation communities)
## Target classification (unit):
## > IUCN Global Ecosystem Typology Level 3: TF1.7 Boreal and temperate fens
## Output format:
## > GeoPackage (`TASVEG-xref-TF1.7-memb.gpkg`) in `outputs/efg-TF1.7-vector/`
## > plus a companion unit-level summary table (`TASVEG-xref-TF1.7-unit-summary.csv`)
##
## Recommended usage:
## R --vanilla < inc/TF1.7-membership-vector.R >\
##  reproducibility-notes/TF1.7-membership-vector-out.txt

## Step 0: Setup

### Benchmarking
start_time <- Sys.time()
date()

### Libraries
library(ecoSynthesis)
library(sf)
library(dplyr)
library(tidyr)
library(readr)

### Paths
here::i_am("inc/TF1.7-membership-vector.R")
load(here::here("outputs/XREFs/lookup-tables.rda"))
load(here::here("outputs/XREFs/memb-summaries.rda"))

out_dir <- here::here("outputs", "efg-TF1.7-vector")
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

target_efg <- "TF1.7"

## Step 1: Prepare individual interpreter and aggregated memberships for TF1.7

expert_initials <- c(
  "Anne Kitchener"    = "memb_AK",
  "Adelina_Latinovic" = "memb_AL",
  "David_Keith"       = "memb_DAK",
  "Jayne_Balmer"      = "memb_JB",
  "Mark_Tozer"        = "memb_MGT"
)

## Aggregated summary for TF1.7 from Round 2 (all 6 assigned VEGCODEs)
tf17_agg <- TASVEG_summary |>
  filter(EFG == target_efg) |>
  select(VEGCODE, EFG, round, prop_memb, total_memb, supporting, total_interp, best)

## Individual interpreter memberships for those VEGCODEs in Round 2
tf17_interp_wide <- TASVEG_revised |>
  filter(EFG == target_efg, VEGCODE %in% tf17_agg$VEGCODE) |>
  mutate(interp_col = expert_initials[expert]) |>
  select(VEGCODE, interp_col, memb) |>
  pivot_wider(
    names_from = interp_col,
    values_from = memb,
    values_fill = 0
  )

## Ensure all 5 interpreter columns exist in consistent order
for (col_nm in unname(expert_initials)) {
  if (!(col_nm %in% colnames(tf17_interp_wide))) {
    tf17_interp_wide[[col_nm]] <- 0
  }
}

tf17_table <- as_tibble(TASVEG) |>
  select(VEG_GROUP, VEGCODE, VEGCODE_D) |>
  inner_join(tf17_agg, by = "VEGCODE") |>
  left_join(tf17_interp_wide, by = "VEGCODE") |>
  select(
    VEG_GROUP, VEGCODE, VEGCODE_D, EFG, round,
    memb_AK, memb_AL, memb_DAK, memb_JB, memb_MGT,
    prop_memb, supporting, total_interp, best
  ) |>
  arrange(desc(prop_memb), VEGCODE)

print(tf17_table)

## Step 2: Filter TASVEG 5.0 polygons and join TF1.7 attributes

TASVEG_xy <- read_sf(here::here(
  "gisdata/LIST_TASVEG_50_STATEWIDE",
  "TASVEG_5_0.shp"
))

TASVEG_tf17_sf <- TASVEG_xy |>
  filter(VEGCODE %in% tf17_table$VEGCODE) |>
  select(VEG_GROUP, VEGCODE, VEGCODE_D, SHAPE_LEN, SHAPE_AREA) |>
  left_join(
    tf17_table |> select(-VEG_GROUP, -VEGCODE_D),
    by = "VEGCODE",
    relationship = "many-to-one"
  ) |>
  select(
    VEG_GROUP, VEGCODE, VEGCODE_D, EFG, round,
    memb_AK, memb_AL, memb_DAK, memb_JB, memb_MGT,
    prop_memb, supporting, total_interp, best,
    SHAPE_LEN, SHAPE_AREA
  )

cat(sprintf(
  "Selected %d polygons across %d VEGCODE units assigned to %s\n",
  nrow(TASVEG_tf17_sf),
  n_distinct(TASVEG_tf17_sf$VEGCODE),
  target_efg
))

## Step 3: Export GeoPackage vector and companion unit-level summary CSV

out_gpkg <- here::here(out_dir, "TASVEG-xref-TF1.7-memb.gpkg")
write_sf(
  TASVEG_tf17_sf,
  dsn = out_gpkg,
  layer = "TASVEG_TF1_7_membership",
  delete_dsn = TRUE
)

poly_stats <- TASVEG_tf17_sf |>
  st_drop_geometry() |>
  summarise(
    n_polygons = n(),
    unweighted_area_km2 = round(sum(SHAPE_AREA, na.rm = TRUE) / 1e6, 4),
    .by = VEGCODE
  )

tf17_unit_summary <- tf17_table |>
  left_join(poly_stats, by = "VEGCODE") |>
  mutate(
    weighted_area_prop_km2 = round(unweighted_area_km2 * prop_memb, 4),
    weighted_area_AK_km2   = round(unweighted_area_km2 * memb_AK, 4),
    weighted_area_AL_km2   = round(unweighted_area_km2 * memb_AL, 4),
    weighted_area_DAK_km2  = round(unweighted_area_km2 * memb_DAK, 4),
    weighted_area_JB_km2   = round(unweighted_area_km2 * memb_JB, 4),
    weighted_area_MGT_km2  = round(unweighted_area_km2 * memb_MGT, 4)
  )

write_csv(
  tf17_unit_summary,
  here::here(out_dir, "TASVEG-xref-TF1.7-unit-summary.csv")
)

## Step X: Benchmarking and session info

end_time <- Sys.time()
end_time - start_time

sessionInfo()
