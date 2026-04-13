# Exercise Guide: Municipality‑Level Population Change in Styria, From Manual CLI Workflow to a Reusable Shell Script

(If you are reading this on VSCode, you can render the markdown using `Ctrl/Cmd+Shift+V`)

## Tender 
**Background & problem statement.** The regional authorities of Styria are concerned about uneven population change across the region. Some municipalities are growing rapidly, others face population decline.  
**Objective.** Identify, classify, and interpret *municipality‑level* population change patterns in Styria 1990-2020 to support the 2027–2033 programming period.

---

## What changes in this exercise

In this new exercise, we turn the **same workflow** into a **reusable shell script**.
We are moving from:

- **manual CLI execution** → to **scripted CLI execution**
- **one command at a time** → to **a complete, repeatable workflow**
- **hard-coded steps** → to **variables and parameters**

The analytical logic stays the same. The difference is that we will now write the workflow into a `.sh` file and run it as a script.

---

## Deliverables
1. `run_population_change.sh`  
   Your shell script for the full workflow

2. Final outputs:
   - `output/results.geojson`
   - `output/municipality_change.csv`
   - `output/pop_diff.tif` (optional)

---

# 1) Before you start: what is a shell script?

---

A shell script is a plain text file containing a sequence of terminal commands.

Instead of typing commands one by one, you can put them into a file and execute them together.

Example:
```bash
#!/usr/bin/env bash
echo "Hello"
pwd
```

Run it, after making it executable:
```bash
chmod +x test.sh # change mode to make it executable
./test.sh # run the script, here the `./` means "run the file in the current directory"
```

### Try it! 
1. _create a new folder_ in your Ubuntu instance `mkdir <folder_name>`
2. _create a file with_ `touch <file_name>.sh`
3. _open the file_ with `vim <file_name>.sh`
4. add the content from the example above & save it (in vim, press `esc` then `:wq` to save and quit)
5. _make it executable_ with `chmod +x <file_name>.sh`
6. _run it_ with `./<file_name>.sh`

---

## Why script a workflow?
### Benefits
- **Repeatability**: run the same workflow again without retyping everything
- **Fewer typing mistakes**: long commands do not need to be rewritten manually
- **Transparency**: the workflow exists as a file you can read, share, and review
- **Parameterisation**: a few variables can control many commands
- **Documentation**: the script itself becomes a form of method documentation

### Risks
- a script can hide mistakes if you run it blindly
- debugging is harder if the script is too long or badly organised
- hard-coded paths and file names make scripts fragile

> [!IMPORTANT]
> **🧠 Questions**
> - Which mistakes are more likely when typing commands manually?
> - Which mistakes become more dangerous in a script?
> - When would you prefer QGIS Desktop over a script?

---

# 2) Identify the repeated logic

---

In the past weeks, we have already defined the manual CLI workflow clearly: data acquisition, inspection, preparation, municipality-level computation, raster difference, validation.

This week, we will **refactor** that workflow into a script.

## 2.1. Extract all the commands from the old workflow
Write them in a text file using VScode or any text editor on your computer.

## 2.2. Identify the repeated logic

### - Fixed parts
These usually stay the same:
- folder names
- output file naming pattern
- general command structure
- CRS strategy
- validation checks

### - Variable parts
These should become script variables:
- input file names
- URLs
- output directory
- year labels (`1990`, `2020`)
- layer names
- container / host working directory assumptions

> [!IMPORTANT]
> **🧠 Questions**
> - Which parts of your previous workflow were repeated exactly?
> - Which parts should become variables?
> - Which parts are still too messy or ambiguous to automate safely?

---

# 3) Project structure for the scripting exercise
 
---

Add a clear structure to the folder your just created:

```text
styria_pop_diff_sh/
  data_raw/
  data_work/
  output/
  run_population_diff.sh
```

The key new file is:

```text
run_population_diff.sh
```

---

# 4) Script design before writing commands 

---

Before writing the script, answer these questions:

## 4.1 What is the script supposed to do?
Your script should:
1. define variables
2. create folders if needed
3. download / extract data if needed
4. inspect and prepare the data
5. compute municipality statistics
6. compute `% change`
7. export outputs
8. compute the raster difference
9. print useful progress messages

## 4.2 What should the script **not** do?
Do not try to make it:
- universal for all countries
- interactive in ten different ways
- a full software installer
- too clever

For this lab, it is enough that the script works for **this exercise**.

> [!IMPORTANT]
> **Reflection prompt**
> - What is the difference between a script that is *useful* and one that is *over-engineered*?


---

# 5) Start the script file

---

Open the script file with `vim` editor:
```bash
vim run_population_diff.sh
```
(you can also use `nano` if you want to try another editor)

Start with this minimal structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Starting population difference workflow..."
```

## What these lines mean
- `#!/usr/bin/env bash` → run the script with Bash, this is called a shebang
- `set -euo pipefail` → safer script behaviour:
  - stop if a command fails
  - stop if an undefined variable is used
  - fail if part of a pipeline fails

> [!IMPORTANT]
> **Reflection prompts**
> - Why is `set -euo pipefail` useful in a GIS workflow?
> - How is this different from running commands manually in a terminal?


