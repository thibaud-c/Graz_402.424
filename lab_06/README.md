# 🚒 Spatial Database Fundamentals for Fire Risk Mapping

## 🎯 Objectives 

- Assign population points to buildings based on proximity
- Create table for fire stations 
- Create risk zones around buildings based on fire station proximity
- Count population in fire risk zones

## 🚀 Optimizing your queries

```diff
! 🤔 What index could be relevant to create in our table population / buildings / osm?
```

> [!TIP]
> You never want to create an index on a column that is not used in a WHERE clause or JOIN condition. Indexes are used to speed up data retrieval, so they should be created on columns that are frequently queried or filtered. <br>
> Indexes incur a performance cost for INSERT, UPDATE, and DELETE operations, so it's important to balance the need for fast reads with the overhead of maintaining indexes. They also increase the storage requirements of the database, which can be very costly in modern software applications. <br>

💡 Geometries column are often good candidates for indexing, especially when you are performing spatial queries like `ST_Intersects`, `ST_DWithin`, or `ST_Distance`. Ids are also a good idea, especially when you are joining tables or filtering data based on those ids. Furthermore, indexes give access to statistics, which make aggregation queries faster.

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> CREATE INDEX idx_population_geom ON population USING GIST (geometry);
> CREATE INDEX idx_buildings_geom ON buildings USING GIST (geometry);
> CREATE INDEX idx_buildings_osm_id ON buildings USING btree (osm_id);
> CREATE INDEX idx_population_ogc_fid ON population USING btree (ogc_fid);
> ```
>
> [!NOTE]
> The `GIST` index is particularly useful for spatial data, as it allows for efficient querying of geometric shapes and their relationships.
> The `btree` index is used for standard data types and is effective for equality and range queries.

<br>
</details>

## 🌆 Assign Population Points to Buildings

To assign population points to buildings, we will use the `ST_Intersects` function to find which population points fall within the boundaries of buildings. We will also handle cases where population points are not assigned to any building by finding the nearest building.<br>
The approach could include the following steps:
- Create a new column in the population table to store building IDs.
- Update the population table with building IDs based on spatial intersection.
- Handle population points that are not assigned to any building by finding the nearest building.


1. **Create a new column in the population table to store building IDs**:

To create a new column in the `population` table to store the building IDs, we will use the `ALTER TABLE` command. <br>
The new column will be of type `bigint` to accommodate the OSM building IDs from the `buildings` table.

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> -- Create a new column in the population table to store building IDs
> ALTER TABLE population -- specify the table name to modify
> ADD COLUMN building_id bigint; -- specify the new column name and type
> ```

<br>
</details>

2. **Update the population table with building IDs based on spatial intersection**:

To update the `population` table with building IDs based on spatial intersection, we will use the `UPDATE` statement along with the `ST_Within` function. This function checks if the geometries of population points intersect with the geometries of buildings. We will also transform the population geometry to match the coordinate system of the buildings if necessary. <br>
An update query looks like this:

```sql
UPDATE table_name
SET column_name = value
FROM other_table
WHERE condition;
```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> -- Update the population table with building IDs based on spatial intersection
> UPDATE population pop -- specify the table to update with an alias because we will use several tables
> SET building_id = osm_buildings.osm_id -- set the new column to the OSM building ID
> FROM buildings osm_buildings -- specify the table to join with an alias
> WHERE ST_Within(ST_Transform(pop.geometry, 3857), osm_buildings.geometry); -- check if the geometries intersect, transforming the population geometry to match the coordinate system of the buildings
> ```

<br>
</details>

3. **Verify how many population points have been assigned to buildings**:

To verify how many population points have been assigned to buildings, we can use a simple `SELECT` statement with a `COUNT` function. This will give us the total number of population points that have a non-null `building_id`.

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> -- Check how many population points have been assigned to buildings
> SELECT COUNT(pop.building_id) FROM population pop WHERE pop.building_id IS NOT NULL; -- count the number of non-null building IDs in the population table
> ```

<br>
</details>

```diff
! 🤔 How does this result compare with the full population? Are all population point assign to buildings? How can we improve this result?  
```

4. **Handle population points that are not assigned to any building by finding the nearest building**:

To handle population points that are not assigned to any building, we will use a KNN (K-Nearest Neighbors) approach to find the nearest building for each population point that does not have a `building_id`. A KNN query is a type of query that retrieves the nearest neighbors of a given point based on a distance metric. To do this, the `<->` operator can be used to find the nearest neighbor based on distance.<br> 
 
