#' Run Parallel Scenario Analysis
#'
#' Executes multiple scenarios in parallel using all available CPU cores.
#' This is the main function for comprehensive analysis of different
#' post-2008 factors affecting the academic job market.
#'
#' @param n_sims Number of simulations per scenario (default: 100)
#' @param n_cores Number of CPU cores to use (default: all available - 1)
#' @param scenarios Optional custom scenario list (uses predefined if NULL)
#' @param simulation_years Number of years to simulate per run
#' @param annual_phd_cohort Number of new PhDs per year
#' @param num_departments Number of departments
#' @return List of results organized by scenario
#' @export
#' @importFrom parallel detectCores mclapply
#' @importFrom purrr map_dfr
#' @importFrom dplyr mutate select
#' @importFrom tidyr pivot_wider
#' @importFrom magrittr %>%
#' @examples
#' \dontrun{
#' # Run full analysis
#' results <- run_parallel_scenario_analysis(n_sims = 25, n_cores = 4)
#'
#' # Quick test run
#' results <- run_parallel_scenario_analysis(n_sims = 5, n_cores = 2)
#' }
run_parallel_scenario_analysis <- function(n_sims = 100,
                                         n_cores = parallel::detectCores() - 1,
                                         scenarios = NULL,
                                         simulation_years = SIMULATION_YEARS,
                                         annual_phd_cohort = ANNUAL_PHD_COHORT,
                                         num_departments = NUM_DEPARTMENTS) {

  if (is.null(scenarios)) {
    scenarios <- get_predefined_scenarios()
  }

  cat("OPTIMIZED: Running parallel scenario analysis with", n_cores, "cores\n")
  cat("Total simulations:", length(scenarios) * n_sims, "\n")

  all_results <- list()

  for (scenario_name in names(scenarios)) {
    scenario <- scenarios[[scenario_name]]
    cat("Running scenario:", scenario$name, "\n")

    # PARALLEL EXECUTION - Major speedup!
    scenario_results <- parallel::mclapply(1:n_sims, function(sim_id) {
      sim_results <- run_simulation_with_scenario(
        seed = sim_id * 1000,
        scenario = scenario,
        simulation_years = simulation_years,
        annual_phd_cohort = annual_phd_cohort,
        num_departments = num_departments
      )

      # Calculate transition rates
      transition_rates <- calculate_transition_rates_detailed(
        sim_results$results,
        sim_results$candidate_outcomes
      )

      return(list(
        sim_id = sim_id,
        scenario = scenario_name,
        scenario_label = scenario$name,
        test_factor = if(is.null(scenario$test_factor)) "baseline" else scenario$test_factor,
        transition_rates = transition_rates,
        summary_stats = sim_results$summary_stats
      ))
    }, mc.cores = n_cores)

    all_results[[scenario_name]] <- scenario_results
  }

  return(all_results)
}

#' Main Scenario Analysis Function
#'
#' High-level function that runs the complete scenario analysis,
#' summarizes results, creates plots, and saves output files.
#'
#' @param n_sims Number of simulations per scenario (default: 100)
#' @param use_parallel Whether to use parallel processing (default: TRUE)
#' @param n_cores Number of CPU cores for parallel processing
#' @param output_dir Directory to save results (default: current directory)
#' @param simulation_years Number of years to simulate
#' @param annual_phd_cohort Number of new PhDs per year
#' @param num_departments Number of departments
#' @return List with scenario_results, summary_results, and plots
#' @export
#' @importFrom parallel detectCores
#' @importFrom dplyr select
#' @importFrom tidyr pivot_wider
#' @importFrom magrittr %>%
#' @examples
#' \dontrun{
#' # Full analysis with default settings
#' analysis <- main_scenario_analysis(n_sims = 100)
#'
#' # Quick test with fewer simulations
#' analysis <- main_scenario_analysis(n_sims = 10, use_parallel = FALSE)
#'
#' # Custom parameters
#' analysis <- main_scenario_analysis(
#'   n_sims = 50,
#'   simulation_years = 15,
#'   annual_phd_cohort = 250
#' )
#' }
main_scenario_analysis <- function(n_sims = 100,
                                 use_parallel = TRUE,
                                 n_cores = parallel::detectCores() - 1,
                                 output_dir = ".",
                                 simulation_years = SIMULATION_YEARS,
                                 annual_phd_cohort = ANNUAL_PHD_COHORT,
                                 num_departments = NUM_DEPARTMENTS) {

  cat("Starting OPTIMIZED scenario analysis...\n")
  cat("Testing 5 scenarios with", n_sims, "simulations each\n")
  cat("Focus: Retirement delays, Failed searches, Extended postdocs\n")

  if (use_parallel) {
    cat("Using parallel processing with", n_cores, "cores\n\n")
    # Run optimized parallel scenarios
    scenario_results <- run_parallel_scenario_analysis(
      n_sims = n_sims,
      n_cores = n_cores,
      simulation_years = simulation_years,
      annual_phd_cohort = annual_phd_cohort,
      num_departments = num_departments
    )
  } else {
    cat("Using sequential processing\n\n")
    # Run original sequential scenarios (fallback)
    scenario_results <- run_sequential_scenario_analysis(
      n_sims = n_sims,
      simulation_years = simulation_years,
      annual_phd_cohort = annual_phd_cohort,
      num_departments = num_departments
    )
  }

  # Summarize results
  summary_results <- summarize_scenario_results(scenario_results)

  # Create plots
  plots <- create_analysis_plots(summary_results)

  # Save everything
  save_results(summary_results, plots, output_dir)

  # Print key findings
  print_key_findings(summary_results)

  return(list(
    scenario_results = scenario_results,
    summary_results = summary_results,
    plots = plots
  ))
}

