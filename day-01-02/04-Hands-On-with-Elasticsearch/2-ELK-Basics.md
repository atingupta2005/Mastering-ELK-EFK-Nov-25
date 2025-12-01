# 📚 **Elastic Stack Hands-On Workshop – Working with Elasticsearch using Kibana Dev Tools**

## 🧩 **1. Indexing Documents**

We’ll begin by creating a simple dataset representing books.

### 🏗 Create `books` index and insert sample documents:

```http
PUT books/_doc/1
{
  "title": "Effective Java",
  "author": "Joshua Bloch",
  "release_date": "2001-06-01",
  "amazon_rating": 4.7,
  "best_seller": true,
  "prices": {
    "usd": 9.95,
    "gbp": 7.95,
    "eur": 8.95
  }
}

PUT books/_doc/2
{
  "title": "Core Java Volume I - Fundamentals",
  "author": "Cay S. Horstmann",
  "release_date": "2018-08-27",
  "amazon_rating": 4.8,
  "best_seller": true,
  "prices": {
    "usd": 19.95,
    "gbp": 17.95,
    "eur": 18.95
  }
}

PUT books/_doc/3
{
  "title": "Java: A Beginner’s Guide",
  "author": "Herbert Schildt",
  "release_date": "2018-11-20",
  "amazon_rating": 4.2,
  "best_seller": true,
  "prices": {
    "usd": 19.99,
    "gbp": 19.99,
    "eur": 19.99
  }
}
```

✅ *You have now successfully indexed 3 book documents.*

---

## 📊 **2. Counting Documents**

### Get document count from a specific index:

```http
GET books/_count
```

### Create another index (`fiction`) with one document:

```http
PUT fiction/_doc/1
{
  "title": "The Enchanters' Child",
  "author": "Navya Sarikonda"
}
```

### Count across multiple indices:

```http
GET books,fiction/_count
```

### Count across **all** indices:

```http
GET /_count
```

### Use wildcard to match index patterns:

```http
GET b*/_count
```

---

## 📖 **3. Retrieving Documents**

### Get document by ID:

```http
GET books/_doc/1
```

### Fetch only the `_source` (without metadata):

```http
GET books/_source/1
```

### Fetch multiple documents by ID:

```http
GET books/_search
{
  "query": {
    "ids": {
      "values": [1,2,3]
    }
  }
}
```

### Turn off `_source` field in results:

```http
GET books/_search
{
  "_source": false,
  "query": {
    "ids": {
      "values": [1,2,3]
    }
  }
}
```

---

## 🔎 **4. Searching with Match and Prefix Queries**

### Retrieve all documents:

```http
GET books/_search
```

### Search for author “Joshua”:

```http
GET books/_search
{
  "query": {
    "match": {
      "author": "Joshua"
    }
  }
}
```

### Case-insensitive search:

```http
GET books/_search
{
  "query": {
    "match": {
      "author": "JoShUa"
    }
  }
}
```

### Search using surname:

```http
GET books/_search
{
  "query": {
    "match": {
      "author": "Bloch"
    }
  }
}
```

### Regex-like partial match won’t work:

```http
GET books/_search
{
  "query": {
    "match": {
      "author": "Josh"
    }
  }
}
```

### Use prefix query for partial matches (case-sensitive!):

```http
GET books/_search
{
  "query": {
    "prefix": {
      "author": "josh"
    }
  }
}
```

---

## 🔠 **5. Match Query Variations**

### Match with multiple keywords:

```http
GET books/_search
{
  "query": {
    "match": {
      "author": {
        "query": "Joshua Sarikonda"
      }
    }
  }
}
```

### Match with logical operator:

```http
GET books/_search
{
  "query": {
    "match": {
      "author": {
        "query": "Joshua Herbert",
        "operator": "AND"
      }
    }
  }
}
```

---

## ⚡ **6. Bulk Indexing**

💡 Copy dataset from
 - kibana-books-dataset.txt

---

## 🧠 **7. Advanced Search Queries**

### Multi-field search using `multi_match`:

```http
GET books/_search
{
  "query": {
    "multi_match": {
      "query": "Java",
      "fields": ["title", "synopsis"]
    }
  }
}
```