---

# 6) Add variables

---

At the top of the script, define variables instead of repeating literal values.

Example structure:
```bash
#!/usr/bin/env bash
set -euo pipefail

YEAR0=1990
YEAR1=2020

RAW_DIR="data_raw"
WORK_DIR="data_work"
OUT_DIR="output"

BOUNDARY_URL="<paste-boundary-url>" # from data.gov.at
POP0_URL="<paste-ghsl-1990-url>" # use the 30 arcsec version
POP1_URL="<paste-ghsl-2020-url>" # use the 30 arcsec version
```

You may also define:
```bash
BOUNDARY_LAYER="<layer_name>"
BOUNDARY_FILE="<downloaded_boundary_file>"
```

> [!NOTE]
> Usually we add check if all software dependencies are available before running the script, but here we know that we already have them installed in the container.
> If you really want to have the most robust approach, you could use 
> ```bash
> command -v <software_name> >/dev/null 2>&1 || { echo "<software_name> is not installed"; exit 1; }
> ```

> [!IMPORTANT]
> **🧠 Questions**
> - Which values are worth turning into variables?
> - Which values should stay fixed because changing them would break the exercise?
> - Why is it better for a script to fail early?
> - What is the equivalent in QGIS Desktop of checking whether a tool is available?


---

# 7) Refactor the manual workflow into script sections

---

Use comments to break the script into readable sections.

Example structure:
```bash
# 1. Download data
# 2. Extract archives
# 3. Inspect inputs
# 4. Reproject boundaries
# 5. Clip rasters
# 6. Run zonal stats
# 7. Compute pct_change
# 8. Export outputs
# 9. Optional raster difference
```

This mirrors the previous CLI exercise structure.

### Important rule
Do **not** write the whole script at once.

Build it in stages:
1. write one section
2. run the script
3. check the outputs
4. continue

That is how you debug scripts safely.

## Use this as a **structure**, not as a copy-paste solution.

```bash
#!/usr/bin/env bash
set -euo pipefail

YEAR0=1990
YEAR1=2020

RAW_DIR="data_raw"
WORK_DIR="data_work"
OUT_DIR="output"

BOUNDARY_URL="<boundary-url>"
POP0_URL="<ghsl-1990-url>"
POP1_URL="<ghsl-2020-url>"

echo "== Creating folders =="
mkdir -p "$RAW_DIR" "$WORK_DIR" "$OUT_DIR"

echo "== Downloading data =="
# curl commands here

echo "== Extracting data =="
# unzip commands here

echo "== Inspecting inputs =="
# ogrinfo / gdalinfo commands here

echo "== Reprojecting vector data =="
# ogr2ogr command here

echo "== Clipping rasters =="
# gdalwarp commands here

echo "== Running zonal statistics =="
# rio zonalstats commands here

echo "== Computing pct_change and exporting CSV =="
# ogr2ogr -sql command here

echo "== Optional raster difference =="
# gdal_calc.py command here

echo "== Workflow complete =="
```

## Make the script executable and run it

```bash
chmod +x run_population_diff.sh
./run_population_diff.sh
```

> [!IMPORTANT]
> **Reflection prompts**
> - Why is incremental scripting safer than writing the whole script at once?
> - How is this similar to, or different from, building a model (Model Builder) in QGIS?
> - Which errors become harder to isolate once commands are chained together?

---

# 8) Compare three workflow styles

---

You have now used three forms of GIS workflow:

## A) QGIS Desktop
Strengths:
- visual
- easier to explore
- easier for first-time users

Weaknesses:
- steps can stay hidden
- parameters are easier to forget
- reproducibility depends on careful note-taking

## B) Manual CLI
Strengths:
- commands are explicit
- easier to understand data flow
- better for reproducibility than undocumented GUI work

Weaknesses:
- repetitive
- typing errors
- harder to rerun cleanly

## C) Scripted CLI
Strengths:
- repeatable
- shareable
- parameterisable
- closer to real automation

Weaknesses:
- harder to debug if badly structured
- easier to trust blindly
- requires discipline in writing readable code

> [!IMPORTANT]
> **Reflection prompts**
> - Which workflow felt most transparent?
> - Which workflow felt fastest?
> - Which workflow would you trust most for a production pipeline?
> - Which workflow is best for learning, and which is best for delivering?

---

# 8) Optional improvement: make the script more reusable

---

If you finish early, improve your script by adding:
- clearer variable names
- comments using `#`
- a usage message
- automatic skipping of downloads if the file already exists using `if` statements
- clearer output file names

You may also start introducing arguments, but this is optional for this lab: have a look at this [article](https://www.redhat.com/en/blog/arguments-options-bash-scripts).

---

## Peer verification

---

Exchange scripts with another pair.

Compare:
- structure
- variable choices
- comments
- output logic
- validation logic

Discuss:
- what your script makes explicit
- what your script still hides
- what one team’s script does better than the other

> [!IMPORTANT]
> **Reflection prompts**
> - Did your script and your peer’s script produce the same outputs?
> - If not, at which section did they diverge?
> - Which script would be easier for a third person to understand?


**💪 Congratulations! You have completed this exercise! 🎉**

