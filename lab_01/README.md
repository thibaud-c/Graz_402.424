# Exercise Guide: Estimating Population Change 📈 in Styria (1990-2025) with QGIS

## In this exercise you will...

- Data Acquisition: Downloading spatial data from online sources.
- Data Preparation: Loading, reprojecting, and clipping raster and vector data in QGIS.
- Spatial Analysis: Performing raster calculations to determine population change.
- Data Visualization: Creating informative maps to communicate your findings.

Let's get started! 💪


## 1. 💾 Get the Data

We need two main datasets:

- Population Data for 1990 and 2025: We will use the Global Human Settlement Layer (GHSL), a great resource for global population data.
- Border of Styria: We will obtain this from OpenStreetMap (OSM) using Overpass Turbo.

### 1.1. Download Population Data from GHSL

GHSL provides valuable data on human settlements and population. We will download population rasters for the years 1990 and 2025.

**1️⃣ Open your web browser and go to the GHSL data download page**: [here](https://ghsl.jrc.ec.europa.eu/download.php)

**2️⃣ Navigate the GHSL website to find population datasets**.<br> 
Look for datasets that are likely to represent population counts or density. Specifically, we are looking for GHSL Population Grid datasets.

> [!TIP]
> Look for a population layer that corresponds to the years 1990 and 2025. The GHSL datasets are usually available in different versions and resolutions. Choose the datasets that best suit your needs. Explore the website to learn about available data.<br>
> Pay attention to the data description and metadata.

<br>
<details>
   <summary>💡 Are you blocked? ______</summary>
   <br>
   
> Select the GHS-POP layer. Epoch 1990 and 2025. Resolution 3 arc-seconds. Coordinate Reference System: WGS 84. 

</details>
<br>

**3️⃣ Download the Population Rasters**

> [!IMPORTANT]
> Ensure you download the data in a raster format compatible with QGIS, such as GeoTIFF (.tif). 
> Observe the data that you downloaded, read the metadata file if present. Is it what you expected?

<br>
**4️⃣ Organize your files**<br>
Rename the files to something descriptive, like population_1990.tif and population_2025.tif to easily distinguish them.


### 1.2. Download Styria Border from OpenStreetMap

We need the boundary of Styria to clip our population data and focus our analysis on this region. We will use Overpass Turbo, a web-based tool to query and extract data from OpenStreetMap (OSM).

**1️⃣ Open your web browser and go to the Overpass Turbo website**: https://overpass-turbo.eu/

> [!TIP]
> The query language for Overpass Turbo is based on Overpass QL. You can find more information about Overpass QL in the [Overpass API documentation](https://wiki.openstreetmap.org/wiki/Overpass_API/Overpass_QL).

<br>
**2️⃣ Try to identify how to query for the boundary of Styria**<br>
You need first to understand what is the geographical object "boundary of Styria".

> [!TIP]
> Go on OpenStreetMap and search for "Styria". What type of object is it? How is it represented in OSM?

<br>
**3️⃣ Write an Overpass Query to Extract the Styria Boundary**

> [!TIP]
> boundary of styria can be described as a `relation` of `type` `boundary` with a specific `name`. You can filter the relation by its name tag.

<details>
   <summary>💡 Are you blocked? ______</summary>
   <br>

> ```js
> rel[type=boundary]['name:en'='Styria'];
> out geom;
> ```
>
> **🔬 Explanation:**
> - `rel[...]`: This targets relations in OSM, which are used to group multiple elements together. Boundaries are often represented as relations.<br>
> - `type=boundary`: We are specifically looking for relations that are of type "boundary".<br>
> - `'name:en'='Styria'`: We are filtering for boundaries that have the English name "Styria".<br>
> - `out geom;`: This instructs Overpass Turbo to output the geometry of the selected feature.

</details>
<br>

**4️⃣ Run the query and export the boundary data as GeoJSON**
- Examine the result: Overpass Turbo will query OSM and display the boundary of Styria on the map on the right side of the interface.
- Export the data: Click on the "Export" button at the top of the Overpass Turbo interface.
- Choose the output format: Select GeoJSON (.geojson) as the format for exporting the Styria boundary. GeoJSON is a simple and widely compatible vector data format.
- Download the file: Click "Download" and save the file as styria_border.geojson in your "Styria_Population_Change" folder.


## 2. 🧹 Prepare Data in QGIS

Now that we have downloaded all the necessary data, we will prepare it in QGIS for analysis.


### 2.1. Open QGIS and Load Data

**1️⃣ Load the Population Rasters**<br>
Go to `Layer` in the menu bar -> `Add Layer` -> `Add Raster Layer...`

**2️⃣ Load the Styria Border Vector Layer**<br>
Go to `Layer` in the menu bar -> `Add Layer` -> `Add Vector Layer...`

> [!TIP]
> You can also drag and drop the files directly into the QGIS window to load them.


#### 2.2. Reproject Your Layers to EPSG:31256

> [!IMPORTANT]
> To ensure accurate spatial analysis, it's crucial that all layers are in the same Coordinate Reference System (CRS). We will reproject all layers to EPSG:31256 - MGI / Austria GK East. This CRS is suitable for Styria as it is a UTM zone system in meters, which is appropriate for measuring distances and areas in this region of Europe.

**1️⃣ Reproject Population Raster 1990**<br>
In the "Layers" panel, right-click on your population_1990 raster layer.<br>
Go to `Layer CRS` -> `Set Layer CRS...`<br>
In the "Layer CRS Setting" dialog, in the "Filter" box, type 31256.<br>
From the list below, select EPSG:31256 - WGS 84 / UTM zone 33N.<br>
Click "OK".

**🔁 Repeat step 1 for the Population Raster 2025 and the Styria border layer**

> [!IMPORTANT]
> Why Reprojection? Reprojecting ensures that all layers are aligned and calculations are performed using a consistent unit of measurement (meters in this case). If layers have different CRSs, spatial operations like clipping and raster calculations will not be geographically accurate.


### 2.3. Clip Rasters with the Styrian Boundary
Now we will clip both population rasters to the extent of the Styria border. This will extract the population data only for the Styria region, making our analysis focused.

**1️⃣ Open the "Clip Raster by Mask Layer" tool**<br>
- Go to Processing in the menu bar -> `Toolbox` (or press Ctrl+Alt+T). This opens the "Processing Toolbox" panel.
- In the "Processing Toolbox", search for `clip raster by mask layer`. You can type it in the search box.
- Double-click on the Clip Raster by Mask Layer tool to open its dialog.

**2️⃣ Clip Population Raster 1990**<br>
- Input layer: Select your population_1990 raster layer (the reprojected one).
- Mask layer: Select your styria_border vector layer (the reprojected one).
- Source CRS: Make sure it is set to EPSG:31256.
- Target CRS: Make sure it is set to EPSG:31256.
- Assign a specified nodata value to output bands: change its value to -9999. This is important to clip only the area of interest and not the extent of the vector layer.

😱 Troubleshooting: Boundary layer doesn't appear in "Mask layer" dropdown?
> [!TIP]
> Is your boundary layer a polygon? The "Clip Raster by Mask Layer" tool requires a polygon layer as the mask. Sometimes, data from OSM can be downloaded as lines or multipolygons, especially boundary relations.<br><br>
> Check your Styria border layer: In the "Layers" panel, right-click on your styria_border layer, go to Properties, and then to the Information tab. Look for "Geometry type". It should be "Polygon" or "MultiPolygon".<br><br>
> If it's not a Polygon: You need to `Polygonize` your boundary layer.<br>
> Go to Processing -> Toolbox and search for Polygonize.<br>
> Double-click on the Polygonize tool (under Vector geometry).<br>
> Input layer: Select your styria_border layer.<br>
> Field name for polygon attribute: You can leave this empty or choose an attribute field if you want to transfer attributes to the polygon layer.<br>
> Click "Run".<br><br>
> Now, try the "Clip Raster by Mask Layer" tool again, and styria_border_polygon should appear in the "Mask layer" dropdown.

**🔁 Clip Population Raster 2025: Repeat step 1&2, but this time**:


## 3. 😎 Analysis: Calculate Population Difference
Now we will calculate the difference between the population raster of 2025 and 1990 to estimate the population change. We will use the Raster Calculator in QGIS.

**1️⃣ Open the Raster Calculator**<br>
- Search for `raster calculator` in the "Processing Toolbox".
- Double-click on the Raster calculator tool to open its dialog.

**2️⃣ Enter the Raster Calculation Formula**<br>
- In the "Raster calculator" dialog, you will see a section to define the "Raster calculator expression".
- In the "Expression" box, enter the appropriate formula

❓ What would be the formula to calculate the population change between 2025 and 1990 for Styria?

> [!TIP]
> The formula is about identify the change in population between 2025 and 1990. In other words we want to know the net change in population for each pixel in the raster (or how much the population has increased or decreased). You need to subtract the two raster layers.

<details>
   <summary>💡 Are you blocked? ______</summary>
   <br>

> The formula should look like this:<br>
> `"population_2025_styria@1" - "population_1990_styria@1"` <br>
> 
> **🔬 Explanation:**
> - `population_2025_styria@1` refers to the first band (and in this case, the only band) of your clipped population raster for 2025.
> - `population_1990_styria@1` refers to the first band of your clipped population raster for 1990.
> - `-` is the subtraction operator, calculating the difference between the two rasters.

</details>
<br>
The resulting raster represents the population difference between 2025 and 1990 for Styria.


## 4. 🎨 Visualize Population Change
The final step is to visualize the population change raster to understand the spatial patterns of population growth and decline in Styria. We will adjust the symbology of the population_change_1990_2025 raster.

**1️⃣ Open Layer Properties**
In the "Layers" panel, double-click on the population_change_1990_2025 raster layer. This opens the "Layer Properties" dialog.
Go to the "Symbology" tab: In the Layer Properties dialog, click on the "Symbology" tab.

**2️⃣ Configure Symbology**
- Render type: Change the `Render type` dropdown to `Singleband pseudocolor`. This is appropriate for visualizing continuous raster data with a color gradient.
- Interpolation: Set `Interpolation` to `Linear`. This provides a smooth color transition in the visualization.
- Mode: Change `Mode` to "`Quantile`. Quantile classification divides the data into classes containing an equal number of pixels. This is useful for highlighting variations in population change even if the distribution is skewed.
- Classes: Set `Classes` to `3`. We want to categorize the population change into three classes: decline, stable (or inhabited), and growth.
- Color ramp: Choose a divergent color ramp that is suitable for showing change around a central value (zero change). A good option is "Red-White-Green" or similar. You can select this from the "Color ramp" dropdown.
- Adjust Class Breaks and Colors: Manually adjust the middle class break value to 0. Double-click on the "Value" of the second class and enter 0. This sets the boundary between population decline and growth at zero change.

Click "Apply" and "OK" in the Layer Properties dialog to apply the symbology changes and close the dialog.


## 5. 🤔 Interpretation and Further Exploration
Take a moment to examine your map.

- **Observe the spatial patterns**: Where in Styria did population grow the most? Where did it decline? Are there any regional trends?<br>
- **Relate to real-world factors**: Can you think of any reasons for the observed population changes? Consider economic factors, urbanization, rural migration, etc.<br>
- **Consider limitations**: Reflect on the data sources and methods used. What are potential limitations of using GHSL data and raster calculations for this type of analysis? (e.g., resolution of the data, accuracy of population estimates).


## 🔍 Further Exploration:

What about the population in Sri Lanka? Can you repeat the same analysis for Sri Lanka using GHSL data?

> [!TIP]
> Here you'll need an additional step. The boundaries of Sri Lanka are spread across multiple tiles. You will need to merge these tiles to create a single raster layer for Sri Lanka. You can use the `Merge Vector Layers` tool in QGIS to combine the boundary tiles into one layer.


💪 Congratulations! You have completed this exercise! 🎉 