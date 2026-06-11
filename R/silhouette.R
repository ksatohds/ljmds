#' Rousseeuw silhouette in functional L2 space
#'
#' Computes Rousseeuw's silhouette (Rousseeuw, 1987) for a partition of
#' keywords on the smoothed occurrence curves \eqn{f_j(t)}.  The within
#' and between distances are pairwise functional \eqn{L_2} distances.
#' Singleton classes contribute zero, following Rousseeuw's convention.
#'
#' With `type = "mean"` (the default) the within- and between-class
#' summaries are arithmetic means of the \eqn{L_2} distances, i.e. the
#' standard Rousseeuw silhouette.  With `type = "rms"` they are
#' root-mean-square distances
#' (\eqn{\sqrt{|C|^{-1}\sum_i \|f_j-f_i\|_2^2}}); each squared term is
#' then an unbiased estimator of the squared oracle distance of the
#' homogeneous-noise model, so the resulting criterion is the exact
#' plug-in estimator of the oracle criterion.  The two variants select
#' the same `(h, k)` on the three bundled datasets; `"mean"` is
#' retained as the default for its classical interpretation and
#' robustness to within-class heterogeneity.
#'
#' @param f Numeric matrix of size n x p; column j is the smoothed
#'   occurrence curve of keyword j.
#' @param cl Integer vector of length p with cluster assignments.
#' @param type Aggregation of the within/between distances: `"mean"`
#'   (standard Rousseeuw, the default) or `"rms"` (root-mean-square,
#'   the plug-in estimator of the oracle criterion).
#' @return Mean silhouette width (scalar) or a per-keyword vector.
#' @references Rousseeuw, P.J. (1987) Silhouettes: a graphical aid to
#'   the interpretation and validation of cluster analysis.
#'   *Journal of Computational and Applied Mathematics* **20**, 53--65.
#' @seealso [ljmds.pipeline()] which produces the `(f, labels)`
#'   inputs, [ljmds.select()] which uses this criterion to pick
#'   `(h, k)`.
#' @export
ljmds.silhouette <- function(f, cl, type = c("mean", "rms")) {
  mean(ljmds.silhouette.per.keyword(f, cl, type = type))
}

#' @rdname ljmds.silhouette
#' @export
ljmds.silhouette.per.keyword <- function(f, cl, type = c("mean", "rms")) {
  type <- match.arg(type)
  pp <- ncol(f); uc <- sort(unique(cl))
  ## squared L2 distances; the L2 distance is its square root
  D2 <- matrix(0, pp, pp)
  for (j in 1:(pp - 1)) for (i in (j + 1):pp) {
    D2[j, i] <- sum((f[, j] - f[, i])^2); D2[i, j] <- D2[j, i]
  }
  ## summary of distances from keyword jj to an index set: arithmetic
  ## mean of L2 distances ("mean") or root-mean-square ("rms")
  agg <- function(jj, idx) {
    if (type == "rms") sqrt(mean(D2[jj, idx])) else mean(sqrt(D2[jj, idx]))
  }
  s <- numeric(pp)
  for (jj in seq_len(pp)) {
    own <- which(cl == cl[jj])
    if (length(own) <= 1) { s[jj] <- 0; next }
    a <- agg(jj, setdiff(own, jj))
    bb <- numeric(0)
    for (oc in setdiff(uc, cl[jj])) bb <- c(bb, agg(jj, which(cl == oc)))
    b <- min(bb)
    s[jj] <- (b - a) / max(a, b, 1e-12)
  }
  s
}
