## The purpose of this script is to create a spatial output from source
## spatial data using cross-referencing information consolidated in
## membership tables.

## Source classification and spatial data (units):
## > TASVEG 5.0 (vegetation communities)
## Target classification (units):
## > IUCN Global Ecosystem Typology (ecosystem functional groups)
## Output format:
## > Raster GeoTiff files with best candidate target unit, membership and
## > number of supporting interpreters

## This script summarises the minimum set of steps to complete four stages
## of the cross-referencing workflow:
## 1) Data preparation
## 2) Data validation
## 3) Synthesis
## 4) Outputs in preferred format

## Recommended usage:
## R --vanilla < inc/TASVEG-xref-IUCNGET-output-best-90m.R >\
##  reproducibility-notes/TASVEG-xref-IUCNGET-output-best-90m-out.txt

## Step O: Setup

### Benchmarking
start_time <- Sys.time()

### Libraries

#### tidyverse libraries
library(dplyr)
library(readr)
library(tidyr)
library(stringr)

#### For loops
library(foreach)

#### Spatial data
library(terra)
library(sf)
library(fasterize)

#### Cross-referencing
library(ecoSynthesis)
library(geco)

### Paths
here::i_am("inc/TASVEG-xref-IUCNGET-output-best-90m.R")

out_dir <- here::here("output-best-candidate")
if (!dir.exists(out_dir)) {
  dir.create(out_dir)
}

### Custom functions
source(here::here("inc", "functions.R"))

## Step 1: data preparation

### Lookup table source classification

TASVEG_xy <- read_sf(here::here(
  "gisdata/LIST_TASVEG_50_STATEWIDE/",
  "TASVEG_5_0.shp"
))


TASVEG_LUT <-
  TASVEG_xy |>
  st_drop_geometry() |>
  select(VEG_GROUP, VEGCODE, VEGCODE_D) |>
  arrange(VEG_GROUP, VEGCODE) |>
  unique() |>
  as_tibble()

not_eligible <- c("OAQ", "OSM", "ORO")
TASVEG <- TASVEG_LUT |>
  mutate(eligible = !(VEGCODE %in% not_eligible)) |>
  lookup_tbl("VEGCODE", "VEGCODE_D", "eligible")

### Lookup table target classification
IUCN_GET <- lookup_tbl(IUCN_GET_LUT, "efg_id", "efg_name")


### Membership tables

memb_data <- foreach(j = dir(here::here("xrefdata")), .combine = bind_rows) %do%
  {
    metadata <- read_csv(
      here::here("xrefdata", j),
      col_names = c("name", "value"),
      n_max = 11,
      show_col_types = F
    )[, 1:2]
    data <- read_csv(here::here("xrefdata", j), skip = 12, show_col_types = F)

    cat(sprintf(
      "Read %s, interpreter %s\n%s\n",
      j,
      metadata[1, 2],
      metadata[11, 2]
    ))

    if ("EFG_1" %in% colnames(data)) {
      pivot_wide_membership_table(
        xref = data,
        original_names = "VEGCODE",
        target_names = sprintf("EFG_%s", 1:4),
        membership_values = sprintf("memb_%s", 1:4),
        expert_name = metadata[[1, 2]],
        round = if_else(grepl("First", metadata[11, 2]), 1, 2)
      )
    } else {
      pivot_membership_matrix(
        xref = data,
        original_names = "VEGCODE",
        target_names = colnames(data)[-1],
        expert_name = metadata[[1, 2]],
        round = if_else(grepl("First", metadata[11, 2]), 1, 2)
      )
    }
  }

TASVEG_xref <- memb_data |>
  filter(
    !is.na(memb),
    memb > 0
  )

## Step 2: data validation

TASVEG_memb <- read_membership_tbl(
  TASVEG_xref,
  source_id = "VEGCODE",
  target_id = "EFG",
  membership = "memb",
  interpreter = "expert",
  round = "round"
)

TASVEG_clean <- clean_membership(TASVEG_memb, TASVEG, IUCN_GET)


check_membership(TASVEG_clean, TASVEG, IUCN_GET)


## Step 3: synthesis

TASVEG_best_summary <-
  summarise_membership(TASVEG_clean, keep_all = FALSE, which_round = 2)

## Step 4: outputs

### Standard pixel values for Global Ecosystem Atlas
efg_pixel_values <- geco_efg_data() |>
  select(efg_code, efg_pixel_value) |>
  rename("EFG" = "efg_code")

### Combined attribute table (vector data)
TASVEG_xy_best <- TASVEG_xy |>
  left_join(
    TASVEG_best_summary,
    by = "VEGCODE",
    relationship = "many-to-one"
  ) |>
  left_join(efg_pixel_values, by = "EFG")

### template raster file
rez <- 90
TASVEG_raster <- raster(TASVEG_xy, res = rez)

### Vector to raster using `fasterize`

#### Best candidate

target_raster <- fasterize(
  TASVEG_xy_best,
  TASVEG_raster,
  field = "efg_pixel_value",
  fun = "first"
) |>
  rast()

ctab <- geco_efg_data() |>
  transmute(value = efg_pixel_value, color = efg_hex_code)
coltab(target_raster) <- ctab
out_file <- here::here(out_dir, "TASVEG-xref-target.tiff")

rast_metadata <- c(
  PROJECT = "Ecosystem Indicators Workflows",
  TITLE = "Best candidate ecosystem function group",
  DESCRIPTION = "Synthesis of crossreference from TASVEG 5.0 to IUCN GET"
)
metags(target_raster) <- rast_metadata

writeRaster(target_raster, out_file, overwrite = TRUE)

#### Best candidate

memb_raster <- fasterize(
  TASVEG_xy_best,
  TASVEG_raster,
  field = "prop_memb",
  fun = "max"
) |>
  rast()
out_file <- here::here(out_dir, "TASVEG-xref-membership.tiff")

rast_metadata[
  "title"
] <- "Membership for the best candidate ecosystem function group"

metags(memb_raster) <- rast_metadata

writeRaster(memb_raster, out_file, overwrite = TRUE)


supp_raster <- fasterize(
  TASVEG_xy_best,
  TASVEG_raster,
  field = "supporting",
  fun = "max"
) |>
  rast()

out_file <- here::here(out_dir, "TASVEG-xref-supporting.tiff")

rast_metadata["title"] <- "Nr. of interpreters supporting assignment"

metags(supp_raster) <- rast_metadata

writeRaster(supp_raster, out_file, overwrite = TRUE)


## Step X: Benchmarking and session info

end_time <- Sys.time()
end_time - start_time

sessionInfo()
