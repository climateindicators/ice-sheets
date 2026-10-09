# Regression checks on the generated data for the Ice Sheets indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 1 dataset(s)", length(meta$datasets) == 1L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
# Pinned from EPA's June 2024 web update. A data update fails here and names
# exactly which value moved. Values compare as strings to keep EPA's full
# precision.
mb <- rd("ice_sheet_mass_balance.csv")
row_of <- function(df, i) paste(unlist(df[i, ]), collapse = ",")
extreme <- function(x, f) paste(unlist(x[f(as.numeric(x$value)), c("decimal_year", "value")]), collapse = ",")

check("mass balance: 1836 rows", nrow(mb) == 1836L)
check("mass balance: first row is 1992,IMBIE,Antarctica,mass,459.2434",
      row_of(mb, 1) == "1992,IMBIE,Antarctica,mass,459.2434")
check("mass balance: last row is 2023.45,NASA,Greenland,mass,-5218.44",
      row_of(mb, nrow(mb)) == "2023.45,NASA,Greenland,mass,-5218.44")

# source, region, measure, rows, then first, last, min, max as decimal_year,value
snap <- list(
  list("IMBIE", "Antarctica", "mass",        348L, "1992,459.2434", "2020.9167,-2213.814",  "2020.9167,-2213.814",  "1992.1667,464.2934"),
  list("IMBIE", "Antarctica", "uncertainty", 348L, "1992,33.0081",  "2020.9167,529.8264",   "1992,33.0081",         "2020.9167,529.8264"),
  list("IMBIE", "Greenland",  "mass",        348L, "1992,458.7701", "2020.9167,-4432.9737", "2020.9167,-4432.9737", "1992,458.7701"),
  list("IMBIE", "Greenland",  "uncertainty", 348L, "1992,16.2813",  "2020.9167,456.6814",   "1992,16.2813",         "2020.9167,456.6814"),
  list("NASA",  "Antarctica", "mass",        222L, "2002.29,0",     "2023.45,-2298.12",     "2021.04,-2860.19",     "2002.79,61.76"),
  list("NASA",  "Greenland",  "mass",        222L, "2002.29,0",     "2023.45,-5218.44",     "2022.71,-5340.8",      "2002.35,67.31")
)
for (s in snap) {
  x    <- mb[mb$source == s[[1]] & mb$region == s[[2]] & mb$measure == s[[3]], ]
  lab  <- paste(s[[1]], s[[2]], s[[3]])
  pair <- function(i) paste(x$decimal_year[i], x$value[i], sep = ",")
  check(sprintf("%s: %d rows", lab, s[[4]]), nrow(x) == s[[4]])
  check(sprintf("%s: first is %s", lab, s[[5]]), pair(1) == s[[5]])
  check(sprintf("%s: last is %s", lab, s[[6]]), pair(nrow(x)) == s[[6]])
  check(sprintf("%s: minimum is %s", lab, s[[7]]), extreme(x, which.min) == s[[7]])
  check(sprintf("%s: maximum is %s", lab, s[[8]]), extreme(x, which.max) == s[[8]])
}

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
