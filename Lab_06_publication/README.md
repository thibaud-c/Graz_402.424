# Exercise Guide: Everyday Amenities From Collection to Visualization

(If you are reading this on VSCode, you can render the markdown using `Ctrl/Cmd+Shift+V`)

### 📝 Mission Brief
**Objective.** The City Urban Development Unit of Graz wants a quick overview of everyday amenities, but the data is not yet organized in a form that supports querying, summarizing, or publishing. You are the data ingestion and database setup team.
**Your task.** Download Overture places for Graz from the command line, load official district boundaries and places into PostGIS, and inspect the tables so they are ready for analysis.

---

### 📖 From points to indicators

Raw point data does not automatically answer a planning question.

To support the client, we need to transform:
- **points** into **district indicators** (or raw data into information)

---

### 🚀 Workflow to implement

- export your data to PMTiles
- inspect it in an online viewer
- publish it live with pg_tileserv or pg_featureserv


---

# 1) 🧭 Export the view as a PMTiles file

---

## Goal

Export the clean `district` table as a **PMTiles** file.

A PMTiles file is a single web-ready file containing map tiles.  
It is useful when you want to share a layer without running a full GIS server.

In this exercise, we use **GDAL / ogr2ogr** directly.

> [!IMPORTANT]
> Here we want to generate PMTiles from or database, we need to run the following commands on our Ubuntu "server"

**Export from PostGIS to PMTiles**

Create an `output` folder if needed:

```bash
mkdir -p output
```

Then, we can export the table using
Then export the view:

```bash
ogr2ogr \
  -f "PMTiles" output/<file_name>.pmtiles -dsco MINZOOM=9 -dsco MAXZOOM=17 \
  "PG:host=YOUR_HOST port=5432 dbname=YOUR_DATABASE user=YOUR_USER password=YOUR_PASSWORD" \
  -sql "SELECT * FROM <table_to_export>" \
  -nln <layer_name> \
  -t_srs EPSG:3857
```

Replace:

```text
<file_name> -> the name of the output file
YOUR_HOST -> rin in local `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgis-db`
YOUR_DATABASE -> the name of the database
YOUR_USER -> the user of the database
YOUR_PASSWORD -> the password of the database
<table_to_export> -> the name of the table to export
<layer_name> -> the name of the layer in the PMTiles file
```

## What is happening?

```text
PostGIS table → ogr2ogr → PMTiles file
```

- `ogr2ogr` reads the table from PostGIS.
- `-f "PMTiles"` tells GDAL to create a PMTiles file.
- `-dsco MINZOOM=9 -dsco MAXZOOM=17` sets the zoom levels for the PMTiles file (9-17 is a common range for web maps).
- `-t_srs EPSG:3857` prepares the data for web map tiling.

