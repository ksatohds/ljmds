#' Animated visualisation of the configuration map
#'
#' Renders one PNG frame per observed time point on the modified
#' MDS configuration: each attribute is drawn at
#' \eqn{\bm{y}_j(t)} with symbol size proportional to the smoothed
#' occurrence \eqn{f_j(t)}, class colours, and a fading trail of
#' the class centroids over the previous `trail` frames.
#'
#' Frame generation uses only base R graphics, so it works in a
#' minimal install.  When the \pkg{magick} package is available
#' the per-time PNGs are additionally assembled into a GIF
#' animation; otherwise the GIF assembly step is skipped (with a
#' message) and the frames are kept on disk so the user can
#' assemble the GIF later by another tool.
#'
#' @param x An object returned by [ljmds.pipeline()].
#' @param file Output GIF path (used only when \pkg{magick} is
#'   available).
#' @param trail Number of trailing frames for the centroid trail.
#' @param fps Frames per second of the GIF.
#' @param class.col Optional colour palette for the classes.
#'   Defaults to `grDevices::palette.colors(8, "Classic Tableau")`,
#'   recycled if `k` exceeds its length.
#' @param frame.dir Optional directory in which to write the
#'   per-frame PNGs.  If `NULL` (default) and \pkg{magick} is
#'   available, a temporary directory is used and removed after
#'   the GIF has been written; if \pkg{magick} is not available,
#'   a fresh directory `ljmds_frames` is created in the current
#'   working directory and kept (so the frames are not lost).
#' @return Invisibly, the GIF file path when \pkg{magick} is
#'   available, otherwise the directory containing the per-frame
#'   PNGs.
#' @seealso [ljmds.pipeline()] which produces the input object,
#'   [plot.ljmds()] for the static counterparts of the animation.
#' @export
ljmds.animate <- function(x, file = "ljmds_animation.gif",
                       trail = 7, fps = 2,
                       class.col = grDevices::palette.colors(8, "Classic Tableau"),
                       frame.dir = NULL) {
  stopifnot(inherits(x, "ljmds"))

  has_magick <- requireNamespace("magick", quietly = TRUE)

  n <- nrow(x$xs); p <- ncol(x$xs)
  cols <- class.col[(seq_len(x$k) - 1) %% length(class.col) + 1]
  cl_cols <- cols[x$labels]
  cent_x <- matrix(0, n, x$k); cent_y <- matrix(0, n, x$k)
  for (j in seq_len(x$k)) {
    members <- which(x$labels == j)
    cent_x[, j] <- if (length(members) > 1) rowMeans(x$xs[, members]) else x$xs[, members]
    cent_y[, j] <- if (length(members) > 1) rowMeans(x$ys[, members]) else x$ys[, members]
  }

  ## Common axis range across all frames so that every keyword
  ## position at every time point is visible and the extent
  ## never changes during the animation.  No outer padding.
  xlim_all <- range(x$xs)
  ylim_all <- range(x$ys)

  ## Decide the frame directory and whether to clean up after
  ## GIF assembly.  When magick is missing we always keep the
  ## frames so the user does not silently lose them.
  user_supplied <- !is.null(frame.dir)
  if (!user_supplied) {
    frame.dir <- if (has_magick) tempfile("ljmds_frames_")
                 else            file.path(getwd(), "ljmds_frames")
  }
  dir.create(frame.dir, showWarnings = FALSE, recursive = TRUE)
  cleanup <- has_magick && !user_supplied
  if (cleanup)
    on.exit(unlink(frame.dir, recursive = TRUE), add = TRUE)

  for (i in 1:n) {
    fr <- sprintf("%s/frame_%03d.png", frame.dir, i)
    grDevices::png(fr, pointsize = 18, height = 800, width = 800)
    graphics::par(mar = c(0.5, 0.5, 0.5, 0.5))
    graphics::plot(x$xs[i, ], x$ys[i, ], type = "n",
                   xlab = "", ylab = "", main = "",
                   xlim = xlim_all, ylim = ylim_all, axes = FALSE)
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
    ## Year at the top-left corner, hugging the visible region.
    graphics::text(xlim_all[1], ylim_all[2],
                   x$t[i], cex = 3, font = 2,
                   adj = c(0, 1))
    grDevices::dev.off()
  }

  if (has_magick) {
    imgs <- magick::image_read(sprintf("%s/frame_%03d.png",
                                       frame.dir, 1:n))
    magick::image_write(magick::image_animate(imgs, fps = fps, loop = 0),
                        file)
    invisible(file)
  } else {
    message("Package 'magick' is not installed; ",
            "skipping GIF assembly.  Per-frame PNGs are at:\n  ",
            normalizePath(frame.dir))
    invisible(frame.dir)
  }
}
