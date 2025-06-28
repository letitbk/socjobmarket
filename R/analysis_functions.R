#' Calculate Detailed Transition Rates from Tracked Outcomes
#'
#' Processes candidate outcome data to calculate transition rates by cohort.
#' This is used for Monte Carlo scenario analysis.
#'
#' @param simulation_results List of simulation results (legacy format)
#' @param candidate_outcomes data.table of candidate outcomes with cohort_year and career_outcome
#' @return data.frame with transition rates by cohort
#' @export
#' @importFrom dplyr group_by summarise mutate filter case_when n
#' @importFrom tidyr pivot_wider
#' @importFrom magrittr %>%
#' @examples
#' \dontrun{
#' # After running a simulation
#' results <- run_simulation_optimized(123)
#' transition_rates <- calculate_transition_rates_detailed(
#'   results$yearly_stats,
#'   results$candidate_outcomes
#' )
#' }
calculate_transition_rates_detailed <- function(simulation_results, candidate_outcomes) {
  # Define parameters locally
  RECESSION_START <- 2008
  RECESSION_END <- 2012

  if (nrow(candidate_outcomes) == 0) {
    return(data.frame(
      cohort_year = integer(0),
      total_graduates = integer(0),
      faculty_placements = integer(0),
      alt_career = integer(0),
      transition_rate = numeric(0),
      period = character(0)
    ))
  }

  # Calculate transition rates by cohort
  outcomes_wide <- candidate_outcomes %>%
    dplyr::group_by(cohort_year, career_outcome) %>%
    dplyr::summarise(count = n(), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = career_outcome, values_from = count, values_fill = 0)

  # Ensure faculty and alt_career columns exist
  if (!"faculty" %in% colnames(outcomes_wide)) {
    outcomes_wide$faculty <- 0
  }
  if (!"alt_career" %in% colnames(outcomes_wide)) {
    outcomes_wide$alt_career <- 0
  }

  transition_rates <- outcomes_wide %>%
    dplyr::mutate(
      total_graduates = faculty + alt_career,
      faculty_placements = faculty,
      transition_rate = ifelse(total_graduates > 0, faculty / total_graduates, 0),
      period = dplyr::case_when(
        cohort_year < RECESSION_START ~ "Pre-recession",
        cohort_year >= RECESSION_START & cohort_year <= RECESSION_END ~ "Recession",
        TRUE ~ "Post-recession"
      )
    ) %>%
    dplyr::filter(total_graduates > 0)  # Only include cohorts with outcomes

  return(transition_rates)
}

#' Calculate Basic Transition Rates (Legacy)
#'
#' Legacy function for calculating transition rates from old simulation results format.
#' For new code, use calculate_transition_rates_detailed().
#'
#' @param simulation_results List from old simulation format
#' @return data.frame with transition rates by cohort
#' @export
calculate_transition_rates <- function(simulation_results) {
  # Define parameters locally
  RECESSION_START <- 2008
  RECESSION_END <- 2012

  # Extract cohort outcomes from all years
  all_outcomes <- purrr::map_dfr(simulation_results, ~.x$cohort_outcomes)

  # Calculate transition rates by cohort
  transition_rates <- all_outcomes %>%
    dplyr::group_by(cohort_year) %>%
    dplyr::summarise(
      total_graduates = sum(count),
      faculty_placements = sum(count[career_outcome == "faculty"], na.rm = TRUE),
      transition_rate = faculty_placements / total_graduates,
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      period = dplyr::case_when(
        cohort_year < RECESSION_START ~ "Pre-recession",
        cohort_year >= RECESSION_START & cohort_year <= RECESSION_END ~ "Recession",
        TRUE ~ "Post-recession"
      )
    )

  return(transition_rates)
}

