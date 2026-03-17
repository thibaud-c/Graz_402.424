# Exercise Guide: Municipality‑Level Population Change in Styria

(If you are reading this on VSCode, you can render the markdown using `Ctrl/Cmd+Shift+V`)

## Tender 
**Background & problem statement.** The regional authorities of Styria are concerned about uneven population change across the region. Some municipalities are growing rapidly, others face population decline.  
**Objective.** Identify, classify, and interpret *municipality‑level* population change patterns in Styria 1990-2020 to support the 2027–2033 programming period.

---

## Why this second exercise exists
In the first exercise, you completed the workflow in **QGIS Desktop**. In this follow-up, you will run the **same analytical logic without a GUI**, using command-line tools.

This is **not a different analysis**. It is the **same pipeline**, but made more explicit:
- data collection becomes `curl` + `unzip`
- raster/vector inspection becomes `gdalinfo` + `ogrinfo`
- reprojection/clipping becomes `gdalwarp` + `ogr2ogr`
- raster maths becomes `gdal_calc`
- municipality statistics and field calculations can be run headlessly with `rio zonalstats & ogr2ogr -sql`

> [!TIP]
> QGIS Desktop uses many GDAL-based algorithms in the Processing framework. In the CLI workflow, these operations become more explicit: you choose the command, parameters, and output yourself.
>
> **Helpful links**
> [QGIS GDAL provider](https://docs.qgis.org/latest/en/docs/user_manual/processing_algs/gdal/index.html), all QGIS function linked to GDAL
> [GDAL programs index](https://gdal.org/en/stable/programs/index.html), all GDAL functions


---

## Tools overview

### Docker
We will use Docker to simulate a **server without a GUI**:

- **Image** = a pre-built software environment
- **Container** = one running instance of that environment
- **Bind mount / volume** = a way to persist files outside the container

The goal is **not** to learn Docker in depth. The goal is to understand that a spatial data pipeline also depends on its runtime environment.

> [!TIP]
> **Helpful links**
> - [What is Docker?](https://docs.docker.com/get-started/docker-overview/)
> - [What is an image?](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-an-image/)
> - [Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)


### Ubuntu / Linux file system
Inside the container, you will work in a Linux environment. The top of the hierarchy is `/` (root).

Important directories:
- `/` → root of the file system
- `/home` → home folders for normal users (we will work within this directory)
- `/root` → home folder of the root user
- `/tmp` → temporary files

Useful commands:
- `pwd` → show the current directory
- `ls` → list files
- `cd` → move to another directory
- `mkdir` → create a directory
- `touch` → create an empty file
- `--help` → show help for a command

> [!TIP]
> **Helpful links**
> - [Ubuntu filesystem hierarchy](https://documentation.ubuntu.com/project/how-ubuntu-is-made/concepts/filesystem-hierarchy-standard/)
> - [Ubuntu command line basics](https://documentation.ubuntu.com/desktop/en/latest/tutorial/the-linux-command-line-for-beginners/)

### Data transfer and archives
- `curl` downloads files from the web
- `unzip` extracts ZIP archives

Examples:
```bash
curl -L -o data_raw/file.zip "https://example.org/file.zip" # -L follows redirects, -o outputs to a file
unzip data_raw/file.zip -d data_raw/extracted/ # -d specifies the destination directory
```

### Geospatial command-line tools
- `gdalinfo` → inspect raster metadata
- `ogrinfo` → inspect vector metadata
- `gdalwarp` → reproject, clip, and warp rasters
- `ogr2ogr` → convert and reproject vector data
- `gdal_calc` → raster calculator (CLI)
- `rio zonalstats` → compute zonal statistics from rasters using vector zones

---

# 1) Start your environment using Docker

---

If you have already created your Docker container, start it from your terminal:
```bash
docker start ubuntu-cli
docker exec -it ubuntu-cli bash
```

If not, follow the setup instructions provided in the course Docker folder.
(Make sure that everything is installed correctly)

> [!IMPORTANT]
> - Type `exit` to leave the container
> - Type `docker stop ubuntu-cli` to stop it
> - Type `docker ps -a` to list all containers


## 1.1) Update your environment and install required software

A fresh Ubuntu container is like a new computer: first update the package list, then install the required software.
```bash
apt-get update # Update package list
apt-get upgrade -y # Upgrade all installed packages, the `-y` flag automatically confirms the upgrade
apt-get clean # Clean up package cache
```

> [!NOTE]
> This is a good practice to keep your system up to date and secure.

Let's now install the software we need. The package manager in Ubuntu is `apt`. You can use `apt install <software_name>`  to install any software. In this exercise we will need: 
- `curl`: download files from the web
- `unzip`: extract zip files
- `libgdal-dev gdal-bin python3-gdal`: 3 packages for installing GDAL

> [!TIP]
> If you see `<software_name>: command not found`, that program is not installed.


## 1.2) Create your working environment within ubuntu

Move to your working directory:
```bash
cd /home
```

Create your project structure:

```text
styria_pop_change_cli/
  data_raw/        # downloads, untouched
  data_work/       # intermediate outputs
  output/          # final published layer + csv + brief
  pipeline_contract.md
```

> [!TIP]
> You can use the command `mkdir` to create the folders, and `touch` to create empty files.

> [!IMPORTANT]
> **🧠 Questions**
> - What is the difference between *raw inputs* and *intermediate outputs*?
> - What becomes more visible in the CLI workflow than in the GUI workflow?

---

# 2) Data acquisition

---

Start to explore how `curl` & `unzip` work. Every command has its own help page, which you can access by running the command with the `--help` flag. Before executing every new command, you should use the `--help` flag to understand what the command does and how to use it.

```bash
curl --help
unzip --help
```

## 2.1 Municipality boundaries 

Last week, we saw that all files we download from the internet are hosted in a server as a file. Find the URL of the file and download it using `curl`.
Don't forget that this will be a raw file that should be stored in your `/data_raw` folder. 

> [!TIP]
> **Helpful links**
> - data.gv.at datasets portal: [data.gv.at](https://www.data.gv.at/)
> - [curl](https://everything.curl.dev/cmdline/options/#short-options)
> - [unzip](https://linux.die.net/man/1/unzip)

> [!IMPORTANT]
> **🧠 Questions***
> - What is the file format?
> - What is the advantage of keeping the original archive unchanged in `data_raw/`?
> - Compared with QGIS Desktop, what is more explicit in this step?

### 2.2 Population grid 

Use **GHSL / GHS-POP R2023A** for:
- `t0 = 1990`
- `t1 = 2020`

Download the raster tile(s) covering Styria, using the URL you found. 

> [!IMPORTANT]
> **🧠 Questions**
> - What pattern do you notice in the GHSL URLs?
> - How could that pattern help automate downloads later?
> - What is the advantage of writing the URLs into your pipeline contract instead of just keeping the files locally?

---

# 3) Inspect the data before you process it
 
---

## 3.1 Inspect vector data
Use `ogrinfo` to inspect:
- geometry type
- attribute fields
- layer names
- CRS

Example pattern:
```bash
ogrinfo -so -al <your-layer>.shp # -so = summary only, -al = all layers
```

## 3.2 Inspect raster data
Use `gdalinfo` to inspect:
- raster size / resolution
- extent
- CRS
- NoData value

Example pattern:
```bash
gdalinfo -stats <your-raster>.tif # -stats calculates statistics
```

> [!TIP]
> Using GDAL, command with `ogr` are targeted to vector data, while commands with `gdal` are targeted to raster data.
>
> **Helpful links**
> - [ogrinfo](https://gdal.org/en/stable/programs/ogrinfo.html)
> - [gdalinfo](https://gdal.org/en/stable/programs/gdalinfo.html)

> [!IMPORTANT]
> **🧠 Questions**
> - Which metadata must be checked before two rasters can be compared safely?
> - What is more visible in the CLI metadata output than in the QGIS layer panel?

---

# 4) Prepare data

---

## 4.1 Reproject municipality polygons (vector)

In this exercise, we keep GHSL in its native CRS. Therefore, we reproject the municipality boundaries to **EPSG:4326**. We can also transform our file in GeoJSON at the same time

> [!IMPORTANT]
> **🧠 Questions**
> - What are other vector formats? What are benefits and drawbacks of each?

Use `ogr2ogr` to reproject the municipality polygons to EPSG:4326:
```bash
ogr2ogr -f GeoJSON -s_srs <source_crs> -t_srs EPSG:4326 <output_file.geojson> <your_file>.shp
```
> [!TIP]
> `ogr2ogr` is the main CLI tool for **vector** conversion, filtering, and reprojection.
> 
> Breaking down this command, we have:
> - `-f GeoJSON`: specify the output format as GeoJSON
> - `-s_srs <source_crs>`: specify the source CRS
> - `-t_srs EPSG:4326`: specify the target CRS
> - `<output_file.geojson>`: specify the output file
> - `<your_file>.shp`: specify the input file
>
> **Helpful links**
> - [ogr2ogr](https://gdal.org/en/stable/programs/ogr2ogr.html)


## 4.2 Clip rasters to Styria
Use `gdalwarp` to clip the raster to the municipality layer (or to a dissolved Styrian outline if you created one).

Pattern:
```bash
gdalwarp -cutline <vector_data> -crop_to_cutline -dstnodata 0 <input_raster>.tif <output_raster>.tif # -dstnodata 0 sets the no data value to 0, -cutline clips the raster to the vector data, -crop_to_cutline crops the raster to the extent of the vector data
```

> [!TIP]
> `gdalwarp` is the raster counterpart of `ogr2ogr`. It can reproject, clip, and resample rasters.
> 
> **Helpful links**
> - [gdalwarp](https://gdal.org/en/stable/programs/gdalwarp.html)

> [!IMPORTANT]
> **🧠 Questions**
> - Why is clipping early a good pipeline habit?
> - What does `-dstnodata` change in the output, and why does it matter later?
> - How does this step compare with “Clip raster by mask layer” in QGIS?

> [!NOTE]
> **👾 Hackerman Fun**
> (optional) Visualize your raster data. You can transform your *.tif in *.png and then visualize it with `chafa` directly in your cli.
> ```bash
> apt install chafa 
> gdal_translate -of PNG -ot Byte -scale <rater_file> <filename>.png # transform your raster to a png
> chafa <png_file>
>```
> This is useful for a quick visual check, but it is **not** a replacement for proper spatial validation.


---

# 5) Municipality-level computation

---

## 5.1 Compute municipality totals with zonal statistics

Our tender output is municipality-level, so we need zonal statistics. 

In the GUI exercise, we used **Zonal statistics** in QGIS Desktop.  
In this CLI exercise, we will use **`rio zonalstats`** from the Python geospatial ecosystem because it is available in our setup and works directly on GeoJSON.

### 5.1.1 Install the additional CLI tools
We will install `rasterstats` and `rasterio` inside a Python virtual environment using `uv`.

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh # install uv
uv init ext-lib # initialize uv project 
cd ext-lib
uv venv # create a virtual environement
uv add rasterio rasterstats # add dependencies
source .venv/bin/activate # activate virtual environment
cd .. # go back to your main project directory
```

> [!TIP]
> **Helpful links**
> When you create a new python project you should already have executed these commands
> - [uv](https://docs.astral.sh/uv/)
> - [Rasterio CLI](https://rasterio.readthedocs.io/en/stable/cli.html)
> - [rasterstats CLI](https://github.com/perrygeo/python-rasterstats/blob/master/docs/cli.rst)

Check that the tools are available:
```bash
rio --help
```

> [!IMPORTANT]
> **🧠 Questions**
> - Do you already know these libraries from Python work?
> - What changes when a Python library also exposes a CLI tool?


### 5.1.2 Run zonal statistics
Use `rio zonalstats` directly on your GeoJSON.

A _simple_ pattern is:
```bash
rio zonalstats <geojson_file> -r <raster_layer> --stats <statistic> --prefix "yXX_" | rio zonalstats -r <raster_layer> --stats <statistic> --prefix "yXX_" > <geojson_output>
```

This means:
1. start from the municipality layer
2. add the population sums
3. use that result as input for the other year
4. write a single output file containing both yearly sums

It is a bit complex, let's break that down:
- `rio zonalstats -r <raster_layer>`: computes zonal statistics using the raster layer
- `--stats <statistic>`: specifies the statistic to compute
- `--prefix "yXX_"`: prefixes the output with the year
- `|`: pipes the output to the next command (e.g. the results of the previous command are used as input)
- same operation as above without the `geojson_file`because it the geojson comes from the `|`
- `> <geojson_output>`: redirects the output to a file, here the `>` is very important

> [!IMPORTANT]
> **🧠 Questions**
> - What do you have after this step?
> - Why is it simpler to keep both years in one file than to create two separate files and join them later?
> - How does this compare to the QGIS zonal statistics workflow?

## 5.2 Compute `pct_change` and export a CSV
Now you have a GeoJSON containing municipality attributes plus:
- `y90_sum`
- `y20_sum`

You can inspect the fields with:
```bash
ogrinfo -so -al <geojson_file>
```

To compute the percentage change and export the attribute table to CSV, use `ogr2ogr` with an SQL query.

Example pattern:
```bash
ogr2ogr -f CSV <output_csv_file> <input_file> -sql "SELECT *, (sum2020 - sum1990) / sum1990 * 100 AS pct_change FROM <layer_name>"
```

This command does three things:
1. reads the input vector file
2. computes a new field called `pct_change`
3. exports the result to CSV

> [!TIP]
> Let's try to understand what each part of the command does:
> - `ogr2ogr -f CSV`: converts the input file to a CSV file
> - `<output_file>`: the name of the output file
> - `<input_file>`: the name of the input file
> - `-sql "SELECT *, (sum2020 - sum1990) / sum1990 * 100 AS pct_change FROM <layer_name>"`: the SQL query to execute
> 
> the `SELECT` statement selects the fields to include in the output
> the `*` means all fields, and the `AS pct_change` renames the result of the calculation to `pct_change`
> the `FROM` statement specifies the layer to query

> [!NOTE]
> If you want a final vector layer as well, you can repeat the same `ogr2ogr` logic and export to GeoPackage instead of CSV.

> [!IMPORTANT]
> **🧠 Questions**
> - How does this compare to Field Calculator in QGIS?


---

# 6) Compute raster population difference

---

This will create a visual output, useful for QA and interpretation, and can complete the output from the municipality-level computation.

To do this, we will use `gdal_calc.py` to calculate the difference between the two rasters. 

Important:
- input rasters must have matching dimensions / alignment
- `gdal_calc` does not automatically guarantee projection consistency
- missing values can propagate into the output

Example pattern:
```bash
gdal_calc.py -A <input_raster_1>.tif -B <input_raster_2>.tif --outfile=<output_raster>.tif --calc="A-B"
```

> [!TIP] 
> **Helpful links**
> - [gdal_calc](https://gdal.org/en/stable/programs/gdal_calc.html)

---

# 7) Validation + limitations

---

## 7.1 Validation checklist
Before exporting final outputs, check:
- municipality count is correct
- final layer CRS is what you expect
- no unexplained missing municipality totals
- values look plausible (top / bottom municipalities)
- class counts are not obviously broken

Use `ogrinfo` and `gdalinfo` to inspect outputs and metadata.

## 7.2 Export final outputs
Export your csv file, your tif file (and optionally your geojson file). 

> [!IMPORTANT]
> If you are working inside a bind-mounted folder or Docker volume, your files already persist outside the running shell. You only need `docker cp` if the file lives inside the container and is **not** in a mounted or persistent location.

```sh
docker cp <container_name>:<path_to_file_in_container> <path_to_file_on_host>
```

> [!IMPORTANT]
> **Reflection prompts**
> - Which validation check would you treat as a hard failure?
> - Compared with the GUI exercise, which errors are easier to notice in the CLI workflow?
> - Compared with the GUI exercise, which errors are easier to make in the CLI workflow?

# 8) Peer verification

Compare your results with your classmates.

Discuss:
- municipality count
- CRS
- top / bottom municipalities
- percentage change values
- differences in method

> [!IMPORTANT]
> **Reflection prompts**
> - At which pipeline stage did your results diverge?
> - Was the difference caused by data acquisition, reprojection, clipping, zonal statistics, or calculation?
> - Which part of the CLI workflow felt more transparent than the GUI workflow?

---

## Desktop GIS ↔ CLI GIS: translation table

| Desktop GIS action | CLI equivalent | Why it matters |
|---|---|---|
| Load layer + inspect properties | `gdalinfo`, `ogrinfo` | Metadata becomes explicit |
| Reproject raster | `gdalwarp` | CRS and resampling become explicit choices |
| Reproject vector / Save Features As | `ogr2ogr` | Format, CRS, and schema become explicit |
| Zonal Statistics | `rio zonalstats` | Municipality metrics become reproducible |
| Field Calculator | `ogr2ogr --sql` | Classification logic becomes auditable |
| Raster Calculator | `gdal_calc.py` | Formula and NoData behaviour become explicit |
| Export layer | `ogr2ogr` | Publication becomes scripted, not manual |

---

## Extension
Run the same pipeline for another Austrian state and compare:
- which steps generalise cleanly
- which steps depend on local data structure or naming conventions


**💪 Congratulations! You have completed this exercise! 🎉**

