# Build tidy long-format data for the Ice Sheets indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# Generated as a stub by the build-indicator skill. Each figure below has a
# `todo_reshape()` call standing where its reshape belongs. Replace that line,
# then delete the todo_reshape() helper once no call to it remains.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Ice Sheets",
  slug                    = "ice-sheets",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-ice-sheets/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/ice-sheets_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Cumulative Mass Balance of Greenland and Antarctica, 1992–2023 ----

f1_path <- file.path(raw_dir, "ice_sheets_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f1_raw,
  id_cols          = "Year",
  expected_headers = c("NASA - Antarctica land ice mass", "NASA - Greenland land ice mass", "IMBIE - Antarctica cumulative mass balance", "IMBIE - Antarctica cumulative mass balance uncertainty", "IMBIE - Greenland cumulative mass balance", "IMBIE - Greenland cumulative mass balance uncertainty"),
  what             = "ice_sheets_fig-1.csv"
)

# Each source column splits into who produced it, which ice sheet, and whether
# it is the mass estimate itself or IMBIE's uncertainty around it.
F1_SERIES <- tibble::tribble(
  ~header,                                                   ~source, ~region,      ~measure,
  "NASA - Antarctica land ice mass",                         "NASA",  "Antarctica", "mass",
  "NASA - Greenland land ice mass",                          "NASA",  "Greenland",  "mass",
  "IMBIE - Antarctica cumulative mass balance",              "IMBIE", "Antarctica", "mass",
  "IMBIE - Antarctica cumulative mass balance uncertainty",  "IMBIE", "Antarctica", "uncertainty",
  "IMBIE - Greenland cumulative mass balance",               "IMBIE", "Greenland",  "mass",
  "IMBIE - Greenland cumulative mass balance uncertainty",   "IMBIE", "Greenland",  "uncertainty"
)

# NASA runs from 2002 and IMBIE ends earlier, so most rows populate only some
# columns; blank cells are dropped rather than written as empty values. The
# time column is a decimal year (monthly steps), so it is not named `year`.
f1 <- f1_raw |>
  tidyr::pivot_longer(-Year, names_to = "header", values_to = "value") |>
  filter(!is.na(value), trimws(value) != "") |>
  inner_join(F1_SERIES, by = "header") |>
  transmute(decimal_year = Year, source, region, measure, value)
assert_conservation(f1_raw, F1_SERIES$header, nrow(f1), "ice_sheets_fig-1.csv")

write_csv_stable(f1, file.path(out_dir, "ice_sheet_mass_balance.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# One entry per output column, in order, filled from the data frame itself so it
# cannot drift. A column missing from `docs` leaves a blank type and description,
# which tests/test-data.R fails on.
describe <- function(df) {
  docs <- list(
    decimal_year = c("number", "Time of the estimate as a decimal year (e.g. 1992.0833 is about the start of February 1992)."),
    source       = c("string", "Who produced the estimate: IMBIE (combined estimate from many studies) or NASA (NASA JPL analysis of GRACE data)."),
    region       = c("string", "Ice sheet: Antarctica or Greenland."),
    measure      = c("string", "mass: cumulative mass balance, centered at zero in 2002; uncertainty: IMBIE's uncertainty around that estimate."),
    value        = c("number", "Billion metric tons.")
  )
  lapply(names(df), function(nm) col(nm, docs[[nm]][1] %||% "", docs[[nm]][2] %||% ""))
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "ice_sheet_mass_balance.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "ice_sheets_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "UTF-8-BOM",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = describe(f1)
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