#' Summarize Results Across Multiple Simulations
#'
#' Aggregates results from multiple Monte Carlo simulations to provide
#' summary statistics across scenarios.
#'
#' @param scenario_results List of scenario results from parallel analysis
#' @return List with transition_summary, period_summary, yearly_summary, and raw data
#' @export
#' @importFrom dplyr group_by summarise select
#' @importFrom purrr map_dfr
#' @importFrom magrittr %>%
#' @examples
#' \dontrun{
#' scenario_results <- run_parallel_scenario_analysis(n_sims = 10)
#' summary <- summarize_scenario_results(scenario_results)
#' print(summary$period_summary)
#' }
summarize_scenario_results <- function(scenario_results) {
  # Define parameters locally
  RECESSION_START <- 2008
  RECESSION_END <- 2012

  cat("Summarizing results across simulations...\n")

  # Extract transition rates from all simulations
  all_transition_rates <- purrr::map_dfr(scenario_results, function(scenario) {
    purrr::map_dfr(scenario, function(sim) {
      sim$transition_rates %>%
        dplyr::mutate(
          sim_id = sim$sim_id,
          scenario = sim$scenario,
          scenario_label = sim$scenario_label,
          test_factor = sim$test_factor
        )
    })
  })

  # Extract yearly statistics
  all_yearly_stats <- purrr::map_dfr(scenario_results, function(scenario) {
    purrr::map_dfr(scenario, function(sim) {
      if (!is.null(sim$summary_stats) && nrow(sim$summary_stats) > 0) {
        sim$summary_stats %>%
          dplyr::mutate(
            sim_id = sim$sim_id,
            scenario = sim$scenario,
            scenario_label = sim$scenario_label,
            test_factor = sim$test_factor
          )
      } else {
        # Return empty data.frame with correct structure
        data.frame(
          year = integer(0),
          total_openings = integer(0),
          candidates_seeking = integer(0),
          placements_made = integer(0),
          failed_searches = integer(0),
          sim_id = integer(0),
          scenario = character(0),
          scenario_label = character(0),
          test_factor = character(0)
        )
      }
    })
  })

  # Calculate summary statistics
  transition_summary <- all_transition_rates %>%
    dplyr::group_by(scenario, scenario_label, test_factor, cohort_year, period) %>%
    dplyr::summarise(
      mean_transition_rate = mean(transition_rate, na.rm = TRUE),
      sd_transition_rate = sd(transition_rate, na.rm = TRUE),
      median_transition_rate = median(transition_rate, na.rm = TRUE),
      q25_transition_rate = quantile(transition_rate, 0.25, na.rm = TRUE),
      q75_transition_rate = quantile(transition_rate, 0.75, na.rm = TRUE),
      n_sims = n(),
      .groups = "drop"
    )

  # Period-level summaries
  period_summary <- transition_summary %>%
    dplyr::group_by(scenario, scenario_label, test_factor, period) %>%
    dplyr::summarise(
      mean_period_rate = mean(mean_transition_rate, na.rm = TRUE),
      sd_period_rate = sd(mean_transition_rate, na.rm = TRUE),
      .groups = "drop"
    )

  # Yearly statistics summary (only if we have data)
  if (nrow(all_yearly_stats) > 0) {
    yearly_summary <- all_yearly_stats %>%
      dplyr::group_by(scenario, scenario_label, test_factor, year) %>%
      dplyr::summarise(
        mean_openings = mean(total_openings, na.rm = TRUE),
        mean_candidates = mean(candidates_seeking, na.rm = TRUE),
        mean_placements = mean(placements_made, na.rm = TRUE),
        mean_failed_searches = mean(failed_searches, na.rm = TRUE),
        placement_rate = mean_placements / pmax(mean_candidates, 1),
        failed_search_rate = mean_failed_searches / pmax(mean_openings, 1),
        .groups = "drop"
      ) %>%
      dplyr::mutate(
        period = dplyr::case_when(
          year < RECESSION_START ~ "Pre-recession",
          year >= RECESSION_START & year <= RECESSION_END ~ "Recession",
          TRUE ~ "Post-recession"
        )
      )
  } else {
    # Create empty yearly_summary with correct structure
    yearly_summary <- data.frame(
      scenario = character(0),
      scenario_label = character(0),
      test_factor = character(0),
      year = integer(0),
      mean_openings = numeric(0),
      mean_candidates = numeric(0),
      mean_placements = numeric(0),
      mean_failed_searches = numeric(0),
      placement_rate = numeric(0),
      failed_search_rate = numeric(0),
      period = character(0)
    )
  }

  return(list(
    transition_summary = transition_summary,
    period_summary = period_summary,
    yearly_summary = yearly_summary,
    raw_transition_rates = all_transition_rates,
    raw_yearly_stats = all_yearly_stats
  ))
}

#' Calculate Simple Summary Statistics
#'
#' Quick summary function for basic analysis without full Monte Carlo.
#'
#' @param results Single simulation results
#' @return List with basic summary statistics
#' @export
#' @examples
#' \dontrun{
#' results <- run_simulation_optimized(123)
#' summary <- calculate_simple_summary(results)
#' print(summary)
#' }
calculate_simple_summary <- function(results) {
  # Basic statistics from yearly data
  yearly_stats <- results$yearly_stats

  total_years <- nrow(yearly_stats)
  recession_years <- sum(yearly_stats$year >= RECESSION_START & yearly_stats$year <= RECESSION_END)

  pre_recession <- yearly_stats[yearly_stats$year < RECESSION_START, ]
  during_recession <- yearly_stats[yearly_stats$year >= RECESSION_START & yearly_stats$year <= RECESSION_END, ]
  post_recession <- yearly_stats[yearly_stats$year > RECESSION_END, ]

  summary_stats <- list(
    total_years = total_years,
    recession_years = recession_years,

    # Pre-recession averages
    pre_openings = if(nrow(pre_recession) > 0) mean(pre_recession$total_openings) else NA,
    pre_placements = if(nrow(pre_recession) > 0) mean(pre_recession$placements_made) else NA,
    pre_placement_rate = if(nrow(pre_recession) > 0) mean(pre_recession$placements_made / pmax(pre_recession$candidates_seeking, 1)) else NA,

    # During recession averages
    recession_openings = if(nrow(during_recession) > 0) mean(during_recession$total_openings) else NA,
    recession_placements = if(nrow(during_recession) > 0) mean(during_recession$placements_made) else NA,
    recession_placement_rate = if(nrow(during_recession) > 0) mean(during_recession$placements_made / pmax(during_recession$candidates_seeking, 1)) else NA,

    # Post-recession averages
    post_openings = if(nrow(post_recession) > 0) mean(post_recession$total_openings) else NA,
    post_placements = if(nrow(post_recession) > 0) mean(post_recession$placements_made) else NA,
    post_placement_rate = if(nrow(post_recession) > 0) mean(post_recession$placements_made / pmax(post_recession$candidates_seeking, 1)) else NA
  )

  return(summary_stats)
}