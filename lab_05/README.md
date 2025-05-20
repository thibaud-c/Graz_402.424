# 🚒 Spatial Database Fundamentals for Fire Risk Mapping

## Iconography 
| Icon | Meaning |
|------|---------|
| 💻 | to do in your personal computer |
| 🐧 | to execute in linux container |
| 💽 | linked to your database container |
| 🦫 | to run in DBeaver |
 


## 🎯 Objectives 

- Understand the structure of OpenStreetMap (OSM) data
- Clean and prepare OSM data for spatial analysis
- Create table for buildings and fire stations
- Create spatial relationships between population data and OSM features

## 🚀 Optimizing your queries

When working with large datasets, it is important to optimize your queries to improve performance. This can be done by using indexes, filtering data, and using spatial functions. <br>
Last week we counted the number of points in our population data, which took a long time.

```sql
SELECT COUNT(*) FROM population; -- 🦫
```

This query counts the number of rows in the `population` table, which can be slow if the table is large. <br>
To speed up this query, we can create an index on the `pop_2020` column, which is used in the `population` table. An index is a data structure that improves the speed of data retrieval operations on a database table at the cost of additional space and slower writes.

```sql
CREATE INDEX pop_2020_idx -- 🦫 name of the index
ON population -- on the population table 
USING btree (pop_2020); -- using a B-tree index on the latitude column
```

Now, when we run the query again, it will be much faster because the database can use the index to quickly find the rows that match the query.

```sql
SELECT COUNT(*) FROM population; -- 🦫
```

```diff
! 🤔 What is the speed difference between your two queries?  
```

The speed difference can be significant, especially for large datasets. The first query without an index may take several seconds or even minutes to execute, while the second query with the index can execute in milliseconds.

> [!NOTE]
> You can use the `EXPLAIN ANALYZE` command to see how the database executes a query and how long it takes. This can help you identify performance bottlenecks and optimize your queries further.
> Let's try it out!
>
>```sql 
> EXPLAIN ANALYZE SELECT COUNT(Latitude) FROM population; -- 🦫 not using the index because the index has been created only on the column latitude
> EXPLAIN ANALYZE SELECT COUNT(pop_2020) FROM population; -- 🦫 using the index that we created
> ```

