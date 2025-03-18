# Exercise Guide: Estimating Population Change 📈 in Styria (1990-2025) in Command-Line

## In this exercise you will... 

- Data Acquisition (Command-Line): Downloading spatial data from online sources using command-line tools.
- Data Preparation (Command-Line): Reprojecting and clipping raster and vector data using GDAL command-line utilities.
- Spatial Analysis (Command-Line): Performing raster calculations using the GDAL raster calculator.
- Data Characterization (Command-Line): Extracting key statistics to understand population change, in lieu of visual mapping in this command-line setting.

Let's begin! 💪

## Tools
Before starting, ensure you have the following installed on your system:

- Command-Line Interface (CLI) via docker (ubuntu image)
- GDAL (Geospatial Data Abstraction Library): GDAL is a fundamental library for geospatial data processing.  Make sure you have GDAL utilities installed and accessible from your command line (like gdalwarp, gdal_calc.py, ogr2ogr). 
- ogr2ogr: A command-line tool for converting between different geospatial formats. It is part of the GDAL suite.
- gdalwarp: A command-line tool for reprojecting and warping raster datasets. It is part of the GDAL suite.
- gdal_calc: A command-line raster calculator that performs mathematical operations on raster data. It is part of the GDAL suite.
- wget or curl: Command-line tools for downloading files from the internet. These tools are commonly available on Unix-based systems.


## 1. 💾 Get the Data (Command-Line)
We will acquire the same datasets as in the GUI exercise, but now using command-line tools.

