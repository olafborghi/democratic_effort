# Study 2: Data Description

Two datasets are used across the analysis scripts. Final analysis-ready versions are saved in `01_data/final/` (after merging with MATLAB-fitted K/β parameters); their post-exclusion clean versions live in `01_data/clean/`. Both are saved as `.csv` and `.RData`.

- **`demeffort_combined_data`** — trial-level task data merged with participant-level survey variables (one row per trial per participant; 18 trials × 632 participants = 11,376 rows). Used in GLMMs on trial-level choices.
- **`demeffort_survey_data`** — participant-level dataset (one row per participant). Used in K-parameter regressions.

Unlike Study 1, Study 2 does not save a separate pre-exclusion `demeffort_bonus_data` file (all task earnings were automatically donated to Vote.org, so no bonus payment file was needed).

Study 2 shares the same task structure and most survey variables as Study 1, but removes the VOTEALL beneficiary condition, adds an experimental treatment manipulation, and replaces the health battery with measures of democratic attitudes. Variables present in Study 1 but absent here are noted below.

---

## Task variables (trial-level)

| Variable | Type | Values / Range | Description |
|----------|------|----------------|-------------|
| `PID` | character | P01–P632 | Anonymised participant ID |
| `agent` | factor | `VOTEURBAN`, `VOTERURAL` | Raw beneficiary condition (VOTEALL condition removed in Study 2) |
| `benefit` | factor | `INGROUP`, `OUTGROUP` | `agent` recoded relative to partisanship: urban = INGROUP for Democrats, OUTGROUP for Republicans; rural = opposite |
| `eff` | factor | `easy65`, `hard80`, `hard95` | Required effort level as % of individually calibrated max (65 / 80 / 95%) |
| `rew` | factor | 4, 12, 20 | Credits available for the work option |
| `decision` | numeric | 1 = Work, 0 = Rest, NA = missed | Trial-level choice |
| `success` | numeric | 1 = boxes completed, NA = rest or time-out | Whether the participant met the clicking target when they chose to work |
| `max_boxes` | numeric | ≥ 13 | Individual calibration: highest box-click count across two practice rounds |
| `easy65_nboxes`, `hard80_nboxes`, `hard95_nboxes` | numeric | | Required number of boxes at each effort level for this participant |

---

## Computational model parameters (participant-level)

Fitted in MATLAB using hierarchical MAP estimation. Winning model: **2K1β hyperbolic** — two beneficiary-specific K parameters, one shared inverse-temperature β.

| Variable | Description |
|----------|-------------|
| `k_urban` | Raw K parameter for VOTEURBAN condition |
| `k_rural` | Raw K parameter for VOTERURAL condition |
| `k_ingroup` | `k_urban` for Democrats, `k_rural` for Republicans |
| `k_outgroup` | `k_rural` for Democrats, `k_urban` for Republicans |
| `k_outgroup_ingroup` | **In-group favouritism index** = K_outgroup − K_ingroup; higher values = stronger partisan bias in effort motivation. Primary outcome variable in Study 2 |
| `k_mean` | Mean of k_ingroup and k_outgroup; general effort discounting |
| `beta` | Inverse temperature (decision consistency); shared across beneficiaries |

Note: `k_all` / `k_everyone` and the difference scores `k_all_ingroup` and `k_outgroup_all` do not exist in Study 2 (no VOTEALL condition).

---

## Survey variables (participant-level)

### Experimental design

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `condition` | factor | Treatment, Control | Random assignment (balanced within party). Treatment participants received corrective feedback about out-party effort willingness before the task; control participants received no feedback |
| `outparty_estimate` | numeric | 1–5 | Participant's estimate of how often the average out-party supporter chose to work for areas associated with the participant's own party in Study 1. Scale: 1 = almost never (0–19%), 2 = rarely (20–39%), 3 = sometimes (40–59%), 4 = often (60–79%), 5 = almost always (80–100%). Correct answer = 4 |
| `deviation` | numeric | −3 to +1 (observed range) | `outparty_estimate − 4`. Negative = underestimation; 0 = accurate; positive = overestimation. Primary predictor in H1 and covariate in follow-up analyses |
| `inparty` / `outparty` | factor | Democrat, Republican | Participant's own party / opposing party labels, used for constructing the estimation items |

