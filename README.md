# ljmds: Local Jaccard MDS for Longitudinal Binary Text Data

R package implementing the methodology of Satoh (2026): visualisation
of longitudinal binary text data (year × keyword indicator matrix) by
a locally weighted Jaccard distance, multidimensional scaling with
sequential modification (Mizuta, 2003), Ward clustering on a
trajectory distance, and a functional Rousseeuw silhouette criterion
for joint selection of bandwidth and class number.

## Installation

```r
# Install from GitHub (private — request access from the author)
remotes::install_github("ksatohds/ljmds", build_vignettes = TRUE)
```

## Quick start

```r
library(ljmds)

# Peace Declaration of Hiroshima
csv <- system.file("extdata", "peace_declaration.csv", package = "ljmds")
d   <- lj_read_csv(csv)             # year + 95 keyword 0/1 columns

# Joint (h, k) selection over a grid
sel <- lj_select(d$X, d$t,
                 h_grid = c(3, 4, 5, 6, 8, 10, 12, 15, 20, 30, 50),
                 k_grid = 3:6)
sel$h_hat   # 8
sel$k_hat   # 4

# Full pipeline
fit <- lj_pipeline(d$X, d$t, h = sel$h_hat, k = sel$k_hat)

# Figures
plot(fit, type = "trajectory")    # centroid trajectories on MDS map
plot(fit, type = "dendrogram")    # Ward dendrogram + class boxes
plot(fit, type = "cmd")           # time-collapsed MDS of trajectory distance
plot(fit, type = "means")         # class mean occurrence curves
plot(fit, type = "panels")        # per-class small multiples
plot(sel)                          # silhouette over the (h, k) grid

# GIF animation
lj_animate(fit, file = "peace_declaration.gif", trail = 10, fps = 2)
```

## Data

Two longitudinal binary keyword corpora ship under `inst/extdata`:

| File | n × p | Coverage |
|---|---|---|
| `peace_declaration.csv` | 78 × 95 | Peace Declaration of Hiroshima, 1947–2025 (no 1950) |
| `inaugural.csv`         | 59 × 106 | US Presidential Inaugural Addresses, 1789–2021 |

Each file has a header row, column 1 named `year`, and columns 2..
giving 0/1 indicators of keyword presence. **No source text is
included** — the matrices are derivative summaries.

## Vignettes

```r
vignette("quickstart-peace", package = "ljmds")
vignette("quickstart-inaugural", package = "ljmds")
```

Each vignette starts from the CSV and reproduces the diagnostic
figures used in the corresponding application section of the paper.

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
