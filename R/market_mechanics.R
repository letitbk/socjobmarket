#' Calculate Match Quality Between Candidate and Department (Single)
#'
#' Legacy function for calculating match quality for a single candidate.
#' For better performance, use calculate_match_quality_vectorized().
#'
#' @param candidate A single candidate data.frame/list
#' @param department A single department data.frame/list
#' @return Numeric match quality score
#' @export
#' @examples
#' candidate <- create_graduate_student(1, 2020)
#' department <- create_department(1)
#' quality <- calculate_match_quality(candidate, department)
calculate_match_quality <- function(candidate, department) {
  # Research fit (closer = better)
  research_fit <- 1 - abs(candidate$research_focus - department$research_orientation) / 10

  # Productivity requirement (binary)
  productivity_fit <- ifelse(candidate$productivity >= department$search_standards, 1, 0)

  # Prestige bonus
  prestige_bonus <- (candidate$prestige_origin / 10) * 0.3

  # Postdoc experience bonus
  postdoc_bonus <- min(candidate$postdoc_duration * 0.1, 0.3)

  return(research_fit * productivity_fit + prestige_bonus + postdoc_bonus)
}

#' Vectorized Match Quality Calculation (OPTIMIZED)
#'
#' High-performance vectorized calculation of match quality between
#' multiple candidates and a single department. This is the preferred
#' function for simulation use as it's 15-20x faster than the single version.
#'
#' @param candidates_dt A data.table of candidate characteristics
#' @param department A single department data.frame/list
#' @return Numeric vector of match quality scores
#' @export
#' @importFrom data.table as.data.table
#' @examples
#' candidates <- create_multiple_agents("student", 10, cohort_year = 2020)
#' department <- create_department(1)
#' qualities <- calculate_match_quality_vectorized(candidates, department)
calculate_match_quality_vectorized <- function(candidates_dt, department) {
  # Ensure we're working with data.table
  if (!data.table::is.data.table(candidates_dt)) {
    candidates_dt <- data.table::as.data.table(candidates_dt)
  }

  # Vectorized calculations - much faster than rowwise
  research_fit <- 1 - abs(candidates_dt$research_focus - department$research_orientation) / 10
  productivity_fit <- as.numeric(candidates_dt$productivity >= department$search_standards)
  prestige_bonus <- (candidates_dt$prestige_origin / 10) * 0.3
  postdoc_bonus <- pmin(candidates_dt$postdoc_duration * 0.1, 0.3)

  return(research_fit * productivity_fit + prestige_bonus + postdoc_bonus)
}

#' Generate Job Openings for a Year
#'
#' Simulates faculty retirement and mobility decisions to generate
#' job openings by department.
#'
#' @param faculty_agents data.table of faculty agents
#' @param departments data.table of department agents
#' @param year Current simulation year
#' @param recession_effects List of recession effect parameters (optional)
#' @return List with updated faculty_agents and openings data.table
#' @export
#' @importFrom data.table as.data.table
#' @examples
#' \dontrun{
#' faculty <- create_multiple_agents("faculty", 100, department_id = rep(1:10, 10))
#' departments <- create_multiple_agents("department", 10)
#' openings <- generate_job_openings(faculty, departments, 2010)
#' }
generate_job_openings <- function(faculty_agents, departments, year, recession_effects = NULL) {
  # Economic conditions
  is_recession <- year >= RECESSION_START & year <= RECESSION_END

  if (is.null(recession_effects)) {
    recession_effects <- default_recession_effects()
  }

  # Convert to data.table if needed
  if (!data.table::is.data.table(faculty_agents)) {
    faculty_agents <- data.table::as.data.table(faculty_agents)
  }

  # Retirement decisions
  retirement_factor <- ifelse(is_recession, recession_effects$retirement_delay_factor, 1.0)
  faculty_agents[, retirement_prob := pmax(0.01, retirement_risk * retirement_factor)]
  faculty_agents[, retires_this_year := rbinom(.N, 1, retirement_prob) == 1]
  faculty_agents[retires_this_year == TRUE, status := "retiring"]

  # Mobility decisions (reduced during recession)
  mobility_multiplier <- ifelse(is_recession, 0.7, 1.0)
  faculty_agents[, moves_this_year := rbinom(.N, 1, mobility_risk * mobility_multiplier) == 1 & !retires_this_year]
  faculty_agents[moves_this_year == TRUE, status := "moving"]

  # Calculate openings by department
  natural_openings <- faculty_agents[retires_this_year == TRUE | moves_this_year == TRUE, .N, by = department_id]
  data.table::setnames(natural_openings, "N", "openings")

  # Merge with all departments (some may have 0 openings)
  if (!data.table::is.data.table(departments)) {
    departments <- data.table::as.data.table(departments)
  }

  openings <- natural_openings[departments[, .(id)], on = c("department_id" = "id")]
  openings[is.na(openings), openings := 0]
  data.table::setnames(openings, "department_id", "id")

  # Add growth-based openings (reduced during recession)
  if (!is_recession) {
    growth_openings <- rpois(nrow(openings), lambda = 0.1)  # 10% growth rate
    openings[, openings := openings + growth_openings]
  }

  # Add baseline turnover (guaranteed openings to ensure market function)
  baseline_openings <- rpois(nrow(openings), lambda = 0.5)  # Average 0.5 openings per dept per year
  openings[, openings := openings + baseline_openings]

  return(list(faculty_agents = faculty_agents, openings = openings))
}