> [!TIP]
> **Helpful links**
> - GDAL ogr2ogr: [https://gdal.org/en/stable/programs/ogr2ogr.html](https://gdal.org/en/stable/programs/ogr2ogr.html)
> - GDAL PMTiles driver: [https://gdal.org/en/stable/drivers/vector/pmtiles.html](https://gdal.org/en/stable/drivers/vector/pmtiles.html)
> - PMTiles specification: [https://protomaps.com/docs/pmtiles](https://protomaps.com/docs/pmtiles)

> [!IMPORTANT]
> **🧠 Questions**
> - What information is included in the PMTiles file?
> - Is a PMTiles file live or static?
> - What happened when you zoom in & zoom out?

---

# 6) 🗺️ Visualize the PMTiles file

---

1. Open the PMTiles viewer:

```text
https://pmtiles.io/
```

2. Copy the file from the Ubuntu _server_ to your local environement

(see lab_02)

3. Drag and drop your file:

```text
output/amenity_screening.pmtiles
```

**Inspect:**

- Does the layer appear?
- Is the map centred correctly?
- Are the attributes visible?
- Are the districts visible?
- Does the layer contain only the fields from the view?

---

# 7) ⚖️ Discuss PMTiles: benefits and drawbacks

---

PMTiles is useful, but it is not always the right publication method.

| PMTiles benefits | PMTiles drawbacks |
|---|---|
| One single file | Not automatically updated when the database changes |
| Easy to share | Needs to be regenerated after changes |
| Good for web maps | Not ideal for complex database queries |
| Does not require a running GIS server | Styling and interaction still need a web map |
| Good for final deliverables | Less suitable for live dashboards |

> [!IMPORTANT]
> **🧠 Questions**
> - When would PMTiles be a good choice?
> - When would PMTiles be a poor choice?
> - What happens if new amenities are added to the database tomorrow?

---

# 8) 🌐 Compare with live PostGIS services

---

PMTiles is a **static export**.

Another option is to serve the database view directly through a web service.

Two lightweight tools are often used with PostGIS:

```text
pg_tileserv
pg_featureserv
```

> [!INFO]
> In this exercise, you are not expected to become a server administrator.  
> The goal is to understand the difference between static files and live services.

**pg_tileserv: vector tiles from PostGIS**

`pg_tileserv` serves vector tiles directly from PostGIS tables or views.

In simple terms:

```text
PostGIS view → pg_tileserv → vector tiles for web maps
```

It is useful when:
- you want a web map to draw the layer,
- the data may change in the database,
- you do not want to manually regenerate PMTiles every time.

> [!IMPORTANT]
> **🧠 Questions**
> - How is `pg_tileserv` different from exporting PMTiles?
> - Why might a live tile service be useful for frequently updated data?
> - What might be more fragile about relying on a running service?

> [!TIP]
> **Helpful links**
> - pg_tileserv: [https://access.crunchydata.com/documentation/pg_tileserv/](https://access.crunchydata.com/documentation/pg_tileserv/)

**pg_featureserv: vector tiles from PostGIS**

`pg_featureserv` serves features from PostGIS tables or views.

In simple terms:

```text
PostGIS view → pg_featureserv → feature API
```

This is useful when:
- you want to request actual features,
- you want to inspect attributes,
- you want data access rather than only map drawing.

> [!IMPORTANT]
> **🧠 Questions**
> - What is the difference between a tile service and a feature service? What other similar services you know?
> - Which one is better for drawing a map quickly?
> - Which one is better if you want to inspect individual records?
> - Why might both be useful in a real spatial data service?

> [!TIP]
> **Helpful links**
> - pg_featureserv: [https://access.crunchydata.com/documentation/pg_featureserv/](https://access.crunchydata.com/documentation/pg_featureserv/)

---

# 9) 🌐 (optional) Let run a pg_tileserv 

---

**(in local) create a config file for pg_tileserv**

1. Create a config file `pg_tileserv.toml` with the following content:

```toml
# Database connection
DbConnection = "host=YOUR_HOST port=5432 dbname=YOUR_DB user=YOUR_USER password=YOUR_PASSWORD"

# Close pooled connections after this interval
DbPoolMaxConnLifeTime = "1h"

# Hold no more than this number of connections in the database pool
DbPoolMaxConns = 4

# Accept connections on this subnet (default accepts on all)
HttpHost = "0.0.0.0"

# Accept connections on this port
HttpPort = 7800
```

Replace:

```text
YOUR_HOST -> run in local `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgis-db`
YOUR_DATABASE -> the name of the database
YOUR_USER -> the user of the database
YOUR_PASSWORD -> the password of the database
```

2. Run the pg_tileserv Docker container with the configuration file:

```bash
docker run --rm \
  -p 7800:7800 \
  -v ./pg_tileserv.toml:/opt/pg_tileserv/pg_tileserv.toml \
  pramsey/pg_tileserv:latest \
  --config /opt/pg_tileserv/pg_tileserv.toml
```

- `run` allows you to run the container name `pramsey/pg_tileserv:latest`
- `--rm` removes the container after it stops, keeping your environment clean
- `-p 7800:7800` maps port 7800 on your host to port 7800 in the container, allowing you to access the tileserver
- `-v` mounts the local configuration file into the container, allowing pg_tileserv to use it
- `--config` specifies the path to the configuration file inside the container

3. Explore the tileserver

- Open your browser and navigate to [`http://localhost:7800`](http://localhost:7800) to see the tileserver interface.
- You should see a list of available layers and tiles.

4. Stop the container

- Press `Ctrl+C` in the terminal to stop the container.

---

# 10) 🧰 Other publication options

---

There are many ways to publish spatial data. The best option depends on the project.

| Option | Useful for | Main limitation |
|---|---|---|
| **PMTiles** | Simple static web map layers | Must be regenerated when data changes |
| **pg_tileserv** | Live vector tiles from PostGIS | Needs a running service |
| **pg_featureserv** | Live feature access from PostGIS | Not mainly for fast map rendering |
| **GeoServer** | Traditional GIS services such as WMS/WFS | More setup and administration |
| **ArcGIS Server / ArcGIS Enterprise** | Enterprise GIS infrastructure | Commercial platform |
| **Mapbox / CARTO / other cloud platforms** | Polished web maps and dashboards | External accounts, platform rules, possible costs |



**💪 Congratulations! You have completed this exercise! 🎉**

