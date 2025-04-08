# Exercise Guide: Estimating Population Change 📈 in Styria (1990-2025) in a Script

## In this exercise you will... 

- Automate the download of spatial data using command-line tools.
- Create a reproducible workflow for data preparation, analysis, and characterization using GDAL command-line utilities.
- Calculate population change between 1990 and 2025 in Styria using the GDAL raster calculator.


Let's begin! 💪

## 🎯 Goal
In this exercise, you will create a shell script to automate the download and processing of population data for the area of Styria. The script will download population rasters from the Global Human Settlement Layer (GHSL) for 1990 and 2025, reproject the rasters to EPSG:31256, clip the rasters with the border of Styria, calculate the population difference, and characterize the population change.


## Prerequisites
Reuse the Docker container you created in the previous exercise. 

Before starting, ensure you have the following installed on your system:

- softwares of the previous weeks
- vim (or any other text editor)

> [!TIP]
> You can use `apt-get install` in your CLI: `apt-get install vim`

## 1. 🧾 Create a config file to provide the parameters
A configuration file is a file that contains the parameters of your program or script. It allows you to separate the configuration from the code, making it easier to manage and update the parameters, but also it helps to reduce the risk of errors.

We will create a configuration file to store the parameters of the exercise. This file will be used to automate the download and processing of the data.

1️⃣ Create a new file named `config.txt` in your working directory (e.g., `lab_03`) 

> [!TIP]
> You can use `cd` to navigate to the directory where you want to create the file.
> Use the `touch` command followed by the filename to create a new file.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    touch config.txt
    ```
    <br>
</details>


2️⃣ Open the `config.txt` file in a text editor 
We will use `vim` as a text editor. Vim is a highly configurable text editor built to enable efficient text editing. It works as a command-line interface and is available on most Unix-based systems.

> [!TIP]
> Use the `vim` command followed by the filename to open the file in vim.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    vim data/config.txt
    ```
    <br>
</details>


3️⃣ Add parameters to the `config.txt` file
❓ What parameters do we need to automate the download and processing of the data? Remember that these parameters should be configurable and reusable for different areas and years.

> [!TIP]
> In vim you can use the `i` key to enter insert mode and start typing.
> Press `Esc` to exit insert mode.
> Type `:wq!` and press `Enter` to save and exit vim.
> - `:` to enter command mode
> - `w` to write
> - `q` to quit
> - `!` to force

We need a few parameters to automate the download and processing of the data:
- `area`: The area for which we want to estimate population change (e.g., Styria).
- `year_start`: The starting year for the population comparison (e.g., 1990).
- `year_end`: The ending year for the population comparison (e.g., 2025).
- `row`: The row number of the tile to download from GHSL (e.g., 5).
- `column`: The column number of the tile to download from GHSL (e.g., 20).

The config file is easy to read and write. It is a simple text file with key-value pairs. Each line contains a parameter name followed by an equal sign and the parameter value.
Example:
> key1=value1
> key2=value2

You can add comment to your file by starting the line with `#`. Comments are useful to explain the purpose of the parameters or to provide additional information.

Here is what you config file should look like:
```plaintext
# Configuration File for Estimating Population Change in Styria (1990-2025)
# selecting an area, it could be any name that are recognized by Nominatim  
area=styria

# years to compare, GHSL data is available every 5 years from 1975 to 2030
year_start=1990
year_end=2025

# Tile numbers to download from GHSL, the tile is a 1x1 degree grid
row=5
column=20

# Projection for the output data
t_proj=31256
```


4️⃣ Verify the contents of the `config.txt` file using the `cat` command.

> [!TIP]
> Use the `cat` command followed by the filename to display the contents of the file.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    cat config.txt
    ```
    <br>
</details>


## 2. 🤖 Create the Script to Automate the Workflow
Now that we have our configuration file, we will create a script to automate the download and processing of the data.

### 2.1. Create a Shell Script
A shell script is a computer program designed to be run by the Unix shell, a command-line interpreter. It is a text file containing a sequence of commands for a shell to execute. In a script each sequences are run in order, and you can add control structures (e.g., loops, conditions) to automate complex tasks. If an error occurs, the script will stop executing.

1️⃣ Create a new file named `population_change.sh` in your working directory (e.g., `lab_03`)
`*.sh` is the standard extension for shell scripts. 

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    touch population_change.sh
    ```
    <br>
