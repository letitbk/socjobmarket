#' Global Simulation Parameters
#'
#' Default parameters for the sociology job market simulation.
#' These can be overridden in specific function calls.
#'
#' @name simulation_parameters
#' @docType data
#' @keywords datasets
NULL

#' Get Global Simulation Parameters
#'
#' @return List of global simulation parameters
#' @export
get_global_params <- function() {
  list(
    SIMULATION_YEARS = 20,
    START_YEAR = 2000,
    RECESSION_START = 2008,
    RECESSION_END = 2012,
    ANNUAL_PHD_COHORT = 300,
    NUM_DEPARTMENTS = 150,
    AVG_DEPT_SIZE = 15
  )
}

# Global simulation parameters (for internal package use)
.SIMULATION_YEARS <- 20  # Default: 2000-2020
.START_YEAR <- 2000
.RECESSION_START <- 2008
.RECESSION_END <- 2012

# Population parameters (for internal package use)
.ANNUAL_PHD_COHORT <- 300  # New sociology PhDs per year
.NUM_DEPARTMENTS <- 150    # Total departments hiring
.AVG_DEPT_SIZE <- 15       # Average faculty per department

# Make parameters available within package
SIMULATION_YEARS <- .SIMULATION_YEARS
START_YEAR <- .START_YEAR
RECESSION_START <- .RECESSION_START
RECESSION_END <- .RECESSION_END
ANNUAL_PHD_COHORT <- .ANNUAL_PHD_COHORT
NUM_DEPARTMENTS <- .NUM_DEPARTMENTS
AVG_DEPT_SIZE <- .AVG_DEPT_SIZE

#' Default Economic Period Effects
#'
#' Default parameters for recession effects on the job market.
#'
#' @export
#' @examples
#' # Access recession effects
#' effects <- default_recession_effects()
#' print(effects$retirement_delay_factor)
default_recession_effects <- function() {
  list(
    retirement_delay_factor = 0.5,    # 50% reduction in retirement probability
    budget_constraint = 0.8,          # 20% budget reduction
    search_standards_inflation = 1.2,  # 20% increase in hiring standards
    postdoc_duration_multiplier = 1.3 # 30% longer postdoc periods
  )
}

#' Predefined Scenario Definitions
#'
#' Returns predefined scenarios for testing different post-2008 factors.
#'
#' @return A list of scenario configurations
#' @export
#' @examples
#' scenarios <- get_predefined_scenarios()
#' names(scenarios)
get_predefined_scenarios <- function() {
  list(
    baseline_pre2008 = list(
      name = "Pre-2008 Baseline",
      retirement_delay_factor = 1.0,
      search_standards_inflation = 1.0,
      search_failure_tolerance = 0.3,
      postdoc_duration_multiplier = 1.0,
      apply_recession_effects = FALSE
    ),

    retirement_delays_only = list(
      name = "Retirement Delays Only",
      retirement_delay_factor = 0.5,
      search_standards_inflation = 1.0,
      search_failure_tolerance = 0.3,
      postdoc_duration_multiplier = 1.0,
      apply_recession_effects = TRUE,
      test_factor = "retirement_delays"
    ),

    failed_searches_only = list(
      name = "Failed Searches Only",
      retirement_delay_factor = 1.0,
      search_standards_inflation = 1.4,
      search_failure_tolerance = 0.5,
      postdoc_duration_multiplier = 1.0,
      apply_recession_effects = TRUE,
      test_factor = "failed_searches"
    ),

    extended_postdocs_only = list(
      name = "Extended Postdocs Only",
      retirement_delay_factor = 1.0,
      search_standards_inflation = 1.0,
      search_failure_tolerance = 0.3,
      postdoc_duration_multiplier = 1.5,
      apply_recession_effects = TRUE,
      test_factor = "extended_postdocs"
    ),

    all_factors_combined = list(
      name = "All Factors Combined",
      retirement_delay_factor = 0.5,
      search_standards_inflation = 1.4,
      search_failure_tolerance = 0.5,
      postdoc_duration_multiplier = 1.5,
      apply_recession_effects = TRUE,
      test_factor = "combined"
    )
  )
}