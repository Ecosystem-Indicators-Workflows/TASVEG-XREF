#  R --vanilla < inc/EFG-membership-raster.R > reproducibility-notes/EFG-membership-raster-out.txt
library(ecoSynthesis)
library(sf)
library(terra)
library(fasterize)
library(dplyr)

date()

here::i_am("inc/EFG-membership-raster.R")
load(here::here("output-XREFs/memb-summaries.rda"))

out_dir <- here::here("gisout")
if (!dir.exists(out_dir)) {
  dir.create(out_dir)
}

rez <- 90

TASVEG <- read_sf(here::here("gisdata", "TASVEG_5_0.shp")) |>
  left_join(TASVEG_summary, by = "VEGCODE", relationship = "many-to-many")

TASVEG_raster <- raster(TASVEG, res = rez)

for (tid in IUCN_GET_LUT$efg_id) {
  cat(sprintf("Starting %s: %s // ", tid, date()))
  out_file <- here::here(out_dir, sprintf("%s-res%s.tiff", tid, rez))
  if (file.exists(out_file)) {
    cat(sprintf("%s already exists\n", out_file))
  } else {
    if (tid %in% TASVEG_summary$EFG) {
      TASVEG_k <- TASVEG |> filter(EFG == tid)
      k_raster <- fasterize(
        TASVEG_k,
        TASVEG_raster,
        field = "prop_memb",
        fun = "sum"
      )

      print(sum(k_raster@data@values, na.rm = T))
      # plot(k_raster)

      writeRaster(k_raster, out_file)
    } else {
      cat(sprintf("%s not found\n", tid))
    }
  }
}
