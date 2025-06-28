#' Create Graduate Student Agent
#'
#' Creates a single graduate student agent with randomized characteristics.
#'
#' @param id Unique identifier for the graduate student
#' @param cohort_year Year the student graduated with PhD
#' @param prestige_origin Prestige rank of origin institution (1-10, optional)
#' @return A data.frame with graduate student characteristics
#' @export
#' @examples
#' student <- create_graduate_student(1, 2020)
#' print(student)
create_graduate_student <- function(id, cohort_year, prestige_origin = NULL) {
  data.frame(
    id = id,
    type = "graduate_student",
    cohort_year = cohort_year,
    research_focus = runif(1, 1, 10),
    teaching_orientation = runif(1, 1, 10),
    productivity = rnorm(1, mean = 5, sd = 2) %>% pmax(1) %>% pmin(10),
    prestige_origin = if(is.null(prestige_origin)) {
      sample(1:10, 1, prob = c(0.4, 0.3, 0.15, 0.08, 0.04, 0.02, 0.005, 0.003, 0.001, 0.001))
    } else {
      prestige_origin
    },
    publications = rpois(1, lambda = 2),
    years_since_phd = 0,
    status = "job_seeking",
    postdoc_duration = 0,
    career_outcome = NA,
    stringsAsFactors = FALSE
  )
}

#' Create Faculty Agent
#'
#' Creates a single faculty agent with rank-dependent characteristics.
#'
#' @param id Unique identifier for the faculty member
#' @param department_id ID of the department where faculty works
#' @param rank Academic rank: "assistant", "associate", or "full"
#' @return A data.frame with faculty characteristics
#' @export
#' @examples
#' faculty <- create_faculty(1, 5, "assistant")
#' print(faculty)
create_faculty <- function(id, department_id, rank = "assistant") {
  age <- switch(rank,
    "assistant" = sample(28:35, 1),
    "associate" = sample(35:50, 1),
    "full" = sample(45:68, 1)
  )

  data.frame(
    id = id,
    type = "faculty",
    department_id = department_id,
    rank = rank,
    tenure_status = ifelse(rank == "assistant", "tenure_track", "tenured"),
    research_focus = runif(1, 1, 10),
    productivity = rnorm(1, mean = 6, sd = 2) %>% pmax(1) %>% pmin(10),
    age = age,
    years_in_position = sample(1:5, 1),
    retirement_risk = pmax(0.02, (age - 55) * 0.05),
    mobility_risk = switch(rank,
      "assistant" = 0.15,
      "associate" = 0.08,
      "full" = 0.03
    ),
    status = "staying",
    stringsAsFactors = FALSE
  )
}

#' Create Department Agent
#'
#' Creates a single department agent with hiring characteristics.
#'
#' @param id Unique identifier for the department
#' @param prestige_rank Prestige rank of the department (1-100, optional)
#' @return A data.frame with department characteristics
#' @export
#' @examples
#' dept <- create_department(1, prestige_rank = 25)
#' print(dept)
create_department <- function(id, prestige_rank = NULL) {
  size <- rpois(1, lambda = AVG_DEPT_SIZE) + 5  # Minimum 5 faculty

  data.frame(
    id = id,
    type = "department",
    prestige_rank = if(is.null(prestige_rank)) sample(1:100, 1) else prestige_rank,
    size = size,
    research_orientation = runif(1, 3, 8),  # Most lean research
    budget_constraint = 1.0,  # Baseline budget
    search_standards = runif(1, 4, 7),  # Productivity threshold
    search_failure_tolerance = 0.3,  # 30% chance of failed search if standards not met
    hiring_history = I(list(list())),  # Use I() to wrap list column
    stringsAsFactors = FALSE
  )
}

#' Create Multiple Agents of Same Type
#'
#' Convenience function to create multiple agents efficiently.
#'
#' @param agent_type Type of agent: "student", "faculty", or "department"
#' @param n Number of agents to create
#' @param ... Additional arguments passed to specific creation functions
#' @return A data.table with multiple agents
#' @export
#' @examples
#' students <- create_multiple_agents("student", 10, cohort_year = 2020)
#' departments <- create_multiple_agents("department", 5)
create_multiple_agents <- function(agent_type, n, ...) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("data.table package is required for this function")
  }
  if (!requireNamespace("purrr", quietly = TRUE)) {
    stop("purrr package is required for this function")
  }

  creation_fun <- switch(agent_type,
    "student" = create_graduate_student,
    "faculty" = create_faculty,
    "department" = create_department,
    stop("Invalid agent_type. Must be 'student', 'faculty', or 'department'")
  )

  agents <- purrr::map_dfr(1:n, ~creation_fun(.x, ...))
  data.table::as.data.table(agents)
}