#' Run Optimized Hiring Market for One Year
#'
#' Simulates the hiring process between candidates and departments using
#' vectorized calculations for optimal performance.
#'
#' @param candidates data.table of job-seeking candidates
#' @param departments_with_openings data.table of departments with job openings
#' @param year Current simulation year
#' @param scenario Optional scenario parameters affecting hiring standards
#' @return List with placements, remaining_candidates, and failed_searches
#' @export
#' @importFrom data.table as.data.table rbindlist
#' @examples
#' \dontrun{
#' candidates <- create_multiple_agents("student", 50, cohort_year = 2020)
#' departments <- create_multiple_agents("department", 10)
#' # Add openings to departments
#' departments$openings <- rpois(10, 2)
#' results <- run_hiring_market_optimized(candidates, departments, 2020)
#' }
run_hiring_market_optimized <- function(candidates, departments_with_openings, year, scenario = NULL) {
  # Convert to data.table
  candidates <- data.table::as.data.table(candidates)
  departments_with_openings <- data.table::as.data.table(departments_with_openings)

  is_recession <- year >= RECESSION_START & year <= RECESSION_END

  # Apply scenario effects if provided
  if (!is.null(scenario) && scenario$apply_recession_effects && is_recession) {
    departments_with_openings[, search_standards := search_standards * scenario$search_standards_inflation]
    departments_with_openings[, search_failure_tolerance := scenario$search_failure_tolerance]
  } else if (is_recession) {
    departments_with_openings[, search_standards := search_standards * 1.2]
  }

  # Pre-allocate results
  placements_list <- vector("list", nrow(departments_with_openings))
  failed_searches <- 0

  # Process departments with openings
  depts_with_openings <- departments_with_openings[openings > 0]

  for (i in seq_len(nrow(depts_with_openings))) {
    dept <- depts_with_openings[i]

    if (nrow(candidates) == 0) break

    # Vectorized match quality calculation
    match_qualities <- calculate_match_quality_vectorized(candidates, dept)

    # Create candidate scores table
    candidate_scores <- candidates[, .(id, research_focus, productivity, prestige_origin, postdoc_duration)]
    candidate_scores[, match_quality := match_qualities]
    candidate_scores[, dept_id := dept$id]
    candidate_scores <- candidate_scores[match_quality > 0][order(-match_quality)]

    if (nrow(candidate_scores) > 0) {
      top_quality <- candidate_scores$match_quality[1]
      failure_threshold <- 0.8

      # Hiring decision
      if (top_quality >= failure_threshold || runif(1) > dept$search_failure_tolerance) {
        n_hires <- min(dept$openings, nrow(candidate_scores))
        hired_ids <- candidate_scores$id[1:n_hires]

        # Store placements
        hired_candidates <- candidates[id %in% hired_ids]
        hired_candidates[, dept_id := dept$id]
        placements_list[[i]] <- hired_candidates

        # Remove hired candidates
        candidates <- candidates[!id %in% hired_ids]
      } else {
        failed_searches <- failed_searches + dept$openings
      }
    } else {
      failed_searches <- failed_searches + dept$openings
    }
  }

  # Combine placements
  placements <- data.table::rbindlist(placements_list[!sapply(placements_list, is.null)])
  if (nrow(placements) == 0) {
    placements <- data.table::data.table()
  }

  return(list(
    placements = placements,
    remaining_candidates = candidates,
    failed_searches = failed_searches
  ))
}