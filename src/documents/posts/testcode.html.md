```
title: Test code formatting
layout: post
tags: ['intro','post']
```

# inventorydb-restclient


This module provides following features:

* SQL like [fluent interface](http://en.wikipedia.org/wiki/Fluent_interface) over inventory db REST interface.
* Supports parameterized queries so that Query can be constructed once, but with different values for query variables. See [example](#example-code-for-querying-clusters-in-multiple-dcs-using-variable)
* Easy way to swap REST data source with JSON from FileSystem so that it can be easily tested without REST endpoint. See [example](#example-code-for-querying-active-asg-clusters-using-json-from-filesystem)
* Built-in caching so that, data can be returned from cache if inventorydb is unavailable. (not implemented yet, fairly easy to do with [spring cache abstraction](http://docs.spring.io/spring/docs/4.0.0.RC1/spring-framework-reference/html/cache.html) )

## Getting Started


Add this maven dependency to your project.

```xml
<dependency>
  <groupId>com.salesforce.mandm</groupId>
  <artifactId>inventorydb-restclient</artifactId>
  <version>0.1-SNAPSHOT</version>
</dependency>
```

```json
{
  "success" : true,
  "data" : [ {
    "@clusterJacksonId" : "19261ad4-cf56-411a-a02f-dc77badfcd10",
    "name" : "NA6",
    "operationalStatus" : "PRE_PRODUCTION"
  }, {
    "@clusterJacksonId" : "7e76c656-74a4-48fa-b231-a69e87e9f727",
    "name" : "CS0",
    "operationalStatus" : "IN_MAINTENANCE"
  }, {
    "@clusterJacksonId" : "9fb447f5-eb65-46a8-9166-4ad6329a9470",
    "name" : "CS1",
    "operationalStatus" : "ACTIVE"
  }, {
    "@clusterJacksonId" : "3e65a5a1-1de2-40a9-9d39-6c9806ea18eb",
    "name" : "NA5",
    "operationalStatus" : "ACTIVE"
  } ],
  "total" : 4
}
```

### Fluent API Grammar

> Every interaction is both precious and an opportunity to delight.

> Seth Godin Welcome to Island Marketing

Basic EBNF grammer for Fluent Interface Query.

**Grammar:**

![Grammar](https://git.soma.salesforce.com/MandMTrust/inventorydb-adapter/raw/master/inventorydb-restclient/diagrams/Grammar.png) 

**Fields:**

![Fields](https://git.soma.salesforce.com/MandMTrust/inventorydb-adapter/raw/master/inventorydb-restclient/diagrams/Fields.png) 

where field referes to any field in inventory db data, if no field passed (zero-args) all fields will be selected

**Resource:**

![Resource](https://git.soma.salesforce.com/MandMTrust/inventorydb-adapter/raw/master/inventorydb-restclient/diagrams/Resource.png) 

where Resource.IDB and Resource.DDB refers to corresponding Enums in java

**Condition:**

![Condition](https://git.soma.salesforce.com/MandMTrust/inventorydb-adapter/raw/master/inventorydb-restclient/diagrams/Condition.png) 

Diagrams generated using [RailRoad diagrams site](http://bottlecaps.de/rr/ui)

### Usage Examples

#####Add following static imports to be able to call methods without qualifiers

```java
import static com.salesforce.mandm.inventorydb.query.Condition.*;
import static com.salesforce.mandm.inventorydb.query.Query.Builder.*;
import static com.salesforce.mandm.inventorydb.query.Resource.Builder.*;
import static com.salesforce.mandm.inventorydb.query.Resource.DDB.*;
import static com.salesforce.mandm.inventorydb.query.Resource.IDB.*;
import static com.salesforce.mandm.inventorydb.query.Variable.*;
```

#####Create iDB or dDB Configuration
```java
Configuration iDBConfiguration =  new Configuration.Builder()
                .inventoryUrl(new URL("https://cfgdev-cidb1-0-sfm.data.sfdc.net/cidb-api"))
                .apiVersion("1.03").build();
RequestSignerConfiguration requestSignerConfiguration = new RequestSignerConfiguration.Builder()
                .keyStoreLocation(System.getProperty("app.home" , "") + "request-signing/config/keyrepo")
                .keyVersion("188").build();

Configuration dDBConfiguration = new Configuration.Builder()
                              .inventoryUrl(new URL("https://cfgqa-deployment2-0-sfm.data.sfdc.net/deployment-api"))
                              .apiVersion("1.0").build();
```


#####Example code for querying all datacenters from **inventory db**.

```java
Query query = select("name").from(source(IDB.DATACENTERS).datacenterAll()).build();

JsonNode data = DataProviderFactory
                .createRequestSigningRestDataProvider(iDBConfiguration, requestSignerConfiguration)
                .query(query, JsonNode.class);
```

Only **name** field is selected.
**where(Condition)** is optional so it is skipped.
The response is mapped to Jackson JsonNode object.


#####Example code for querying all POD clusters in ASG datacenter from **inventory db**.

```java
Query query = select("name")
                .from(source(IDB.CLUSTERS).datacenter("asg"))
                .where(condition("operationalStatus").eq("ACTIVE")
                    .and("dr").eq("false")
                    .and("clusterType").eq("POD"))
                .build()

String data = DataProviderFactory
                .createRequestSigningRestDataProvider(iDBConfiguration, requestSignerConfiguration)
                .query(query, String.class);
```

The response is mapped to String.

##### Example code for querying clusters in multiple DCs using variable

```java
   Query query = select("name")
                   .from(source(IDB.CLUSTERS).datacenter(var("dc")))
                   .where(condition("operationalStatus").eq("ACTIVE")
                       .and("dr").eq("false")
                       .and("clusterType").eq("POD"))
                   .build();
   Map<String,String> queryVariables = new HashMap<String, String>();
   String datacenters[] = new String[] {"asg", "sjl"};

   for(String datacenter : datacenters){
       queryVariables.put("dc", datacenter);
       JsonNode actual = DataProviderFactory
                            .createRequestSigningRestDataProvider(iDBConfiguration, requestSignerConfiguration)
                            .query(query, JsonNode.class, queryVariables);
   }
```

Query is created once but different values for datacenter is used in **queryVariables**.

#####Example code for querying all fields in GOC RoleConfig from **deployment db**.

```java
Query query = select().from(source(DDB.ROLECONFIGS)).where(condition("name").eq("goc")).build();
Map data = DataProviderFactory.createRestDataProvider(dDBConfiguration).query(query, Map.class);
```

**select()** is called with no-args, so all fields will be returned.
The response is mapped to Java Map.

##### Example code for querying active ASG clusters using JSON from FileSystem

```java
   DataProvider fsd = DataProviderFactory.createFileSystemDataProvider("test");
   Query query = select("name")
                   .from(source(IDB.CLUSTERS).datacenter("asg"))
                   .where(condition("operationalStatus").eq("ACTIVE")
                       .and("dr").eq("true")
                       .and("clusterType").eq("POD"))
                   .build();
   JsonNode actual = fsd.query(query, JsonNode.class);
```

FileSystemDataProvider will load data for query from JSON File in FileSystem. It will look for file in classpath {com/saleforce/mandm/inventorydb/file} with file name format 
{<name\>\__<dc\>\__<resource\>\__MD5HASHOF\_(fields--<field1\>--<fieldN\>\__<conditionParam1\>--<conditionValue1\>\__<conditionParamN\>--<conditionValueN\>).json}

The query was part of the filename, but filenames were getting too long so implemented a md5 hash for fields and conditions to avoid long filename,
With this new md5 the file for the above example is loaded from ` com/salesforce/mandm/inventorydb/file/test__asg__clusters__f10ec8d017b0cd52f72923521d69351e.json `

For naming convention, refer to [FileSystemDataProvider Javadocs](https://rpendyck-wsl6.internal.salesforce.com:9999/job/inventorydb-adapter/javadoc/index.html?com/salesforce/mandm/inventorydb/file/FileSystemDataProvider.html)

See [RestDataProviderTest](https://git.soma.salesforce.com/MandMTrust/inventorydb-adapter/blob/master/inventorydb-restclient/src/test/java/com/salesforce/mandm/inventorydb/rest/RestDataProviderTest.java) and [FileSystemProviderTest](https://git.soma.salesforce.com/MandMTrust/inventorydb-adapter/blob/development/inventorydb-restclient/src/test/java/com/salesforce/mandm/inventorydb/file/FileSystemDataProviderTest.java) for above examples in action.

### Databinding

It provides built-in support for serializing JSON response to Java objects using Jackson. So you can use [Jackson Annotated class](http://wiki.fasterxml.com/JacksonAnnotations) to automatically convert
JSON response to Java object. But if you want to extract only specific values from JSON, use [jsonpath-databinding module](https://git.soma.salesforce.com/MandMTrust/inventorydb-adapter/tree/master/jsonpath-databinding)

