## The purpose of this script is to create per-EFG membership rasters (90 m)
## from TASVEG 5.0 spatial data and Round 2 aggregated cross-referencing
## membership tables.
##
## Source classification and spatial data (units):
## > TASVEG 5.0 (vegetation communities)
## Target classification (units):
## > IUCN Global Ecosystem Typology Level 3 (Ecosystem Functional Groups, EFGs)
## Output format:
## > 31 GeoTIFF files (`TASVEG-xref-{EFG}-memb-90m.tiff`) in `results/efg-membership-rasters/`
## > plus a companion summary table (`TASVEG-xref-EFG-membership-summary.csv`)
##
## Recommended usage:
## R --vanilla < scripts/EFG-membership-raster.R >\
##  docs-src/reproducibility-notes/EFG-membership-raster-out.txt

## Step 0: Setup

### Benchmarking
start_time <- Sys.time()
date()

### Libraries
library(ecoSynthesis)
library(geco)
library(sf)
library(terra)
library(fasterize)
library(dplyr)
library(readr)

### Paths
here::i_am("scripts/EFG-membership-raster.R")
load(here::here("results/XREFs/lookup-tables.rda"))
load(here::here("results/XREFs/memb-summaries.rda"))

out_dir <- here::here("results", "efg-membership-rasters")
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

## Step 1: Join TASVEG 5.0 spatial polygons with Round 2 aggregated memberships

rez <- 90

TASVEG_xy <- read_sf(here::here(
  "gisdata/LIST_TASVEG_50_STATEWIDE",
  "TASVEG_5_0.shp"
))

TASVEG <- TASVEG_xy |>
  left_join(TASVEG_summary, by = "VEGCODE", relationship = "many-to-many")

TASVEG_raster <- raster(TASVEG_xy, res = rez)

efg_info <- geco_efg_data() |>
  select(efg_code, efg_pixel_value, efg_hex_code, efg_rgb_code) |>
  rename("EFG" = "efg_code")

## Step 2: Generate 90m membership GeoTIFF per candidate EFG

efg_stats_list <- list()

for (tid in IUCN_GET_LUT$efg_id) {
  cat(sprintf("Starting %s: %s // ", tid, date()))
  fname <- sprintf("TASVEG-xref-%s-memb-%sm.tiff", tid, rez)
  out_file <- here::here(out_dir, fname)

  if (tid %in% TASVEG_summary$EFG) {
    efg_name_str <- IUCN_GET_LUT$efg_name[IUCN_GET_LUT$efg_id == tid][1]

    if (file.exists(out_file)) {
      cat(sprintf("%s already exists, loading for summary\n", fname))
      k_rast <- rast(out_file)
    } else {
      TASVEG_k <- TASVEG |> filter(EFG == tid)
      k_rast <- fasterize(
        TASVEG_k,
        TASVEG_raster,
        field = "prop_memb",
        fun = "sum"
      ) |>
        rast()

      rast_metadata <- c(
        PROJECT = "Ecosystem Indicators Workflows",
        TITLE = sprintf("Aggregated membership for %s (%s)", tid, efg_name_str),
        DESCRIPTION = sprintf(
          "Proportion of total Round 2 membership votes (prop_memb) from TASVEG 5.0 to IUCN GET %s (%s) at %sm resolution",
          tid,
          efg_name_str,
          rez
        ),
        EFG_CODE = tid,
        EFG_NAME = efg_name_str
      )
      metags(k_rast) <- rast_metadata

      writeRaster(k_rast, out_file, overwrite = TRUE)
    }

    vals <- values(k_rast, mat = FALSE)
    valid_vals <- vals[!is.na(vals) & vals > 0]
    sum_memb <- sum(valid_vals)
    n_pixels <- length(valid_vals)
    print(sum_memb)

    efg_stats_list[[tid]] <- tibble(
      EFG = tid,
      file_name = fname,
      mapped_pixels_90m = n_pixels,
      unweighted_area_km2 = round(n_pixels * (rez * rez) / 1e6, 2),
      sum_pixel_memb = round(sum_memb, 3),
      weighted_area_km2 = round(sum_memb * (rez * rez) / 1e6, 2)
    )
  } else {
    cat(sprintf("%s not found\n", tid))
  }
}

## Step 3: Export companion EFG membership summary CSV

efg_summary_csv <- TASVEG_summary |>
  summarise(
    round = first(round),
    total_interp = max(total_interp),
    n_tasveg_units = n_distinct(VEGCODE),
    n_best_units = sum(best),
    min_prop_memb = round(min(prop_memb), 4),
    max_prop_memb = round(max(prop_memb), 4),
    max_supporting = max(supporting),
    .by = EFG
  ) |>
  left_join(
    as_tibble(IUCN_GET) |>
      select(efg_id, efg_name, realm_id, realm_name, biome_id, biome_name),
    by = c("EFG" = "efg_id")
  ) |>
  left_join(efg_info, by = "EFG") |>
  left_join(bind_rows(efg_stats_list), by = "EFG") |>
  select(
    file_name,
    EFG,
    efg_name,
    efg_pixel_value,
    realm_id,
    realm_name,
    biome_id,
    biome_name,
    efg_hex_code,
    efg_rgb_code,
    round,
    total_interp,
    n_tasveg_units,
    n_best_units,
    min_prop_memb,
    max_prop_memb,
    max_supporting,
    mapped_pixels_90m,
    unweighted_area_km2,
    sum_pixel_memb,
    weighted_area_km2
  ) |>
  arrange(EFG)

write_csv(
  efg_summary_csv,
  here::here(out_dir, "TASVEG-xref-EFG-membership-summary.csv")
)

## Step X: Benchmarking and session info

end_time <- Sys.time()
end_time - start_time

sessionInfo()
