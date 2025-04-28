#!/bin/bash
# Script that automates the download and processing of population data of a defined area. 

####################
## Before started ##

# Please configure the parameters in the config.txt file. #


##################################
## Initialization of the script ##

echo ""
echo "## Starting Population Change Estimation Script... ##"

# Create a working envrioment
mkdir -p data
mkdir -p output

# Read the configuration file
source ./config.txt

echo "Area: ${area}"
echo "Year Start: ${year_start}"
echo "Year End: ${year_end}"
echo "Targeted Projection: ${t_proj}"

# Download Population Data
wget "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E${year_start}_GLOBE_R2023A_4326_3ss/V1-0/tiles/GHS_POP_E${year_start}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.zip" -O data/GHS_POP_E${year_start}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.zip
wget "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E${year_end}_GLOBE_R2023A_4326_3ss/V1-0/tiles/GHS_POP_E${year_end}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.zip" -O data/GHS_POP_E${year_end}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.zip

# Unzip Population Rasters
unzip "data/*.zip" "*.tif" -d data


# Download area border from Nominatim
wget "https://nominatim.openstreetmap.org/search?q=${area}&format=geojson&polygon_geojson=1" -O data/${area}_border.geojson


#####################
## Data Processing ##

echo ""
echo "## Start Processing Data... ##"

# Reproject Area Border
ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:${t_proj} data/${area}_border_reprojected.geojson data/${area}_border.geojson

# Reproject Population Rasters
gdalwarp -s_srs EPSG:4326 -t_srs EPSG:${t_proj} data/GHS_POP_E${year_start}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.tif data/population_${year_start}_reprojected.tif
gdalwarp -s_srs EPSG:4326 -t_srs EPSG:${t_proj} data/GHS_POP_E${year_end}_GLOBE_R2023A_4326_3ss_V1_0_R${row}_C${column}.tif data/population_${year_end}_reprojected.tif

# Clip Population Rasters with Area Border
gdalwarp -cutline data/${area}_border_reprojected.geojson -cl ${area}_border -dstalpha -crop_to_cutline data/population_${year_start}_reprojected.tif data/population_${year_start}_${area}_clipped.tif
gdalwarp -cutline data/${area}_border_reprojected.geojson -cl ${area}_border -dstalpha -crop_to_cutline data/population_${year_end}_reprojected.tif data/population_${year_end}_${area}_clipped.tif

#####################################
## Calculate Population Difference ##

# Calculate Population Difference
gdal_calc.py -A data/population_${year_end}_${area}_clipped.tif -B data/population_${year_start}_${area}_clipped.tif --outfile=output/population_change_${year_start}_${year_end}_${area}.tif --calc="A-B" --format="GTiff"

# Get Raster Statistics
echo ""
echo "## Population Change Statistics: ##"
gdalinfo -stats output/population_change_${year_start}_${year_end}_${area}.tif

# Clean Up
rm -r data

echo "Success!"