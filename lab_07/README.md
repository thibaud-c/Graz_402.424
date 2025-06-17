# 🚒 From Database to the Web: Fire Risk Mapping


We saw in the previous exercises how to create a PostGIS database with fire risk data. We also learned how to visualize this data using QGIS. In this lab, we will take it a step further by publishing our fire risk zones on the web using pg_tileserv and pg_featureserv.
This will allow us to create interactive web maps and serve our data as vector tiles and features, making it accessible for web applications and GIS clients. 


## 🎯 Objectives 

- Publish a web map with fire risk zones
- Understand back-end data services
- Create a web tileserver and a feature server


## 📚 Resources
- [pg_tileserv](https://access.crunchydata.com/documentation/pg_tileserv/1.0.8/introduction/): A PostGIS tileserver for serving vector tiles
- [pg_featureserv](https://access.crunchydata.com/documentation/pg_featureserv/1.3.1/): A PostGIS featureserver for serving vector features


## 🚀 Quick Start

> [!TIP]
> Check if your postgres database is running in Docker.
> You will need your database connection string to run the services.


### 🏁 Run pg_tileserv

1. Create a config file `pg_tileserv.toml` with the following content:

```toml
# Database connection
DbConnection = "user=YOUR_USER host=YOUR_CONTAINER_IP dbname=YOUR_DB password=YOUR_PASSWORD port=5432"

# Close pooled connections after this interval
DbPoolMaxConnLifeTime = "1h"

# Hold no more than this number of connections in the database pool
DbPoolMaxConns = 4

# Accept connections on this subnet (default accepts on all)
HttpHost = "0.0.0.0"

# Accept connections on this port
HttpPort = 7800
```

2. Run the pg_tileserv Docker container with the configuration file:
```bash
docker run --rm  -p 7800:7800 -v ./pg_tileserv.toml:/opt/pg_tileserv/pg_tileserv.toml pramsey/pg_tileserv:latest --config /opt/pg_tileserv/pg_tileserv.toml
```

> [!NOTE]
> - `run` allows you to run the container name `pramsey/pg_tileserv:latest`.
> - `--rm` removes the container after it stops, keeping your environment clean.
> - `-p 7800:7800` maps port 7800 on your host to port 7800 in the container, allowing you to access the tileserver.
> - `-v` mounts the local configuration file into the container, allowing pg_tileserv to use it.
> - `--config` specifies the path to the configuration file inside the container.

3. Explore the tileserver 

You can access the tileserver by navigating to `http://localhost:7800` in your web browser.

```diff
! 🤔 What layer are present in your service?
! 🤔 How are your spatial features displayed? 
```

> [!TIP]
> To stop the container your can use `Ctrl+C`.

### ✨ Run pg_featureserv

1. Create a config file `pg_featureserv.toml` with the following content:

```toml
[Server]
# Accept connections on this subnet (default accepts on all)
HttpHost = "0.0.0.0"

# Accept connections on this port
HttpPort = 9000

# String to return for Access-Control-Allow-Origin header
# CORSOrigins = "*"

# Maximum duration for reading entire request (in seconds)
ReadTimeoutSec = 1

# Maximum duration for writing response (in seconds)
# Also controls maximum time for processing request
WriteTimeoutSec = 30

[Database]
# Database connection
DbConnection = "postgresql://username:password@host/dbname"

# Hold no more than this number of connections in the database pool
# DbPoolMaxConns = 4

[Paging]
# The default number of features in a response
LimitDefault = 20
# Maxium number of features in a response
LimitMax = 10000

[Website]
# URL for the map view basemap
BasemapUrl = "https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png"
```

2. Run the pg_featureserv Docker container with the configuration file:

```bash
docker run --rm -p 9000:9000 -v ./pg_featureserv.toml:/opt/pg_featureserv/pg_featureserv.toml pramsey/pg_featureserv:latest --config /opt/pg_featureserv/pg_featureserv.toml
```

> [!NOTE]
> `run` allows you to run the container name `pramsey/pg_featureserv:latest`.
> `--rm` removes the container after it stops, keeping your environment clean.
> `-p 9000:9000` maps port 9000 on your host to port 9000 in the container, allowing you to access the featureserver.
> `-v` mounts the local configuration file into the container, allowing pg_featureserv to use it.
> `--config` specifies the path to the configuration file inside the container.

3. Explore the featureserver
You can access the featureserver by navigating to `http://localhost:9000` in your web browser.

```diff
! 🤔 What layer are present in your service?
```

Let's navigate to the `/collections` endpoint to see the available collections (layers) in your featureserver. The you can select the building layer. Click on `view` to see the features in this layer.

```diff
! ⁉️ What is the URL of the featureserver? 
```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ➡️ `http://localhost:9000/collections/public.buildings/items.html`

<br>
</details>


```diff
! 🤔 How many features are displayed on the map? Change the limit to see a change
```

💡 This is a feature server, which means that you can query your database from http queries! So cool 😎 <br>
Let's try this, preciously we created a fire_risk in our building table, let's try to query it.

```diff
! 🤔 How to add a filter to the query? We say this with the apis! 
```   

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```
> http://localhost:9000/collections/public.buildings/items?fire_risk=3'
> ```
>
> Results:
> ```json
> {
>    "type": "FeatureCollection",
>    "features": [
>        {
>            "type": "Feature",
>            "geometry": { ...},
>            "properties": {
>                "access": null,
>                "addr:housename": null,
>                "addr:housenumber": "84",
>                "amenity": null,
>                "building": "house",
>                "fire_risk": 3,
>                "historic": null,
>                "leisure": null,
>                "osm_id": 191457613,
>                "population": 2,
>                "population_id": null,
>                "tourism": null
>            }
>        },
>        {
>            "type": "Feature",
>            "geometry": { ... },
>            "properties": {
>                "access": null,
>                "addr:housename": null,
>                "addr:housenumber": null,
>                "amenity": null,
>                "building": "yes",
>                "fire_risk": 3,
>                "historic": null,
>                "leisure": null,
>                "osm_id": 230248339,
>                "population": 2,
>                "population_id": null,
>                "tourism": null
>            }
>        },
>        {
>            "type": "Feature",
>            "geometry": { ... },
>            "properties": {
>                "access": null,
>                "addr:housename": null,
>                "addr:housenumber": null,
>                "amenity": null,
>                "building": "yes",
>                "fire_risk": 3,
>                "historic": null,
>                "leisure": null,
>                "osm_id": 490587174,
>                "population": 2,
>                "population_id": null,
>                "tourism": null
>            }
>        },
>    ],
>    "numberReturned": 20,
>    "timeStamp": "2025-06-16T12:34:52Z",
>    "links": [
>        {
>            "href": "http://localhost:9000/collections/public.buildings/items",
>            "rel": "self",
>            "type": "application/json",
>            "title": "This document as JSON"
>        },
>        {
>            "href": "http://localhost:9000/collections/public.buildings/items.html",
>            "rel": "alternate",
>            "type": "text/html",
>            "title": "This document as HTML"
>        }
>    ]
> }
>```

<br>
</details>

> [!TIP]
> You can combine multiple filters using `&`. <br>
> Adding `&limit=100` to the query will return up to 100 features. <br>
> You can also use `filter=` to filter features based on SQL expressions.

```diff
! 👀 Observe the http request that you are sending to the server
```

💪 Congratulations! You have completed this exercise! 🎉 