To find the nearest building  for each population point that does not have a `building_id`, we can use a subquery to first identify the population points without a building ID, then join with the buildings table to find the closest building. <br>
To find and update the nearest building for each population point that does not have a `building_id`, we can use a subquery to first identify the population points without a building ID. 
We will also use the `ST_DWithin` function to find buildings within a certain distance (e.g., 50 meters). This will help us to find the nearest building within a reasonable distance. <br>

> [!NOTE]
> A subquery is a query nested inside another query. It can be used to filter results, perform calculations, or retrieve data from another table. In this case, we will use a subquery to find the nearest building for each population point that does not have a `building_id`. <br>

The logic of the query is as follows:
- We want to update the `population` table and set the `building_id` to the nearest building's OSM ID.
- We will use the `ST_DWithin` function to find buildings within a certain distance (e.g., 50 meters) of each population point.
- We will order the results by distance to get the closest building.

To achieve this, we can use the following SQL query:

```sql
UPDATE population AS p -- specify the table to update with an alias
SET    building_id = ( -- set the building_id to the result of the subquery
    SELECT  b.osm_id -- select the OSM ID of the nearest building
    FROM    buildings AS b -- specify the buildings table with an alias
    WHERE   ST_DWithin(ST_Transform(p.geom, 3857), b.geometry, 50) -- check if the population point is within 50 meters of the building
    ORDER BY ST_Transform(p.geom, 3857) <-> b.geometry   -- KNN operator to order by distance
    LIMIT 1 -- limit the result to the nearest building
)
WHERE  p.building_id IS NULL; -- only update population points that do not have a building_id
```

```diff
! 🤔 How many population points have been assigned to buildings now? What can we do to make the results better?
Would making the buffer bigger help?
```

## 🚒 Create Table for Fire Stations

1. **Create a new table for fire stations**:

We want to create a new table for fire stations, which will include the following columns:
- `osm_id`: The unique identifier for the fire station (bigint)
- `name`: The name of the fire station (text) (if available)
- `geometry`: The geometry of the fire stations footprint (geometry)

To create the table, we will use the `CREATE TABLE` statement. This statement will define the structure of the table, including the column names and their data types. We will also set the `osm_id` as the primary key to ensure uniqueness. <br> 
A primary key is a column or a set of columns that uniquely identifies each row in a table. It must contain unique values and cannot contain NULL values. <br>
We will also create a spatial index on the geometry column to optimize spatial queries.

```sql
CREATE TABLE fire_stations (
    id SERIAL PRIMARY KEY, -- auto-incrementing id for the fire station
    osm_id bigint,-- unique identifier for the fire station
    geometry geometry(Polygon, 3857) -- is the coordinate system of your database
);
```
> [!NOTE]
> We don't want to create indexes on the fire stations table yet, as we will insert data. This will lower the performances ... <br>
> We will create the indexes after inserting the data. <br> 

2. **Identify fire stations from OSM data**:

```diff
! 🤔 How can we identify the fire stations from the OSM data?
```

> [!TIP]
> We can explore the OSM data to identify fire stations by looking for specific tags in the `planet_osm_point` and `planet_osm_polygon` tables. <br>
> The `amenity` tag is commonly used to identify fire stations in the `planet_osm_point` table, while the `building` tag can be used in the `planet_osm_polygon` table. <br>

One of the main challenges of osm data is that the same feature can be tagged in different ways, depending on the contributor. For example, a fire station can be tagged as `amenity=fire_station`, or `building=fire_station`. <br> Furthermore, the geometry of the fire station can be represented as a point or a polygon, depending on the data source. <br>

We should explore the `planet_osm_point` and `planet_osm_polygon` tables to identify fire stations. We can use the following SQL queries to find fire stations in both tables:

```sql
-- Query to find fire stations in the planet_osm_point table
SELECT osm_id, name, way AS geometry
FROM planet_osm_point
WHERE amenity = 'fire_station'; -- filter for fire stations
```

```sql
-- Query to find fire stations in the planet_osm_polygon table
SELECT osm_id, name, way AS geometry
FROM planet_osm_polygon
WHERE building = 'fire_station'; -- filter for fire stations
```

Let's also check if the `anemity` column in the `buildings` table is consistent over our dataset. <br>

```sql
SELECT DISTINCT amenity FROM buildings WHERE amenity LIKE '%fire%'; -- check distinct values in the amenity column that contain 'fire'
```

> [!NOTE]
> The `LIKE` operator is used to search for a specified pattern in a column. The `%` wildcard represents zero or more characters, so `'%fire%'` will match any value that contains the word 'fire'. <br>

```diff
! 🤔 Did we explore all the possible option to record a fire station in OSM? 
```

3. ** Standardize the fire_station data **:

To handle this we will try to standardize the data by updating the `amenity` column in the `buildings` table to 'fire_station' where the building type is 'fire_station'. This will help us to have a consistent representation of fire stations in our database. <br>