### Partisanship

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `party_preference` | factor | Democrat, Republican | Final partisan classification: self-identified party, or leaning for Independents/Other |
| `party_importance` | numeric | z-scored | Perceived personal importance of party membership |
| `ideology` | numeric | z-scored | Self-reported political ideology (liberal–conservative) |

Note: `party_intensity` is not computed in Study 2. `party_identity_strength` is not included in Study 2.

### Affective polarisation

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `valence_democrats` / `valence_republicans` | numeric | 0–100 | Favourability ratings toward each party |
| `arousal_democrats` / `arousal_republicans` | numeric | 0–100 | Emotional intensity of feelings toward each party |
| `affpol_weighted` | numeric | z-scored | **Primary affective polarisation measure.** Arousal-weighted spread of valence ratings across parties (Kasper et al., 2025); higher = more polarised |
| `affpol_raw` | numeric | z-scored | Unweighted valence spread (sensitivity check) |

### Democratic attitudes

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `democratic_support` | numeric | z-scored | 4-item scale (0–100 scale; all items reverse-coded from anti-democratic framing); higher = stronger pro-democratic norms. Note: different operationalisation from Study 1 (7-item Likert) |
| `antidemocratic_01`–`antidemocratic_04` | numeric | 0–100 | Raw anti-democratic attitude items (reversed before scoring) |
| `freefair` | numeric | z-scored | 2-item support for free and fair elections (1–5 Likert; freefair_02 reverse-coded); higher = stronger support |

### Treatment check variables (Study 2 only)

| Variable | Description |
|----------|-------------|
| `treat_dem_surprise` / `treat_rep_surprise` | How surprising participants found the corrective feedback (Democrat / Republican version) |
| `treat_dem_credible` / `treat_rep_credible` | How credible participants found the feedback |

### Task summaries (participant-level aggregates)

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `work_total` | integer | 0–18 | Total work choices across all 18 trials |
| `work_voteurban` | integer | 0–9 | Work choices in VOTEURBAN condition |
| `work_voterural` | integer | 0–9 | Work choices in VOTERURAL condition |
| `work_ingroup` | integer | 0–9 | Work choices in the participant's in-group condition |
| `work_outgroup` | integer | 0–9 | Work choices in the participant's out-group condition |
| `work_difference` | integer | −9 to 9 | work_ingroup − work_outgroup; raw behavioural in-group favouritism |

### Demographics

| Variable | Values | Description |
|----------|--------|-------------|
| `age` | numeric | Age in years |
| `gender` | Man, Woman, Other, Prefer not to say | |
| `rururb03` | numeric | Urban–rural self-placement |
| `education` | 6 levels (less than high school → postgraduate) | Highest education level |
| `ethnicity01` / `ethnicity02` | 7 categories | Self-identified ethnicity (up to two selections) |
| `income` | 12 levels ($<10k → $150k+) | Annual household income |

Note: Study 2 does not include health or wellbeing measures (no PSS-10, PHQ-8, health_politics, health_general, stress_politics). The donation decision item is also absent from Study 2; all task earnings were automatically donated to Vote.org.

---

## Notes on scoring

- All continuous survey predictors are **z-scored** prior to regression analyses.
- Affective polarisation (`affpol_weighted`) follows the arousal-weighted spread-of-valence method from Kasper et al. (2025): arousal-weighted mean valence is computed first, then the arousal-weighted spread of valence values around that mean.
- `democratic_support`: four items (`antidemocratic_01`–`antidemocratic_04`) are reverse-coded (100 − item) and summed; higher = more pro-democratic. This is a different measure and scale from Study 1's 7-item Likert scale.
- `freefair`: `freefair_02` is reverse-coded (6 − item) before summing the two items.
- Pre-registered analyses are restricted to the **N = 550 participants (87%) who underestimated out-party effort willingness** (i.e., `deviation < 0`), as specified in the preregistration. Results for the full sample are reported in Supplementary Materials.
