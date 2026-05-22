

study2/
  ├── Model_real_data/
  │   ├── no_na/
  │   ├── workspaces/
  │   └── full_democraticeffortdata_for_model.mat
├── PM_R_code/
  │   └── data/
  ├── models/
  ├── tools/
  └── unifiedpipeline_K_mv.m



# Democratic Effort Task – Modelling Pipeline

This project implements the unified modelling pipeline for the **Democratic Effort Task**, adapted from Jo Cutler’s toolbox and extended for **2 agents** ( `rural`, `urban`) with **3 effort levels**.

## Workflow Overview

### Step 1 – Import data
**Input:** trial-level CSV files in: /Model_real_data/no_na/
  
  Columns: `agent`, `effort`, `reward`, `choice`.  
Actions: recode agents (`VOTEALL→1`, `VOTERURAL→2``), standardise names, build struct `s`.  
**Output:** `full_democraticeffortdata_for_model.mat`.

### Step 2 – Model setup
Define models in `M.modid` (2-agent), set bounds (`beta`, `k`).

### Step 3 – EM fitting
Fit all models via EM.  
EM fitting proceeds until convergence (change in group log posterior < 0.001) or a maximum of 800 iterations
Save: `/Model_real_data/workspaces/EM_fit_results_full_democraticeffortdata_<date>.mat`.  
Compute integrated BIC.

### Step 4 – Model comparison
Metrics: `lme`, `bicint`, `xp`, `pseudoR2`, `choiceProbMedianR2`.  
Save summary: `/PM_R_code/data/PM_model_fit_statistics_full_democraticeffortdata.csv`.  
Figures show Group-level model evidence, Integrated BIC comparison, Exceedance probabilities

### Step 5 – Parameter extraction
Pick best model by `criteria` (default `bicint`).  
Extract per-participant:
  - `rural_k`, `urban_k` (effort sensitivity),
- `beta' (choice consistency),
- `urban–rural_k` contrast,
- `rural_choice`, `urban_choice` (accept proportions).

### Step 6 – Save results
- **Parameters CSV:** `/PM_R_code/data/EM_fit_parameters_full_democraticeffortdata_<bestmodel>.csv` (one row per participant).  
- **Workspace:** `/Model_real_data/workspaces/EM_fit_results_full_democraticeffortdata_<date>.mat`.  
- **Fit stats CSV:** `/PM_R_code/data/PM_model_fit_statistics_full_democraticeffortdata.csv`.

###### Practical Usage

### Run the main pipeline (MATLAB)
1. Open `unifiedpipeline_K_mv.m`.
2. Check `dataFolder`, `output_dir`, `workspace_dir`.
3. Run end-to-end.

### Outputs
- Parameters: `PM_R_code/data/EM_fit_parameters_full_democraticeffortdata_<bestmodel>.csv`
- Model comparison: `PM_R_code/data/PM_model_fit_statistics_full_democraticeffortdata.csv`
- Workspace: `Model_real_data/workspaces/EM_fit_results_full_democraticeffortdata_<date>.mat`

## Reload without refitting (MATLAB)
```matlab
load('/Model_real_data/workspaces/EM_fit_results_full_democraticeffortdata_<date>.mat')
% then rerun Step 5 + Step 6