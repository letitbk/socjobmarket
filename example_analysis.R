# Example Analysis Script for socjobmarket Package
# This script demonstrates the complete research workflow using the socjobmarket package

# Load required packages
library(socjobmarket)
library(ggplot2)
library(dplyr)

cat("=== socjobmarket Example Analysis ===\n")
cat("Demonstrating the complete research workflow\n\n")

# =============================================================================
# PART 1: BASIC SIMULATION
# =============================================================================

cat("PART 1: Basic Single Simulation\n")
cat("Simulating 20 years of academic job market (2000-2020)\n")

# Run a single simulation for exploration
basic_results <- run_simulation_optimized(
  seed = 123,
  simulation_years = 20,
  annual_phd_cohort = 300,
  num_departments = 150
)

# Display basic statistics
summary_stats <- calculate_simple_summary(basic_results)
cat("Basic simulation completed:\n")
cat("  Total years simulated:", summary_stats$total_years, "\n")
cat("  Pre-recession placement rate:", round(summary_stats$pre_placement_rate * 100, 1), "%\n")
cat("  Recession placement rate:", round(summary_stats$recession_placement_rate * 100, 1), "%\n")

# Create and display basic visualization
basic_plot <- create_single_simulation_plot(basic_results, show_details = TRUE)
print(basic_plot)

# =============================================================================
# PART 2: AGENT EXPLORATION
# =============================================================================

cat("\nPART 2: Understanding Agents\n")

# Create sample agents to understand the model
sample_student <- create_graduate_student(1, 2020, prestige_origin = 5)
sample_faculty <- create_faculty(1, 1, "assistant")
sample_department <- create_department(1, prestige_rank = 25)

cat("Sample agents created:\n")
cat("  Graduate student productivity:", sample_student$productivity, "\n")
cat("  Faculty retirement risk:", sample_faculty$retirement_risk, "\n")
cat("  Department search standards:", sample_department$search_standards, "\n")

# Test match quality calculation
match_quality <- calculate_match_quality(sample_student, sample_department)
cat("  Match quality between student and department:", round(match_quality, 3), "\n")

# =============================================================================
# PART 3: SCENARIO COMPARISON
# =============================================================================

cat("\nPART 3: Quick Scenario Comparison\n")
cat("Comparing a few key scenarios with reduced simulations for demonstration\n")

# Get predefined scenarios
scenarios <- get_predefined_scenarios()
cat("Available scenarios:", paste(names(scenarios), collapse = ", "), "\n")

# Run a small scenario analysis (just a few simulations for speed)
cat("Running reduced scenario analysis (10 simulations per scenario)...\n")

scenario_analysis <- main_scenario_analysis(
  n_sims = 10,              # Small number for demonstration
  use_parallel = TRUE,      # Use available cores
  output_dir = "example_results/",
  simulation_years = 15,    # Shorter simulation for speed
  annual_phd_cohort = 200,  # Smaller cohort for speed
  num_departments = 100     # Fewer departments for speed
)

# Display key findings
cat("\nKey Findings from Scenario Analysis:\n")
period_summary <- scenario_analysis$summary_results$period_summary
for(i in 1:nrow(period_summary)) {
  row <- period_summary[i,]
  cat(sprintf("  %s (%s): %.1f%%\n",
              row$scenario_label,
              row$period,
              row$mean_period_rate * 100))
}

# =============================================================================
# PART 4: CUSTOM SCENARIO
# =============================================================================

cat("\nPART 4: Custom Scenario\n")
cat("Creating and testing a custom extreme scenario\n")

# Define an extreme custom scenario
extreme_scenario <- list(
  name = "Extreme Post-2008 Effects",
  retirement_delay_factor = 0.3,    # Very delayed retirement (70% reduction)
  search_standards_inflation = 1.8,  # Much higher hiring standards
  postdoc_duration_multiplier = 2.5, # Much longer postdocs
  search_failure_tolerance = 0.7,    # High willingness to fail searches
  apply_recession_effects = TRUE
)