- Population Data for 1990 and 2025 (GHSL): We will download these using `wget`.
- Border of Styria (OSM): We will use wget to query [Nominatim](https://nominatim.org/) and download the GeoJSON border.


### 1.1. Download Population Data from GHSL (Command-Line)
Open your command-line interface (from docker).

1️⃣ Create a working directory: Navigate to a suitable location on your system where you want to store the exercise data  (e.g., `home/ubuntu`). Create a new directory named `lab_02`, a subdirectory `data` and navigate into it:

> [!TIP]
> Navigate within your system using the `cd` command
> List the contents of a directory using the `ls` command
> Create a new directory with the `mkdir` command and navigate into it using `cd`.

<details>
   <summary>💡 Are you blocked? </summary>
   <br>

    ```bash
    cd home/ubuntu
    mkdir lab_02 lab_02/data
    cd lab_02/data
    ```

    <br>
</details>

2️⃣ Identify the link to download the raster data from the GHSL website. 
Identify Download URLs: You will need to manually visit the GHSL download page in a web browser: https://ghsl.jrc.ec.europa.eu/download.php and find the direct download links for the GHSL Population Grid datasets for years close to 1990 and 2025.

> [!TIP]
> Use the inspector F12 to open the developer panel and find the download links in the network tab.
> You can also right-click on the tile and copy the link address. 

3️⃣ Use your command-line interface to download the population rasters. 
You can use the command `wget` 

> [!TIP]
> Use the `wget` command followed by the URL of the file you want to download.
> Use the `-O` flag to specify the output filename.
> Use --help to get more information about the `wget` command.

> [!NOTE]
> 😱 `wget: command not found`
> To install a tool in ubuntu you can use `apt-get install` in your CLI: `apt-get install wget` 

<details>
   <summary>💡 Are you blocked? </summary>
   <br>

    ```bash
    wget "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E1990_GLOBE_R2023A_4326_3ss/V1-0/tiles/GHS_POP_E1990_GLOBE_R2023A_4326_3ss_V1_0_R5_C20.zip"
    wget "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2025_GLOBE_R2023A_4326_3ss/V1-0/tiles/GHS_POP_E2025_GLOBE_R2023A_4326_3ss_V1_0_R5_C20.zip"
    ```

    <br>
</details>

> [!NOTE]
> you can also use `curl` instead of `wget` to download the files.

> [!IMPORTANT]
>After running these commands, verify that your files are downloaded and present in your directory.


### 1.2. Download Styria Border from OpenStreetMap (Command-Line)
Overpass Turbo can be cumbersome to use in the command line because the query is URL-encoded. Instead, we will use another tool: [Nominatim](https://nominatim.org/).
Nominatim is a search engine for OpenStreetMap data. We will use it to query the border of Styria and download the GeoJSON file.

1️⃣ Let's explore [the documentation](https://nominatim.org/release-docs/develop/api/Overview/)

❓ Which service should we use to get the border of Styria? What are the options of the service?

2️⃣ Create an url to request the border of Styria.

> [!TIP]
> You need the base URL of the service (or endpoint): `https://nominatim.openstreetmap.org/search?<params>`
> You need to specify the parameters of the request: 
> - Free-form query: `q=Styria`
> - Format of the response: `format=geojson`
> - Include the polygon in the response: `polygon_geojson=1`

> [!NOTE]
> Try to download the file directly, what happen if you don't use the `-O` flag?
> You shouldn't forget to use the `-O` flag to specify the output filename.
> You can also use `mv` to rename the file to `styria_border.geojson`

<details>
   <summary>💡 Are you blocked? </summary>
   <br>

    ```bash
    wget "https://nominatim.openstreetmap.org/search?q=Styria&format=geojson&polygon_geojson=1" -O styria_border.geojson
    ```

    <br>

    _🔬 Explanation:_
    - `wget`: Command-line tool for downloading files from the internet.
    - `"https://nominatim.openstreetmap.org/search?`: Base URL of the Nominatim service.
    - `q=Styria`: Free-form query to search for the border of Styria.
    - `&format=geojson`: Additional parameter to specify the response format as GeoJSON.
    - `&polygon_geojson=1"`: Additional parameter to include the polygon in GeoJSON format.
    - `-O styria_border.geojson`: Specifies the output filename as styria_border.geojson.

    <br>
</details>

> [!IMPORTANT]
> Verify Download: Check that styria_border.geojson is now in your directory.


## 2. Prepare Data (Command-Line)
Now we will use GDAL command-line tools to prepare our data. 
🌐 Visit the [GDAL documentation](https://gdal.org/en/stable/index.html) and try to identitfy which function we would need to prepare our data (reproject and clip) 


### 2.1. unzip Population Rasters (Command-Line)
We will use the [`unzip`](https://manpages.ubuntu.com/manpages/jammy/man1/unzip.1.html) command to extract the population raster files from the downloaded zip archives.

1️⃣ Unzip Population Rasters

> [!TIP]
> Use the `unzip` command followed by the filename of the zip file you want to extract.
> You can list the contents of a zip file using `unzip -l filename.zip`. 

> [!NOTE]
> Test if unzip in installed in your computer by typing `unzip --version` in your CLI.
> If you have an error, you can install unzip using `apt-get install unzip`
> To be noted, your zip files contain the same metadata, you will have to overwrite the files when unzipping the second file.

<details>
   <summary>💡 Are you blocked? </summary
   <br>

    ```bash
    unzip -l GHS_POP_E1990_GLOBE_R2023A_4326_3ss_V1_0_R5_C20.zip
    unzip -l GHS_POP_E2025_GLOBE_R2023A_4326_3ss_V1_0_R5_C20.zip
    unzip GHS_POP_E1990_GLOBE_R2023A_4326_3ss_V1_0_R5_C20.zip
    unzip -o GHS_POP_E2025_GLOBE_R2023A_4326_3ss_V1_0_R5_C20.zip
    ```

    <br>
</details>

> [!TIPS]
> you can use `gdalinfo filename` to get information about the file (e.g., projection, size, etc.)


### 2.2. Reproject Layers to EPSG:31256 (Command-Line)
We will use [`gdalwarp`](https://gdal.org/en/stable/programs/gdalwarp.html#gdalwarp) to reproject both raster and vector layers to EPSG:31256.

1️⃣ Reproject Population Raster 1990

> [!NOTE]
> Test if GDAL in installed in your computer by typing `gdal --version` in your CLI. 
> If you have an error, you can install GDAL using `apt-get install gdal-bin libgdal-dev`

Use the `gdalwarp` command followed by the target SRS, the input raster file, and the output raster file.

> [!TIP]
> The target SRS for EPSG:31256 is `-t_srs EPSG:31256`
> The source SRS for EPSG:4326 is `-s_srs EPSG:4326`

<details>
    <summary>💡 Are you blocked? </summary
    <br>

    ```bash
    gdalwarp -s_srs EPSG:4326 -t_srs EPSG:31256 GHS_POP_E1990_GLOBE_R2023A_4326_3ss_V1_0_R5_C20.tif population_1990_reprojected.tif
    ```

    _🔬 Explanation:_
    - `gdalwarp`: GDAL utility for reprojecting and warping raster datasets.
    - `-s_srs EPSG:4326`: Specifies the source Spatial Reference System (SRS) as EPSG:4326.
    - `-t_srs EPSG:31256`: Specifies the target SRS as EPSG:31256.
    - `GHS_POP_E1990_GLOBE_R2023A_4326_3ss_V1_0_R5_C20.tif`: Input raster file to be reprojected.
    - `population_1990_reprojected.tif`: Output reprojected raster file.

    <br>
</details>

🔁 Repeat the same command for the Population Raster 2025 (🚧 Think about changing filenames)

<br>

2️⃣ Reproject Styria Border Vector Layer
We will use [`ogr2ogr`](https://gdal.org/en/stable/programs/ogr2ogr.html) to reproject the Styria border GeoJSON file to EPSG:31256.
`org2ogr` is a command-line tool for converting between different geospatial formats, focusing on vector data.
This tool is installed by default with GDAL.

Use the `ogr2ogr` command followed by the target SRS, the source SRS, the output file, and the input file. 


> [!TIP]
> `t_srs EPSG:31256` sets the target Spatial Reference System (SRS) to EPSG:31256.
> `-s_srs EPSG:4326` sets the source Spatial Reference System (SRS) to EPSG:4326.
> You can use `ogrinfo filename` to get information about the file (e.g., projection, size, etc.):
> - list the layers in the file with `ogrinfo -al -geom=NO styria.geojson`



<details>
    <summary>💡 Are you blocked? </summary>
    <br>

    ```bash
    ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:31256 styria_border_reprojected.geojson styria_border.geojson
    ```

    <br>
</details>


3️⃣ Verify Reprojection: After running these commands, you should have new files: population_1990_reprojected.tif, population_2025_reprojected.tif, and styria_border_reprojected.geojson. These are the reprojected versions of your data.

> [!TIP]
> Use `ls` to list the files in your directory.
> Use `gdalinfo` to get information about the file (e.g., projection, size, etc.)
> Use `ogrinfo` to get information about the vector file (e.g., projection, size, etc.)


### 2.2. Clip Rasters with Styria Border (Command-Line)
We will use gdalwarp again to clip the reprojected population rasters using the reprojected Styria border.

1️⃣ Clip Population Raster 1990

> [!TIP]
> Use the `gdalwarp` command followed by the cutline, the layer name, the input raster file, and the output raster file.
> The option `--cutline` specifies the vector file to use as the clipping boundary.
> The option `--crop_to_cutline` ensures the output raster extent is exactly the extent of the cutline.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>

    ```bash
    gdalwarp -cutline styria_border_reprojected.geojson -cl styria -dstalpha -crop_to_cutline population_1990_reprojected.tif population_1990_styria_clipped.tif
    ```

    _ 🔬 Explanation_
    - `gdalwarp`: Used for clipping as well as reprojection.
    - `-cutline styria_border_reprojected.geojson`: Specifies the vector file to use as the clipping boundary (the Styria border).
    - `-cl styria_border_reprojected`: Specifies the layer name from the cutline file. In this case, the GeoJSON file usually has the layer name same as the filename (without extension). GDAL tries to guess if not provided. It's good practice to provide it explicitly.
    - `-dstalpha`: Adds an alpha band to the output raster to ensure transparency. It allows to clip the raster exactly to the border. 
    - `-crop_to_cutline`: Ensures the output raster extent is exactly the extent of the cutline.
    - `population_1990_reprojected.tif`: Input raster to be clipped.
    - `population_1990_styria_clipped.tif`: Output clipped raster file.
    
    <br>
</details>


🔁 Repeat the same command for the Population Raster 2025 (🚧 Think about updating filenames)

2️⃣ Verify the clipped areas: 
After running these commands, you should have new files: population_1990_styria_clipped.tif, population_2025_styria_clipped.tif. These are the clipped versions of your population rasters within the Styria border.


## 3. Analysis: Calculate Population Difference (Command-Line)
We will use [`gdal_calc`](https://gdal.org/en/stable/programs/gdal_calc.html), the GDAL raster calculator, to calculate the population difference.

1️⃣ Calculate Raster Difference
Use the `gdal_calc.py` command followed by the input rasters and the calculation expression.

> [!TIP]
> The calculation expression should be in quotes and follow the format: `"A-B"` to subtract raster B from raster A.
> Use the `--format` flag to specify the output format (e.g., GeoTIFF).

<details>
    <summary>💡 Are you blocked? </summary
    <br>

    ```bash
    gdal_calc.py -A population_2025_styria_clipped.tif -B population_1990_styria_clipped.tif --outfile=population_change_1990_2025.tif --calc="A-B" --format="GTiff"
    ```

    _🔬 Explanation:_
    - `gdal_calc.py`: The GDAL raster calculator script (🚧 don't for forget the `.py`).
    - `-A` population_2025_styria_clipped.tif: Assigns the 2025 clipped raster to variable 'A'.
    - `-B` population_1990_styria_clipped.tif: Assigns the 1990 clipped raster to variable 'B'.
    - `--outfile=population_change_1990_2025.tif`: Specifies the output raster filename.
    - `--calc="A-B"`: Defines the raster calculation expression: subtract raster B (1990) from raster A (2025).
    - `--format=GTiff`: Sets the output raster format to GeoTIFF.
    
    <br>
</details>


2️⃣ Verify Calculation
A new raster file population_change_1990_2025.tif will be created, representing the population difference.


## 4. Characterize Population Change (Command-Line)
In a command-line environment, "visualization" in the traditional sense is not directly applicable for raster data output. Instead, we will focus on characterizing the resulting population_change_1990_2025.tif raster using command-line tools to understand the statistical properties of population change.

1️⃣ Get Raster Statistics using gdalinfo
`gdalinfo` is a versatile command-line utility that provides detailed information about raster datasets, including statistics (min, max, mean, standard deviation, etc.).

> [!TIP]
> Use the `gdalinfo` command with the `-stats` flag followed by the raster filename to calculate and display raster statistics.

<details>
    <summary>💡 Are you blocked? </summary
    <br>

    ```bash
    gdalinfo -stats population_change_1990_2025.tif
    ```
    
    <br>
</details>


2️⃣ Look for the `STATISTICS_MINIMUM`, `STATISTICS_MAXIMUM`, and `STATISTICS_MEAN` values. These values are crucial for understanding the population change:
- `STATISTICS_MINIMUM`: Represents the largest population decline observed in any grid cell in Styria between 1990 and 2025.
- `STATISTICS_MAXIMUM`: Represents the largest population growth observed in any grid cell.
- `STATISTICS_MEAN`: Represents the average population change across all grid cells in Styria. A positive mean indicates overall population growth, while a negative mean suggests overall decline.

❓ Do you remember the values of last week exercise? Are they the same?


💪 Congratulations! You have completed this exercise! 🎉 