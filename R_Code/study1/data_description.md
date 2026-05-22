# Study 1: Data Description

Three datasets are produced by the cleaning pipeline. Final analysis-ready versions of the two analysis datasets are saved in `01_data/final/` (after merging with MATLAB-fitted K/β parameters); their post-exclusion clean versions live in `01_data/clean/`. All datasets are saved as both `.csv` and `.RData`.

- **`demeffort_combined_data`** — trial-level task data merged with participant-level survey variables (one row per trial per participant; 27 trials × 284 participants = 7,668 rows). Post-exclusion. Used in GLMMs on trial-level choices.
- **`demeffort_survey_data`** — participant-level dataset (one row per participant; post-exclusion). Used in K-parameter regressions.
- **`demeffort_bonus_data`** — participant-level dataset *before* analysis exclusions (saved in `01_data/clean/` only). Used to calculate bonus payments for all participants who completed the study, including those later excluded from analysis.

---

## Task variables (trial-level)

| Variable | Type | Values / Range | Description |
|----------|------|----------------|-------------|
| `PID` | character | P01–P284 | Anonymised participant ID |
| `agent` | factor | `VOTEURBAN`, `VOTERURAL`, `VOTEALL` | Raw beneficiary condition as presented in the task |
| `benefit` | factor | `INGROUP`, `OUTGROUP`, `EVERYONE` | `agent` recoded relative to partisanship: urban = INGROUP for Democrats, OUTGROUP for Republicans; rural = opposite; VOTEALL = EVERYONE for all |
| `eff` | factor | `easy65`, `hard80`, `hard95` | Required effort level as % of individually calibrated max (65 / 80 / 95%) |
| `rew` | factor | 4, 12, 20 | Credits available for the work option |
| `decision` | numeric | 1 = Work, 0 = Rest, NA = missed | Trial-level choice |
| `success` | numeric | 1 = boxes completed, NA = rest or time-out | Whether the participant met the clicking target when they chose to work |
| `max_boxes` | numeric | ≥ 13 | Individual calibration: highest box-click count across two practice rounds |
| `easy65_nboxes`, `hard80_nboxes`, `hard95_nboxes` | numeric | | Required number of boxes at each effort level for this participant |

---

## Computational model parameters (participant-level)

Fitted in MATLAB using hierarchical MAP estimation. Winning model: **3K1β hyperbolic** — three beneficiary-specific K parameters, one shared inverse-temperature β.

| Variable | Description |
|----------|-------------|
| `k_urban` | Raw K parameter for VOTEURBAN condition (higher = steeper discounting = less motivated) |
| `k_rural` | Raw K parameter for VOTERURAL condition |
| `k_all` | Raw K parameter for VOTEALL condition |
| `k_ingroup` | `k_urban` for Democrats, `k_rural` for Republicans |
| `k_outgroup` | `k_rural` for Democrats, `k_urban` for Republicans |
| `k_everyone` | `k_all` relabelled |
| `k_outgroup_ingroup` | **In-group favouritism index** = K_outgroup − K_ingroup; higher values = stronger partisan bias in effort motivation |
| `k_all_ingroup` | K_all − K_ingroup; how much more steeply participants discount the everyone condition vs. their in-group |
| `k_outgroup_all` | K_outgroup − K_all |
| `k_mean` | Mean of k_all, k_ingroup, k_outgroup; general effort discounting |
| `beta` | Inverse temperature (decision consistency); shared across beneficiaries |

---

## Survey variables (participant-level)

### Partisanship

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `party_preference` | factor | Democrat, Republican | Final partisan classification: self-identified party, or leaning for Independents/Other |
| `party_intensity` | numeric | 0, 1, 2 | 0 = Independent/Other lean; 1 = not very strong partisan; 2 = strong partisan |
| `party_identity_strength` | numeric | z-scored | Single-item partisan identity strength |
| `ideology` | numeric | z-scored | Self-reported political ideology (liberal–conservative) |

### Affective polarisation

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `valence_democrats` / `valence_republicans` | numeric | 0–100 | Favourability ratings toward each party |
| `arousal_democrats` / `arousal_republicans` | numeric | 0–100 | Emotional intensity of feelings toward each party |
| `affpol_weighted` | numeric | z-scored | **Primary affective polarisation measure.** Arousal-weighted spread of valence ratings across parties (Kasper et al., 2025); higher = more polarised |
| `affpol_raw` | numeric | z-scored | Unweighted valence spread (sensitivity check) |

### Cross-partisan attitudes

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `bipartisan_support` | numeric | z-scored | Mean of 2 items (0–100 scale) assessing support for cross-partisan cooperation; higher = more bipartisan |
| `social_polarization` | numeric | z-scored | Variance-based measure of partisan friendship comfort differences; higher = more socially polarised |
| `friends_democrats` / `friends_republicans` | numeric | 0–100 | Comfort with having Democrats / Republicans as close friends |

### Democratic attitudes and civic engagement

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `democratic_support` | numeric | z-scored | 7-item scale (1–5 Likert; 6 items reverse-coded); higher = stronger support for democratic norms |
| `vote_importance` | numeric | z-scored | Single item: perceived importance of voting |
| `vote_election` | factor | Yes, No | Whether the participant voted in the most recent election |
| `political_engagement` | numeric | z-scored | 3-item scale (interest, discussion, follow); higher = more politically engaged |
| `donation_decision` | factor | Donate, Keep | Post-task behavioural measure: chose to donate $0.20 to Vote.org vs. keep as bonus (used as preregistered task validation) |

### Health and wellbeing (Study 1 only)

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `health_general` | numeric | z-scored | Single item: self-rated general health |
| `health_politics` | numeric | z-scored | 10-item scale (1–5 Likert); higher = better perceived health in relation to politics |
| `stress_general` | numeric | z-scored | PSS-10: perceived stress scale (0–4 items; 4 items reverse-coded); higher = greater stress |
| `stress_politics` | numeric | z-scored | Single item: political stress |
| `depression_01`–`depression_08` | numeric | Raw item scores | PHQ-8 depression items (not aggregated in current analyses) |

### Task summaries (participant-level aggregates)

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `work_total` | integer | 0–27 | Total work choices across all 27 trials |
| `work_voteall` | integer | 0–9 | Work choices in VOTEALL condition |
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
| `rururb01` | Rural area, Small town, Suburb, City | Current locality of residence |
| `education` | 6 levels (less than high school → postgraduate) | Highest education level |
| `ethnicity01` / `ethnicity02` | 7 categories | Self-identified ethnicity (up to two selections) |
| `income` | 12 levels ($<10k → $150k+) | Annual household income |

---

## Notes on scoring

- All continuous survey predictors are **z-scored** prior to regression analyses to allow comparison of standardised coefficients across models.
- Affective polarisation (`affpol_weighted`) follows the arousal-weighted spread-of-valence method from Kasper et al. (2025): arousal-weighted mean valence is computed first, then the arousal-weighted spread of valence values around that mean.
- `democratic_support`: items dem_01–03, 05–07 are **reverse-coded** (6 − item) before summing; dem_04 is pro-democratic and scored as-is.
- `health_politics`: all 10 items are negatively worded; the raw sum is reversed (60 − sum) so that higher scores indicate better health.
- `stress_general` (PSS-10): items PSS_04, PSS_05, PSS_07, PSS_08 are reverse-coded (4 − item).
