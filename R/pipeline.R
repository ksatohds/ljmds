#' Local Jaccard MDS pipeline at fixed (h, k)
#'
#' Run the full pipeline of local Jaccard distance, multi-dimensional
#' scaling with sequential Mizuta modification, trajectory distance,
#' and Ward clustering.  Returns the cluster labels, the per-time
#' configurations, the trajectory distance, the smoothed curves and
#' the class mean curves.
#'
#' @param X Integer/numeric n x p matrix of 0/1 keyword occurrences.
#'   Rows are time points, columns keywords.
#' @param t Numeric vector of length n giving the time of each row.
#' @param h Bandwidth (standard deviation of the Gaussian kernel).
#' @param k Number of classes.
#' @return A list with class `"ljmds"`:
#'   - `labels`: integer p-vector of cluster ids,
#'   - `xs`, `ys`: n x p matrices of MDS coordinates,
#'   - `H`: p x p trajectory distance,
#'   - `f`: n x p smoothed occurrence curves,
#'   - `m`: n x k class mean curves,
#'   - `t`, `h`, `k`, `keywords`.
#' @seealso [ljmds.read.csv()] to load a corpus,
#'   [ljmds.select()] to choose `(h, k)` from a grid,
#'   [ljmds.silhouette()] for the criterion used inside
#'   `ljmds.select()`, [plot.ljmds()] for diagnostic figures,
#'   [ljmds.animate()] to render a GIF.
#' @export
ljmds.pipeline <- function(X, t, h, k) {
  X <- as.matrix(X); X[X > 0] <- 1
  storage.mode(X) <- "double"
  n <- nrow(X); p <- ncol(X)
  kw <- colnames(X); if (is.null(kw)) kw <- paste0("v", seq_len(p))

  xs <- matrix(0, n, p); ys <- matrix(0, n, p); old <- NULL
  f  <- matrix(0, n, p); colnames(f) <- kw

  for (i in 1:n) {
    w <- stats::dnorm(t, mean = t[i], sd = h); w <- w / sum(w)
    f[i, ] <- as.numeric(crossprod(w, X))
    distx <- matrix(0, p, p)
    for (a in 1:(p - 1)) for (b in (a + 1):p) {
      num   <- sum(w * (X[, a] * (1 - X[, b]) +
                          (1 - X[, a]) * X[, b]))
      denom <- 1 - sum(w * (1 - X[, a]) * (1 - X[, b]))
      d_ab <- if (denom <= 1e-12) 0 else num / denom
      if (!is.finite(d_ab)) d_ab <- 0
      distx[a, b] <- d_ab; distx[b, a] <- d_ab
    }
    res <- stats::cmdscale(distx)
    if (is.null(old)) old <- res
    Y <- as.matrix(old); Xm <- as.matrix(res)
    B  <- t(Xm) %*% Y %*% t(Y) %*% Xm
    eg <- eigen(B); P <- eg$vectors
    ev <- pmax(eg$values, 0)
    Bhalf  <- P %*% diag(sqrt(ev)) %*% t(P)
    IBhalf <- tryCatch(solve(Bhalf),
                       error = function(e) MASS::ginv(Bhalf))
    Q <- IBhalf %*% t(Xm) %*% Y
    res <- Xm %*% Q
    xs[i, ] <- res[, 1]; ys[i, ] <- res[, 2]; old <- res
  }

  H <- matrix(0, p, p)
  for (a in 1:(p - 1)) for (b in (a + 1):p) {
    H[a, b] <- sum(sqrt((xs[, a] - xs[, b])^2 + (ys[, a] - ys[, b])^2))
    H[b, a] <- H[a, b]
  }
  rownames(H) <- colnames(H) <- kw

  hc  <- stats::hclust(stats::as.dist(H), method = "ward.D2")
  cl  <- stats::cutree(hc, k = k)

  ## Reorder cluster IDs deterministically: descending class size,
  ## ties broken by ascending sum of column indices.  Independent of
  ## dendrogram subtree orientation, so the labelling is reproducible
  ## across runs and BLAS builds.
  sizes <- tabulate(cl, nbins = k)
  idx.sum <- vapply(seq_len(k),
                    function(j) sum(which(cl == j)),
                    numeric(1))
  new.order <- order(-sizes, idx.sum)
  perm <- order(new.order)
  cl   <- perm[cl]

  ## Class mean curves
  m <- matrix(0, n, k)
  for (j in 1:k) {
    members <- which(cl == j)
    m[, j] <- if (length(members) > 1) rowMeans(f[, members]) else f[, members]
  }

  out <- list(labels = cl, xs = xs, ys = ys, H = H,
              f = f, m = m, hc = hc,
              t = t, h = h, k = k, keywords = kw)
  class(out) <- "ljmds"
  out
}
