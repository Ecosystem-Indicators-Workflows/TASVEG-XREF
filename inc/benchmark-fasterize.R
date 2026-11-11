#  R --vanilla < inc/benchmark-fasterize.R > reproducibility-notes/benchmark-fasterize-out.txt
library(ecoSynthesis)
library(sf)
library(terra)
library(fasterize)
library(dplyr)

date()

here::i_am("inc/benchmark-fasterize.R")
load(here::here("outputs/XREFs/memb-summaries.rda"))

TASVEG <- read_sf(here::here(
  "gisdata/LIST_TASVEG_50_STATEWIDE",
  "TASVEG_5_0.shp"
))

TASVEG_k <- TASVEG |>
  left_join(TASVEG_summary, by = "VEGCODE", relationship = "many-to-many") |>
  filter(EFG == "TF1.3")

for (rez in c(10000, 1000, 100, 90)) {
  print(rez)
  TASVEG_rast <- rast(TASVEG, rez)
  TASVEG_raster <- raster(TASVEG, res = rez)
  bench <- microbenchmark::microbenchmark(
    terrarize = k_rast <- rasterize(
      TASVEG_k,
      TASVEG_rast,
      field = "prop_memb",
      fun = "sum"
    ),
    fasterize = k_raster <- fasterize(
      TASVEG_k,
      TASVEG_raster,
      field = "prop_memb",
      fun = "sum"
    ),
    unit = "ms",
    times = 10L
  )
  print(bench, digits = 3)
}
sessionInfo()
