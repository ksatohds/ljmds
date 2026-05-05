#' Joint (h, k) selection by functional Rousseeuw silhouette
#'
#' For each candidate bandwidth `h.grid[i]` and class number
#' `k.grid[j]`, runs [ljmds.pipeline()] and computes the functional
#' Rousseeuw silhouette of the resulting partition.  Returns the
#' grid of silhouette values and the maximizer over `k >= k.min`
#' (default 3, to avoid the trivial k = 2 split).
#'
#' @param X Integer/numeric n x p matrix of 0/1 keyword occurrences.
#' @param t Numeric vector of length n.
#' @param h.grid Numeric vector of candidate bandwidths.
#' @param k.grid Integer vector of candidate class numbers.
#' @param k.min Smallest k considered admissible (default 3).
#' @return A list with class `"ljmds.sel"`:
#'   - `S`: matrix of silhouette values, rows = h.grid, cols = k.grid,
#'   - `h.hat`, `k.hat`: maximizer over k >= k.min,
#'   - `S.hat`: silhouette at the maximizer,
#'   - `h.grid`, `k.grid`, `k.min`.
#' @seealso [ljmds.pipeline()] to run the analysis at the chosen
#'   `(h, k)`, [ljmds.silhouette()] for the criterion used here,
#'   [plot.ljmds.sel()] to visualise the grid of silhouette values.
#' @export
ljmds.select <- function(X, t, h.grid, k.grid = 2:6, k.min = 3) {
  S <- matrix(NA_real_, length(h.grid), length(k.grid),
              dimnames = list(paste0("h", h.grid),
                              paste0("k", k.grid)))
  for (i in seq_along(h.grid)) {
    for (j in seq_along(k.grid)) {
      fit <- ljmds.pipeline(X, t, h = h.grid[i], k = k.grid[j])
      S[i, j] <- ljmds.silhouette(fit$f, fit$labels)
    }
  }
  ## maximizer over admissible k
  ad <- k.grid >= k.min
  S.ad <- S[, ad, drop = FALSE]
  best <- which(S.ad == max(S.ad, na.rm = TRUE), arr.ind = TRUE)[1, ]
  out <- list(S = S, h.grid = h.grid, k.grid = k.grid,
              k.min = k.min,
              h.hat = h.grid[best[1]],
              k.hat = k.grid[ad][best[2]],
              S.hat = S.ad[best[1], best[2]])
  class(out) <- "ljmds.sel"
  out
}
