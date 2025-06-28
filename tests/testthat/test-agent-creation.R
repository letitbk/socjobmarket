test_that("create_graduate_student works correctly", {
  student <- create_graduate_student(1, 2020)

  expect_s3_class(student, "data.frame")
  expect_equal(nrow(student), 1)
  expect_equal(student$id, 1)
  expect_equal(student$cohort_year, 2020)
  expect_equal(student$type, "graduate_student")
  expect_equal(student$status, "job_seeking")
  expect_equal(student$years_since_phd, 0)

  # Check that numeric fields are in reasonable ranges
  expect_true(student$research_focus >= 1 && student$research_focus <= 10)
  expect_true(student$productivity >= 1 && student$productivity <= 10)
  expect_true(student$prestige_origin >= 1 && student$prestige_origin <= 10)
})

test_that("create_faculty works correctly", {
  faculty <- create_faculty(1, 5, "assistant")

  expect_s3_class(faculty, "data.frame")
  expect_equal(nrow(faculty), 1)
  expect_equal(faculty$id, 1)
  expect_equal(faculty$department_id, 5)
  expect_equal(faculty$rank, "assistant")
  expect_equal(faculty$type, "faculty")
  expect_equal(faculty$status, "staying")

  # Check age is appropriate for rank
  expect_true(faculty$age >= 28 && faculty$age <= 35)
  expect_equal(faculty$tenure_status, "tenure_track")
})

test_that("create_department works correctly", {
  dept <- create_department(1, prestige_rank = 25)

  expect_s3_class(dept, "data.frame")
  expect_equal(nrow(dept), 1)
  expect_equal(dept$id, 1)
  expect_equal(dept$prestige_rank, 25)
  expect_equal(dept$type, "department")
  expect_true(dept$size >= 5)  # Should have minimum 5 faculty
  expect_equal(dept$budget_constraint, 1.0)
})

test_that("create_multiple_agents works correctly", {
  students <- create_multiple_agents("student", 5, cohort_year = 2020)

  expect_s3_class(students, "data.table")
  expect_equal(nrow(students), 5)
  expect_true(all(students$cohort_year == 2020))
  expect_true(all(students$type == "graduate_student"))
  expect_true(all(students$id %in% 1:5))
})

test_that("create_multiple_agents handles different agent types", {
  departments <- create_multiple_agents("department", 3)

  expect_s3_class(departments, "data.table")
  expect_equal(nrow(departments), 3)
  expect_true(all(departments$type == "department"))

  faculty <- create_multiple_agents("faculty", 2, department_id = c(1, 2), rank = "associate")

  expect_s3_class(faculty, "data.table")
  expect_equal(nrow(faculty), 2)
  expect_true(all(faculty$type == "faculty"))
  expect_true(all(faculty$rank == "associate"))
})

test_that("agent creation handles edge cases", {
  # Test with prestige_origin specified
  student <- create_graduate_student(1, 2020, prestige_origin = 5)
  expect_equal(student$prestige_origin, 5)

  # Test different faculty ranks
  full_prof <- create_faculty(1, 1, "full")
  expect_true(full_prof$age >= 45 && full_prof$age <= 68)
  expect_equal(full_prof$tenure_status, "tenured")

  # Test department without specified prestige
  dept <- create_department(1)
  expect_true(dept$prestige_rank >= 1 && dept$prestige_rank <= 100)
})