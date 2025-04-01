# Exercise Guide: Working with Geo APIs

## Needed libraries

```bash
curl
jq
libxml2-utils
```

> [!TIP]
> You can install the above libraries using the following command:
>
> ```bash
> apt-get install library_name
> ```

## Introduction

In this exercise, you are a GIS expert who is looking to access data for their analysis.
A colleague has suggested using APIs to access the data.

They have share with you the following APIs:
[https://ahocevar.com/geoserver/wfs?service=WFS&version=1.1.0&request=GetFeature&typename=osm:water_areas&outputFormat=application/json&srsname=EPSG:3857&bbox=-8933308.907933006,5370452.51819444,-8884465.646858776,5393383.626679991,EPSG:3857](https://ahocevar.com/geoserver/wfs?service=WFS&version=1.1.0&request=GetFeature&typename=osm:water_areas&outputFormat=application/json&srsname=EPSG:3857&bbox=-8933308.907933006,5370452.51819444,-8884465.646858776,5393383.626679991,EPSG:3857)

## 🎯 Objectives

For your analysis, you need to answer the following questions:

1. What are the countries that have between 150M and 250M inhabitants?
2. In which continent are the 5 longest road segments, and what is their length?

## Step 1

You need to confirm that this API is providing the data you need.

- What is the service type of the API? What is its purpose?
- What is the version of the API? Is there other versions available?
- What are the layers available in the API?
- What are output formats available in the API?

> [!TIP]
> You need to create a specific request using the base url of the link provided above.
> The result will be in XML format.
> You can pipe the result of the request to the libxml2-utils library to make the answer more redable.
> **Example**
>
> ```bash
> your_request | xmllint --format -
> ```

## Step 2
Now that you have confirmed that the API is providing the data you need, you can start working with it.
Let's start with the first question.

- What attributes are available in the API, for the layer you are interested in?
- You can try to return a unique feature to see the attributes available.

> [!TIP]
> You will need to build the call to get the requested data.
> I recommend to work with the latest version of the API. Which one is it?
> Here are some parameters that might be useful:
> - `count=<number>` ➡️ used to limit the number of features returned
> - `propertyname=<name_of_the_properties_separated_by_comma>` ➡️ used to specify the exact properties you want to return
> - `cql_filter=<name_of_the_property><operator><filter>` ➡️ used to filter the data. What is the syntax of the filter? If there is the operator is a text keyword, you need to add space between the keyword and the value. The space should be encoded in the URL, it is replaced by `%20`.


## Step 3
Let's now focus on the second question.

- What are the attributes available in the API, for the layer you are interested in?
- You can try to return a unique feature to see the attributes available.
- You will need to filter for the road segments.

> [!TIP]
> You will need to build the call to get the requested data.
> Here are some additional parameters that might be useful:
> - `sortBy=<name_of_the_property>` ➡️ used to sort the data