### Boosting specific field relevance:

```http
GET books/_search
{
  "query": {
    "multi_match": {
      "query": "Java",
      "fields": ["title^3", "synopsis"]
    }
  }
}
```

---

## 💬 **8. Phrase Queries**

### Exact phrase match:

```http
GET books/_search
{
  "query": {
    "match_phrase": {
      "synopsis": "must-have book for every Java programmer"
    }
  }
}
```

### With highlighting:

```http
GET books/_search
{
  "query": {
    "match_phrase": {
      "synopsis": "must-have book for every Java programmer"
    }
  },
  "highlight": {
    "fields": {
      "synopsis": {}
    }
  }
}
```

### Phrase with missing word (fails):

```http
GET books/_search
{
  "query": {
    "match_phrase": {
      "synopsis": "must-have book every Java programmer"
    }
  }
}
```

### Phrase with slop:

```http
GET books/_search
{
  "query": {
    "match_phrase": {
      "synopsis": {
        "query": "must-have book every Java programmer",
        "slop": 1
      }
    }
  }
}
```

---

## ✍️ **9. Fuzzy and Prefix Matching**

### Fuzzy query (spelling tolerance):

```http
GET books/_search
{
  "query": {
    "fuzzy": {
      "title": {
        "value": "kava",
        "fuzziness": 1
      }
    }
  }
}
```

### Add more test docs:

```http
PUT books/_doc/99
{
  "title": "Java Collections Deep Dive"
}

PUT books/_doc/100
{
  "title": "Java Computing World"
}
```

### Match phrase prefix:

```http
GET books/_search
{
  "query": {
    "match_phrase_prefix": {
      "title": "Java co"
    }
  }
}
```

---

## 🧩 **10. Term, Range, and Bool Queries**

### Check mapping:

```http
GET books/_mapping
```

### Range query (filter by rating):

```http
GET books/_search
{
  "query": {
    "range": {
      "amazon_rating": {
        "gte": 4.5,
        "lte": 5
      }
    }
  }
}
```

### Boolean queries (combining multiple conditions):

```http
GET books/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"author": "Joshua"}}
      ],
      "must_not": [
        {"range": {"amazon_rating": {"lt": 4.7}}}
      ],
      "filter": [
        {"range": {"release_date": {"gte": "2015-01-01"}}}
      ]
    }
  }
}
```

---

## 📈 **11. Analytics and Aggregations**

### Average rating of books:

```http
GET books/_search
{
  "aggs": {
    "avg_rating": {
      "avg": {
        "field": "amazon_rating"
      }
    }
  }
}
```

---

## 🦠 **12. COVID Dataset Analytics**

💡 Copy the file
 - covid-26march2021.txt
and load it into Kibana Dev Tools using `_bulk`.

### Sum of critical patients:

```http
GET covid/_search
{
  "size": 0,
  "aggs": {
    "critical_patients": {
      "sum": {
        "field": "critical"
      }
    }
  }
}
```

### Maximum deaths:

```http
GET covid/_search
{
  "size": 0,
  "aggs": {
    "total_deaths": {
      "max": {
        "field": "deaths"
      }
    }
  }
}
```

### Stats and Extended Stats:

```http
GET covid/_search
{
  "size": 0,
  "aggs": {
    "all_extended_stats": {
      "extended_stats": {
        "field": "deaths"
      }
    }
  }
}
```

---

## 🧮 **13. Bucketing Aggregations**

### Histogram (by `critical` count):

```http
GET covid/_search
{
  "size": 0,
  "aggs": {
    "critical_patients_as_histogram": {
      "histogram": {
        "field": "critical",
        "interval": 2500
      }
    }
  }
}
```

### Range aggregation:

```http
GET covid/_search
{
  "size": 0,
  "aggs": {
    "range_countries": {
      "range": {
        "field": "deaths",
        "ranges": [
          {"to": 60000},
          {"from": 60000, "to": 70000},
          {"from": 70000, "to": 80000},
          {"from": 80000, "to": 120000}
        ]
      }
    }
  }
}
```

