#' ljmds: Local Jaccard MDS for Longitudinal Binary Data
#'
#' @description Visualisation of longitudinal binary data
#' (a time-by-attribute 0/1 matrix) by a locally weighted Jaccard
#' distance, multidimensional scaling with sequential modification
#' in the sense of Mizuta (2003), Ward clustering on a trajectory
#' distance, and a functional Rousseeuw silhouette criterion for
#' joint selection of bandwidth and class number.
#'
#' @section Main entry points:
#' - [ljmds.read.csv()] reads a `(year, keyword1, keyword2, ...)` CSV.
#' - [ljmds.select()] performs joint (h, k) selection.
#' - [ljmds.pipeline()] runs the full pipeline at fixed (h, k).
#' - [plot.ljmds()] reproduces the diagnostic figures.
#' - [ljmds.animate()] writes a GIF of the trajectory map.
#'
#' @section Example data:
#' Two binary corpora ship as CSV under `inst/extdata`; see
#' [ljmds_data].
#'
#' @references Rousseeuw, P.J. (1987) Silhouettes: a graphical aid to
#'   the interpretation and validation of cluster analysis.
#'   *Journal of Computational and Applied Mathematics* **20**, 53--65.
#'
#'   Mizuta, M. (2003) Multidimensional scaling for dissimilarity
#'   functions with continuous argument.
#'   *Journal of the Japanese Society of Computational Statistics*
#'   **15**(2), 327--333.
#'
#' @keywords internal
"_PACKAGE"
