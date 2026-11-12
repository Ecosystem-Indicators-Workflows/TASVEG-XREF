## The purpose of this script is to create a bundle of spatial vector
## (GeoPackage) and membership matrices for each source to target units
## including all TASVEG 5.0 polygons.
##
## Source classification and spatial data (units):
## > TASVEG 5.0 (vegetation communities)
## Target classification (unit):
## > IUCN Global Ecosystem Typology Level 3
## Output format:
## > GeoPackage (`TASVEG-xref-IUCN-GET.gpkg`) in `outputs/TASVEG-vector-bundle/`
## > with multiple attribute tables (one for each interpreter),
## > plus companion membership matrices in csv format:
## > (`TASVEG-xref-IUCN-GET-{initials}.csv`)
##
## Recommended usage:
## R --vanilla --file="inc/TASVEG-membership-matrices.R" > reproducibility-notes/TASVEG-membership-matrices-out.txt

## Step 0: Setup

### Benchmarking
start_time <- Sys.time()
date()

### Libraries
library(ecoSynthesis)
library(geco)
library(sf)
library(dplyr)
library(tidyr)
library(readr)
library(XML)


### Paths
here::i_am("inc/TASVEG-membership-matrices.R")
load(here::here("outputs/XREFs/lookup-tables.rda"))
load(here::here("outputs/XREFs/memb-tables.rda"))

out_dir <- here::here("outputs", "TASVEG-vector-bundle/")
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

### Custom functions
source(here::here("scripts", "functions.R"))

## Step 1: Prepare aggregated memberships for each source
## Aggregated summary for each VEGCODE from Round 2 (best candidate EFG)
TASVEG_summary <-
  TASVEG_clean |>
  summarise_membership(keep_all = FALSE, which_round = 2)


## Step 2: Prepare membership matrices per individual interpreter

expert_initials <- c(
  "Anne Kitchener" = "memb_AK",
  "Adelina_Latinovic" = "memb_AL",
  "David_Keith" = "memb_DAK",
  "Jayne_Balmer" = "memb_JB",
  "Mark_Tozer" = "memb_MGT"
)

# ## Individual interpreter memberships for those VEGCODEs in Round 2
TASVEG_revised <- TASVEG_clean |>
  filter(round == 2)

TASVEG_matrix <- membership_matrix(TASVEG_revised)

# print(efg_table)

## Step 3:  join TASVEG 5.0  EFG attributes

TASVEG_xy <- read_sf(here::here(
  "gisdata/LIST_TASVEG_50_STATEWIDE",
  "TASVEG_5_0.shp"
))

TASVEG_union <- TASVEG_xy |>
  summarise(
    geometry = st_union(geometry),
    .by = c(VEG_GROUP, VEGCODE, VEGCODE_D)
  )

TASVEG_best_candidate <- TASVEG_union |>
  select(VEG_GROUP, VEGCODE, VEGCODE_D) |>
  left_join(
    TASVEG_summary,
    by = "VEGCODE",
    relationship = "one-to-one"
  ) |>
  mutate(SHAPE_AREA = st_area(geometry))


## Step 3: Export outputs

## 3a) Export GeoPackage vector

out_gpkg <- here::here(out_dir, "TASVEG-xref-IUCN-GET-best.gpkg")
write_sf(
  TASVEG_best_candidate,
  dsn = out_gpkg,
  layer = "EFG_best_candidate",
  delete_dsn = TRUE
)


TASVEG_best_candidate <- TASVEG_union |>
  select(VEG_GROUP, VEGCODE, VEGCODE_D) |>
  left_join(
    TASVEG_selected,
    by = "VEGCODE",
    relationship = "one-to-one"
  ) |>
  mutate(SHAPE_AREA = st_area(geometry))

write_sf(storms, dsn = out_gpkg, layer = "EFG_best_candidate", append = TRUE)

## 3b)  Create style table for QGIS

efg_info <- geco_efg_data() |>
  select(efg_code, efg_name, efg_pixel_value, efg_hex_code, efg_rgb_code) |>
  rename("EFG" = "efg_code")

cat_table <- TASVEG_best_candidate |>
  st_drop_geometry() |>
  left_join(efg_info, by = "EFG") |>
  transmute(
    value = VEGCODE,
    label = if_else(
      is.na(EFG),
      "NOTREF",
      sprintf(
        "%s (EFG=%s; prop_memb=%0.1f; support=%s/%s)",
        VEGCODE_D,
        EFG,
        prop_memb,
        supporting,
        total_interp
      )
    ),
    alpha = if_else(is.na(EFG), 0.5, prop_memb),
    colour = if_else(
      is.na(EFG),
      "25,35,35,255",
      sprintf("%s,255", efg_rgb_code)
    )
  )
out_qml <- here::here(out_dir, "TASVEG-xref-IUCN-GET-best.qml")

qml_styler(cat_table, attribute = "VEGCODE", out_qml)

## 3c) companion unit-level summary CSV

layer_info <- list(
  Source_ID = 999,
  data_id_code = "TASVEG-xref-IUCN-GET-best",
  layer_id = 999,
  layer_name = "EFG_best_candidate"
)

not_eligible <- c("OAQ", "ORO", "OSM")
hdr <- TASVEG_best_candidate |>
  st_drop_geometry() |>
  transmute(
    crossref_date = "2026-01-10",
    crossref_by = "",
    GET_vsn = "2.1",
    Source_ID = layer_info$Source_ID,
    data_id_code = layer_info$data_id_code,
    layer_id = layer_info$layer_id,
    layer_name = layer_info$layer_name,
    in_class_field_name = "VEGCODE",
    in_class_value = VEGCODE,
    in_class_description = VEGCODE_D,
    in_class_description_detail = case_when(
      VEGCODE %in% not_eligible ~
        sprintf("Group: %s, not eligible for crossreferencing", VEG_GROUP),
      TRUE ~ sprintf(
        "Group: %s, best candidate %s, prop_memb=%0.1f supporting=%s/%s",
        VEG_GROUP,
        EFG,
        prop_memb,
        supporting,
        total_interp
      )
    )
  )

# Target full set of column names
target_cols <- efg_info$EFG
# Create a full matrix filled with NA
full_mat <- matrix(
  NA,
  nrow = nrow(mtz),
  ncol = length(target_cols),
  dimnames = list(rownames(mtz), target_cols)
)
for (nm in names(expert_initials)) {
  mtz <- TASVEG_matrix[,, nm]
  hdr$crossref_by <- nm
  # Copy existing data into the matching columns
  common_cols <- intersect(colnames(mtz), target_cols)
  full_mtz <- full_mat
  full_mtz[, common_cols] <- mtz[, common_cols]
  membmat <- merge(
    hdr,
    full_mtz,
    by.x = "in_class_value",
    by.y = "row.names",
    all.x = TRUE
  )

  ss <- membmat$in_class_value %in% c("OAQ", "ORO", "OSM")
  membmat[ss, "NOTREF"] <- 1
  out_csv <- here::here(
    out_dir,
    sprintf("TASVEG-xref-IUCN-GET-best-interpreter-%s.csv", expert_initials[nm])
  )
  write_csv(membmat, out_csv)
}

## Step X: Benchmarking and session info

end_time <- Sys.time()
end_time - start_time

sessionInfo()