</details>

2️⃣ Open the file with vim and start writing the script.

### 2.2. Add the Script to Automate the Workflow - Part 1
We will write a shell script to automate the download and processing of the population data for the specified area and years. The script will read the parameters from the `config.txt` file and execute the necessary commands using GDAL and wget.

❓ What steps do we need to automate the download and processing of the data? Think about the sequence of commands and tools we need to use.

Let's add and test the following steps in the script:

1️⃣ Add context and comments to the script 
Like before, comments are useful for explaining the purpose of the script and the different sections of the code.
Furthermore, each bash script should start with a shebang `#!/bin/bash` to indicate that the script should be executed using the bash shell.

```bash
#!/bin/bash

# Script to automate the download and processing of population data of an area.
# Please configure the parameters in the config.txt.

echo "Starting Population Change Estimation Script..."
```

> [!NOTE]
> The command `echo` is used to print a message to the terminal. It is useful for debugging and providing feedback to the user. 


2️⃣ Create a working directory and an output directory.
It is cleaner to store the downloaded data in a separate directory. We will create a `data` directory to store the downloaded files and an `output` directory to store the processed data. Also, separating your files into different directories helps to keep your workspace organized, and facilitate the cleanup of temporary files.

```bash
# Create a working and output directory
mkdir -p data
mkdir -p output
```

> [!TIP]
> The `-p` flag is used to create parent directories if they do not exist. It prevents errors if the directories already exist.

3️⃣ Read the configuration file to get the parameters.
We will use the `source` command to read the parameters from the `config.txt` file. This command reads and executes the content of the file in the current shell context. It is a convenient way to load configuration parameters into your script.

```bash
# Read the configuration file
source ./config.txt

echo "Area: ${area}"
echo "Year Start: ${year_start}"
echo "Year End: ${year_end}"
echo "Targeted Projection: ${t_proj}"
```

> [!TIP]
> The `source` command is also known as `.` (dot). You can use `.` instead of `source` to achieve the same result.
> To use a variable in a string, you can enclose the variable name in curly braces `${variable}`. It will be useful to create the URL for the download.


3️⃣ Download Population Data
As last week, we will use `wget` to download the population rasters from GHSL. We need to construct the download URLs based on the parameters in the configuration file.

> [!TIP]
> Use the base URL from last week. Identify and replace the parameters in the URL with the variables from the configuration file.
> You need to download the data in the `data` directory.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    wget "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E${year_start}_GLOBE_R2023A_4326_3ss/V1-0/tiles/GHS_POP_E${year_start}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.zip" -O data/GHS_POP_E${year_start}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.zip
    ```

    **Explanation:**
    - `wget`: Command-line tool for downloading files from the internet.
    - `"URL"`: The URL of the file to download. We use double quotes to enclose the URL.
    - `-O data/filename.zip`: Specifies the output filename and directory for the downloaded file.
    - `${variable}`: The variable name enclosed in curly braces is replaced by the value of the variable.
    <br>
</details>

🔁 Do the same for both of the raster urls. 

4️⃣ Download the Area Border from Nominatim
You need to construct the URL to download the area border from Nominatim.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    wget "https://nominatim.openstreetmap.org/search?q=${area}&format=geojson&polygon_geojson=1" -O data/${area}_border.geojson
    ```
    **Explanation:**
    - `wget`: Command-line tool for downloading files from the internet.
    - `"URL"`: The URL of the file to download. We use double quotes to enclose the URL.
    - `-O data/filename.geojson`: Specifies the output filename and directory for the downloaded file.
    - `${variable}`: The variable name enclosed in curly braces is replaced by the value of the variable.
    ```
    <br>
</details>

5️⃣ Unzip Population Rasters
Add the commands to unzip the population raster files downloaded from GHSL in your script.

> [!TIP]
> Use the `unzip` command followed by the filename of the zip file you want to extract.
> Remember to use the `data` directory and to specify the output directory for the extracted files.
> You can use the `-d` flag to specify the output directory.
> You zip folders contain the same metadata files as last week, you can use the `-o` flag to overwrite the files.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    unzip -o data/GHS_POP_E${year_start}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.zip -d data
    ```
    <br>
</details>

> [!NOTE]
> **Advanced:** You can use a wildcard `*` to extract all the zip files in the `data` directory.
> `unzip -o data/*.zip -d data`