cat("Testing extreme scenario with the following parameters:\n")
cat("  Retirement delay factor:", extreme_scenario$retirement_delay_factor, "\n")
cat("  Search standards inflation:", extreme_scenario$search_standards_inflation, "\n")
cat("  Postdoc duration multiplier:", extreme_scenario$postdoc_duration_multiplier, "\n")

# Run custom scenario
custom_results <- run_simulation_with_scenario(
  seed = 789,
  scenario = extreme_scenario,
  simulation_years = 15,
  annual_phd_cohort = 200,
  num_departments = 100
)

# Calculate transition rates for custom scenario
custom_transition_rates <- calculate_transition_rates_detailed(
  custom_results$results,
  custom_results$candidate_outcomes
)

if(nrow(custom_transition_rates) > 0) {
  # Calculate period averages
  custom_summary <- custom_transition_rates %>%
    group_by(period) %>%
    summarise(mean_rate = mean(transition_rate, na.rm = TRUE), .groups = "drop")

  cat("Custom scenario results:\n")
  for(i in 1:nrow(custom_summary)) {
    cat(sprintf("  %s: %.1f%%\n",
                custom_summary$period[i],
                custom_summary$mean_rate[i] * 100))
  }
} else {
  cat("Custom scenario: No completed outcomes in simulation period\n")
}

# =============================================================================
# PART 5: VISUALIZATION EXAMPLES
# =============================================================================

cat("\nPART 5: Advanced Visualizations\n")

# Create diagnostic plots
diagnostics <- create_diagnostic_plots(basic_results)
cat("Created diagnostic plots for basic simulation\n")

# Show supply vs demand dynamics
print(diagnostics$supply_vs_demand)

# Create comprehensive plots from scenario analysis
if(!is.null(scenario_analysis$plots)) {
  cat("Displaying scenario comparison plots\n")

  # Main transition rate comparison
  print(scenario_analysis$plots$transition_rates)

  # Period comparison
  print(scenario_analysis$plots$period_comparison)
}

# =============================================================================
# PART 6: RESEARCH APPLICATIONS
# =============================================================================

cat("\nPART 6: Research Applications\n")
cat("This package enables several types of academic research:\n")
cat("  1. Factor Attribution: Isolate individual vs. combined effects\n")
cat("  2. Magnitude Quantification: Measure percentage point impacts\n")
cat("  3. Temporal Analysis: Track changes across recession periods\n")
cat("  4. Policy Simulation: Test interventions and counterfactuals\n")
cat("  5. Sensitivity Analysis: Vary parameters to test robustness\n")

cat("\nFor full research-quality analysis:\n")
cat("  - Use n_sims = 100 or more for statistical power\n")
cat("  - Run full 20-year simulations with realistic population sizes\n")
cat("  - Examine both transition rates and market dynamics\n")
cat("  - Export results to CSV for further statistical analysis\n")
cat("  - Use generated plots in academic publications\n")

# =============================================================================
# SUMMARY
# =============================================================================

cat("\n=== Analysis Complete ===\n")
cat("This example demonstrated:\n")
cat("  ✓ Basic simulation and visualization\n")
cat("  ✓ Agent creation and exploration\n")
cat("  ✓ Scenario comparison analysis\n")
cat("  ✓ Custom scenario development\n")
cat("  ✓ Advanced plotting capabilities\n")
cat("  ✓ Research workflow guidance\n")

cat("\nGenerated files in example_results/:\n")
if(dir.exists("example_results")) {
  files <- list.files("example_results", pattern = "\\.(csv|pdf)$")
  for(file in files) {
    cat("  -", file, "\n")
  }
} else {
  cat("  (Directory not created - check output_dir parameter)\n")
}

cat("\nNext steps for your research:\n")
cat("  1. Modify parameters in R/simulation_parameters.R for your specific study\n")
cat("  2. Create custom scenarios based on your research hypotheses\n")
cat("  3. Run comprehensive analysis with appropriate sample sizes\n")
cat("  4. Analyze results using the generated CSV files\n")
cat("  5. Use publication-quality PDF plots in your papers\n")

cat("\nHappy researching with socjobmarket!\n")