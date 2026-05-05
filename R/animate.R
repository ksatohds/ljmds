#' Animated visualisation of the configuration map
#'
#' Generates a GIF in which keyword positions \eqn{\bm{y}_j(t)} are
#' redrawn each year with font size proportional to the smoothed
#' occurrence \eqn{f_j(t)}, class colours, and a fading trail of the
#' class centroids over the previous `trail` frames.
#'
#' @param x An object returned by [ljmds.pipeline()].
#' @param file Output GIF path.
#' @param trail Number of trailing frames for the centroid trail.
#' @param fps Frames per second.
#' @param class.col Optional colour palette for the classes.
#'   Defaults to the current R palette (`grDevices::palette.colors(8, "Classic Tableau")`);
#'   recycled if `k` exceeds its length.
#' @param frame.dir Optional directory to keep the per-frame PNGs;
#'   if `NULL` (default) a temporary directory is used.
#' @return The output GIF file path (invisibly).
#' @seealso [ljmds.pipeline()] which produces the input object,
#'   [plot.ljmds()] for the static counterparts of the animation.
#' @export
ljmds.animate <- function(x, file = "ljmds_animation.gif",
                       trail = 7, fps = 2,
                       class.col = grDevices::palette.colors(8, "Classic Tableau"),
                       frame.dir = NULL) {
  stopifnot(inherits(x, "ljmds"))
  if (!requireNamespace("magick", quietly = TRUE))
    stop("Package 'magick' is required for ljmds.animate().")

  n <- nrow(x$xs); p <- ncol(x$xs)
  cols <- class.col[(seq_len(x$k) - 1) %% length(class.col) + 1]
  cl_cols <- cols[x$labels]
  cent_x <- matrix(0, n, x$k); cent_y <- matrix(0, n, x$k)
  for (j in seq_len(x$k)) {
    members <- which(x$labels == j)
    cent_x[, j] <- if (length(members) > 1) rowMeans(x$xs[, members]) else x$xs[, members]
    cent_y[, j] <- if (length(members) > 1) rowMeans(x$ys[, members]) else x$ys[, members]
  }

  myrange <- c(-0.4, 0.4)

  cleanup <- is.null(frame.dir)
  if (cleanup) frame.dir <- tempfile("ljmds_frames_")
  dir.create(frame.dir, showWarnings = FALSE, recursive = TRUE)
  if (cleanup)
    on.exit(unlink(frame.dir, recursive = TRUE), add = TRUE)

  for (i in 1:n) {
    fr <- sprintf("%s/frame_%03d.png", frame.dir, i)
    grDevices::png(fr, pointsize = 18, height = 800, width = 800)
    graphics::par(mar = c(2, 2, 2, 2))
    graphics::plot(x$xs[i, ], x$ys[i, ], type = "n",
                   xlab = "", ylab = "", main = "",
                   xlim = myrange, ylim = myrange, axes = FALSE)
    start <- max(1, i - trail)
    if (i > start) {
      n_seg <- i - start
      alphas <- seq(0.10, 1.0, length.out = n_seg)
      for (j in seq_len(x$k)) {
        for (m_ in (start + 1):i) {
          a_ <- alphas[m_ - start]
          graphics::segments(cent_x[m_ - 1, j], cent_y[m_ - 1, j],
                             cent_x[m_, j], cent_y[m_, j],
                             col = grDevices::adjustcolor(cols[j], alpha.f = a_),
                             lwd = 4)
        }
      }
    }
    fonts <- 1.5 * x$f[i, ] + 0.5
    graphics::text(x$xs[i, ], x$ys[i, ], x$keywords, font = 2,
                   cex = fonts,
                   col = grDevices::adjustcolor(cl_cols, alpha.f = 0.85))
    for (j in seq_len(x$k))
      graphics::points(cent_x[i, j], cent_y[i, j], pch = 21, cex = 2.6,
                       bg = cols[j], col = "black", lwd = 2)
    graphics::text(0, 0.35, x$t[i], cex = 3, font = 2)
    grDevices::dev.off()
  }

  imgs <- magick::image_read(sprintf("%s/frame_%03d.png", frame.dir, 1:n))
  magick::image_write(magick::image_animate(imgs, fps = fps, loop = 0),
                      file)
  invisible(file)
}
