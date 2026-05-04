#' Plot methods for ljmds objects
#'
#' Reproduces the diagnostic figures used in Satoh (2026):
#' - `"trajectory"`: cluster centroid trajectories on the
#'    modified MDS configuration (Figure of `inaug_trajectory`/
#'    `trajectorysd10` in the paper).
#' - `"dendrogram"`: Ward dendrogram on H with k boxes.
#' - `"cmd"`: time-collapsed MDS map of H, points coloured by class.
#' - `"means"`: class mean curves on the same axes.
#' - `"panels"`: 2x2 small multiples, one panel per class, showing
#'    individual smoothed curves and the class mean.
#'
#' @param x An object returned by [lj_pipeline()].
#' @param type One of `"trajectory"`, `"dendrogram"`, `"cmd"`,
#'   `"means"`, `"panels"`.
#' @param mycol Optional 4-colour palette for the classes.
#' @param ... Further arguments passed to underlying plot calls.
#' @export
plot.ljmds <- function(x, type = c("trajectory", "dendrogram", "cmd",
                                    "means", "panels"),
                       mycol = c("green4", "purple", "red", "orange"),
                       ...) {
  type <- match.arg(type)
  k <- x$k
  cols <- mycol[(seq_len(k) - 1) %% length(mycol) + 1]
  switch(type,
    trajectory = .plot_trajectory(x, cols, ...),
    dendrogram = .plot_dendrogram(x, cols, ...),
    cmd        = .plot_cmd(x, cols, ...),
    means      = .plot_means(x, cols, ...),
    panels     = .plot_panels(x, cols, ...)
  )
  invisible(x)
}

.plot_trajectory <- function(x, cols, ...) {
  cent_x <- matrix(0, nrow(x$xs), x$k)
  cent_y <- matrix(0, nrow(x$ys), x$k)
  for (j in seq_len(x$k)) {
    members <- which(x$labels == j)
    cent_x[, j] <- if (length(members) > 1) rowMeans(x$xs[, members]) else x$xs[, members]
    cent_y[, j] <- if (length(members) > 1) rowMeans(x$ys[, members]) else x$ys[, members]
  }
  xrange <- range(cent_x) + c(-0.05, 0.20) * diff(range(cent_x))
  yrange <- range(cent_y) + c(-0.10, 0.10) * diff(range(cent_y))
  graphics::plot(0, 0, type = "n",
                 xlim = xrange, ylim = yrange,
                 xlab = "", ylab = "", ...)
  for (j in seq_len(x$k))
    graphics::lines(cent_x[, j], cent_y[, j], col = cols[j], lwd = 4)
  j0 <- c(1, length(x$t))
  for (j in seq_len(x$k)) {
    graphics::points(cent_x[j0, j], cent_y[j0, j], pch = 21, cex = 2,
                     bg = cols[j], col = "black", lwd = 1.5)
    graphics::text(cent_x[j0, j], cent_y[j0, j], x$t[j0],
                   cex = 0.95, font = 2, pos = 4, offset = 0.5)
  }
  graphics::legend("top", bg = "white", ncol = x$k, cex = 0.95,
                   legend = sprintf("Class %d", seq_len(x$k)),
                   lwd = 4, col = cols)
}

.plot_dendrogram <- function(x, cols, ...) {
  graphics::plot(x$hc, cex = 0.5, hang = -1, ...)
  if (requireNamespace("dendextend", quietly = TRUE)) {
    dendextend::rect.dendrogram(stats::as.dendrogram(x$hc),
                                k = x$k, border = cols, lwd = 3)
  } else {
    stats::rect.hclust(x$hc, k = x$k, border = cols)
  }
}

.plot_cmd <- function(x, cols, ...) {
  cmd <- stats::cmdscale(stats::as.dist(x$H))
  cl_cols <- cols[x$labels]
  graphics::plot(cmd, type = "n", xlab = "", ylab = "", ...)
  graphics::text(cmd[, 1], cmd[, 2], labels = rownames(cmd),
                 col = cl_cols, cex = 0.85)
}

.plot_means <- function(x, cols, ...) {
  graphics::plot(c(0, 0), type = "n",
                 xlim = range(x$t), ylim = c(0, 1),
                 xlab = "calendar year",
                 ylab = "occurrence probability",
                 main = "class mean curves", ...)
  for (j in seq_len(x$k))
    graphics::lines(x$t, x$m[, j], col = cols[j], lwd = 6)
  graphics::legend("top", bg = "white", ncol = x$k,
                   legend = paste0("class", seq_len(x$k)),
                   lwd = 5, col = cols)
}

.plot_panels <- function(x, cols, ...) {
  k  <- x$k
  nr <- floor(sqrt(k))
  nc <- ceiling(k / nr)
  op <- graphics::par(mfrow = c(nr, nc), mar = c(4, 4, 2, 1))
  on.exit(graphics::par(op))
  for (j in seq_len(k)) {
    members <- which(x$labels == j)
    graphics::plot(c(0, 0), type = "n",
                   xlim = range(x$t), ylim = c(0, 1),
                   xlab = "calendar year",
                   ylab = "occurrence probability",
                   main = sprintf("Class %d (n = %d)", j, length(members)),
                   ...)
    for (jj in members)
      graphics::lines(x$t, x$f[, jj], lwd = 1, col = "grey60")
    graphics::lines(x$t, x$m[, j], col = cols[j], lwd = 6)
  }
}

#' @rdname plot.ljmds
#' @export
plot.ljmds_sel <- function(x, mycol = c("green4", "purple", "red", "orange"),
                           ...) {
  k_grid <- x$k_grid; h_grid <- x$h_grid
  graphics::matplot(h_grid, x$S, type = "b", pch = 19, lty = 1, lwd = 2,
                    log = "x",
                    xlab = expression(bandwidth ~ h),
                    ylab = expression(S(k, h)), ...)
  graphics::legend("topright", legend = paste0("k=", k_grid),
                   col = seq_along(k_grid), pch = 19, lwd = 2,
                   bg = "white")
  graphics::abline(v = x$h_hat, col = "red", lty = 2, lwd = 2)
}