```diff
! 🤔 How can we do this? 
```

We can update the `amenity` column in the `buildings` table to 'fire_station' where the building type is 'fire_station', we can use the `UPDATE` statement with a `WHERE` clause. This will allow us to filter the rows that need to be updated based on the condition that the building type is 'fire_station'. <br>

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> UPDATE buildings
> SET amenity = 'fire_station' -- Set the amenity column to 'fire_station'
> WHERE building = 'fire_station' -- Only update rows where the building type is 'fire_station'
> AND (amenity IS NULL OR amenity != 'fire_station'); -- Ensure we only update if the amenity is not already set to 'fire_station'
> ```

<br>
</details>

We now have to compare the fire stations from the points and polygons tables, and update the `buildings` table accordingly. We will use a `WITH` clause to create a temporary table that contains the missing fire stations, and then update the `buildings` table with the missing fire stations. <br>

```diff
! 🤔 How can we identify if some fire stations from the the table `planet_osm_point` don't have an entry in the `buildings` table?
```

We can select these points with a subquery that checks if the location of the fire stations in the `planet_osm_point` table is not present in the `buildings` table. We can use a `JOIN` with a spatial function like `ST_DWithin` to find fire stations that are within a certain distance (e.g., 10 meters) of the buildings. We also need to ensure that we only select fire stations that are not already marked as 'fire_station' in the `buildings` table. <br>

> [!TIP]
> the logic of the query is as follows:
> - join the `buildings` table with the `planet_osm_point` table where the selected points have the amenity 'fire_station'
> - use the `ST_DWithin` function to check if the point is within a certain distance (e.g., 10 meters) of a building
> - filter for buildings that are not already marked as fire stations

```diff
! 🤔 How many fire stations are meeting these conditions?
```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> SELECT b.osm_id -- Select the OSM ID of the building you can add , b.way to visualize the geometries
> FROM buildings b -- Specify the buildings table with an alias
> JOIN ( -- create a subquery to collect the needed point geometry
>     SELECT way -- Select the way (geometry) of fire stations from the planet_osm_point table
>     FROM planet_osm_point -- Specify the planet_osm_point table
>     WHERE amenity = 'fire_station' -- Filter for fire stations
>     ) AS fire_station_locations -- Create an alias for the subquery
>   ON ST_DWithin(b.geometry, fire_station_locations.way, 10) -- Check if the building is within 10 meters of a fire station point
> WHERE  b.amenity != 'fire_station' OR b.amenity IS NULL -- filter the buildings to keep only the ones that are not already marked as fire stations
> GROUP BY b.osm_id -- Group by the OSM ID to avoid duplicates
> ```

<br>
</details>

Now we need to update the `buildings` table with the missing fire stations. We can use the `UPDATE` statement with a `FROM` clause to join the `buildings` table with the query we just created to collect the missing stations. This will allow us to set the `amenity` column to 'fire_station' for those buildings that are missing this information. <br>

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> UPDATE buildings
> SET amenity = 'fire_station' -- Set the amenity column to 'fire_station'
> FROM ( -- create a subquery to identify the correct building to update
>   SELECT b.osm_id
>   FROM buildings b
>   JOIN (
>       SELECT way 
>       FROM planet_osm_point 
>       WHERE amenity = 'fire_station'
>       ) AS fire_station_locations
>     ON ST_DWithin(b.geometry, fire_station_locations.way, 10) 
>   WHERE  b.amenity != 'fire_station' OR b.amenity IS NULL
>   GROUP BY b.osm_id
> ) AS missing_stations -- name the subquery
> WHERE buildings.osm_id = missing_stations.osm_id; -- update the identified building by id 
> ```

<br>
</details>


Great! We now can easily identify the fire stations from the table `buildings`!


3. ** Import the fire stations in the `fire_stations` table **:

To import data in an existing table we can use the `INSERT INTO ... SELECT` statement. This allows us to select data from one or more source tables and insert it into the target table. The syntax is as follows:

```sql
INSERT INTO fire_station_table (col1, col2, col3) -- the table name is link to a set of columns to fill, these columns should exist in the table
SELECT col1, col2, col3 -- the columns to select from the source table
FROM source_table -- the source table to select from
WHERE condition; -- optional condition to filter the data
```

```diff
! 🤔 What should the query look like?
```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> INSERT INTO fire_stations (osm_id, geometry) -- specify the columns to insert data into
> SELECT 
>   osm_id, -- select the osm_id from the source table
>   , geometry -- select the geometry from the source table
> FROM buildings -- specify the source table
> WHERE amenity = 'fire_station' -- filter for fire stations
> ```

