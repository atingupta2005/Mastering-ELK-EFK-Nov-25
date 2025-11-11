# 🧠 **Kibana Filtering, KQL & Analysis**

## 🗂️ Dataset Files Used

* **Mapping file:** `products_mapping.txt`
* **Data file (for bulk insert):** `products.txt`

---

## ⚙️ Step 1: Create the Index and Mapping

We’ll create an index called **`products`** and define a rich schema for product-related data.

```json
PUT products
{
  "mappings": {
    "properties": {
      "brand": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } }
      },
      "colour": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } }
      },
      "energy_rating": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } }
      },
      "images": { "type": "text" },
      "model": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } }
      },
      "overview": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } }
      },
      "price": { "type": "double" },
      "product": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } }
      },
      "resolution": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } }
      },
      "size": { "type": "text" },
      "type": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } }
      },
      "user_ratings": { "type": "double" }
    }
  }
}
```

✅ **Verify Index Creation**

```json
GET products/_mapping
```

---

## 🧾 Step 2: Bulk Index Sample Data

Use the **Bulk API** to load product data.

```json
POST _bulk
{ "index": { "_index": "products" } }
{ "brand": "LG", "product": "TV", "price": 999, "colour": "black", "resolution": "4k", "user_ratings": 4.8, "overview": "4K Ultra HD Smart TV", "energy_rating": "A++", "type": "Smart TV" }
{ "index": { "_index": "products" } }
{ "brand": "Samsung", "product": "TV", "price": 1200, "colour": "silver", "resolution": "4k", "user_ratings": 4.6, "overview": "4K UHD QLED TV", "energy_rating": "A++", "type": "QLED" }
{ "index": { "_index": "products" } }
{ "brand": "Sony", "product": "TV", "price": 2500, "colour": "black", "resolution": "8k", "user_ratings": 4.9, "overview": "8K HDR OLED TV", "energy_rating": "A++", "type": "OLED" }
{ "index": { "_index": "products" } }
{ "brand": "Philips", "product": "Fridge", "price": 800, "colour": "white", "resolution": "N/A", "user_ratings": 4.3, "overview": "Smart Inverter Fridge", "energy_rating": "A+", "type": "Fridge Freezer" }
{ "index": { "_index": "products" } }
{ "brand": "LG", "product": "Fridge", "price": 950, "colour": "silver", "user_ratings": 4.7, "overview": "Frost Free Smart Fridge", "energy_rating": "A++", "type": "Frost Free Fridge Freezer" }
```

✅ **Validate Insertion**

```json
GET products/_count
GET products/_search
{
  "query": { "match_all": {} },
  "_source": ["brand", "product", "price", "user_ratings"]
}
```

---

## 🔍 Step 3: Exploring Compound Queries

### 3.1 – `bool` Query with `must`

Find all TVs.

```json
GET products/_search
{
  "query": {
    "bool": { "must": [{ "match": { "product": "TV" } }] }
  }
}
```

### 3.2 – `must` with `range`

Find TVs priced between ₹700–₹800.

```json
GET products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "product": "TV" } },
        { "range": { "price": { "gte": 700, "lte": 800 } } }
      ]
    }
  }
}
```

### 3.3 – `must` with `terms`

Find TVs in a price range with specific colors.

```json
GET products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "product": "TV" } },
        { "range": { "price": { "gte": 1000, "lte": 2000 } } },
        { "terms": { "colour": ["silver", "black"] } }
      ]
    }
  }
}
```

---

## 🚫 Step 4: Using `must_not` Clause

### Exclude Specific Brands

Exclude Samsung and Philips TVs.

```json
GET products/_search
{
  "query": {
    "bool": {
      "must_not": [
        { "terms": { "brand.keyword": ["Samsung", "Philips"] } }
      ],
      "must": [{ "match": { "product": "TV" } }]
    }
  }
}
```

---

## ⭐ Step 5: `should` Clause and Relevance Boost

### Add `should` Clause to Influence Scores

```json
GET products/_search
{
  "_source": ["product","brand","overview","price"], 
  "query": {
    "bool": {
      "must": [
        { "match": { "product": "TV" } },
        { "match": { "brand": "LG" } }
      ],
      "should": [
        { "range": { "price": { "gte": 500, "lte": 1000 } } },
        { "match_phrase_prefix": { "overview": "4k ultra hd" } }
      ],
      "minimum_should_match": 1
    }
  }
}
```

---

## 🧱 Step 6: Using Filters (for non-scoring conditions)

### Example – Filter TVs by Price

```json
GET products/_search
{
  "_source": ["brand","product","colour","price"], 
  "query": {
    "bool": {
      "filter": [
        { "term": { "product.keyword": "TV" } },
        { "range": { "price": { "gte": 500, "lte": 1000 } } }
      ]
    }
  }
}
```

---

## 🎯 Step 7: Combining All Clauses

```json
GET products/_search
{
  "query": {
    "bool": {
      "must": [{ "match": { "brand": "LG" } }],
      "must_not": [{ "term": { "colour": "silver" } }],
      "should": [
        { "match": { "energy_rating": "A++" } },
        { "term": { "type": "Fridge Freezer" } }
      ],
      "filter": [{ "range": { "price": { "gte": 500, "lte": 1000 } } }]
    }
  }
}
```

---

## 🧮 Step 8: Function Score & Boosting Queries

### a. Simple Function Score

```json
GET products/_search
{
  "query": {
    "function_score": {
      "query": { "term": { "product": "tv" } },
      "field_value_factor": {
        "field": "user_ratings",
        "factor": 2,
        "modifier": "square"
      }
    }
  }
}
```

### b. Boosting Query Example

```json
GET products/_search
{
  "_source": ["product", "price", "colour"],
  "query": {
    "boosting": {
      "positive": { "term": { "product": "tv" } },
      "negative": { "range": { "price": { "gte": 2500 } } },
      "negative_boost": 0.5
    }
  }
}
```

---

## 🧠 Step 9: Advanced Scoring Examples

### Weighted Function Score with Multiple Conditions

```json
GET products/_search
{
  "query": {
    "function_score": {
      "query": { "term": { "product": "tv" } },
      "functions": [
        {
          "filter": { "term": { "brand": "LG" } },
          "weight": 3
        },
        {
          "filter": { "range": { "user_ratings": { "gte": 4.5, "lte": 5 } } },
          "field_value_factor": {
            "field": "user_ratings",
            "factor": 1.2,
            "modifier": "square"
          }
        }
      ],
      "score_mode": "avg",
      "boost_mode": "sum"
    }
  }
}
```

---

## ✅ Step 10: Validation Commands

Run these to confirm all documents are correctly indexed and your queries return expected results.

```json
GET products/_count
GET products/_search
{
  "query": { "match_all": {} },
  "_source": ["brand", "product", "price", "user_ratings", "energy_rating"]
}
```
