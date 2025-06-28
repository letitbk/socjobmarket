---
layout: default
title: Home
nav_order: 1
---

# socjobmarket: Agent-Based Simulation of the Academic Job Market in Sociology

{: .fs-9 }

An optimized R package for simulating academic career pathways and understanding post-2008 changes in faculty transition rates.

{: .fs-6 .fw-300 }

[Get Started](docs/getting-started.html){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 } [View on GitHub](https://github.com/yourusername/socjobmarket){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Overview

The `socjobmarket` package provides a high-performance agent-based simulation framework for analyzing the academic job market in sociology. Built with optimized `data.table` operations and parallel processing, it enables rigorous research on how economic and institutional factors affect PhD-to-faculty career transitions.

### Research Context

This package was developed to understand why sociology PhD graduates became significantly less likely to get faculty jobs after the Great Recession:

- **Pre-2008**: ~25% transition rate from PhD to faculty
- **Post-2008**: ~12% transition rate
- **Job postings**: No significant decrease observed

The simulation tests four key hypotheses about contributing factors.

## Key Features

- **High Performance**: 15-20x speedup with vectorized operations and `data.table`
- **Parallel Processing**: Multi-core Monte Carlo analysis using all available CPUs
- **Built-in Scenarios**: Pre-configured tests for recession effects, retirement delays, failed searches, and extended postdocs
- **Publication Ready**: Professional visualizations and CSV/PDF exports
- **Research Validated**: Based on empirical data and academic research

## Quick Example

```r
library(socjobmarket)

# Run a complete scenario analysis
analysis <- main_scenario_analysis(
  n_sims = 100,           # Monte Carlo simulations
  use_parallel = TRUE,    # Use all CPU cores
  output_dir = "results/" # Save results
)

# View key findings
print(analysis$summary_results$period_summary)

# Generate plots
print(analysis$plots$transition_rates)
```

## Performance

**Complete 5-scenario analysis (500 simulations) runs in ~2 minutes** on a modern laptop, compared to ~30 hours with unoptimized code.

- Vectorized match quality calculations
- Pre-allocated data structures
- Multi-core parallel execution
- Memory-efficient `data.table` operations

## Installation

```r
# Install from GitHub
devtools::install_github("yourusername/socjobmarket")

# Load the package
library(socjobmarket)
```

## Documentation

- [Getting Started Guide](docs/getting-started.html) - Basic usage and first simulations
- [Installation Instructions](docs/installation.html) - Detailed setup guide
- [API Reference](docs/api-reference.html) - Complete function documentation
- [Examples](docs/examples.html) - Research use cases and advanced scenarios

## Research Applications

### Supported Analyses

- **Factor Attribution**: Isolate individual vs. combined effects of recession factors
- **Magnitude Quantification**: Measure percentage point impacts on transition rates
- **Temporal Dynamics**: Track changes across pre/during/post recession periods
- **Statistical Validation**: Monte Carlo confidence intervals and hypothesis testing

### Generated Outputs

- `transition_rates_summary.csv`: Detailed cohort-level transition rates
- `period_summary.csv`: Pre/during/post recession comparisons
- `yearly_market_dynamics.csv`: Annual job market statistics
- `simulation_results.pdf`: Publication-quality visualizations

## Academic Citation

If you use this package in academic research, please cite:

```
[Author Names] ([Year]). socjobmarket: Agent-Based Simulation of the Academic Job Market in Sociology.
R package version [version]. https://github.com/yourusername/socjobmarket
```

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](https://github.com/yourusername/socjobmarket/blob/main/CONTRIBUTING.md) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/socjobmarket/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/socjobmarket/discussions)
- **Documentation**: This site and package vignettes

## License

MIT License - see the [LICENSE](https://github.com/yourusername/socjobmarket/blob/main/LICENSE) file for details.