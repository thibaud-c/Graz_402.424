# Exercise Guide: Municipality‑Level Population Change in Styria

## Tender 
**Background & problem statement.** The regional authorities of Styria are concerned about uneven population change across the region. Some municipalities are growing rapidly, others face population decline.  
**Objective.** Identify, classify, and interpret *municipality‑level* population change patterns in Styria 1990-2020 to support the 2027–2033 programming period.

---

## What you will deliver
1) **Published results layer**: `pop_diff.tif`,
2) **Ranked table**: `municipality_change.csv` 
3) **Planning brief**: `<500 words`  
- Where are growth/decline zones concentrated, and why?  
- What are the top 3 planning implications for the regional authority?
- Limit and Ethics
4) **Reproducibility package**: `README.md` how to reproduce steps, folder structure, outputs & limits, `pipeline_contract.md` tools and version, data card, parameters, threshold rules, validation.

---

## Tools
- **QGIS Desktop (GUI)**  
- **Processing Toolbox**

---

# 0) Before you start: project structure + “data card”

---

## 0.1 Get the course materials

Clone or download the course materials from the repository.
```sh
git clone <repository-url>
```

You can also update the repository with the latest changes (only after you have cloned it):
```sh
git pull # do a git pull at the beginning of each lecture to get the most recent materials
```

## 0.2 Project structure

Create a folder structure that makes your work auditable.
Within your git local folder, create the following folders/files structured as follows (use the folder of the exercise as root):
```
styria_pop_change/
  data_raw/        # downloaded archives, untouched
  data_work/       # intermediate outputs (clipped rasters, reprojected layers)
  output/          # final published layer + csv + brief
  README.md        
  pipeline_contract.md
```

> [!IMPORTANT]
> **🧠 Questions**
> - What is the difference between *raw inputs* and *intermediate outputs*?

---

# 1) Data acquisition

---

## 1.1 Municipality boundaries (polygon layer)
You need **municipality polygons** (not just a Styrian outline).

**Good starting point:**
- **Styria municipality boundaries from data.gv.at** (Steiermark “Gemeindegrenzen”).

**What you must record (Data Card in your contract)**
- dataset name + provider
- licence/terms
- version / release
- date accessed
- CRS
- etc.

