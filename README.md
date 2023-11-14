# Purpose

This script will help you identify PRs and Issues to review for any given organization. Useful for understanding how the organization operates.

# Requirements

You must have [https://miller.readthedocs.io/en/6.9.0/](mlr), [https://jqlang.github.io/jq/](jq), and the [https://cli.github.com/](GitHub CLI) installed. You must also be logged into the GitHub CLI with `gh auth login`.

# Running the script

The script can be run with `./make_csvs.sh <org_name>`. This will create a directory called `output` with the following files:

- issues.csvs - A CSV of the issues with the most comments as well as the most recent issues.
- prs.csv - A CSV of PRs with the most comments, reviews, and the most recently updated.
- top30repos.txt - 10 of the most recently updated repos, the 10 repos with the most open issues, and the 10 repos with the most total PRs.