### 2.3. 🧪 Time to test 
Save your changes with `:wq!` and run the script in your terminal.

> [!TIP]
> To run the script, you simply have to type `./script_name.sh` in your terminal.

> [!IMPORTANT]
> 😱 My script does not run. I have the error `Permission denied`
> To run a script in your terminal, you need first to allow the script to be executed. You can use the `chmod` command to change the permissions of the file.

```bash
chmod +x population_change.sh
```

**Explanation:**
- `chmod`: Command to change the permissions of a file.
- `+x`: Adds the executable permission to the file.

Now you can run the script with `./population_change.sh` in your terminal.
If you have some error messages, you need to tackle them, read the error and proof read your code.


## 2.4. 🚀 Add the Rest of the Script - part 2

Now that the first part of the script is working, let's add the rest of the commands to reproject, clip, and calculate the population change.

> [!IMPORTANT]
> Don't forget to comment you script to explain the purpose of each section and each command.

> [!TIP]
> You can comment the lines of your script to avoid downloading the data again. 
> You can use the `#` character at the beginning of a line to comment it. A line that is commented is not seen as a command by the shell, it will be ignored.

1️⃣ Reproject Population Rasters
Add the commands to reproject the population rasters to EPSG:31256.

> [!TIP]
> Use the `gdalwarp` command followed by the source and target SRS, the input raster file, and the output raster file.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    gdalwarp -s_srs EPSG:4326 -t_srs EPSG:${t_proj} data/GHS_POP_E${year_start}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.tif data/population_${year_start}_reprojected.tif
    ```
    <br>
</details>

2️⃣ Reproject Area Border
Add the command to reproject the area border GeoJSON file to EPSG:31256.

> [!TIP]
> Use the `ogr2ogr` command followed by the source and target SRS, the output file, and the input file.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:${t_proj} data/${area}_border_reprojected.geojson data/${area}_border.geojson
    ```
    <br>
</details>

3️⃣ Clip Population Rasters with Area Border
Add the commands to clip the reprojected population rasters with the reprojected area border.

> [!TIP]
> Use the `gdalwarp` command followed by the cutline, the layer name, the input raster file, and the output raster file.
> Remember to use the proper layer name for your geojson layer (filename used for the download without the extension). 

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    gdalwarp -cutline data/${area}_border_reprojected.geojson -cl ${area}_border -dstalpha -crop_to_cutline data/population_${year_start}_reprojected.tif data/population_${year_start}_${area}_clipped.tif
    ```
    <br>
</details>

🔁 Apply the same function on your other raster


4️⃣ Calculate Population Difference
Add the command to calculate the population difference between the two clipped population rasters.

> [!TIP]
> Use the `gdal_calc.py` command followed by the input rasters, the output raster, and the calculation expression.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    gdal_calc.py -A data/population_${year_end}_${area}_clipped.tif -B data/population_${year_start}_${area}_clipped.tif --outfile=output/population_change_${year_start}_${year_end}_${area}.tif --calc="A-B" --format="GTiff"
    ```
    <br>
</details>


5️⃣ Get Raster Statistics
Add the command to get the statistics of the population change raster.

> [!TIP]
> Use the `gdalinfo` command followed by the `-stats` flag and the filename of the raster.
> You need to print the output to the terminal (`echo`).

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    echo gdalinfo -stats output/population_change_${year_start}_${year_end}_${area}.tif
    ```
    <br>
</details>


## 3. 🧪 Test the Script
Save your changes with `:wq!` and run the script in your terminal.
Fix any errors that occur and test the script again.


## 4. 🧹 Clean Up
After running the script, you can clean up the working directory by removing the downloaded files and the temporary files.

> [!TIP]
> Use the `rm` command followed by the filename to remove a file.
> you can remove a directory and its content using the `-r` flag.

<details>
    <summary>💡 Are you blocked? </summary>
    <br>
    ```bash
    rm -r data
    ```
    <br>
</details>


## 5. 📝 Reflect on the Exercise
- How did you find the process of automating the download and processing of spatial data using a shell script?
- What are the advantages of using a shell script for this task?
- What are the limitations of using a shell script for this task?
- Would it be possible to further automate the process?


## 📚 Solution
Check the file `population_change.sh` in the `lab_03` directory for the solution to this exercise.

💪 Congratulations! You have completed this exercise! 🎉 
