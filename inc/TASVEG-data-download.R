## Download TASVEG 5.0 from www.theLIST.tas.gov.au ©State of Tasmania

## Original data description:
## > TASVEG is a comprehensive digital map of Tasmania’s vegetation, including sub-Antarctic Macquarie Island. The map depicts the extent of more than 150 vegetation communities, including coastal heathlands, eucalypt forest and alpine communities.
## > The current release version for mainland Tasmania is TASVEG 5.0 and was published in November 2025. The current release version for Macquarie Island is TASVEG 3.0 Macquarie Island and was published in November 2013.
## > Data is supplied under Creative Commons Attribution 3.0 Australia (CC BY 3.0 AU) Licence http://creativecommons.org/licenses/by/3.0/au/

## Recommended usage:
## R --vanilla < inc/TASVEG-data-download.R \
##  > reproducibility-notes/TASVEG-data-download-out.txt

## Summary of steps from data source to prepared data:
## 1. Obtaining the original data from www.theLIST.tas.gov.au
## 2. Extract target file from downloaded zip archive

## Time for action:

## 0. Setup

### Benchmarking
(start_time <- Sys.time())

### No special libraries needed

### Paths
here::i_am("inc/TASVEG-data-download.R")
gisdata <- here::here("gisdata")
if (!dir.exists(gisdata)) {
  dir.create(gisdata)
}

# This script requires 'wget' to be installed for downloading files.
# Please install 'wget' using your package manager:
# For macOS users: brew install wget
# For Ubuntu users: sudo apt-get install wget
# For Windows users: Please refer to the wget documentation for installation instructions at:
# https://eternallybored.org/misc/wget/

## 1. Obtaining the original data from www.theLIST.tas.gov.au

## This is the source URL at theLIST repository
data_url <- 'https://listdata.thelist.tas.gov.au/opendata/data/LIST_TASVEG_50_STATEWIDE.zip'

## Download to a tempfile
temp_zip <- tempfile(fileext = ".zip")

## very large file (1.7GB) will require sometime to download
options(timeout = max(300, getOption("timeout")))

## Download with wget seems to be more stable
download.file(
  data_url,
  destfile = temp_zip,
  mode = "wb",
  method = "wget",
  extra = c("-c")
)

## 2. Extract all files from downloaded zip archive

## Unzip the selected file
unzip(
  temp_zip,
  exdir = gisdata
)

## Step X: Benchmarking and session info

end_time <- Sys.time()
end_time - start_time

sessionInfo()
