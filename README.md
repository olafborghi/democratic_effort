# Democratic Effort

**Project:** *Is Democracy Worth the Effort? Seeing the Other Side as Willing Strengthens Pro-Democratic Motivation*

Data and Code for two preregistered studies (total *N* = 916) using the **Pro-Democratic Effort Task** — a computational behavioral paradigm measuring US partisans' willingness to exert physical effort to support democratic engagement in areas associated with their own party (in-group), the opposing party (out-group), or across the US (Study 1 only). Hierarchical computational models estimate beneficiary-specific effort-discounting parameters (K) that separate motivation from decision noise.

- **Study 1** (*N* = 284) validates the task and maps partisan differences and psychological correlates of pro-democratic effort.
- **Study 2** (*N* = 632) tests whether correcting partisans' systematic underestimation of out-party effort willingness reduces in-group favoritism.

---

## Repository structure

```
demeffort_analyses/
├── R_Code/                       # Data cleaning + all statistical analyses (Quarto / R)
│   ├── README.md                 # Detailed script-by-script overview
│   ├── study1/
│   └── study2/
└── Matlab_Code/                  # Computational modelling (hierarchical EM)
    ├── README.md                 # Detailed pipeline + model space
    ├── study1/
    └── study2/
```

The two language stacks are separated because the computational modelling toolbox runs in MATLAB, while data cleaning, regressions, and figures are in R. The two sides communicate via CSV files.

For details, see `R_Code/README.md` and `Matlab_Code/README.md`.

---

## Pipeline

The analysis pipeline crosses the two language stacks. For each study, the order is:

```
  Raw Qualtrics CSV
        │
        ▼
  R: 01_cleaning.qmd            ── produces per-participant trial-level CSVs
        │                          (R_Code/studyN/01_data/models/prep/)
        │
        │   [copy CSVs into MATLAB inputs folder]
        ▼
  MATLAB: unifiedpipeline_K_mv_*.m   ── EM fitting, model comparison,
        │                                parameter extraction
        │                          (Matlab_Code/studyN/PM_R_code/data/)
        │
        │   [copy MATLAB outputs back to R inputs folders]
        ▼
  R: 02_comp_model_prep.qmd     ── merges K/β into survey data,
        │                          recodes by partisanship
        ▼
  R: 03_descriptives.qmd
  R: 04_*.qmd, 05_*.qmd         ── regressions, follow-ups, figures
```

### Step-by-step reproduction

For each study (replace `N` with `1` or `2`):

1. **Open the R project** `R_Code/studyN/studyN.Rproj` and render `00_power_analysis.qmd` (optional — pre-study power simulations) and `01_cleaning.qmd`. This produces the per-participant trial-level CSVs in:
   ```
   R_Code/studyN/01_data/models/prep/
   ```
2. **Copy** those CSVs into the MATLAB inputs folder:
   ```
   Matlab_Code/studyN/Model_real_data/no_na/
   ```
3. **Open MATLAB**, set the four paths at the top of `Matlab_Code/studyN/Model_real_data/unifiedpipeline_K_mv_*.m` (`dataFolder`, `output_dir`, `workspace_dir`, `spm_dir`), and run the script end-to-end. This writes two CSVs to:
   ```
   Matlab_Code/studyN/PM_R_code/data/
   ```
   (`EM_fit_parameters_..._labeled.csv` — per-participant K and β; and `PM_model_fit_statistics_...csv` — model comparison table.)
4. **Copy** those two CSVs back into the R inputs folders:
   - `EM_fit_parameters_..._labeled.csv` → `R_Code/studyN/01_data/models/matlab_pars/`
   - `PM_model_fit_statistics_...csv` → `R_Code/studyN/01_data/models/matlab_fit/`
5. **Back in R**, render the remaining scripts in order: `02_comp_model_prep.qmd` → `03_descriptives.qmd` → `04_*.qmd` → (Study 2 only) `05_followup_regressions.qmd`.

### Optional: model validation

`Matlab_Code/studyN/simulations/` contains stand-alone scripts for model identifiability and parameter recovery on the winning model. These are validation checks (not part of the main pipeline) and can be run any time after Step 3.

---

## Software versions

- **R** 4.5.2, with [`groundhog`](https://groundhogr.com/) for reproducible package management, locked to `2026-01-01`. Core packages: `tidyverse`, `afex`, `marginaleffects`, `estimatr`, `modelsummary`, `tinytable`, `patchwork`.
- **MATLAB** R2025b, with the **Statistics and Machine Learning Toolbox** and **Optimization Toolbox**.
- **SPM12** — required for `spm_BMS` (exceedance probabilities) and `spm_gamrnd`. Install separately and point `spm_dir` in the MATLAB pipeline script to your local copy.

---

## Notes for reproducing

- Both MATLAB pipeline scripts contain hard-coded paths from the original development machine (paths beginning with `/Users/marianavonmohr/Desktop/...`). Replace these at the top of each `unifiedpipeline_K_mv_*.m` before running.
- EM fitting uses `rng default` for reproducibility; results should match across machines given identical inputs and SPM12 version.
- The winning model in both studies is the **hyperbolic, one-β-per-participant, one-K-per-beneficiary** variant (`ms_three_k_one_beta_hyperbolic` for Study 1; `ms_two_k_one_beta_hyperbolic` for Study 2). Model selection is based on integrated BIC, with exceedance probabilities reported for completeness.

## Contact 

- For questions/comments on the MATLAB code, please email: Mariana.vonmohr@rhul.ac.uk
- For questions/comments on the R code, please email: olaf.borghi@rhul.ac.uk
