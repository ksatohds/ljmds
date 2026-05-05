#' Joint (h, k) selection by functional Rousseeuw silhouette
#'
#' For each candidate bandwidth `h.grid[i]` and class number
#' `k.grid[j]`, runs [ljmds.pipeline()] and computes the functional
#' Rousseeuw silhouette of the resulting partition.  Returns the
#' grid of silhouette values and the maximizer over `(h, k)`.
#'
#' The trivial `k = 2` split typically gives a silhouette value
#' larger than any admissible (`k >= 3`) cell, and `k = 1` is not a
#' partition at all.  Both are excluded by simply not putting them
#' into `k.grid`; the default `k.grid = 3:6` already does so.
#'
#' @param X Integer/numeric n x p matrix of 0/1 keyword occurrences.
#' @param t Numeric vector of length n.
#' @param h.grid Numeric vector of candidate bandwidths.
#' @param k.grid Integer vector of candidate class numbers; the
#'   default `3:6` excludes the trivial `k = 2` split.
#' @return A list with class `"ljmds.sel"`:
#'   - `S`: matrix of silhouette values, rows = h.grid, cols = k.grid,
#'   - `h.hat`, `k.hat`: maximizer over the supplied grid,
#'   - `S.hat`: silhouette at the maximizer,
#'   - `h.grid`, `k.grid`.
#' @seealso [ljmds.pipeline()] to run the analysis at the chosen
#'   `(h, k)`, [ljmds.silhouette()] for the criterion used here,
#'   [plot.ljmds.sel()] to visualise the grid of silhouette values.
#' @export
ljmds.select <- function(X, t, h.grid, k.grid = 3:6) {
  S <- matrix(NA_real_, length(h.grid), length(k.grid),
              dimnames = list(paste0("h", h.grid),
                              paste0("k", k.grid)))
  for (i in seq_along(h.grid)) {
    for (j in seq_along(k.grid)) {
      fit <- ljmds.pipeline(X, t, h = h.grid[i], k = k.grid[j])
      S[i, j] <- ljmds.silhouette(fit$f, fit$labels)
    }
  }
  best <- which(S == max(S, na.rm = TRUE), arr.ind = TRUE)[1, ]
  out <- list(S = S, h.grid = h.grid, k.grid = k.grid,
              h.hat = h.grid[best[1]],
              k.hat = k.grid[best[2]],
              S.hat = S[best[1], best[2]])
  class(out) <- "ljmds.sel"
  out
}
