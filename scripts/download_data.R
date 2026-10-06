dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
source_url <- "https://archive.ics.uci.edu/static/public/352/online%2Bretail.zip"
archive <- "data/raw/online-retail.zip"
source_file <- "data/raw/Online Retail.xlsx"
if (!file.exists(source_file)) {
  download.file(source_url, archive, mode = "wb", method = "libcurl")
  unzip(archive, exdir = "data/raw")
}
actual_hash <- digest::digest(file = source_file, algo = "sha256")
manifest_path <- "data/source-manifest.json"
if (file.exists(manifest_path)) {
  expected <- jsonlite::read_json(manifest_path, simplifyVector = TRUE)
  if (!identical(actual_hash, expected$sha256)) stop("Source checksum mismatch; do not overwrite the manifest.")
} else {
  manifest <- list(dataset = "UCI Online Retail", creator = "Daqing Chen",
    citation = "Chen, D. (2015). Online Retail. UCI Machine Learning Repository.",
    doi = "https://doi.org/10.24432/C5BW33", license = "CC BY 4.0",
    landing_page = "https://archive.ics.uci.edu/dataset/352/online+retail",
    download_url = source_url, file = source_file, sha256 = actual_hash,
    bytes = unname(file.info(source_file)$size),
    retrieved_at_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ"))
  jsonlite::write_json(manifest, manifest_path, pretty = TRUE, auto_unbox = TRUE)
}
cat("Source file verified:", actual_hash, "\n")
