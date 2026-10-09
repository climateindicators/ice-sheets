# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-ice-sheets/index.html>  \
  sha256 `03fd635433c49f3ed7c4411300a7137194c3bcac021c69d7ef06de5d0179f93f`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-06/ice-sheets_documentation.pdf>

## Figure data

- `ice_sheets_fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-05/ice_sheets_fig-1.csv>  \
  sha256 `ba6ff9bbf959fd48f6f8039af798c101c86dbc7acd4b547cca4ee9ca2914763b`  \
  encoding UTF-8-BOM, 569 data rows, columns: `Year`, `NASA - Antarctica land ice mass`, `NASA - Greenland land ice mass`, `IMBIE - Antarctica cumulative mass balance`, `IMBIE - Antarctica cumulative mass balance uncertainty`, `IMBIE - Greenland cumulative mass balance`, `IMBIE - Greenland cumulative mass balance uncertainty`  \
  title: Figure 1. Cumulative Mass Balance of Greenland and Antarctica, 1992–2023  \
  data source: IMBIE, 2021; NASA, 2023; web update: June 2024; units: Billion metric tons