> [!TIP]
> **Helpful links**
> - data.gv.at datasets portal: [data.gv.at](https://www.data.gv.at/)
> - inspire european portal: [inspire-geoportal.ec.europa.eu](https://inspire-geoportal.ec.europa.eu/srv/eng/catalog.search#/home)

> [!IMPORTANT]
> **🧠 Questions**
> - What are two alternative sources of municipality boundaries, and what could go wrong with each?

### 1.2 Population grid 

**GHSL / GHS‑POP R2023A** (100m; estimates 1975–2020 in 5‑year steps; projections to 2025/2030). 
- Identify the correct two epochs (t0, t1) and download the relevant raster tile(s) covering Styria ( **1990** and **2020**)
- Save the download URLs (or stable acquisition path) in your pipeline contract

➡️ Select the GHS-POP layer. Epoch 1990 and 2020. Resolution 3 arc-seconds. Coordinate Reference System: WGS 84.

> [!IMPORTANT]
> **🧠 Questions**
> - Are your two time points comparable (same product family, same resolution, same units)?
> - If one time point is a projection (after 2023): what claim *cannot* be made responsibly?
> - What would happen to reproducibility if the download URL changes?

---

# 2) CRS discipline: Reproject your data in the same CRS 

---

## Choose a CRS strategy you can defend

**Option A (recommended for integrity): Keep rasters in their native CRS**
- Keep GHSL rasters in **EPSG:4326** (avoids resampling the population surface)
- Reproject municipality polygons to **EPSG:4326**

**Option B: Work in a metric Austrian CRS (e.g., [EPSG:31256](https://epsg.io/31256))**
- Reproject both rasters and polygons into a projected CRS
- You must document your raster _resampling_ method (it can change values)
 
> [!TIP] 
> **Helpful QGIS docs**
> - Reproject Vector layers: Processing > Toolbox > Vector > Data Management Tools > Reproject Layer 
>     (or Save Features As…)
> - Reproject Raster Layers (warp): Processing > Toolbox > Raster > Projections > Warp
> - [Layer properties / metadata](https://docs.qgis.org/latest/en/docs/user_manual/managing_data_source/opening_data.html)
> - Discussion of “[Define vs reproject CRS](https://gis.stackexchange.com/questions/477646/)” in QGIS

> [!IMPORTANT]
> **🧠 Questions**
> - When would a metric CRS be necessary (area/distance), and when is it not?
> - If you reproject rasters, which resampling method preserves the meaning of population counts best?

---

# 3) Prepare data in QGIS (Processing Toolbox)

---

## 3.1 Load and inspect
- Load the municipality boundaries and the two population rasters.
- Inspect metadata:
  - CRS
  - pixel size / resolution
  - NoData value (if present)
  - coverage (does it fully cover Styria?)

> [!TIP] 
> **Helpful QGIS docs**
> - [Layer properties / metadata](https://docs.qgis.org/latest/en/docs/user_manual/managing_data_source/opening_data.html)


## 3.2 Clip rasters to Styria
Goal: reduce compute and keep outputs focused.

Use **Clip Raster by Mask Layer** (Processing Toolbox).
- Mask: municipality polygons (or dissolved Styria outline if you create one)
- Set a NoData value (document it)
- Ensure output extent is cropped to cutline

> [!TIP] 
> **Helpful QGIS docs**
> - GDAL raster extraction algorithms (incl. [clip by mask](https://docs.qgis.org/latest/en/docs/user_manual/processing_algs/gdal/rasterextraction.html): 
>
> **😱 Troubleshooting**
> - Your mask layer should be a polygon. You can use the tool `Polygonize`.

> [!WARNING]
> **Checkpoint**
> - Confirm clipped rasters have the expected extent and NoData behaviour.

> [!IMPORTANT]
> **🧠 Questions**
> - Why is “clip early” a pipeline principle?
> - How would an incorrect NoData value contaminate later zonal sums?

---

# 4) Municipality‑level computation (zonal aggregation)

---

## 4.1 Compute municipality totals for each time point
Your output must be municipality‑level, so you need **zonal statistics**.

Use **Zonal statistics** (Processing Toolbox > Raster analysis > zonal statistics).
- Input polygons: municipalities
- Raster: population raster t0
- Statistic: **Sum** (because you want totals per municipality)
- Rename your zonal sum fields to `pop_t0`
- Repeat for raster t1 (use a different prefix)

> [!TIP] 
> **Helpful QGIS docs**
> - QGIS Processing: [Zonal statistics](https://docs.qgis.org/latest/en/docs/user_manual/processing_algs/qgis/rasteranalysis.html#zonal-statistics) (parameters + outputs)

> [!WARNING]
> **Checkpoint**
> - After each run, verify the new fields exist and look plausible for a few municipalities.

> [!IMPORTANT]
> **🧠 Questions**
> - Why is *Sum* more meaningful than *Mean* for municipality population totals?
> - What does zonal stats do at polygon edges where a raster cell is only partially covered?

## 4.2 Compute relative change (%) and 4‑class label
- (optional) Clean the attribute from municipalities 
- Create a new field `pct_change` 
- Calculate `pct_change = ((pop_t1 - pop_t0) / pop_t0) * 100` (using `Field Calculator`)
- Handle **missing values** and **pop_t0 = 0** explicitly (define your rule in the pipeline contract)
- Classify into (you can create a new field `class` for this):
  - 🟢 Strong Growth (> +5%)
  - 🟡 Moderate Growth (0% to +5%)
  - 🟠 Moderate Decline (−5% to 0%)
  - 🔴 Strong Decline (< −5%)

> [!TIP]
> **Helpful QGIS docs**
> - [Field Calculator Tutorial](https://mapscaping.com/beginners-guide-to-the-qgis-field-calculator/): municipality `attribute table` > `Field Calculator`
> - [QGIS expressions](https://docs.qgis.org/latest/en/docs/user_manual/working_with_vector/expression.html)
> - when pop_t0 is `NULL` or `0`, the percentage change calculation will result in an error or incorrect value. Set directly `pct_change` to `NULL`.

> [!IMPORTANT]
> **🧠 Questions**
> - Which municipalities have small baseline populations that make % change volatile?
> - If you moved the thresholds by ±2%, would your “hotspots” change?

---

# 5) Calculate Population Difference in Styria For Exploration

---

Goal: Calculate the difference in population between the 2 pop layers

Use **Raster Calculator** (Processing Toolbox)
- Add the 2 population layers
- Set the `raster calculator expression` (what is the formula to quantify the change?)

> [!TIP] 
> **Helpful QGIS docs**
> - [Raster Calculator](https://docs.qgis.org/3.40/en/docs/user_manual/working_with_raster/raster_analysis.html) (Processing)

> [!IMPORTANT]
> **🧠 Questions**
> - What does a positive value mean in your difference raster, and what does a negative value mean?
> - Does aggregation hide pockets of growth/decline within otherwise ‘stable’ units? 

---

# 6) Validation + limitations

---

## 6.1 Validation checklist

- **Boundary integrity:** expected number of municipalities for Styria
- **CRS consistency:** all layers align
- **Coverage:** no missing zonal stats for municipalities
- **Sanity of totals:** totals are plausible (order of magnitude + spot checks)
- **Range/outliers:** identify and explain extremes (or flag as suspect)

## 6.2 Limitations

- Modelled population surface uncertainty (not census truth)
- MAUP (municipal boundaries structure interpretation)
- Resolution and resampling effects (if you reproject rasters)
- Any projection/estimate semantics (if applicable)

> [!IMPORTANT]
> **🧠 Questions**
> - What is a limitation that would change a planning decision if ignored?
> - Which limitation is *most likely* to be exploited for political narratives?

---

# 7) Communication and data sharing

---

### 7.1 Export final layers

- data layers: `pop_diff.tif` & `municipality_change.csv` 
- files: `README.md`, `pipeline_contract.md`

> [!TIP]
> **Helpful QGIS docs**
> [Export / Save Features As…](https://docs.qgis.org/latest/en/docs/user_manual/managing_data_source/create_layers.html#exporting-layers)

## 7.2 (Optional) Export a map figure
If you produce a map, ensure it is anchored to the tender:
- include legend with your 4 classes
- include a short caption summarising the main pattern + caveats

## 7.3 Planning brief

1) **Headline finding**: where growth/decline concentrates
2) **Evidence**: reference your ranked table + class map; name 3 municipalities
3) **Top 3 implications** (bullet points)
4) **Limitations + ethics** (specific to your data/method)

## 7.4 Peer verification
Goal: ensure your published outputs match your method and are reproducible by someone else.

**Exchange with another pair**
- `pop_diff.tif` & `municipality_change.csv` 
- `pipeline_contract.md` (and/or screenshots of key settings)

**Compare**
- municipality count
- CRS of final layer
- top 5 growth + top 5 decline overlap
- class counts
- min/max `pct_change`

> [!IMPORTANT]
> **🧠 Questions**
> - At which pipeline stage did your results diverge (collect → prepare → analyse → publish)?
> - Did you do something differently? What is the most interesting approach?
> - What did you learn from your classmates that you will implement in your future workflow?


## 🥊 Run the analysis for all of Austria or another Austrian State
> [!IMPORTANT]
> **🧠 Questions**
> - What challenges to expect? 
> - Is your workflow reproducible for other regions?


**💪 Congratulations! You have completed this exercise! 🎉**

