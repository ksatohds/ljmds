#' Rousseeuw silhouette in functional L2 space
#'
#' Computes Rousseeuw's silhouette (Rousseeuw, 1987) for a partition of
#' keywords on the smoothed occurrence curves \eqn{f_j(t)}.  The within
#' and between distances are pairwise functional \eqn{L_2} distances.
#' Singleton classes contribute zero, following Rousseeuw's convention.
#'
#' @param f Numeric matrix of size n x p; column j is the smoothed
#'   occurrence curve of keyword j.
#' @param cl Integer vector of length p with cluster assignments.
#' @return Mean silhouette width (scalar) or a per-keyword vector.
#' @references Rousseeuw, P.J. (1987) Silhouettes: a graphical aid to
#'   the interpretation and validation of cluster analysis.
#'   *Journal of Computational and Applied Mathematics* **20**, 53--65.
#' @export
lj_silhouette <- function(f, cl) {
  mean(lj_silhouette_per_keyword(f, cl))
}

#' @rdname lj_silhouette
#' @export
lj_silhouette_per_keyword <- function(f, cl) {
  pp <- ncol(f); uc <- sort(unique(cl))
  D <- matrix(0, pp, pp)
  for (j in 1:(pp - 1)) for (i in (j + 1):pp) {
    D[j, i] <- sqrt(sum((f[, j] - f[, i])^2)); D[i, j] <- D[j, i]
  }
  s <- numeric(pp)
  for (jj in seq_len(pp)) {
    own <- which(cl == cl[jj])
    if (length(own) <= 1) { s[jj] <- 0; next }
    a <- mean(D[jj, setdiff(own, jj)])
    bb <- numeric(0)
    for (oc in setdiff(uc, cl[jj])) {
      idx <- which(cl == oc); bb <- c(bb, mean(D[jj, idx]))
    }
    b <- min(bb)
    s[jj] <- (b - a) / max(a, b, 1e-12)
  }
  s
}
