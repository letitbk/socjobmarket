#' Create Comprehensive Analysis Plots
#'
#' Generates a comprehensive set of plots for scenario analysis results.
#'
#' @param summary_results Output from summarize_scenario_results()
#' @param include_ribbons Whether to include confidence ribbons (default: TRUE)
#' @param theme_style ggplot2 theme to use (default: "minimal")
#' @return List containing ggplot objects for different visualizations
#' @export
#' @importFrom ggplot2 ggplot aes geom_line geom_point geom_ribbon geom_col geom_errorbar
#' @importFrom ggplot2 geom_hline geom_vline labs scale_y_continuous theme_minimal theme
#' @importFrom ggplot2 position_dodge element_text
#' @importFrom scales percent_format
#' @examples
#' \dontrun{
#' # After running scenario analysis
#' scenario_results <- run_parallel_scenario_analysis(n_sims = 10)
#' summary_results <- summarize_scenario_results(scenario_results)
#' plots <- create_analysis_plots(summary_results)
#' print(plots$transition_rates)
#' }
create_analysis_plots <- function(summary_results, include_ribbons = TRUE, theme_style = "minimal") {
  RECESSION_START <- 2008  # Define locally

  # Set theme
  plot_theme <- switch(theme_style,
    "minimal" = ggplot2::theme_minimal(),
    "classic" = ggplot2::theme_classic(),
    "bw" = ggplot2::theme_bw(),
    ggplot2::theme_minimal()  # default
  )

  # 1. Main transition rate plot by scenario
  p1 <- ggplot2::ggplot(summary_results$transition_summary,
               ggplot2::aes(x = cohort_year, y = mean_transition_rate, color = scenario_label)) +
    ggplot2::geom_line(size = 1) +
    ggplot2::geom_point(size = 2)

  # Add confidence ribbons if requested
  if (include_ribbons && "sd_transition_rate" %in% colnames(summary_results$transition_summary)) {
    p1 <- p1 + ggplot2::geom_ribbon(
      ggplot2::aes(ymin = pmax(0, mean_transition_rate - sd_transition_rate/2),
                   ymax = pmin(1, mean_transition_rate + sd_transition_rate/2),
                   fill = scenario_label),
      alpha = 0.2, color = NA
    )
  }

  # Add reference lines and formatting
  p1 <- p1 +
    ggplot2::geom_hline(yintercept = 0.25, linetype = "dashed", alpha = 0.7, color = "blue") +
    ggplot2::geom_hline(yintercept = 0.12, linetype = "dashed", alpha = 0.7, color = "red") +
    ggplot2::geom_vline(xintercept = RECESSION_START, linetype = "dotted", alpha = 0.7) +
    ggplot2::labs(
      title = "Faculty Transition Rates by Scenario",
      subtitle = "Impact of Different Post-2008 Factors on PhD-to-Faculty Transitions",
      x = "PhD Cohort Year",
      y = "Faculty Transition Rate",
      color = "Scenario",
      fill = "Scenario",
      caption = "Dashed lines: Pre-2008 (25%) and Post-2008 (12%) observed rates\nDotted line: Recession start (2008)"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    plot_theme +
    ggplot2::theme(legend.position = "bottom")

  # 2. Period comparison plot
  p2 <- ggplot2::ggplot(summary_results$period_summary,
               ggplot2::aes(x = period, y = mean_period_rate, fill = scenario_label)) +
    ggplot2::geom_col(position = "dodge", alpha = 0.8)

  # Add error bars if we have standard deviations
  if ("sd_period_rate" %in% colnames(summary_results$period_summary)) {
    p2 <- p2 + ggplot2::geom_errorbar(
      ggplot2::aes(ymin = pmax(0, mean_period_rate - sd_period_rate),
                   ymax = pmin(1, mean_period_rate + sd_period_rate)),
      position = ggplot2::position_dodge(width = 0.9), width = 0.2
    )
  }

  p2 <- p2 +
    ggplot2::labs(
      title = "Average Faculty Transition Rates by Period and Scenario",
      x = "Period",
      y = "Mean Faculty Transition Rate",
      fill = "Scenario"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    plot_theme +
    ggplot2::theme(legend.position = "bottom")

  # 3. Market dynamics plot (only if yearly data exists)
  p3 <- NULL
  if (nrow(summary_results$yearly_summary) > 0) {
    p3 <- ggplot2::ggplot(summary_results$yearly_summary,
                 ggplot2::aes(x = year, color = scenario_label)) +
      ggplot2::geom_line(ggplot2::aes(y = placement_rate), size = 1) +
      ggplot2::geom_vline(xintercept = RECESSION_START, linetype = "dotted", alpha = 0.7) +
      ggplot2::labs(
        title = "Annual Placement Rates by Scenario",
        subtitle = "Placements / Job Seekers",
        x = "Year",
        y = "Placement Rate",
        color = "Scenario"
      ) +
      ggplot2::scale_y_continuous(labels = scales::percent_format()) +
      plot_theme +
      ggplot2::theme(legend.position = "bottom")
  }

  # 4. Failed search rates (only if yearly data exists)
  p4 <- NULL
  if (nrow(summary_results$yearly_summary) > 0) {
    p4 <- ggplot2::ggplot(summary_results$yearly_summary,
                 ggplot2::aes(x = year, color = scenario_label)) +
      ggplot2::geom_line(ggplot2::aes(y = failed_search_rate), size = 1) +
      ggplot2::geom_vline(xintercept = RECESSION_START, linetype = "dotted", alpha = 0.7) +
      ggplot2::labs(
        title = "Failed Search Rates by Scenario",
        subtitle = "Failed Searches / Total Openings",
        x = "Year",
        y = "Failed Search Rate",
        color = "Scenario"
      ) +
      ggplot2::scale_y_continuous(labels = scales::percent_format()) +
      plot_theme +
      ggplot2::theme(legend.position = "bottom")
  }

  plots <- list(
    transition_rates = p1,
    period_comparison = p2
  )

  if (!is.null(p3)) plots$placement_rates <- p3
  if (!is.null(p4)) plots$failed_search_rates <- p4

  return(plots)
}

#' Create Single Simulation Plot
#'
#' Simple plotting function for results from a single simulation run.
#'
#' @param results Output from run_simulation_optimized()
#' @param show_details Whether to include detailed annotations (default: TRUE)
#' @return ggplot object
#' @export
#' @examples
#' \dontrun{
#' results <- run_simulation_optimized(123)
#' plot <- create_single_simulation_plot(results)
#' print(plot)
#' }
create_single_simulation_plot <- function(results, show_details = TRUE) {
  yearly_stats <- results$yearly_stats
  RECESSION_START <- 2008  # Define locally

  # Calculate placement rate
  yearly_stats$placement_rate <- yearly_stats$placements_made / pmax(yearly_stats$candidates_seeking, 1)

  p <- ggplot2::ggplot(yearly_stats, ggplot2::aes(x = year)) +
    ggplot2::geom_line(ggplot2::aes(y = placement_rate), color = "blue", size = 1) +
    ggplot2::geom_point(ggplot2::aes(y = placement_rate), color = "blue", size = 2) +
    ggplot2::geom_vline(xintercept = RECESSION_START, linetype = "dashed", alpha = 0.7, color = "red") +
    ggplot2::labs(
      title = "Annual Placement Rates",
      subtitle = "Single Simulation Results",
      x = "Year",
      y = "Placement Rate (Placements / Job Seekers)",
      caption = "Red line indicates recession start (2008)"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::theme_minimal()

  if (show_details) {
    # Add text annotations for key periods
    RECESSION_END <- 2012  # Define locally too
    pre_recession_rate <- mean(yearly_stats$placement_rate[yearly_stats$year < RECESSION_START])
    recession_rate <- mean(yearly_stats$placement_rate[yearly_stats$year >= RECESSION_START & yearly_stats$year <= RECESSION_END])

    p <- p + ggplot2::annotate("text",
                      x = 2004, y = 0.9,
                      label = paste0("Pre-recession: ", round(pre_recession_rate * 100, 1), "%"),
                      hjust = 0) +
      ggplot2::annotate("text",
                      x = 2010, y = 0.1,
                      label = paste0("Recession: ", round(recession_rate * 100, 1), "%"),
                      hjust = 0)
  }

  return(p)
}

#' Save Results to Files
#'
#' Saves analysis results to CSV files and plots to PDF.
#'
#' @param summary_results Output from summarize_scenario_results()
#' @param plots Output from create_analysis_plots()
#' @param output_dir Directory to save files (default: current directory)
#' @param file_prefix Prefix for output files (default: "socjobmarket")
#' @return Invisibly returns list of created file paths
#' @export
#' @examples
#' \dontrun{
#' # After running analysis
#' scenario_results <- run_parallel_scenario_analysis(n_sims = 10)
#' summary_results <- summarize_scenario_results(scenario_results)
#' plots <- create_analysis_plots(summary_results)
#' files <- save_results(summary_results, plots, "output/")
#' }
save_results <- function(summary_results, plots, output_dir = ".", file_prefix = "socjobmarket") {
  # Create output directory if it doesn't exist
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  # Define file paths
  transition_file <- file.path(output_dir, paste0(file_prefix, "_transition_rates_summary.csv"))
  period_file <- file.path(output_dir, paste0(file_prefix, "_period_summary.csv"))
  yearly_file <- file.path(output_dir, paste0(file_prefix, "_yearly_market_dynamics.csv"))
  pdf_file <- file.path(output_dir, paste0(file_prefix, "_simulation_results.pdf"))

  # Save CSV files
  write.csv(summary_results$transition_summary, transition_file, row.names = FALSE)
  write.csv(summary_results$period_summary, period_file, row.names = FALSE)

  if (nrow(summary_results$yearly_summary) > 0) {
    write.csv(summary_results$yearly_summary, yearly_file, row.names = FALSE)
  }

  # Save plots as PDF
  pdf(pdf_file, width = 12, height = 8)
  print(plots$transition_rates)
  print(plots$period_comparison)
  if (!is.null(plots$placement_rates)) print(plots$placement_rates)
  if (!is.null(plots$failed_search_rates)) print(plots$failed_search_rates)
  dev.off()

  cat("Results saved to:", output_dir, "\n")
  cat("Files created:\n")
  cat("  -", basename(transition_file), "\n")
  cat("  -", basename(period_file), "\n")
  if (nrow(summary_results$yearly_summary) > 0) {
    cat("  -", basename(yearly_file), "\n")
  }
  cat("  -", basename(pdf_file), "\n")

  # Return created file paths
  created_files <- list(
    transition_summary = transition_file,
    period_summary = period_file,
    plots_pdf = pdf_file
  )

  if (nrow(summary_results$yearly_summary) > 0) {
    created_files$yearly_summary <- yearly_file
  }

  return(invisible(created_files))
}

#' Create Diagnostic Plots
#'
#' Creates diagnostic plots to validate simulation results.
#'
#' @param results Single simulation results
#' @return List of diagnostic plots
#' @export
#' @examples
#' \dontrun{
#' results <- run_simulation_optimized(123)
#' diagnostics <- create_diagnostic_plots(results)
#' print(diagnostics$openings_vs_time)
#' }
create_diagnostic_plots <- function(results) {
  yearly_stats <- results$yearly_stats

  # 1. Job openings over time
  p1 <- ggplot2::ggplot(yearly_stats, ggplot2::aes(x = year)) +
    ggplot2::geom_line(ggplot2::aes(y = total_openings), color = "green", size = 1) +
    ggplot2::geom_vline(xintercept = RECESSION_START, linetype = "dashed", alpha = 0.7) +
    ggplot2::labs(title = "Job Openings Over Time", x = "Year", y = "Total Openings") +
    ggplot2::theme_minimal()

  # 2. Job seekers over time
  p2 <- ggplot2::ggplot(yearly_stats, ggplot2::aes(x = year)) +
    ggplot2::geom_line(ggplot2::aes(y = candidates_seeking), color = "orange", size = 1) +
    ggplot2::geom_vline(xintercept = RECESSION_START, linetype = "dashed", alpha = 0.7) +
    ggplot2::labs(title = "Job Seekers Over Time", x = "Year", y = "Candidates Seeking") +
    ggplot2::theme_minimal()

  # 3. Supply vs demand
  yearly_stats_long <- data.frame(
    year = rep(yearly_stats$year, 2),
    value = c(yearly_stats$total_openings, yearly_stats$candidates_seeking),
    type = rep(c("Openings", "Candidates"), each = nrow(yearly_stats))
  )

  p3 <- ggplot2::ggplot(yearly_stats_long, ggplot2::aes(x = year, y = value, color = type)) +
    ggplot2::geom_line(size = 1) +
    ggplot2::geom_vline(xintercept = RECESSION_START, linetype = "dashed", alpha = 0.7) +
    ggplot2::labs(title = "Supply vs Demand", x = "Year", y = "Count", color = "Type") +
    ggplot2::theme_minimal()

  return(list(
    openings_vs_time = p1,
    candidates_vs_time = p2,
    supply_vs_demand = p3
  ))
}