#' Read a longitudinal binary keyword corpus from CSV
#'
#' The CSV must have a header row, with column 1 named `year` (or
#' another time variable, e.g. calendar year) and columns 2.. giving
#' \eqn{\{0,1\}} indicators of keyword presence in each row's time
#' point.
#'
#' @param file Path to the CSV.
#' @return A list with components `t` (numeric n-vector of times),
#'   `X` (n x p binary matrix), `keywords` (column names of X).
#' @export
#' @examples
#' f <- system.file("extdata", "peace_declaration.csv", package = "ljmds")
#' d <- ljmds.read.csv(f)
#' dim(d$X)              # 78 95
#' length(d$t)           # 78
#' head(d$keywords)      # first six keywords
ljmds.read.csv <- function(file) {
  d <- utils::read.csv(file, check.names = FALSE)
  t <- d[, 1]; X <- as.matrix(d[, -1])
  X[X > 0] <- 1
  storage.mode(X) <- "integer"
  list(t = t, X = X, keywords = colnames(X))
}

#' Built-in example corpora
#'
#' Two longitudinal binary keyword corpora ship with the package as
#' CSV files in `inst/extdata`, accessible via [system.file()].
#' No source text is included; the matrices are 0/1 indicators of
#' the presence of each (lemmatised) keyword in each year's text.
#'
#' - `peace_declaration.csv` : 78 years (1947--2025, no 1950),
#'   95 keywords, derived from the English Peace Declaration of
#'   Hiroshima.
#' - `inaugural.csv` : 59 inaugural addresses (1789--2021),
#'   106 keywords, derived from the corpus distributed with the
#'   `quanteda` R package.
#'
#' @section Loading:
#' ```r
#' f <- system.file("extdata", "peace_declaration.csv",
#'                  package = "ljmds")
#' d <- ljmds.read.csv(f)
#' ```
#'
#' @name ljmds_data
NULL
