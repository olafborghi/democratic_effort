# Democratic Effort: Computational Modelling (MATLAB)

**Project:** *Is Democracy Worth the Effort? Seeing the Other Side as Willing Strengthens Pro-Democratic Motivation*

This folder contains the computational-modelling pipeline for the **Pro-Democratic Effort Task**. Trial-level choices (Work vs. Rest across beneficiary conditions, effort levels, and reward levels) are fit with hierarchical Expectation-Maximisation to estimate per-participant **effort-discounting parameters (K)** for each beneficiary and a shared **decision-consistency parameter (β)**. These per-participant estimates are then exported to the R pipeline as individual-difference measures.

Adapted from the hierarchical-EM toolbox and extended for the multi-beneficiary design.

---

## Repository structure

```
Matlab_Code/
├── study1/                       # 3 beneficiaries: all, rural, urban
└── study2/                       # 2 beneficiaries: rural, urban
```

Each study folder follows the same layout:

```
studyN/
├── README.md
├── Model_real_data/
│   ├── unifiedpipeline_K_mv_*.m       # End-to-end pipeline script
│   ├── no_na/                         # Per-participant trial-level CSVs (input)
│   ├── models/mod_ms_all.m            # Unified choice-model likelihood
│   ├── tools/                         # EM-fit toolbox (Cutler et al.)
│   ├── workspaces/                    # Saved .mat workspaces from EM fitting
│   └── full_democraticeffortdata_for_model.mat   # Imported data struct
├── PM_R_code/data/                    # CSV outputs handed off to R pipeline
├── simulations/                       # Model identifiability & parameter recovery
└── Figures/                           # Exported plots
```

---

## Pipeline

Both studies run the same six steps via `unifiedpipeline_K_mv_*.m`:

| Step | Purpose |
|------|---------|
| 1. Import | Reads trial-level CSVs from `Model_real_data/no_na/`; recodes `agent` (Study 1: `VOTEALL→1`, `VOTERURAL→2`, `VOTEURBAN→3`; Study 2: rural/urban only); builds the `s.PM` struct expected by the toolbox |
| 2. Model setup | Defines the candidate model space and parameter bounds (`beta ∈ [0,10]`) |
| 3. EM fitting | Hierarchical MAP/EM (`EMfit_ms_par`) — convergence at ΔlogPost < 0.001 or 800 iterations; integrated BIC computed via `cal_BICint_ms` |
| 4. Model comparison | Computes `lme`, `bicint`, `xp` (SPM12 `spm_BMS`), `pseudoR2`, `choiceProbMedianR2`; includes Hessian-based LME recomputation and an XP-from-BIC cross-check |
| 5. Parameter extraction | Selects winning model (criterion: `bicint`); extracts per-participant K parameters and β via `getparams` |
| 6. Save | Writes per-participant parameter CSV and model-fit-statistics CSV to `PM_R_code/data/` (handoff to R) |

### Model space

`mod_ms_all.m` implements a softmax choice between a Work offer with subjective value `SV_work` and a Rest baseline (`SV_rest = 1`):

- **Parabolic** (default): `SV = reward − k · effort²`
- **Linear**: `SV = reward − k · effort`
- **Hyperbolic**: `SV = reward / (1 + k · effort)`

Crossed with the number of agent-specific K and β parameters:

| Study | Candidate models |
|-------|------------------|
| Study 1 | 3K × {1β, 3β} × {parabolic, linear, hyperbolic} = 6 models |
| Study 2 | 2K × {1β, 2β} × {parabolic, linear, hyperbolic} = 6 models |

**Winning model (both studies):** `ms_{three,two}_k_one_beta_hyperbolic` — one K per beneficiary, a shared β, hyperbolic discounting.

---

## Outputs (handoff to R)

Each study writes two CSVs into `PM_R_code/data/`:

| File | Contents |
|------|----------|
| `EM_fit_parameters_full_democraticeffortdata_<bestmodel>.csv` | One row per participant: `all_k`, `rural_k`, `urban_k` (Study 1) or `rural_k`, `urban_k` (Study 2), plus `beta`. A `_labeled` version with explicit agent column names is also written |
| `PM_model_fit_statistics_full_democraticeffortdata.csv` | One row per candidate model: `lme`, `bicint`, `xp`, `pseudoR2`, `choiceProbMedianR2`, `relbic` |

These files are read by `R_Code/study*/02_comp_model_prep.qmd`, which merges the K/β parameters into the survey dataset and recodes them relative to partisanship (`k_ingroup`, `k_outgroup`, `k_outgroup_ingroup`) for downstream analyses.

---

## Simulations

Validation scripts in `simulations/` (not part of the main pipeline):

- `modelidentifiability_study{1,2}.m` — simulates data from each candidate model and refits all candidates; outputs confusion matrices (`*_confusion_BICint.csv`, `*_confusion_XP.csv`) and heatmaps to verify the true generator is recovered.
- `parameterrecovery_study{1,2}*.m` — simulates choices from the winning model across a grid of known parameters, refits via hierarchical EM, and reports true-vs-recovered correlations (scatterplots, heatmaps, summary CSV).
- Small `plot_*.R` helpers render the recovery figures.

Both checks use the actual trial schedule (27 trials in Study 1, 18 in Study 2).

---

## Dependencies

MATLAB R2025b with:

- **Statistics and Machine Learning Toolbox**
- **Optimization Toolbox**
- **SPM12** — required for `spm_BMS` (exceedance probabilities) and `spm_gamrnd`

Before running, set `dataFolder`, `output_dir`, `workspace_dir`, and `spm_dir` at the top of `unifiedpipeline_K_mv_*.m` to match your local paths.