#' Sequential Scenario Analysis (Fallback)
#'
#' Non-parallel version of scenario analysis for systems that don't
#' support parallel processing.
#'
#' @param n_sims Number of simulations per scenario
#' @param simulation_years Number of years to simulate
#' @param annual_phd_cohort Number of new PhDs per year
#' @param num_departments Number of departments
#' @return List of results organized by scenario
#' @export
run_sequential_scenario_analysis <- function(n_sims = 100,
                                            simulation_years = SIMULATION_YEARS,
                                            annual_phd_cohort = ANNUAL_PHD_COHORT,
                                            num_departments = NUM_DEPARTMENTS) {

  scenarios <- get_predefined_scenarios()

  cat("Running sequential scenario analysis\n")
  cat("Total simulations:", length(scenarios) * n_sims, "\n")

  all_results <- list()

  for (scenario_name in names(scenarios)) {
    scenario <- scenarios[[scenario_name]]
    cat("\nRunning scenario:", scenario$name, "\n")

    scenario_results <- list()

    for (sim in 1:n_sims) {
      if (sim %% 20 == 0) cat("  Simulation", sim, "of", n_sims, "\n")

      # Run simulation with unique seed
      sim_results <- run_simulation_with_scenario(
        seed = sim * 1000 + which(names(scenarios) == scenario_name),
        scenario = scenario,
        simulation_years = simulation_years,
        annual_phd_cohort = annual_phd_cohort,
        num_departments = num_departments
      )

      # Calculate transition rates
      transition_rates <- calculate_transition_rates_detailed(
        sim_results$results,
        sim_results$candidate_outcomes
      )

      # Store results with simulation ID
      scenario_results[[sim]] <- list(
        sim_id = sim,
        scenario = scenario_name,
        scenario_label = scenario$name,
        test_factor = if(is.null(scenario$test_factor)) "baseline" else scenario$test_factor,
        transition_rates = transition_rates,
        summary_stats = sim_results$summary_stats
      )
    }

    all_results[[scenario_name]] <- scenario_results
  }

  return(all_results)
}

#' Print Key Findings Summary
#'
#' Internal function to print formatted key findings from scenario analysis.
#'
#' @param summary_results Summarized scenario results
#' @keywords internal
print_key_findings <- function(summary_results) {
  cat("\n", rep("=", 60), "\n")
  cat("KEY FINDINGS:\n")
  cat(rep("=", 60), "\n")

  if (!requireNamespace("tidyr", quietly = TRUE)) {
    cat("tidyr package required for detailed findings display\n")
    return(invisible())
  }

  findings_wide <- summary_results$period_summary %>%
    dplyr::select(scenario_label, period, mean_period_rate) %>%
    tidyr::pivot_wider(names_from = period, values_from = mean_period_rate)

  # Handle column names safely
  names(findings_wide) <- make.names(names(findings_wide))

  key_findings <- findings_wide %>%
    dplyr::mutate(
      recession_impact = ifelse("Recession" %in% names(.),
                               round((Pre.recession - Recession) * 100, 1), NA),
      persistent_impact = ifelse("Post.recession" %in% names(.),
                                round((Pre.recession - Post.recession) * 100, 1), NA)
    )

  # Select available columns
  available_cols <- c("scenario_label",
                     intersect(c("Pre.recession", "Recession", "Post.recession"), names(key_findings)),
                     intersect(c("recession_impact", "persistent_impact"), names(key_findings)))
  key_findings <- key_findings[, available_cols]

  print(key_findings)

  cat("\nImpact interpretation:\n")
  cat("- recession_impact: Percentage point drop during recession\n")
  cat("- persistent_impact: Percentage point drop in post-recession period\n")
}