# Exercise Guide: Everyday Amenities From Collection to Visualization

(If you are reading this on VSCode, you can render the markdown using `Ctrl/Cmd+Shift+V`)

### 📝 Mission Brief
**Objective.** The City Urban Development Unit of Graz wants a quick overview of everyday amenities, but the data is not yet organized in a form that supports querying, summarizing, or publishing. You are the data ingestion and database setup team.
**Your task.** Download Overture places for Graz from the command line, load official district boundaries and places into PostGIS, and inspect the tables so they are ready for analysis.

---

### Why a spatial database?
A file is useful for viewing.  
A database is useful for:
- storing multiple layers together,
- querying them repeatedly,
- joining them,
- keeping field names and geometry types organised,
- and building new layers from the data.

---

## 🚀 Workflow to implement
- get the data
- ingest it
- inspect it
- make sure it is usable


---

# 0) 🏠 Create your project structure

---

This time we will simply use our _`ubuntu server`_ to download the data. The data will be directly loaded to our new database.

> [!IMPORTANT]
> **🧠 Questions**
> - What project structure would make sense in this case?

---

# 1) 💽 Input data

---

#### 1.1)  District boundaries**

Find & Download the official Graz district layer.
- Base url [geodata graz](https://geodaten.graz.at/arcgis/rest/services/OGD/VERWALTUNGSEINHEITEN_WMS/MapServer/2/query)

> [!IMPORTANT]
> **🧠 Questions**
> - How to use the geodata graz API to download the data? What do we need to add to the url?
> - What are the available options for the geodata graz API?

> [!TIP]
> We need to use:
> - `where`: with the value `1=1`, we want all features so we enter a always true value
> - format (use `f` in the url): with the value `geojson`
> - `returnGeometry`: with the value `true`
>
> remember that the base URL should end with `?`and that your parameter should be connected with `&`

Try to build the url and download the data.

The final URL should look like this:
`https://geodaten.graz.at/arcgis/rest/services/OGD/VERWALTUNGSEINHEITEN_WMS/MapServer/2/query?where=1=1&f=geojson&returnGeometry=true`

#### 1.2)  Overture places**

Download a Graz subset from the CLI.
Look at the [📚 documentation](https://docs.overturemaps.org/getting-data/overturemaps-py/). 

> [!IMPORTANT]
> **🧠 Questions**
> - How to use overture CLI without installing it? what are the prerequisites?
> - What are the available options for the overture CLI?
> - In which format should we download the data? I recommand geojson. Why?

#### 1.3) Data Check**
- the file exists
- the file is not empty
- the geometry type is what you expect
- use `ogrinfo` and `cat` to inspect the data

> [!INFO]
> Remember to use `-so -al` with `ogrinfo` 
> [📚 documentation](https://gdal.org/en/stable/programs/ogrinfo.html)

> [!IMPORTANT]
> **🧠 Questions**
> - What files are present in the downloaded data repository? 
> - Why is the download step part of the pipeline and not just preparation?
> - What are the advantages of using a bounding box when downloading data?

---

# 2) 📤 Load the data into PostGIS

---

To import your data into the data base (PostGreSQL/PostGIS), we will again use our swiss army knife: `gdal`, with vector data.

To transform any vector data to another vector format (including database), we will use the `ogr2ogr` command.
[📚 documentation](https://gdal.org/en/stable/programs/ogr2ogr.html).

> [!IMPORTANT]
> **🧠 Questions**
> - Look on the web if you can find the command to load a geojson file into a PostGIS database.

One example pattern is:

```bash
ogr2ogr -f PostgreSQL PG:"<connection information to your PG database>" <path to your geojson file> -nln <name of the table in the database: overture_places/districts>
```

> [!INFO]
> Remember to use `-overwrite` to overwrite the table if it already exists.
>
> The connection to your _`remote`_ data base needs: 
> - host: specifies the IP address of the PostgreSQL server (e.g., in our case it is the IP address of the Docker container)
> - port: specifies the port number of the PostgreSQL server (e.g., 5432)
> - dbname: specifies the name of the database to connect to (e.g., postgres)
> - user: specifies the username to connect to the database (e.g., postgres)
> - password: prompts for the password for the user. If you are not using this parameter, the command will try to connect without a password...
>
> To get the IP address of the container, run (from your local machine):
> ```bash
> docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgis-db
> ```

Load the data for the following layers:
- district boundaries
- Overture places

> [!IMPORTANT]
> **🧠 Questions**
- What is the benefit of importing to PostGIS instead of querying the GeoJSON file directly every time?
- What problems would appear if you kept all analysis at file level only?

---

# 3) 📊 Inspect the database tables with DBCode

---

Before doing any analysis, we need to understand what we imported.

#### 3.1) Open DBCode and connect your database

Open the data using DBCode extension from VScode. Install the extension if you haven't already.
- Use DBCode, ➕ to connect to your PostGIS database with the information above (you can use `localhost`for the host value). 
- navigate to dbname (postgres) > schemas > public > tables. You should see your tables `districts` and `overture_places`.

> [!INFO]
> A schema in a database is a way to organize tables. The default schema is `public`. 
>
> In DBcode, if you don't see an update, you can click on 🔄 to refresh. 


#### 3.2) Table preview

Click on any of your table to see the data that has been loaded on your database. You have access to all your data (by page of 100 records). It is useful to inspect the data and understand the structure of the tables, but for more complex queries, you should use SQL.

This helps you see:
- column names,
- example values,
- whether the table imported correctly,
- whether the geometry column exists.

> [!IMPORTANT]
> **🧠 Questions**
- What are the columns available in each of your tables? 
- Is there a geometry column? 
- Are the geometries in the same projection?
- What is the main column to find the amenities?
- Is there any other columns that could be useful for the rest of the exercise?

---

# 4) 🤓 Understand your data with SQL

---

#### 4.1) What is SQL doing?

SQL lets you ask the database questions, it is a simple language to query databases. It is very powerful and can be used to filter, aggregate, and transform data. 
Most queries use this structure:
```sql
SELECT  -- what do I want to see?
FROM    -- from which table?
WHERE   -- which rows should I keep?
GROUP BY -- how should rows be grouped?
ORDER BY -- how should results be sorted?
LIMIT   -- how many rows should I return?
;
```

Not every query needs every line.

#### 4.2) Writing your first SQL query in DBCode

You can also use the SQL editor in DBcode to run queries directly on the database. Right click on your table > script > SELECT. You should arrive on a text editor, where you can write and execute SQL. 

You should see:
```sql
SELECT <all_columns_names>
FROM <table_name>;
```
> [!IMPORTANT]
> **🧠 Questions**
> - What is this query doing?
> - What could be the issue with this query?

> [!TIP]
> **Explanation**
> ```sql
> SELECT <all_columns_names> means “show these columns”, if you want all colunms, you can replace all columns by *
> FROM <table_name> means “use this table”
> ```

- replace all columns names by `*`
- add a `LIMIT` clause to this query (e.g., `LIMIT 10`)
- don't forget the `;`, which ends the query
- execute the query (above the your SQL query you should see a button `▹ execute`)
- create the same query for the other table

> [!IMPORTANT]
> **🧠 Questions**
> - Which table contains points?
> - Which table contains polygons?
> - Which columns are easy to understand?
> - Which columns look complicated or nested?


#### 4.2) How big is your data

We will count how many rows have each table. 
The query will look like this:
```sql
SELECT COUNT(*) AS count
FROM <table_name>;
```

> [!TIP]
> It is the same SELECT ... FROM ...; structure, but instead of reading directly the columns values, we apply an aggregation function to count the rows. 
> **Explanation**
> ```sql
> COUNT(*) means “count all rows”, instead of * you can use any column names
> AS count means “name the result 'count'” (it can be any name you want). Try to delete this part. What is the name of the output? 
> ```
>
> Some examples of aggregation functions are: 
> COUNT
> SUM
> AVG
> MAX
> MIN 

> [!IMPORTANT]
> **🧠 Questions**
> - Does the number of districts look plausible?
> - Does the number of places look too small, too large, or reasonable for Graz?
> - What could cause a wrong number of places/districts?


#### 4.3) Identify available places categories

We will identify the different places categories available in the data.

You can use the keyword `DISTINCT` to get unique values from a column.
The query will look like this:
```sql
SELECT DISTINCT <column_name>
FROM <table_name>;
```

Additionally you can order the results by adding an `ORDER BY` clause:

```sql
SELECT DISTINCT <column_name>
FROM <table_name>
ORDER BY <column_name>;
```

> [!IMPORTANT]
> **🧠 Questions**
> - Which categories are irrelevant for this client question?
> - Are there categories that are too broad or too ambiguous? 


#### 4.4) Check the distribution of places

We will check the distribution of places by counting how many places have each category.
The query will look like this:
```sql
SELECT <column_name>, COUNT(*) AS count
FROM <table_name>
GROUP BY <column_name>
ORDER BY count DESC;
```

> [!NOTE]
> - the `SELECT` clause has 2 outputs: the value of `<column_name>` and its aggregated count.
> - This query uses `GROUP BY` to group rows by the places category, then `COUNT(*)` to count how many places have each category.
> - `ORDER BY count DESC` sorts the results by count in descending order, so the most common places appear first.

> [!IMPORTANT]
> **🧠 Questions**
> - What are the top 5 common places types in Graz?
> - Are rare categories still important for public services?
> - Are the most frequent categories useful for urban planning?
> 


#### 4.5) Filter one category

We will filter the places table to only include places with the category "restaurant".
The query will look like this:
```sql
SELECT *
FROM <table_name>
WHERE <column_name> = 'restaurant'
;
```

> [!NOTE]
> - The `WHERE` clause filters the rows to only include those where the places category is "restaurant".

Filtering is very powerful and help you to focus on specific data.
Let's try to get all places within a street (e.g., Zinzendorfgasse)

In a where clause you can filter for specific values, but also for patterns using the `LIKE` operator (like in QGIS).
The where clause will look like this:

```sql
WHERE addresses LIKE '%Zinzendorfgasse%'
```

> [!NOTE]
> - The `LIKE` operator is used to filter for patterns in text data.
> - The `%` wildcard matches any sequence of characters, so `'%Zinzendorfgasse%'` matches any address containing "Zinzendorfgasse", anything can ve before or after.

However our query will not work out of the box ... What is the issue? 
The problem is that the column `addresses` is not `text` or `varchar` (i.e., string...). It is a `array` of `json` type.

We can cast the column on-the-fly using `TEXT(addresses)`. 
Casting is a way to convert data from one type to another. 


> [!IMPORTANT]
> **🧠 Questions**
> - Are all places present in the database?
> - Why some addresses are missing?


**(optional) QGIS connection**: You can also connect to the database from QGIS using the same connection information as above. It is a quick way to visualize & inspect the data.



**💪 Congratulations! You have completed this exercise! 🎉**

