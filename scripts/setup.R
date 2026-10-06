options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 600)
packages <- c("renv", "readxl", "dplyr", "tidyr", "ggplot2", "scales",
              "lubridate", "readr", "jsonlite", "digest", "openxlsx", "knitr", "rmarkdown")
missing <- setdiff(packages, rownames(installed.packages()))
if (length(missing)) install.packages(missing, type = "binary")
if (!file.exists("renv.lock")) {
  renv::init(bare = TRUE, restart = FALSE)
  renv::hydrate(packages = setdiff(packages, "renv"), prompt = FALSE)
  renv::snapshot(packages = packages, prompt = FALSE)
} else {
  renv::restore(prompt = FALSE)
}
cat("Project dependencies are ready.\n")
