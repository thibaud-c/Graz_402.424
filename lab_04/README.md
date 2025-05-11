# 🚒 Spatial Database Fundamentals for Fire Risk Mapping

## Iconography 
| Icon | Meaning |
|------|---------|
| 💻 | to do in your personal computer |
| 🐧 | to execute in linux container |
| 💽 | linked to your database container |
| 🦫 | to run in DBeaver |
 


## 🎯 Objectives 

- Download population data and OSM data
- Import the data into a PostGIS database
- Explore the data using DBeaver
- Execute SQL queries to visualize the data


## 📚 Prerequisites

- Docker installed
- DBeaver installed
- Pulled PostGIS image

- data from the following sources:
  - [Population data](https://data.humdata.org/dataset/66fa6572-0cf0-493d-8805-02a107169b29/resource/c168bb2f-6350-4d44-8789-3d2d22f5a2eb/download/aut_general_2020_csv.zip)
  - [OSM data](https://download.geofabrik.de/europe/austria-latest.osm.pbf)

> [!TIP]

> 🌍 **OSM data download**
> ```bash
> curl -L "URL" --output austria-latest.osm.pbf # 🐧
> ```
>
> 🌆 **Population data from meta's Data for Good**
> ```bash
> curl -L "URL" --output aut_general_2020_csv.zip # 🐧
> ```
>
>
> 💡 **In both case you can also use...**
> ```bash
> wget "URL"
> ```

> [!NOTE]
> the `-L` flag in `curl` is used to follow redirects. This is useful when the URL you are trying to download from has been moved or redirected to a different location. The `-o` or `--output` flag specifies the output file name.


### Let's begin! 💪

## 🐘 Docker & PostGIS Launch

Using the CLI in your local machine, run the following command to run the PostGIS image and create a container:


```bash
docker run --name postgis-db -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgis/postgis # 💻
```

> [!NOTE]
> - The `--name` flag assigns a name to the container (in this case, `postgis-db`).
> - The `-e` flag sets an environment variable (in this case, the password for the `postgres` user). While working in local, we often use `postgres` as the default password. It is not important since we are not using it as a server published on the Internet (called production). However, in production, you should use a strong password.
> - The `-p` flag maps the container's port 5432 to the host's port 5432. We defined the port here to access the database from our local machine via `localhost`. 5432 is the default port for PostgreSQL.
> - The `-d` flag runs the container in detached mode (in the background).

> [!TIP]
> To check if the container is running, you can use the following command:
> ```bash
> docker ps # 💻
> ```

## 🗺️ Connect DBeaver to your PostGIS container

1. Open DBeaver and create a new connection (💻)
2. Select PostgreSQL as the database type
3. In the connection settings (💽), enter the following details:
   - 
   - **Host**: `localhost`
   - **Port**: `5432`
   - **Database**: `postgres` (or any other database name you want to use)
   - **Username**: `postgres`
   - **Password**: `postgres` (or the password you set when creating the container)
4. Click on the "Test Connection" button to verify that the connection is successful
5. If the connection is successful, click "Finish" to create the connection
6. In the DBeaver database navigator, you should now see your PostGIS database listed under the "Database" section

<br>
<font color="orange">👀 Explore what is already present in the database!</font> 
<br>

## 🌆 Import of the population data within PostgreSQL/PostGIS

### 🔓 Unzip the data

Your population data is in a zip file. You need to unzip it before using it. You should now know how to do it!

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```bash
> unzip aut_general_2020_csv.zip # 🐧
> ```

<br>
</details>
<br>

### 👀 Sneak peek on the population data

The extracted population data is in CSV format, which is a text file that uses commas to separate values. Each line in the file represents a row of data, and each value in the row is separated by a comma. The first line of the file usually contains the column names.

This file is quite big! The `cat` command that we know will print the entire file to the terminal, which can be overwhelming. Instead, we will use the `head` command to see the first few lines of the file.

```bash
head -n 10 aut_general_2020.csv # 🐧
```

> [!NOTE]
> The `-n` option specifies the number of lines to display. In this case, we are displaying the first 10 lines of the file. You can change this number to display more or fewer lines as needed.

<br>
<font color="orange">👀 What columns are present in the population file? What is the geometry? What is the CRS? </font>
<br>

### 🐘 Import the population data into PostGIS

We will use the `ogr2ogr` command to import the population data into the PostGIS database. The `ogr2ogr` command is part of the GDAL library, which is a translator library for raster and vector geospatial data formats. It can read and write various formats, including shapefiles, GeoJSON, KML, and PostGIS.<br>

`ogr2ogr` can upload data directly to a PostgreSQL/PostGIS database. For this, we need to specify the connection string to the database, the input file, and the name of the table to create in the database.<br>

Here is the parameters your will need for your `ogr2ogr` command:
- `-f PostgreSQL`: specifies the output format as PostgreSQL.
- `PG:"host= dbname= user= password="`: specifies the connection string to the PostgreSQL database. 
  - `host`: the hostname or IP address of the PostgreSQL server (e.g., `localhost` or the IP address of the Docker container).
  - `dbname`: the name of the database to connect to (e.g., `postgres`).
  - `user`: the username to connect to the database (e.g., `postgres`).
  - `password`: the password for the user (e.g., `postgres`).
- `file_name_to_upload`: the input file to be imported.
- `-nln `: specifies the name of the table to create in the database.
- `-overwrite`: overwrites the table if it already exists.
<br>
<font color="orange">🤔 What are our database parameters to create the connection string?</font>
<br>

`dbname`, `user`, `password` should be the same as the ones you used to create the container. If you didn't change them, they are `postgres` for all of them, which is the default value.<br>

The `host` parameter is a bit more complex because, we are using Docker. The `host` parameter should be the IP address of the Docker container running PostgreSQL. You can find this IP address by running the following command in your (local) terminal: 

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgis-db # 💻
```

> [!NOTE]
> `postgis-db` is the name of the container we created earlier. If you used a different name, replace it with the correct one.

> [!TIP]
> the connection string to the database will look like this:
> ```bash
> PG:"host=<container_ip> dbname=postgres user=postgres password=postgres" # 💽
> ```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```bash
> ogr2ogr \ # 🐧
>     -f PostgreSQL \
>     PG:"host=<container_ip> dbname=postgres user=postgres password=postgres" \
>     aut_general_2020.csv \  # or the name of your file
>     -nln population \ # or any name you want to give to the table
>     -overwrite
> ```

<br>
</details>
<br>

There process should take a few minutes. You can check the progress in DBeaver by refreshing the database connection (right click on the database ➡️ refresh). Once the import is finished, you should see a new table called `population` in the database navigator. <br>

<font color="grey">(💡 Launch now the import of the OSM data in the background, it will take a while...)</font> <br>

### 🦫 Check the data with simple SQL query

Let's check if the data has been imported correctly. In DBeaver, you can run the following SQL query to see the first 10 rows of the population table:

```sql
SELECT * FROM population LIMIT 10; -- 🦫
```
> [!TIP]
> This is a SQL query that selects all columns (`*`) from the `population` table and limits the result to 10 rows. A SQL query is always formatted with a `SELECT` statement, followed by the columns you want to select, the `FROM` clause to specify the table, and the `LIMIT` clause to limit the number of rows returned.

You can also check the number of rows in the table by running the following SQL query:


```sql
SELECT COUNT(*) FROM population; -- 🦫
```
> [!NOTE]
> The `COUNT(*)` function is an aggregate function and returns the total number of rows in the table. Because `COUNT` returns a single value, you don't need to use the `LIMIT` clause.

<font color="orange">🤔 How many rows did we imported in our database? Is it impressive for the execution time? </font>
Now you understand why we need to use `LIMIT` in our first query. If we had not used it, the query would have returned all rows in the table, which could be a lot of data and take a long time to process!

### 🧹 Tailoring your data

Now that we have imported the population data, we need to check the data types of the columns. 
We you execute a simple SQL query, the result will be displayed in a table format. You can see the column names and their data types in the result set. 

<br>
<font color="orange">🤔 What datatype are present in your columns?</font>
<br>

It seems that the data types are not correct. The `latitude`, `longitude`, and `aut_general_2020` columns should be of type `double precision` instead of `varchar`. We need to create new columns with the correct data types and copy the data from the old columns to the new ones. We often create new columns instead of modifying the existing ones to avoid data loss and keep the original data intact.
We will create three new columns: `pop_2020`, `lat`, and `lon`. 

To do this, we will use the `ALTER TABLE` command to add new columns to the table. The `ALTER TABLE` command is used to modify the structure of an existing table in a database. We will use the `ADD` clause to add new columns to the table.

```sql
ALTER TABLE population
ADD pop_2020 double precision,
ADD lat double precision,
ADD lon double precision; -- 🦫
```
> [!NOTE]
> The `double precision` data type is used to store floating-point numbers with double precision. It is commonly used for storing geographic coordinates (latitude and longitude) and other numerical values that require high precision. <br>
Now we will use the `UPDATE` command to copy the data from the old columns to the new ones. The `UPDATE` command is used to modify existing records in a table. We will use the `SET` clause to specify the new values for the columns.

```sql
UPDATE population
SET pop_2020 = aut_general_2020::double precision,
    lat = latitude::double precision,
    lon = longitude::double precision; -- 🦫
```

> [!NOTE]
> The `::` operator is used to cast a value from one data type to another. In this case, we are casting the values from `varchar` to `double precision`. This is necessary because the original columns are of type `varchar`, and we need to convert them to the correct data type before copying them to the new columns.

<br>
<font color="orange">🤔 Let's check if everything is ok by running a simple SQL query to see the first 10 rows of the population table again. Does everything looks good?</font>
<br>

If everything is ok, we can drop the old columns using the `ALTER TABLE` command with the `DROP COLUMN` clause. The `DROP COLUMN` clause is used to remove one or more columns from a table.

```sql
ALTER TABLE population
DROP COLUMN latitude,
DROP COLUMN longitude,
DROP COLUMN aut_general_2020; -- 🦫
```

Optionally, we can rename the new columns to the original names using the `ALTER TABLE` command with the `RENAME COLUMN` clause. The `RENAME COLUMN` clause is used to change the name of a column in a table.

```sql
ALTER TABLE population
RENAME COLUMN lat TO latitude; -- 🦫
ALTER TABLE population
RENAME COLUMN lon TO longitude; -- 🦫
```

> [!NOTE]
> The `RENAME COLUMN` is limited to one column at a time. You need to execute the command for each column you want to rename.

Our columns are now ready! However, `latitude` and `longitude` are still not in the correct format, both are still only numbers and not considered as a geometry by PostGIS. We need to add a geometry column to the table to store the geographic coordinates as a point. The `geometry` data type is used to store geometric data, such as points, lines, and polygons.
To do this, we should add a new column of type `geometry` to the table. The `geometry` data type is a special data type used in PostGIS to store geometric data. It can store various types of geometric data, including points, lines, and polygons. In this case, we will use it to store the latitude and longitude as a point.

we will use the `ALTER TABLE` command to add a new column called `geometry` to the table. The `geometry` column will be of type `geometry(Point,4326)`, which means it will store points in the WGS 84 coordinate reference system (CRS). We could also imagine to use a CRS that is more suitable for our region, but we will keep it simple for now. 

```sql
ALTER TABLE population
ADD geometry geometry(Point,4326); -- 🦫
```

<font color="orange">🤔 Is the new column created?</font>

Before create the point geometry, we need to check if the `latitude` and `longitude` columns are not null. If they are null, we cannot create a point geometry from them. To do this, we can use the `WHERE` clause in the `SELECT` statement to filter the rows where either `latitude` or `longitude` is null. We can use the `IS NULL` operator to check if a column is null. 

```sql
SELECT * FROM population
WHERE latitude IS NULL OR longitude IS NULL; -- 🦫
```

It seems that everything is alright. Now we will use the `UPDATE` command to set the values of the `geometry` column based on the `latitude` and `longitude` columns. We will use the `ST_SetSRID` and `ST_MakePoint` functions to create a point geometry from the latitude and longitude values.

```sql
UPDATE population pop
SET geometry = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
WHERE longitude IS NOT NULL AND latitude IS NOT NULL; -- 🦫
```

Now we have a geometry created from the latitude and longitude values. We can check if everything is ok by running a simple SQL query to see the first 10 rows of the population table again.

```sql
SELECT * FROM population LIMIT 10; -- 🦫
``` 

In DBeaver, you can visualize the geometry column as a point on a map. You should have a new panel `Spatial` in your result window. <br>
Having 10 points displayed on the map is not very informative. You can use the `TABLESAMPLE` clause to limit the number of rows returned by the query. The `TABLESAMPLE` clause is used to sample a percentage of rows from a table.

```sql  
SELECT * FROM population TABLESAMPLE SYSTEM (1); -- 🦫
```

> [!NOTE]
> The `SYSTEM` method is used to sample rows based on the physical storage of the table. This method is faster than other sampling methods because it does not require scanning the entire table alternatively, you can use the `BERNOULLI` method, which samples rows randomly. The `BERNOULLI` method is slower than the `SYSTEM` method because it requires scanning the entire table to determine which rows to sample.
> The `(1)` specifies the percentage of rows to sample. In this case, we are sampling 1% of the rows in the table. You can adjust this value to sample more or fewer rows as needed.

By default DBeaver will pre-query the data to display the first 200 rows to avoid overloading the system. You can scroll down in the `grid` or `text` panel to load more rows. You can change this default value in the preferences. <br>


<font color="orange">🤔 How the population data looks like? Distribution? Coverage? What should be the next steps? etc. </font>


## 🌍 Import the OSM data

We will use the `osm2pgsql` command to import the OSM data into the PostGIS database. The `osm2pgsql` command is a tool that converts OSM data into a format that can be imported into a PostgreSQL/PostGIS database.
It can read OSM data in various formats, including PBF (Protocolbuffer Binary Format) and XML.

### 🐧 Install osm2pgsql

You can install `osm2pgsql` in your Linux container. You should already know how to do it! 

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> 🐧
> ```bash
> apt-get install osm2pgsql
> ```

<br>
</details>
<br>

> [!TIP]
> If you are facing some issue with the installation, you can try to update and upgrade your system first (🐧):
> ```bash
> sudo apt-get update
> sudo apt-get upgrade
> ```

### 🌐 Import your OSM data

To import the OSM data, we will use the `osm2pgsql` command with the following parameters (see the [documentation](https://osm2pgsql.org/doc/manual.html) for more details):

- `--database`: specifies the name of the database to connect to (e.g., `postgres`)
- `--user`: specifies the username to connect to the database (e.g., `postgres`)
- `--password`: prompts for the password for the user. If you are not using this parameter, the command will try to connect without a password... 
- `--host`: specifies the IP address of the PostgreSQL server (e.g., the same IP address of the Docker container we used for the import of the population)
- `--port`: specifies the port number of the PostgreSQL server (e.g., `5432`)
- `--input-reader`: specifies the input format (e.g., `pbf` for PBF files)
- `--slim`: uses a slim mode for importing data, which reduces memory usage. This will allow to run the import process on your laptop without running out of memory
- `--bbox`: specifies the bounding box for the area to import (e.g., `xmin,ymin,xmax,xmin`). We don't want to import all of OSM data, it will be too heavy. We will only import the data for Styria. 
- `pbf_file_name`: the input file to be imported

> [!TIP]
> If you have some problem during the import you can add the parameter `-C 2048`. The `-C` option specifies the amount of memory to use for caching (in MB). You can adjust this value based on your machine's available memory.

```diff
! 🤔 What method did we learn to get the spatial data about a specific region ?
```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> 🐧
> ```bash
> curl 'https://nominatim.openstreetmap.org/search?q=Steiermark&format=json&limit=1'
> ```
>
> [!TIP]
> You can use `jq` to extract only the bounding box coordinates 
> ```bash
> curl -s 'https://nominatim.openstreetmap.org/search?q=Steiermark&format=json&limit=1' | jq '.[0].boundingbox'
> ```

<br>
</details>
<br>

You can now copy paste the bounding box coordinates in your command to import the OSM data! 

<details>
    <summary>💡 Are you blocked? </summary
<br>

> 🐧
> ```bash
> osm2pgsql \
>     --database postgres \
>     --user postgres \
>     --password \
>     --host <container_ip> \
>     --port 5432 \
>     --input-reader=pbf \
>     --slim \
>     --bbox xmin,ymin,xmax,xmin \ # replace with the bbox you got from the previous command
>     austria-latest.osm.pbf
> ```

<br>
</details>
<br>

The process should take a few minutes (> 10min). You can check the progress in DBeaver by refreshing the database connection (right click on the database ➡️ refresh)


[🏠 Explore the OSM data that you just imported!](color:darkorange)

<br>

💪 Congratulations! You have completed this exercise! 🎉 
