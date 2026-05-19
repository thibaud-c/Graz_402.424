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

- select the relevant categories
- spatially join points to districts
- count them
- compute densities
- compare districts

> [!IMPORTANT]
> Aggregation is useful, but it also simplifies reality.  
> A district summary hides internal variation.
> Here is a great video to watch: [here](https://www.youtube.com/watch?v=8pRcdMVkA3k)


---

### 🍱 Suggested focus categories
To keep the exercise manageable, work with a small set of “everyday amenities”.

Recommended starter key categories:
- Education
- Health
- Food

> [!NOTE]
> Your dataset use different category labels. Find the real values in your table before filtering.

---
# 0) 👀 Inspect the categories before filtering

---

Use the query of last week that lists categories and counts.

Then decide:
- which categories are relevant to the client (e.g., education, health, food),
- which categories are too rare,
- which categories are too broad or too noisy.

> [!IMPORTANT]
> **🧠 Questions**
> - What counts as an “everyday amenity” is not purely technical. Who decides? How it could impact the results
> - What is the risk of using every available place category in the screening?
> - Why should category selection happen before aggregation?


---

# 1) 🆕 Create new table with the filtered places

---

Create a table that keeps only the selected categories.
How can we create a new table in SQL, what are revelant parameters? [📚 documentation](https://www.postgresql.org/docs/current/sql-createtable.html)

Suggested Query:
```sql
CREATE OR REPLACE TABLE selected_places AS
SELECT -- add the columns you need
FROM overture_places
WHERE basic_category IN (
  'The categories',
  'that you identified'
);
```

> [!INFORMATION]
> The `CREATE OR REPLACE TABLE` statement creates a new table or replaces an existing one with the same name. It makes persistent the result of your `SELECT`.
> The `SELECT` statement is used to query the data from the `overture_places` table and filter it based on the `basic_category` column.
> `WHERE ... IN()` is used to filter the data based on the categories you identified.

> [!IMPORTANT]
> **🧠 Questions**
> - Why use a table here instead of rewriting the filter in every later query?
> - Why should we not simply publish the full `districts` table?

---

# 2) 🧮 Count selected places by district

---

Build a district-level count using a spatial join.
The next query will be a bit different, to count our amenities in each district, we will need to use 2 tables: the districts table and the selected places table.
The logic is: 
- We need to get all our selected places
- We need to find which district each place is in
- We need to count the number of places in each district

The pattern of the query will look like: 
```sql
SELECT 
  district_name,
  COUNT(count_value)
FROM districts
LEFT JOIN selected_places ON ST_Within(places_geometry, districts_geometry)
GROUP BY district_name;
```

In this query you reconize the `GROUP BY` / `COUNT` clause. 
The `LEFT JOIN` is used to join the districts table with the selected places table, based on the condition that the place geometry is within the district geometry.
This is a simple spatial join. Now, that the data is joined we can use the places to count the number of places in each district.

Before creating the full query let's break it down:
- select all district from the districts table

```sql
SELECT 
  *
FROM districts
```

- join the two tables on the condition that the place geometry is within the district geometry
In SQL, spatial functions are prefixed with `ST_` (for Spatial_Temporal).

```sql
SELECT 
  *
FROM districts
LEFT JOIN selected_places ON ST_Within(places_geometry, districts_geometry)
```

> [!INFORMATION]
> Here you have now 2 tables joined together. 
> If some columns have the same name, PostgreSQL will struggle to know which one to use. 
> To avoid this, you can use the table name as a prefix for the column name: `table_name.column_name`_
> For instance, `selected_places.geometry` & `districts.geometry` 

> [!IMPORTANT]
> **🧠 Questions**
> - What additional information contains your result?
> - What happens if you use `RIGHT JOIN` instead? 

- count the number of places in each district
```sql
SELECT 
  district_name,
  COUNT(count_value)
FROM districts
LEFT JOIN selected_places ON ST_Within(places_geometry, districts_geometry)
GROUP BY district_name
```

> [!IMPORTANT]
> **🧠 Questions**
> - Are the results something that you expected?


---

# 3) 🧮 Count by category and district

---

Update the previous query to count the number of places in each district by category.
💡 Hint: You have to change the `GROUP BY` clause 

> [!IMPORTANT]
> **🧠 Questions**
> - What is the difference between the two queries?
> - Which is more useful for the client: one total count, or counts by category?

---

# 4) 🌍 Compute district-level densities

---

Calculate:
- total selected amenities per districts
- district area in km²
- amenities per km²

To calculate an area you can use the function `ST_Area()`.

> [!IMPORTANT]
> **🧠 Questions**
> - Does the results looks realistic? Why?

We need to reproject the data in a metric crs! to reproject data you can use the function `ST_Transform(geom, epsg_code)`.

> [!TIP]
> In you `SELECT` clause you can also do any calculation, for instance: `ST_Area(ST_Transform(geom, 3857)) / 1000000` to get the area in km². It will be usefull to calculate the density.

> [!IMPORTANT]
> **🧠 Questions**
> - Why is density usually more informative than raw count?
> - What are the limitations of using district area as the denominator?

---

# 5) 💽 Save the results in new columns

---

Similar to QGIS and the attribute table, you can add new columns to a Postgres table.
To do so, you can use the `ALTER TABLE` statement. This is followed by the name of the table, and then the `ADD COLUMN` keyword, followed by the name of the column and its data type.

In our previous example we calculated the area of each district. We can save this result in a new column in the same table:

First, we need to create a new column in the districts table:
```sql
ALTER TABLE districts ADD COLUMN area NUMERIC;
```

> [!TIP]
> You can read this statement as: "Modify the table `districts` by adding a new column named `area` of type `NUMERIC`."


Now, we have a new empty columns! (👀 look the result in DBcode). 
We can update the column with the calculated area. To update a column, you can use the `UPDATE` statement. This is followed by the name of the table, and then the `SET` keyword, followed by the name of the column and its new value.
In this case we can use:  
```sql
UPDATE districts SET area = <calculated_area>;
```

> [!TIP]
> You can read this statement as: "Update the table `districts` by setting the column `area` to the value of `<calculated_area>`."

- Do the same for the amenities count and density columns.
- Do a final check of the table to see if the values are correct.

> [!IMPORTANT]
> **🧠 Questions**
> - What makes this result a new layer rather than just a query result?
> - Which fields are essential for publication, and which are only raw or intermediate?


**💪 Congratulations! You have completed this exercise! 🎉**

