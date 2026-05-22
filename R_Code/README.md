# Democratic Effort: Analysis Repository

**Project:** *Is Democracy Worth the Effort? Seeing the Other Side as Willing Strengthens Pro-Democratic Motivation*

Two preregistered studies (total *N* = 916) using the **Pro-Democratic Effort Task** — a computational behavioral paradigm measuring US partisans' willingness to exert physical effort to support democratic engagement in areas associated with their own party (in-group), the opposing party (out-group), or across the US (Study 1 only). Hierarchical computational models estimate beneficiary-specific effort-discounting parameters (K) that separate motivation from decision noise.

**Study 1** (N = 284) validates the task and maps partisan differences and psychological correlates of pro-democratic effort. **Study 2** (N = 632) tests whether correcting partisans' systematic underestimation of out-party effort willingness reduces in-group favouritism.

---

## Repository structure

```
demeffort_analyses/
├── study1/                       # Study 1 R project
└── study2/                       # Study 2 R project
```

Each study folder follows the same layout:

```
studyN/
├── studyN.Rproj
├── 0N_*.qmd          # Analysis scripts (Quarto; rendered .html where available)
├── 01_data/
│   ├── raw/          # Raw Qualtrics export (demeffort_raw.csv)
│   ├── clean/        # Cleaned task and survey data (.csv / .RData)
│   ├── models/
│   │   ├── prep/          # Per-participant input files for MATLAB model fitting
│   │   ├── matlab_fit/    # Full MATLAB EM-fit output (all candidate models, fit statistics)
│   │   └── matlab_pars/   # Winning-model K and β parameters per participant
│   └── final/        # Combined analysis-ready datasets (survey + K/β parameters)
└── 02_output/
    ├── figures/      # Saved plots (.png / .svg), organised by analysis stage
    ├── tables/       # Saved tables (.docx), organised by analysis stage
    └── models/       # Cached fitted R model objects (.rds) — Study 2 only
```

---

## Scripts

### Study 1

| Script | Purpose |
|--------|---------|
| `00_power_analysis.qmd` | Pre-study power simulations (DeclareDesign)
| `01_cleaning.qmd` | Loads raw Qualtrics export; applies exclusion criteria; reshapes to trial-level format; cleans and scores survey measures; saves task and survey datasets to `01_data/clean/` |
| `02_comp_model_prep.qmd` | Merges MATLAB-estimated K/β parameters with survey data; recodes K parameters relative to partisanship (K_ingroup, K_outgroup, K_all); computes difference scores; saves combined dataset to `01_data/final/` |
| `03_descriptives.qmd` | Participant demographics; summary tables; correlations; key figures (choice behaviour, K distributions, in-group/out-group and partisanship plots) saved to `02_output/figures/descriptives/` |
| `04_log_regressions.qmd` | GLMMs on trial-level choices (decision ~ beneficiary × effort × reward); model-based contrasts; validates in-group favouritism behaviourally |
| `05_k_regressions.qmd` | Robust linear regressions on K parameters: task validation (H1d), partisan differences (H2a–d), political correlates (H3a–d), mental and physical health correlates (H4a–d); Bayesian correlations between K parameters and key political/health variables; correlogram and Bayesian correlation heatmap |

### Study 2

| Script | Purpose |
|--------|---------|
| `00_power_analysis.qmd` | Pre-study power simulations (DeclareDesign)
| `01_cleaning.qmd` | Same pipeline as Study 1; additionally processes the misperception estimation items and experimental condition assignment; computes `deviation` score (out-party estimate − 4, where 4 = "often 60–79%") |
| `02_comp_model_prep.qmd` | Same as Study 1 (2K models: K_ingroup, K_outgroup); merges with survey and condition data; saves to `01_data/final/` |
| `03_descriptives.qmd` | Participant demographics; baseline misperception distributions; descriptive plots saved to `02_output/figures/descriptives/` |
| `04_regressions.qmd` | Pre-registered K-parameter models on the underestimator sub-sample: H1 (deviation predicts in-group favouritism), H2A/B (treatment effects on K_outgroup_ingroup and K_outgroup via robust regression), H3A/B (affective polarisation predictors), H4 (conditional treatment × affective polarisation); plus exploratory H3C (deviation + condition on in-group favouritism) and a re-specified LMM addendum to H2 |
| `05_followup_regressions.qmd` | Follow-up models on the full sample: GLMM on trial-level choices (decision ~ condition × benefit × effort × reward); over- / accurate- / under-estimator comparison with simple slopes and Bayes factors; exploratory GAM with non-linear affective-polarisation smooths; exploratory Bayesian model comparison (JZS priors); non-registered partisan-difference replications |

---

## Key variables

### Trial-level task data (`demeffort_combined_data`)

| Variable | Description |
|----------|-------------|
| `PID` | Participant ID (P01, P02, …) |
| `agent` | Beneficiary condition: `VOTEURBAN`, `VOTERURAL`, `VOTEALL` (Study 1 only) |
| `eff` | Effort level: `easy65`, `hard80`, `hard95` (% of calibrated max boxes) |
| `rew` | Reward available: 4, 12, or 20 credits |
| `decision` | Choice: 1 = Work, 0 = Rest, NA = missed trial |
| `max_boxes` | Individually calibrated maximum box-click rate |

### Combined analysis dataset (`demeffort_bonus_data` / `demeffort_survey_data`)

| Variable | Description |
|----------|-------------|
| `party_preference` | Democrat / Republican |
| `party_intensity` | 0 = Independent/Other lean, 1 = not very strong, 2 = strong (Study 1 only; Study 2 uses `party_importance` instead) |
| `affpol_weighted` | Affective polarisation (arousal-weighted valence spread; higher = more polarised) |
| `k_urban` / `k_rural` | Raw MATLAB K parameters for urban / rural beneficiary |
| `k_all` | Raw K parameter for all-areas condition (Study 1 only) |
| `k_ingroup` / `k_outgroup` | K recoded relative to partisanship (Democrats: k_ingroup = k_urban; Republicans: k_ingroup = k_rural) |
| `k_outgroup_ingroup` | In-group favouritism index (K_outgroup − K_ingroup; higher = more partisan bias) |
| `k_everyone` | K_all relabelled (Study 1 only) |
| `beta` | Shared inverse-temperature (decision consistency) parameter |
| `work_ingroup` / `work_outgroup` | Raw count of work decisions in each beneficiary condition |
| `donation_decision` | Donate vs. keep task bonus (Study 1 task-validation measure) |
| `condition` | `Treatment` vs. `Control` (Study 2 only) |
| `deviation` | Out-party effort estimate − 4; negative = underestimation (Study 2 only) |

---

## Dependencies

All scripts use [`groundhog`](https://groundhogr.com/) for reproducible package management, locked to `2026-01-01`. Core packages: `tidyverse`, `afex`, `marginaleffects`, `estimatr`, `BayesFactor`, `mgcv`, `modelsummary`, `tinytable`, `ggdist`, `patchwork`. Computational models were fitted in MATLAB R2025b; R version 4.5.2.
