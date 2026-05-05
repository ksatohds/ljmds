# ljmds: Local Jaccard MDS for Longitudinal Binary Data

R package implementing the methodology of Satoh (2026): visualisation
of longitudinal binary data (a time × attribute 0/1 matrix) by a
locally weighted Jaccard distance, multidimensional scaling with
sequential modification (Mizuta, 2003), Ward clustering on a
trajectory distance, and a functional Rousseeuw silhouette criterion
for joint selection of bandwidth and class number.

## Animated examples

Each frame plots the attributes on the modified MDS configuration
$\bm{y}_j(t)$ at calendar year $t$, with font/symbol size proportional
to the smoothed occurrence $f_j(t)$ and a fading trail of class
centroids over the previous frames.  Cluster colours follow the
default Classic Tableau palette and the silhouette criterion
$\mathcal{S}(k, h)$ jointly selects $(k, h)$ from a user-supplied
grid.

| Peace Declaration of Hiroshima (1947–2025, $h = 8$, $k = 4$) | US Presidential Inaugural Addresses (1789–2021, $h = 50$, $k = 3$) | Eurovision Song Contest (1956–2023, $h = 20$, $k = 5$) |
|:---:|:---:|:---:|
| ![Peace Declaration animation](inst/extdata/peace_declaration.gif) | ![Inaugural Addresses animation](inst/extdata/inaugural.gif) | ![Eurovision animation](inst/extdata/eurovision.gif) |

## Installation

```r
# Install from GitHub (private — request access from the author)
remotes::install_github("ksatohds/ljmds", build_vignettes = TRUE)
```

## Quick start

```r
library(ljmds)

# Peace Declaration of Hiroshima (built-in)
d <- ljmds.read.csv("peace_declaration")   # year + 95 keyword 0/1 columns
# d <- ljmds.read.csv("inaugural")          # alternative built-in
# d <- ljmds.read.csv(file = "my.csv")      # external CSV

# Joint (h, k) selection over a grid
# k = 1, 2 are excluded by leaving them out of k.grid (default 3:6).
sel <- ljmds.select(d$X, d$t,
                    h.grid = c(3, 4, 5, 6, 8, 10, 12, 15, 20))
sel$h.hat   # 8
sel$k.hat   # 4
sel$S.hat   # 0.201

# Full pipeline
fit <- ljmds.pipeline(d$X, d$t, h = sel$h.hat, k = sel$k.hat)

# Figures (default class.col = grDevices::palette.colors(8, "Classic Tableau"))
plot(fit, type = "trajectory")    # centroid trajectories on MDS map
plot(fit, type = "dendrogram")    # Ward dendrogram + class boxes
plot(fit, type = "cmd")           # time-collapsed MDS of trajectory distance
plot(fit, type = "means")         # class mean occurrence curves
plot(fit, type = "panels")        # per-class small multiples (square layout)
plot(sel)                          # silhouette heatmap with maximizer marker

# GIF animation
ljmds.animate(fit, file = "peace_declaration.gif", trail = 10, fps = 2)
```

## Data

Three longitudinal binary datasets ship under `inst/extdata`:

| File | n × p | Domain | Coverage |
|---|---|---|---|
| `peace_declaration.csv` | 78 × 95 | Text | Peace Declaration of Hiroshima, 1947–2025 (no 1950) |
| `inaugural.csv`         | 59 × 106 | Text | US Presidential Inaugural Addresses, 1789–2021 |
| `eurovision.csv`        | 68 × 52 | Non-text | Eurovision Song Contest country participation, 1956–2023 |

Each file has a header row, column 1 named `year`, and columns 2..
giving 0/1 indicators (keyword presence for the first two, country
participation for the third). The first two contain **no source
text** — they are derivative summaries; the third is a non-text
example showing that the methodology applies beyond text mining
(`eurovision.csv` is derived from the [Amsterdam Music Lab
Mirovision](https://github.com/Amsterdam-Music-Lab/mirovision)
project, MIT-licensed).

## Vignettes

```r
vignette("quickstart-peace", package = "ljmds")
vignette("quickstart-inaugural", package = "ljmds")
vignette("quickstart-eurovision", package = "ljmds")
```

Each vignette starts from the bundled CSV and reproduces the
diagnostic figures used in the corresponding application section
of the paper.

## References

- Rousseeuw, P.J. (1987) Silhouettes: a graphical aid to the
  interpretation and validation of cluster analysis.
  *Journal of Computational and Applied Mathematics* **20**, 53–65.
- Mizuta, M. (2003) Multidimensional scaling for dissimilarity
  functions with continuous argument.
  *Journal of the Japanese Society of Computational Statistics*
  **15**(2), 327–333.

## License

MIT.