> [!TIP]
> There are many index types available in PostGIS, such as B-tree, GiST, SP-GiST, GIN, and BRIN. Each index type has its own advantages and disadvantages, so it is important to choose the right one for your use case. <br>
> We will not go into details about the different index types, but you can find more information in the [PostgreSQL documentation](https://www.postgresql.org/docs/current/indexes-types.html). 
> For the needs of this course, we will use the `GiST` index for geometries and B-tree for all other datatypes. This is already a good way to start optimizing your queries!


## 🚦 Filtering your population data 

We imported the OSM data from the extend of Styria into our PostGIS database and it seems that we imported the population data from the extend of Austria. It is a lot of data! 

```diff
! 🤔 What can we do to reduce our the amount of data? What data do we need to do our analysis? 
! Why do we want to reduce the amount of data? 
```

1. Let's start by getting the geometry from Styria!

We would like to filter the data to only include the region of Styria (Steiermark). We can do this by clipping the population data and OSM data to the geometry of Styria.

```diff
! 🤔 How can we find the geometry Styria?
```

> [!TIP]
> We already know the methods using Overpass or Nominatim to get the geometry of a region.
> But, both methods are based on the OSM data, so we can use the OSM data we already have in our database to get the geometry of Styria! 

We can try to find the geometry of Styria in the `planet_osm_polygon` table, which contains polygon data from OSM, including administrative boundaries, buildings, and other land use types. We are looking for the administrative boundary of Styria

```sql
SELECT * -- 🦫 select all columns
FROM planet_osm_polygon -- from the OSM polygon table
WHERE name = 'Steiermark'; -- where the name is 'Steiermark'
```

> [!NOTE]
> Using `WHERE name = 'Steiermark'` filters the results to only include the polygon that have the value `Steiermark` in their `name` column.


2. Now we can use this geometry to filter the population data.

The geometry of Styria is stored in a different table than the population data, so we need to use a spatial function to link the population points with the polygon of Styria.

> [!TIP]
> The Keyword `JOIN ... ON ...` is used to combine rows from two or more tables based on a related column between them. <br>
> In this case, we can use the `ST_WITHIN` function to check if the population points are within the polygon of Styria.

```sql
SELECT * -- 🦫 select all columns
FROM population pop -- from the population table
JOIN planet_osm_polygon osm -- join with the OSM polygon table
    ON ST_WITHIN(pop.geometry, osm.way) -- where the population points are within the polygon
WHERE osm.name = 'Steiermark'; -- filter the results to only include the polygon of Styria
```

> [!NOTE]
> The `JOIN ... ON ...` clause combines the population data with the OSM polygon data based on the spatial relationship defined by `ST_WITHIN`.
> The `ST_WITHIN` function checks if the first geometry (population points) is completely within the second geometry (polygon of Styria). 
> The `WHERE` clause filters the results to only include the polygon with the name 'Steiermark'. This is very powerful because using the where clause we can filter the data based on any attribute of the polygon, not just the name. In this case, we select first only the polygon of Styria in the `planet_osm_polygon` table, and then we use this polygon to join AND filter the population data!

```diff
! 🤔 What is the result of this query? What could have gone wrong? 
```

> [!TIP]
> Observe the geometry column of your data. 

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> It is in EPSG:4326 (WGS 84) coordinate system, while the `planet_osm_polygon` table is in EPSG:3857 (Web Mercator).
> 💡 We need to reproject our data to make it work!

<br>
</details>

In SQL, the reprojection of geometries is done using the `ST_Transform` function. You can use it on the fly to transform the geometry from one coordinate system to another, or you can create a new column in your table to store the transformed geometry.

```sql
... ST_Transform(geometry, EPSG_CODE) ...; -- the EPSG code is called SRID code in SQL
```

```diff
! 🤔 How to use `ST_TRANSFORM` to make our query work?
```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> SELECT * -- 🦫 select all columns
> FROM population pop -- from the population table
> JOIN planet_osm_polygon osm -- join with the OSM polygon table 
>   ON ST_WITHIN(ST_Transform(pop.geometry, 3857), osm.way) -- where the population points are within the polygon
> WHERE osm.name = 'Steiermark'; -- filter the results to only include the polygon of Styria
> ```


<br>
</details>

```diff
! 🤔 If the operation is too long, what can we do to improve the performance of this query? 
```

3. Let's keep only the population data from Styria.

Until now we have only selected the population data that is within the polygon of Styria. Now we want to delete all the population data that is not within the polygon of Styria. <br>
To delete records in SQL, we can use the `DELETE` statement. We will use a `USING` clause to specify the table we want to join with, and a `WHERE` clause to filter the records we want to delete. <br>
DELETE statement can be dangerous, so it is always a good idea to test your query first with a `SELECT` statement to see which records will be deleted. (it is what we did in the previous step!)

```sql
DELETE FROM population pop -- 🦫 delete from the population table
USING planet_osm_polygon osm -- using the OSM polygon table, this is like a join
WHERE ...;
```

> [!IMPORTANT]
> Don't forget to use a where clause to filter the records you want to delete, otherwise you will delete all records in the table!

```diff
! 🤔 What is the where clause we need to use here? What is the opposite of our select query? 
```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> DELETE FROM population pop -- 🦫
> FROM population pop -- from the population table
> USING planet_osm_polygon osm -- using the OSM polygon table, this is like a join
> WHERE NOT ST_WITHIN(ST_Transform(pop.geometry, 3857), osm.way) -- where the population points are not within the polygon
> AND osm.name = 'Steiermark'; -- filter the results to only include the polygon of Styria
> ```

<br>
</details>

```diff
! 🤔 How many records are left in the population table? What is the total population of Styria? 
```

> [!NOTE]
> Other concept to further optimize your query. The geometry of Styria is quite complex, it is possible to simplify it to improve the performance of the query, with `ST_Simplify` function. However, the accuracy of the geometry will be reduced, so it might not be suitable for all use cases. <br>
> Another option could be to create a spatial index (GIST) on the geometry column of the `population` table, which can significantly speed up spatial queries. The index as seen above a very powerful tool to improve the performance of spatial queries, especially when working with large datasets. However, it requires additional storage space and can slow down write operations, so it should be used judiciously. Furthermore, the index is applied on non transformed geometries. In our case, the dynamic transformation of the geometries in the query makes it impossible to use the index. It would be better to create a new column with the transformed geometries and then create the index on this column. <br>
> An additional consideration could be to use a bounding box to filter the data before applying the spatial function. This can significantly reduce the number of records that need to be processed, especially for large datasets. The bounding box can be created using the `ST_Envelope` function, which returns the minimum bounding rectangle that contains the geometry.


## 🏠 Creating a buildings table from OSM data

Our OSM table `planet_osm_polygon` contains a lot of data, including buildings, administrative boundary, land use, and more. For our analysis, we are only interested in the buildings. <br>
Deleting all data `planet_osm_polygon` to keep only the buildings might be too extreme. We may need the other data later, so it is better to create a new table that contains only the buildings. 

1. Identifying the buildings in OSM data

```diff
! 🤔 From our raw osm data, how can we identify the records that are buildings?
```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> We can identify the buildings by checking the `building` column in the `planet_osm_polygon` table. If the `building` column is not null, it means that the geometry is a building. <br>
>
> ```sql
> SELECT * -- 🦫 select all columns
> FROM planet_osm_polygon -- from the OSM polygon table
> WHERE building IS NOT NULL; -- where the building column is not null

<br>
</details>

2. Identifying the columns we want to keep

```diff
! 🤔 What columns do we want to keep in our new buildings table? 
```

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> We want to keep the following columns:
> - `osm_id`: the unique identifier of the building in OSM
> - `addr:housename`: the name of the building (if available)
> - `addr:housenumber`: the house number of the building (if available)
> - `amenity`: the type of building (if available)
> - `building`: the type of building (if available) 
> - `historic`: the historical significance of the building (if available)
> - `way`: the geometry of the building

<br>
</details>

3. Creating the buildings table

We can create a new table called `buildings` that contains only the buildings from the `planet_osm_polygon` table. We will use a `JOIN` clause to filter the buildings that are within the polygon of Styria, and we will select only the columns we want to keep. <br>
SQL is very powerful, we can create a new table from the result of a query using the `CREATE TABLE AS` statement. 

```sql
CREATE TABLE buildings AS -- 🦫 
SELECT ...;
```

```diff
! 🤔 What select query can we use to select the buildings that are within Styria?
```

> [!NOTE]
> We have to assess a spatial relation between the geometry of Styria and the buildings geometry. The problem is that both of them are in the same table, so we need to use a self-join to filter the buildings that are within the polygon of Styria! In SQL you cannot join a table with itself out-of-the-box, but you can use an alias to create a temporary name for the table. The alias is created by using the `AS` keyword followed by the alias name. When you want to refer to the table in the query, you can use the alias name instead of the original table name. <br>
> To use the attibutes of the table with the alias, you need to prefix the column names with the alias name. For example, if you have a table called `MY_TABLE` and you want to create an alias called `my_alias`, you can do it like this:

>
>```sql
> SELECT my_alias.id, my_alias.name
> FROM MY_TABLE AS my_alias;
>```

Currently our `SELECT` should look like this:

```sql
SELECT ... -- 🦫 select the columns we want to keep
FROM planet_osm_polygon osm_buildings -- 🦫 alias for the buildings table
JOIN planet_osm_polygon styria_geom ON ... -- 🦫 join with condition for the region table
WHERE ... -- 🦫 filter the buildings
AND ...; -- 🦫 filter the region
```

```diff
! 🤔 What join condition we would like to use to connect the building to the region? We learned already the clause `ST_WITHIN`. Do you think it is adapted for the buildings?
```

> [!TIP]
> The `ST_WITHIN` function checks if one geometry is completely within another geometry. This might be an issue for buildings that are on the border of the region, as they might not be completely within the polygon of Styria. <br> 
> A better option could be to use the `ST_Intersects` function, which checks if two geometries intersect. This way, we can include buildings that are on the border of Styria as well.

Now you have all the information to create the `buildings` table! 

<details>
    <summary>💡 Are you blocked? </summary>
<br>

> ```sql
> CREATE TABLE buildings AS -- 🦫 create a new table called buildings with the result of the following select
> SELECT osm_buildings.osm_id, -- attribute we want to keep for the buildings, we use the alias osm_buildings to refer to the planet_osm_polygon table
>   osm_buildings."addr:housename", 
>   osm_buildings."addr:housenumber",
>   osm_buildings.amenity, 
>   osm_buildings.building, 
>   osm_buildings.historic, 
>   osm_buildings.way AS geometry -- we rename the way column to geometry for clarity, in the new table the geometry column will be called geometry instead of way
> FROM planet_osm_polygon osm_buildings -- alias for the buildings table
> JOIN planet_osm_polygon region ON ST_Intersects(osm_buildings.way, region.way) -- add the region table to the query and check if the buildings are intersecting the polygon of Styria
> WHERE osm_buildings.building IS NOT NULL -- filter the buildings records
> AND region.name = 'Steiermark'; -- filter the region 

<br>
</details>

```diff
! 👀 Let's explore the new table buildings
! 🤔 How many buildings are present? Does this number look possible?
! 🤔 How can we still improve our table? Is there any index to create that could make sense?
! 🤔 What could be the next steps of the analysis?
```


💪 Congratulations! You have completed this exercise! 🎉 
