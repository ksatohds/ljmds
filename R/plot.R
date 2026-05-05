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
#' @param x An object returned by [ljmds.pipeline()].
#' @param type One of `"trajectory"`, `"dendrogram"`, `"cmd"`,
#'   `"means"`, `"panels"`.
#' @param class.col Optional colour palette for the classes.
#'   Defaults to the current R palette (`grDevices::palette.colors(8, "Classic Tableau")`);
#'   recycled if `k` exceeds its length.
#' @param ... Further arguments passed to underlying plot calls.
#' @seealso [ljmds.pipeline()] which produces the object,
#'   [ljmds.select()] for `(h, k)` selection, [ljmds.animate()] for
#'   the dynamic counterpart.
#' @export
plot.ljmds <- function(x, type = c("trajectory", "dendrogram", "cmd",
                                    "means", "panels"),
                       class.col = grDevices::palette.colors(8, "Classic Tableau"),
                       ...) {
  type <- match.arg(type)
  k <- x$k
  cols <- class.col[(seq_len(k) - 1) %% length(class.col) + 1]
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
  ## rect.dendrogram / rect.hclust draws k boxes from left to right
  ## in dendrogram order; assign each box the colour of the class it
  ## actually contains so the boxes match Table / trajectory / means.
  cls_LtoR <- unique(x$labels[x$hc$order])
  box_cols <- cols[cls_LtoR]
  if (requireNamespace("dendextend", quietly = TRUE)) {
    dendextend::rect.dendrogram(stats::as.dendrogram(x$hc),
                                k = x$k, border = box_cols, lwd = 3)
  } else {
    stats::rect.hclust(x$hc, k = x$k, border = box_cols)
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
  nc <- ceiling(sqrt(k))
  nr <- ceiling(k / nc)
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
#' @param pal Diverging or sequential palette used for the heatmap
#'   cells of [plot.ljmds.sel()].  Default is a reversed YlGnBu
#'   sequential palette so that high silhouette values appear
#'   darker.
#' @export
plot.ljmds.sel <- function(x,
                           pal = grDevices::hcl.colors(64, "YlGnBu",
                                                       rev = TRUE),
                           ...) {
  S  <- x$S
  hg <- x$h.grid
  kg <- x$k.grid
  zr <- range(S, finite = TRUE)
  S_disp <- S; S_disp[!is.finite(S_disp)] <- NA
  npal <- length(pal)

  graphics::par(mar = c(4.5, 4.5, 2, 8))
  graphics::image(seq_along(hg), seq_along(kg), S_disp,
                  col = pal, axes = FALSE, zlim = zr,
                  xlab = expression(bandwidth ~ h),
                  ylab = expression(number ~ of ~ classes ~ k),
                  main = expression(silhouette ~ S(k, h)), ...)
  graphics::axis(1, at = seq_along(hg), labels = hg)
  graphics::axis(2, at = seq_along(kg), labels = kg, las = 1)
  graphics::box()

  ## Cell values; text colour from the luminance of the background.
  for (i in seq_along(hg))
    for (j in seq_along(kg)) {
      fr  <- (S[i, j] - zr[1]) / diff(zr)
      fr  <- pmin(pmax(fr, 0), 1)
      idx <- round(1 + fr * (npal - 1))
      rgb <- grDevices::col2rgb(pal[idx])
      luma <- 0.299 * rgb["red", ] + 0.587 * rgb["green", ] +
              0.114 * rgb["blue", ]
      txt_col <- if (luma < 128) "white" else "black"
      graphics::text(i, j, sprintf("%.3f", S[i, j]),
                     col = txt_col, cex = 0.9)
    }

  ## Red rectangle around the maximizer.
  i_hat <- which(hg == x$h.hat)
  j_hat <- which(kg == x$k.hat)
  graphics::rect(i_hat - 0.5, j_hat - 0.5,
                 i_hat + 0.5, j_hat + 0.5,
                 border = "red", lwd = 4)

  ## Vertical colour-bar legend on the right.
  graphics::par(xpd = NA)
  legend_x <- length(hg) + 0.85 + c(0, 0.4)
  legend_y <- seq(0.5, length(kg) + 0.5, length.out = 65)
  for (m in 1:64)
    graphics::rect(legend_x[1], legend_y[m],
                   legend_x[2], legend_y[m + 1],
                   col = pal[m], border = NA)
  graphics::rect(legend_x[1], legend_y[1],
                 legend_x[2], legend_y[65], border = "black")
  ticks_z <- pretty(zr, 5)
  ticks_z <- ticks_z[ticks_z >= zr[1] & ticks_z <= zr[2]]
  for (z in ticks_z) {
    fr <- (z - zr[1]) / diff(zr)
    yy <- legend_y[1] + fr * (legend_y[65] - legend_y[1])
    graphics::segments(legend_x[2], yy,
                       legend_x[2] + 0.10, yy, col = "black")
    graphics::text(legend_x[2] + 0.15, yy, sprintf("%.2f", z),
                   adj = c(0, 0.5), cex = 0.85)
  }
  graphics::par(xpd = FALSE)
  invisible(x)
}
