# **Kibana Filtering, KQL & Analysis**

## **1. Objective**

* Create an index with explicit mappings.
* Index structured JSON movie data using Bulk API.
* Perform multiple search operations using `term`, `terms`, `range`, `exists`, `wildcard`, `prefix`, and `fuzzy` queries.
* Understand advanced Elasticsearch query behaviors like date math, highlighting, and expensive query restrictions.

---

## **2. Setup and Index Creation**

### **Delete old index (if any)**

```bash
DELETE movies
```

### **Create Movies Index with Explicit Mapping**

```json
PUT movies
{
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "fields": { "original": { "type": "keyword" } }
      },
      "synopsis": {
        "type": "text",
        "fields": { "original": { "type": "keyword" } }
      },
      "actors": {
        "type": "text",
        "fields": { "original": { "type": "keyword" } }
      },
      "director": {
        "type": "text",
        "fields": { "original": { "type": "keyword" } }
      },
      "rating": { "type": "half_float" },
      "release_date": {
        "type": "date",
        "format": "dd-MM-yyyy"
      },
      "certificate": {
        "type": "keyword",
        "fields": { "original": { "type": "keyword" } }
      },
      "genre": {
        "type": "text",
        "index_prefixes": {},
        "fields": { "original": { "type": "keyword" } }
      }
    }
  }
}
```

---

## **3. Insert Sample Data Using Bulk API**

### **Load movie dataset**

```bash
POST _bulk
{ "index": { "_index": "movies", "_id": "1" } }
{ "title": "The Shawshank Redemption", "synopsis": "...", "actors": ["Tim Robbins", "Morgan Freeman"], "director": "Frank Darabont", "rating": 9.3, "certificate": "R", "genre": "Drama", "release_date": "17-02-1995" }

# ... (continue for all 25 movies from dataset)
```

---

## **4. Query Examples**

### **Term Query**

Exact match on keyword fields.

```json
GET movies/_search
{
  "query": { "term": { "certificate": "R" } }
}
```

> 🔸 **Note:** `term` queries are case-sensitive for keyword fields.

---

### **Terms Query**

Match multiple values.

```json
GET movies/_search
{
  "query": {
    "terms": {
      "certificate": ["PG-13", "R"]
    }
  }
}
```

---

### **Change Index Setting**

```json
PUT movies/_settings
{
  "index": { "max_terms_count": 10 }
}
```

---

## **5. Terms Lookup Query**

### **Create Reference Index**

```json
PUT classic_movies
{
  "mappings": {
    "properties": {
      "title": { "type": "text" },
      "director": { "type": "keyword" }
    }
  }
}
```

### **Index Documents**

```bash
PUT classic_movies/_doc/1
{ "title": "Jaws", "director": "Steven Spielberg" }

PUT classic_movies/_doc/2
{ "title": "Jaws II", "director": "Jeannot Szwarc" }

PUT classic_movies/_doc/3
{ "title": "Ready Player One", "director": "Steven Spielberg" }
```

### **Terms Lookup Search**

```json
GET classic_movies/_search
{
  "query": {
    "terms": {
      "director": {
        "index": "classic_movies",
        "id": "3",
        "path": "director"
      }
    }
  }
}
```

---

## **6. Range Queries**

### **Numeric Range**

```json
GET movies/_search
{
  "query": {
    "range": {
      "rating": { "gte": 9.0, "lte": 9.5 }
    }
  }
}
```

### **Date Range and Sorting**

```json
GET movies/_search
{
  "query": {
    "range": { "release_date": { "gte": "01-01-1970" } }
  },
  "sort": [{ "release_date": { "order": "asc" } }]
}
```

---

### **Date Math Examples**

```json
# Before 13 Feb 1995
GET movies/_search
{
  "query": { "range": { "release_date": { "lte": "15-02-1995||-2d" } } }
}

# Movies from last 4 years
GET movies/_search
{
  "query": { "range": { "release_date": { "gte": "now-4y" } } }
}
```

---

## **7. Wildcard Queries**

### **Wildcard at the End**

```json
GET movies/_search
{
  "query": {
    "wildcard": { "title": { "value": "god*" } }
  }
}
```

### **Wildcard with Highlight**

```json
GET movies/_search
{
  "query": {
    "wildcard": { "title": { "value": "g*d" } }
  },
  "highlight": { "fields": { "title": {} } }
}
```

> ⚠️ Expensive queries like `wildcard` can be disabled using:

```json
PUT _cluster/settings
{
  "transient": { "search.allow_expensive_queries": "false" }
}
```

---

## **8. Prefix Queries**

```json
GET movies/_search
{
  "query": {
    "prefix": { "genre.original": { "value": "Ad" } }
  },
  "highlight": { "fields": { "genre.original": {} } }
}
```

---

## **9. Fuzzy Queries**

### **Single Edit Distance**

```json
GET movies/_search
{
  "query": {
    "fuzzy": {
      "genre": { "value": "rama", "fuzziness": 1 }
    }
  }
}
```

### **Two-Letter Difference**

```json
GET movies/_search
{
  "query": {
    "fuzzy": {
      "genre": { "value": "ama", "fuzziness": 2 }
    }
  }
}
```

---

## **10. Exists and Missing Field Queries**

```json
# Find docs missing 'confidential' field
GET top_secret_files/_search
{
  "query": {
    "bool": {
      "must_not": [{ "exists": { "field": "confidential" } }]
    }
  }
}
```
