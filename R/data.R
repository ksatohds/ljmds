#' Read a longitudinal binary keyword corpus
#'
#' Reads a CSV in which column 1 is the time variable (e.g. calendar
#' year) and columns 2.. are 0/1 indicators of attribute presence at
#' each time point.  Two example corpora ship with the package and
#' can be loaded by name; an external CSV can be loaded by passing a
#' path to `file`.
#'
#' @param name Built-in dataset name; one of `"peace_declaration"`,
#'   `"inaugural"`, or `"eurovision"`.  Ignored if `file` is
#'   supplied.  Defaults to `"peace_declaration"`.
#' @param file Optional path to a user-supplied CSV.  When given,
#'   `name` is ignored and the file is read directly.
#' @return A list with components `t` (numeric n-vector of times),
#'   `X` (n x p binary matrix), `keywords` (column names of X).
#' @seealso [ljmds.pipeline()] for the full pipeline at fixed
#'   `(h, k)`, [ljmds.select()] for joint `(h, k)` selection,
#'   and [ljmds_data] for a description of the bundled CSVs.
#' @export
#' @examples
#' # Built-in Peace Declaration of Hiroshima
#' d <- ljmds.read.csv("peace_declaration")
#' dim(d$X)              # 78 95
#'
#' # Built-in US Presidential Inaugural Addresses
#' d <- ljmds.read.csv("inaugural")
#' dim(d$X)              # 59 106
#'
#' # Built-in Eurovision Song Contest country participation
#' d <- ljmds.read.csv("eurovision")
#' dim(d$X)              # 68 52
#'
#' \dontrun{
#' # User-supplied CSV (column 1 = year, columns 2.. = 0/1)
#' d <- ljmds.read.csv(file = "my_corpus.csv")
#' }
ljmds.read.csv <- function(name = c("peace_declaration", "inaugural",
                                    "eurovision"),
                           file = NULL) {
  if (is.null(file)) {
    name <- match.arg(name)
    file <- system.file("extdata", paste0(name, ".csv"),
                        package = "ljmds")
    if (!nzchar(file))
      stop("Bundled CSV '", name, ".csv' not found.")
  }
  d <- utils::read.csv(file, check.names = FALSE)
  t <- d[, 1]; X <- as.matrix(d[, -1])
  X[X > 0] <- 1
  storage.mode(X) <- "integer"
  list(t = t, X = X, keywords = colnames(X))
}

#' Built-in example datasets
#'
#' Three longitudinal binary datasets ship with the package as CSV
#' files in `inst/extdata`.  Each has column 1 = time and columns
#' 2.. = 0/1 indicators.  The first two are derived from text but
#' contain no source text; the third is non-text and demonstrates
#' that the methodology applies beyond text mining.
#'
#' - `peace_declaration.csv` : 78 years (1947--2025, no 1950),
#'   95 keyword indicators from the English Peace Declaration of
#'   Hiroshima.
#' - `inaugural.csv` : 59 inaugural addresses (1789--2021),
#'   106 keyword indicators derived from the corpus distributed
#'   with the `quanteda` R package.
#' - `eurovision.csv` : 68 contest years (1956--2023), 52 country
#'   participation indicators in the Eurovision Song Contest.
#'   Source: Amsterdam Music Lab Mirovision dataset (MIT licence).
#'
#' @section Loading:
#' ```r
#' d <- ljmds.read.csv("peace_declaration")   # or "inaugural", "eurovision"
#' ```
#'
#' @seealso [ljmds.read.csv()] to load the data, [ljmds.pipeline()]
#'   for the full analysis pipeline.
#' @name ljmds_data
NULL
