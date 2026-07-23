# Frame: Tidyverse
# - The tidyverse is a tightly integrated framework of hugely popular R packages (e.g., dplyr, ggplot2, tidyr, readr, purrr)
# - Mostly created between 2010 and 2015 by Hadley Wickham and others
# - Has been the de facto standard for data analysis in R since around 2017: 8 of the top 10 most downloaded R packages are part of the tidyverse ecosystem.
# - Most well-known feature: piping syntax (%>%)
# - Not part of base R because of different design philosophy, and to maintain backwards compatibility.


# -----------------------------------------------------------------------------
# Data Setup
# -----------------------------------------------------------------------------

# Frame: Load Main Panel Data
# The main dataset is a Firm-year panel (2015--2024), with one row per firm and year. Variables include output, employment, wages, exports, profits, and treatment status (for an intervention).
# Here, treated = 1 means the firm is exposed to a carbon-pricing policy that starts in 2020.
library(tidyverse)
library(x12)
panel_raw <- read_csv("firm_panel.csv")

panel_raw
glimpse(panel_raw)

# In the tidyverse, data frames are called tibbles, which have some nice printing and subsetting features. The glimpse() function gives a compact overview over all variables, their types, and a preview of values.

# Frame: How Piping Works with %>%
# The pipe operator %>% passes the left-hand result as input to the next function. This lets us write operations as a readable sequence, left to right.
# The following two lines are exactly equivalent:
glimpse(panel_raw)
panel_raw %>% glimpse()

# Other examples:
panel_raw %>% head() %>% print()
panel_raw %>% dim() %>% print()
panel_raw %>% names() %>% print()


# -----------------------------------------------------------------------------
# Basic Transformations
# -----------------------------------------------------------------------------

# Frame: Select and Filter
# Use select() to pick out specific columns:
panel_clean <- panel_raw %>%
    select(firm_id, year, industry, region, treated, employment, output, wage)

# Use filter() to subset rows based on conditions:
panel_clean %>%
    select(firm_id, year, industry, output, wage) %>%
    filter(year >= 2020, industry == "Manufacturing")

# Note how the pipe makes this very elegant. Without it, we would need to either nest functions, or create intermediate variables for each step, which is much less readable and more error-prone.

# Frame: Mutate and Summarize
# Use mutate() to create new columns or change existing ones:
panel_features <- panel_clean %>%
    mutate(
        log_output = log(output),
        log_wage = log(wage),
        labor_productivity = output / employment
    )
panel_features 
# Use summarise() to compute summary statistics across the whole dataset:
panel_summary <- panel_features %>%
    summarise(
        n_obs = n(),
        max_log_output = max(log_output),
        avg_labor_prod = mean(labor_productivity)
    )
panel_summary
# Frame: Renaming, Sorting, and Duplicates
# Column renaming and sorting with rename() and arrange():
panel_sorted <- panel_features %>%
    rename(firm = firm_id) %>%
    arrange(desc(output))
panel_sorted
# Print duplicated rows (by firm, year):
panel_sorted %>% nrow() %>% print()
panel_sorted %>% distinct(firm, year) %>% nrow() %>% print()
panel_sorted %>%
    add_count(firm, year, name = "n_key") %>%
    filter(n_key > 1) %>%
    arrange(firm, year) %>%
    print()

# Frame: Exercise: Basic Transformations
# Apply the same basic transformations to the macro controls dataset.
# Starter:
macro_ex <- read_csv("macro_controls.csv")
# - Use select() to keep year, inflation, policy_rate.
# - Use filter() to keep years >= 2020.
# - Use mutate() to create real_rate = policy_rate - inflation.
# - Use summarise() to report n_obs, mean inflation, and mean real rate.
# - Use rename() and arrange() to create a sorted output table.
# - Use distinct(year) and row counts to check duplicate years.
# - You can of course use an LLM to draft a clean pipeline.


# -----------------------------------------------------------------------------
# Merging
# -----------------------------------------------------------------------------

# Frame: Merging
# (joins illustration)

# Frame: Join Safety First, Then Merge
# We now want to combine the firm-year panel with macroeconomic controls at the year level.
macro_raw <- read_csv("macro_controls.csv")
macro_raw %>% glimpse()

# Always verify key uniqueness before joins to avoid accidental row duplication:
macro_raw %>% count(year) %>% filter(n > 1)

panel_joined <- panel_features %>%
  left_join(macro_raw, by = "year")

panel_joined %>% glimpse()

# Frame: Exercise: Merging
# Starter:
region_shocks <- read_csv("region_shocks.csv")
# - Inspect the dataset structure and identify the natural merge key.
# - Check key uniqueness with count(region, year) %>% filter(n > 1) and interpret what the output implies for merging.
# - Then merge on the appropriate keys (you need to use two).
# - Compare row counts before and after the join and think about why they do (or do not) change.
# - Rerun the same grouping summary and grouped plot after adding region controls, and compare the pattern to the current one.
# - You can of course use an LLM to draft a clean pipeline.


# -----------------------------------------------------------------------------
# Grouping & Plotting
# -----------------------------------------------------------------------------

# Frame: Grouping Data with dplyr
# Grouping aggregates data by one or more variables, allowing you to compute summary statistics within each group. The group_by() function is used to specify the grouping variables, and then summarise() computes the desired summaries for each group.
year_treat_summary <- panel_joined %>%
  group_by(year, treated) %>%
  summarise(
    mean_output = mean(output, na.rm = TRUE),
    mean_log_output = mean(log_output, na.rm = TRUE),
    mean_wage = mean(wage, na.rm = TRUE),
    n_firms = n(),
    .groups = "drop"
  )

year_treat_summary

# group_by() and summarise() are very commonly used together.

# Frame: Group Plot
# ggplot2 is the de facto standard for plotting in R. It is very elegant in that you literally add (+) layers of plot elements.
ggplot(year_treat_summary, aes(x = year, y = mean_output, color = factor(treated), group = treated)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  scale_x_continuous(
    breaks = seq(min(year_treat_summary$year), max(year_treat_summary$year), by = 1)
  ) +
  labs(
    title = "Mean output by year and treatment",
    x = "Year",
    y = "Mean output",
    color = "Treated"
  ) +
  theme_minimal()


# -----------------------------------------------------------------------------
# Reshaping Data
# -----------------------------------------------------------------------------

# Frame: Reshaping Illustration
# (reshape illustration)

# Frame: Pivot Firm-Year Data to Wide
# Our panel is currently in long format (one row per firm-year). Here we pivot to a wide format where years become horizontal columns, and then inspect both versions with View().
panel_long <- panel_joined %>%
  select(firm_id, year, output)

panel_wide <- panel_long %>%
  pivot_wider(
    names_from = year,
    values_from = output,
    names_prefix = "year_"
  )

View(panel_long)
View(panel_wide)


# Frame: Thank you!
# Install Julia for next week!