<br>
</details>

```
! Are the data correctly inserted? What could we do to ensure the data is correctly inserted?
```

To ensure the data is correctly inserted, we can run a `SELECT` query to check the number of rows in the `fire_stations` table and compare it with the number of fire stations in the `planet_osm_point` and `planet_osm_polygon` tables. We can also check for any NULL values in the `osm_id` or `geometry` columns. <br>

```sql
SELECT COUNT(*) FROM fire_stations; -- count the number of rows in the fire_stations table
```

```diff
! 🤔 How many fire stations are in the `fire_stations` table? How does this compare with the number of fire stations in the `planet_osm_point` and `planet_osm_polygon` tables?
```

4. ** Handling duplicates **:

To check if there are duplicates in the `fire_stations` table, we can use the `COUNT` function along with a `GROUP BY` clause to group the rows by the `osm_id` and count the occurrences. If the count is greater than 1 for any `osm_id`, it means there are duplicates. <br>

```sql
SELECT osm_id, COUNT(*) AS count
FROM fire_stations
GROUP BY osm_id
HAVING COUNT(*) > 1; -- filter for duplicates
```

```diff
! 🤔 Do we have duplicate in our data? Why is it the case? 
```

5. ** Create a spatial index for the fire stations table **:

```
! 🤔 What indexes could be useful for our table `fire_stations`? 
```


## 🚒 Create Risk Zones Around Buildings Based on Fire Station Proximity

To create risk zones around buildings based on fire station proximity, we will follow these steps:
1. **Add a fire risk column to the buildings table**: 

We will add a new column to the `buildings` table to store the fire risk level. This column will be of type `int` to represent different risk levels (e.g., 1 for high risk, 2 for medium risk, and 3 for low risk).


<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> ALTER TABLE buildings ADD COLUMN fire_risk INT; -- add a new column to the buildings table
> ```

<br>
</details>


2. **Create buffer zones around fire stations**: 

We will create buffer zones around fire stations to define risk zones. We will use the `ST_Buffer` function to create buffers of different sizes (e.g., 1500 meters, 5000 meters, and 10000 meters). The buffer can be created using the `ST_Buffer` function, which creates a buffer around a geometry. The size of the buffer will determine the risk level assigned to buildings within that zone.

```diff
! 🤔 Are our fire stations and buildings in an appropriate, metric, crs?
```

We will use a CTE (Common Table Expression) to create buffer zones around fire stations. The CTE will select the `osm_id` and the geometry of the fire stations, and create buffers of 1500 meters, 5000 meters, and 10000 meters. We will use the `ST_Buffer` function to create these buffers. <br>

> [!NOTE]
> A CTE is a temporary result set that can be referenced within a `SELECT`, `INSERT`, `UPDATE`, or `DELETE` statement. It is defined using the `WITH` clause and can be used to simplify complex queries or to break down a query into smaller, more manageable parts. <br>


```sql
WITH fire_stations_buf AS (
    SELECT 
        osm_id,
        ST_Buffer(geometry, 1500) AS buffer_1500 -- create a buffer of 1500 meters around fire stations
    FROM fire_stations
)
```

We can then use this CTE in the next step to update the `fire_risk` column in the `buildings` table based on the proximity to fire stations.
A CTE will be not saved between your query, so you have to execute it every time.

3. **Update the buildings table with fire risk levels**: 
We will update the `fire_risk` column in the `buildings` table based on the proximity to fire stations. We will use the `ST_Intersects` function to check if a building is within a buffer zone and assign the appropriate risk level.

```sql
WITH fire_stations_buf AS ( -- create a CTE to define buffer zones around fire stations
    SELECT 
        osm_id,
        ST_Buffer(geometry, 1500) AS buffer_1500,
    FROM fire_stations
)
UPDATE buildings b
SET fire_risk = 1 -- set the fire risk level to 1 for buildings 
FROM fire_stations_buf f
WHERE ST_Intersects(b.geometry, f.buffer_1500) -- check if the building is within the 1500 meter buffer
AND b.fire_risk IS NULL
AND b.population IS NOT NULL;
```

🔁 You can now reproduce the same operation for the other buffers.


4. **Count the population in each risk zone**: 

We will count the total population in each fire risk zone to understand the impact of fire station proximity on the population.

```sql
-- Count population in each risk zone
SELECT 
    fire_risk,
    SUM(population) AS total_population -- sum the population in each risk zone and add an alias to rename the output column
FROM buildings
WHERE fire_risk IS NOT NULL
GROUP BY fire_risk -- group by fire risk level to get the total population in each risk zone
ORDER BY fire_risk;
```

```diff
! 🤔 How many people are in each risk zone? How does this compare with the total population?
```