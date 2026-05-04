#' Joint (h, k) selection by functional Rousseeuw silhouette
#'
#' For each candidate bandwidth `h_grid[i]` and class number
#' `k_grid[j]`, runs [ljmds.pipeline()] and computes the functional
#' Rousseeuw silhouette of the resulting partition.  Returns the
#' grid of silhouette values and the maximizer over `k >= k_min`
#' (default 3, to avoid the trivial k = 2 split).
#'
#' @param X Integer/numeric n x p matrix of 0/1 keyword occurrences.
#' @param t Numeric vector of length n.
#' @param h_grid Numeric vector of candidate bandwidths.
#' @param k_grid Integer vector of candidate class numbers.
#' @param k_min Smallest k considered admissible (default 3).
#' @return A list with class `"ljmds_sel"`:
#'   - `S`: matrix of silhouette values, rows = h_grid, cols = k_grid,
#'   - `h_hat`, `k_hat`: maximizer over k >= k_min,
#'   - `S_hat`: silhouette at the maximizer,
#'   - `h_grid`, `k_grid`, `k_min`.
#' @export
ljmds.select <- function(X, t, h_grid, k_grid = 2:6, k_min = 3) {
  S <- matrix(NA_real_, length(h_grid), length(k_grid),
              dimnames = list(paste0("h", h_grid),
                              paste0("k", k_grid)))
  for (i in seq_along(h_grid)) {
    for (j in seq_along(k_grid)) {
      fit <- ljmds.pipeline(X, t, h = h_grid[i], k = k_grid[j])
      S[i, j] <- ljmds.silhouette(fit$f, fit$labels)
    }
  }
  ## maximizer over admissible k
  ad <- k_grid >= k_min
  S_ad <- S[, ad, drop = FALSE]
  best <- which(S_ad == max(S_ad, na.rm = TRUE), arr.ind = TRUE)[1, ]
  out <- list(S = S, h_grid = h_grid, k_grid = k_grid,
              k_min = k_min,
              h_hat = h_grid[best[1]],
              k_hat = k_grid[ad][best[2]],
              S_hat = S_ad[best[1], best[2]])
  class(out) <- "ljmds_sel"
  out
}
