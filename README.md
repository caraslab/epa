# epa (EPsych Analysis) — User Manual

## What it is
**epa** is a MATLAB toolbox for physiology & behavioral data analysis, organized into modules for loading, analysis, plotting, metrics, and UIs. The repository includes packages like `+analysis`, `+load`, `+metric`, `+plot`, `+ui`, `+examples`, plus class folders such as `@Session`, `@Stream`, `@Behavior`, `@DataBrowser`, `@Cluster`, and `@ClusterEditor`. KiloSort/Phy helpers (`kilosort2session.m`, `phy2session.m`) are included.

---

## Install
1. **Clone**  
   `git clone https://github.com/caraslab/epa`
2. **Add to path (MATLAB)**  
   ```matlab
   addpath(genpath('/path/to/epa')); 
   savepath
   ```
3. **Verify**  
   Confirm MATLAB recognizes packages/classes (no compiled deps; MATLAB-only code).

---

## Data organization (recommended)
- Keep each recording **session** in its own folder (raw data + derived outputs).
- Place spike-sorting outputs (e.g., KiloSort/Phy) inside the session folder.
- Maintain a simple metadata file or consistent folder names for subject/date/protocol.

---

## Typical workflows

### A) Electrophysiology (sorted spikes)
1. **Import KiloSort/Phy** → epa session using `kilosort2session.m` or `phy2session.m`.
2. **Create/load a `Session`** to represent the recording/behavior session.
3. **Explore data** with `@DataBrowser`; use `@Cluster` / `@ClusterEditor` for cluster ops.
4. **Compute metrics** in `+metric` (unit quality, rates, PSTHs, receptive-field helpers).
5. **Analyze** via `+analysis` (tuning, responses; see `@ReceptiveField`).
6. **Plot** via `+plot` (rasters, PSTHs, tuning curves, summary figures).

### B) Behavior (EPsych)
1. **Load logs** using `+load` and `@Behavior`.
2. **Link to physiology** with `@Session`/`@Event` to align behavior and unit activity.
3. **Metrics & plots** via `+metric` and `+plot` (performance, RTs, psychometric).

---

## Key components (where to look)
- **Loading/parsing:** `+load` — readers & converters for raw/processed formats.  
- **Session model:** `@Session`, `@Stream`, `@Event`, `@Behavior` — core data & events.  
- **Analysis routines:** `+analysis` — tuning/response analyses; `@ReceptiveField`.  
- **Metrics:** `+metric` — unit quality, rates, trial/behavior metrics.  
- **Plotting:** `+plot` — rasters, PSTHs, tuning & summary plots.  
- **User interfaces:** `+ui`, `@DataBrowser`, `@Cluster`, `@ClusterEditor`.  
- **Examples:** `+examples` — minimal, runnable demos to copy-adapt for your data.  
- **KiloSort/Phy import:** `kilosort2session.m`, `phy2session.m` to build sessions.

---

## Minimal analysis recipe (electrophysiology)
1. Convert sorter output → epa session (`kilosort2session.m` / `phy2session.m`).  
2. Instantiate a `Session` to register spikes, events, metadata.  
3. Align events (`@Event`) and stimulus epochs to spikes (`@Stream`).  
4. Compute metrics in `+metric` (firing rates, ISI, quality).  
5. Run analyses in `+analysis` (e.g., tuning), optionally with `@ReceptiveField`.  
6. Plot with `+plot` (raster, PSTH, tuning heatmaps).


---

## Minimal analysis recipe (behavior)
1. Load logs via `+load` / `@Behavior`.  
2. Extract trials & performance with `+metric`.  
3. Plot psychometric/performance with `+plot`.  
4. Join with physiology via `@Session` + event timestamps.

**Useful MATLAB built-ins:** `readtable`, `datetime`, `groupsummary`, `fitnlm`, `glmfit`.

---

## UI quickstart
Launch `@DataBrowser` to step through units/trials, view rasters/PSTHs, and sanity-check alignment. Use `@Cluster` / `@ClusterEditor` for cluster maintenance.

---

## Examples
Start from `+examples` for working templates covering loading, metric computation, plotting, and receptive-field workflows; adapt paths and file patterns to your dataset.

---

## Notes & tips
- **Pathing:** Put `epa` high in your MATLAB path; avoid shadowing functions with local files of the same name.
- **Batching:** Use `dir`, `cellfun`, and `parfor` (Parallel Computing Toolbox) to scale across sessions.
- **Reproducibility:** Save derived outputs (tables/figures) alongside session folders; record MATLAB release/toolbox versions with `ver`.

---

## Learn more
Browse the repository folders to find modules, classes, and helpers (including KiloSort/Phy converters). Open issues/discussions on the GitHub repo if needed.
