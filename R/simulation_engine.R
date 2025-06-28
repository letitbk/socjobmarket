#' Run Optimized Single Simulation
#'
#' Runs a single simulation of the academic job market with optimized
#' data.table operations for maximum performance.
#'
#' @param seed Random seed for reproducibility
#' @param simulation_years Number of years to simulate (default: 20)
#' @param annual_phd_cohort Number of new PhDs per year (default: 300)
#' @param num_departments Number of departments (default: 150)
#' @param scenario Optional scenario parameters to modify recession effects
#' @return List containing yearly statistics and candidate outcomes
#' @export
#' @importFrom data.table as.data.table data.table rbindlist
#' @importFrom purrr map_dfr
#' @examples
#' \dontrun{
#' # Run a simple simulation
#' results <- run_simulation_optimized(seed = 123)
#'
#' # Run with custom parameters
#' results <- run_simulation_optimized(
#'   seed = 456,
#'   simulation_years = 10,
#'   annual_phd_cohort = 200
#' )
#' }
run_simulation_optimized <- function(seed = 123,
                                   simulation_years = SIMULATION_YEARS,
                                   annual_phd_cohort = ANNUAL_PHD_COHORT,
                                   num_departments = NUM_DEPARTMENTS,
                                   scenario = NULL) {
  set.seed(seed)

  # Initialize agents using data.table
  departments <- data.table::data.table(
    id = 1:num_departments,
    type = "department",
    prestige_rank = sample(1:100, num_departments),
    size = pmax(5, rpois(num_departments, AVG_DEPT_SIZE)),
    research_orientation = runif(num_departments, 3, 8),
    budget_constraint = 1.0,
    search_standards = runif(num_departments, 4, 7),
    search_failure_tolerance = 0.3
  )

  # Initialize faculty
  total_faculty <- num_departments * AVG_DEPT_SIZE
  faculty_agents <- data.table::data.table(
    id = 1:total_faculty,
    type = "faculty",
    department_id = rep(1:num_departments, each = AVG_DEPT_SIZE)[1:total_faculty],
    rank = sample(c("assistant", "associate", "full"), total_faculty,
                  prob = c(0.4, 0.35, 0.25), replace = TRUE),
    age = 0,  # Will set based on rank
    years_in_position = sample(1:5, total_faculty, replace = TRUE),
    status = "staying"
  )

  # Set age based on rank
  faculty_agents[rank == "assistant", age := sample(28:35, .N)]
  faculty_agents[rank == "associate", age := sample(35:50, .N)]
  faculty_agents[rank == "full", age := sample(45:68, .N)]

  # Set derived variables
  faculty_agents[, tenure_status := ifelse(rank == "assistant", "tenure_track", "tenured")]
  faculty_agents[, retirement_risk := pmax(0.02, (age - 55) * 0.05)]
  faculty_agents[, mobility_risk := dplyr::case_when(
    rank == "assistant" ~ 0.15,
    rank == "associate" ~ 0.08,
    rank == "full" ~ 0.03
  )]

  # Pre-allocate tracking structures
  n_years <- simulation_years
  yearly_stats <- data.table::data.table(
    year = integer(n_years),
    total_openings = integer(n_years),
    candidates_seeking = integer(n_years),
    placements_made = integer(n_years),
    failed_searches = integer(n_years)
  )

  # Track all candidate outcomes
  max_candidates <- annual_phd_cohort * n_years * 2  # Conservative estimate
  all_outcomes <- data.table::data.table(
    id = integer(max_candidates),
    cohort_year = integer(max_candidates),
    career_outcome = character(max_candidates),
    outcome_year = integer(max_candidates)
  )
  outcome_counter <- 0L

  candidate_pool <- data.table::data.table()

  # Main simulation loop
  for (year_idx in 1:n_years) {
    year <- START_YEAR + year_idx - 1

    # Create new graduates
    new_grad_ids <- if (nrow(candidate_pool) == 0) {
      1:annual_phd_cohort
    } else {
      (max(candidate_pool$id) + 1):(max(candidate_pool$id) + annual_phd_cohort)
    }

    new_graduates <- data.table::data.table(
      id = new_grad_ids,
      type = "graduate_student",
      cohort_year = year,
      research_focus = runif(annual_phd_cohort, 1, 10),
      teaching_orientation = runif(annual_phd_cohort, 1, 10),
      productivity = pmax(1, pmin(10, rnorm(annual_phd_cohort, 5, 2))),
      prestige_origin = sample(1:10, annual_phd_cohort, replace = TRUE,
                              prob = c(0.4, 0.3, 0.15, 0.08, 0.04, 0.02, 0.005, 0.003, 0.001, 0.001)),
      publications = rpois(annual_phd_cohort, 2),
      years_since_phd = 0,
      status = "job_seeking",
      postdoc_duration = 0,
      career_outcome = NA_character_
    )

    # Update existing candidates
    if (nrow(candidate_pool) > 0) {
      is_recession <- year >= RECESSION_START & year <= RECESSION_END

      # Apply scenario-specific effects
      postdoc_multiplier <- if (!is.null(scenario) && scenario$apply_recession_effects && is_recession) {
        scenario$postdoc_duration_multiplier
      } else if (is_recession) {
        1.3
      } else {
        1.0
      }

      candidate_pool[, years_since_phd := year - cohort_year]

      # Vectorized status updates
      postdoc_prob <- ifelse(candidate_pool$status == "job_seeking", 0.4 * postdoc_multiplier, 0)
      leave_prob <- ifelse(candidate_pool$years_since_phd > 5, 0.1, 0)
      return_prob <- ifelse(candidate_pool$status == "postdoc" & candidate_pool$postdoc_duration >= 2, 0.6, 0)

      candidate_pool[, enters_postdoc := runif(.N) < postdoc_prob]
      candidate_pool[, leaves_academia := runif(.N) < leave_prob]
      candidate_pool[, returns_to_market := runif(.N) < return_prob]

      # Update statuses
      candidate_pool[enters_postdoc == TRUE, status := "postdoc"]
      candidate_pool[leaves_academia == TRUE, status := "alt_career"]
      candidate_pool[leaves_academia == TRUE, career_outcome := "alt_career"]
      candidate_pool[returns_to_market == TRUE, status := "job_seeking"]

      # Update postdoc duration
      candidate_pool[status == "postdoc", postdoc_duration := postdoc_duration + 1]

      # Productivity boost for returning postdocs
      candidate_pool[returns_to_market == TRUE, productivity := pmin(10, productivity + rnorm(.N, 0.5, 0.3))]

      # Track outcomes for those leaving academia
      leaving <- candidate_pool[status == "alt_career" & !is.na(career_outcome)]
      if (nrow(leaving) > 0) {
        n_leaving <- nrow(leaving)
        outcome_rows <- (outcome_counter + 1):(outcome_counter + n_leaving)
        all_outcomes[outcome_rows, `:=`(
          id = leaving$id,
          cohort_year = leaving$cohort_year,
          career_outcome = leaving$career_outcome,
          outcome_year = year
        )]
        outcome_counter <- outcome_counter + n_leaving
      }
    }

    # Combine with new graduates
    candidate_pool <- data.table::rbindlist(list(candidate_pool, new_graduates), fill = TRUE)

    # Generate job openings
    opening_results <- generate_job_openings(faculty_agents, departments, year)
    faculty_agents <- opening_results$faculty_agents
    openings <- opening_results$openings

    # Merge departments with openings
    departments_with_openings <- openings[departments, on = "id"]
    departments_with_openings[is.na(openings), openings := 0]

    # Run hiring market
    job_seekers <- candidate_pool[status == "job_seeking"]

    market_results <- run_hiring_market_optimized(job_seekers, departments_with_openings, year, scenario)

    # Track faculty placements
    if (nrow(market_results$placements) > 0) {
      placed <- market_results$placements
      n_placed <- nrow(placed)

      # Update candidate pool
      candidate_pool[id %in% placed$id, `:=`(status = "faculty", career_outcome = "faculty")]

      # Track outcomes
      outcome_rows <- (outcome_counter + 1):(outcome_counter + n_placed)
      all_outcomes[outcome_rows, `:=`(
        id = placed$id,
        cohort_year = placed$cohort_year,
        career_outcome = "faculty",
        outcome_year = year
      )]
      outcome_counter <- outcome_counter + n_placed
    }

    # Store yearly statistics
    yearly_stats[year_idx, `:=`(
      year = year,
      total_openings = sum(departments_with_openings$openings),
      candidates_seeking = nrow(job_seekers),
      placements_made = nrow(market_results$placements),
      failed_searches = market_results$failed_searches
    )]

    # Remove placed/alt-career candidates
    candidate_pool <- candidate_pool[!status %in% c("faculty", "alt_career")]
  }

  # Return only used portion of all_outcomes
  final_outcomes <- all_outcomes[1:outcome_counter]

  return(list(
    yearly_stats = yearly_stats,
    candidate_outcomes = final_outcomes
  ))
}

