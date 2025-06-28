# socjobmarket Package Setup Script
# Run this script to set up the package for development and testing

# Required packages for development
required_packages <- c(
  "devtools", "roxygen2", "testthat", "knitr", "rmarkdown",
  "data.table", "dplyr", "ggplot2", "purrr", "tidyr", "scales", "parallel"
)

# Install missing packages
missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(missing_packages)) {
  cat("Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
  install.packages(missing_packages)
}

# Load devtools for package development
library(devtools)

cat("=== socjobmarket Package Setup ===\n\n")

# 1. Generate documentation
cat("1. Generating documentation...\n")
document()

# 2. Install the package
cat("2. Installing package...\n")
install()

# 3. Load the package
cat("3. Loading package...\n")
library(socjobmarket)

# 4. Run basic tests
cat("4. Running basic tests...\n")

# Test agent creation
cat("   Testing agent creation...\n")
student <- create_graduate_student(1, 2020)
faculty <- create_faculty(1, 1, "assistant")
department <- create_department(1)

cat("   ✓ Agent creation works\n")

# Test basic simulation (small scale)
cat("   Testing basic simulation...\n")
test_results <- run_simulation_optimized(
  seed = 123,
  simulation_years = 5,    # Short test
  annual_phd_cohort = 50,  # Small cohort
  num_departments = 20     # Few departments
)

cat("   ✓ Basic simulation works\n")

# Test plotting
cat("   Testing plotting functions...\n")
test_plot <- create_single_simulation_plot(test_results)
cat("   ✓ Plotting functions work\n")

# 5. Run unit tests if available
cat("5. Running unit tests...\n")
if (dir.exists("tests")) {
  test_results <- test()
  cat("   ✓ Unit tests completed\n")
} else {
  cat("   No unit tests found\n")
}

# 6. Build vignettes
cat("6. Building vignettes...\n")
if (dir.exists("vignettes")) {
  build_vignettes()
  cat("   ✓ Vignettes built\n")
} else {
  cat("   No vignettes found\n")
}

# 7. Package check
cat("7. Running package check...\n")
check_results <- check()

if (length(check_results$errors) == 0 && length(check_results$warnings) == 0) {
  cat("   ✓ Package check passed\n")
} else {
  cat("   ⚠ Package check found issues\n")
  if (length(check_results$errors) > 0) {
    cat("   Errors:", length(check_results$errors), "\n")
  }
  if (length(check_results$warnings) > 0) {
    cat("   Warnings:", length(check_results$warnings), "\n")
  }
}

cat("\n=== Setup Complete ===\n")
cat("Package is ready for use!\n\n")

# Example usage
cat("Example usage:\n")
cat("library(socjobmarket)\n")
cat("results <- run_simulation_optimized(seed = 123)\n")
cat("plot <- create_single_simulation_plot(results)\n")
cat("print(plot)\n\n")

cat("For full analysis:\n")
cat("analysis <- main_scenario_analysis(n_sims = 25, output_dir = 'results/')\n\n")

cat("Next steps:\n")
cat("1. Customize parameters in R/simulation_parameters.R\n")
cat("2. Add your own scenarios using get_predefined_scenarios() as a template\n")
cat("3. Run comprehensive analysis with main_scenario_analysis()\n")
cat("4. View results in generated CSV and PDF files\n")
cat("5. Publish to GitHub and enable GitHub Pages for documentation\n")