#' Run Simulation with Specific Scenario
#'
#' Extended version of the simulation that tracks detailed outcomes
#' for scenario analysis.
#'
#' @param seed Random seed for reproducibility
#' @param scenario List of scenario parameters
#' @param simulation_years Number of years to simulate
#' @param annual_phd_cohort Number of new PhDs per year
#' @param num_departments Number of departments
#' @return List with results, summary_stats, and candidate_outcomes
#' @export
#' @examples
#' \dontrun{
#' scenario <- list(
#'   name = "Test Scenario",
#'   retirement_delay_factor = 0.5,
#'   apply_recession_effects = TRUE
#' )
#' results <- run_simulation_with_scenario(123, scenario)
#' }
run_simulation_with_scenario <- function(seed = 123,
                                       scenario,
                                       simulation_years = SIMULATION_YEARS,
                                       annual_phd_cohort = ANNUAL_PHD_COHORT,
                                       num_departments = NUM_DEPARTMENTS) {

  # Use the optimized simulation with scenario parameter
  sim_results <- run_simulation_optimized(
    seed = seed,
    simulation_years = simulation_years,
    annual_phd_cohort = annual_phd_cohort,
    num_departments = num_departments,
    scenario = scenario
  )

  return(list(
    results = list(yearly_stats = sim_results$yearly_stats),
    summary_stats = sim_results$yearly_stats,
    candidate_outcomes = sim_results$candidate_outcomes
  ))
}