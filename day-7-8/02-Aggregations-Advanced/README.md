## 📅 Day 6: Aggregations (Advanced)

### 1\. What are Aggregations? (Topic 22)

An **aggregation** is a powerful framework within Elasticsearch that allows you to perform analytics over your data.

A `query` (like `match` or `term`) is used to *find* documents. An `aggregation` is used to *calculate* summaries, statistics, or find patterns *within* those documents. It is the engine that powers every visualization in Kibana.

The aggregation framework is best understood by its similarity to SQL's `GROUP BY` and aggregate functions (like `COUNT`, `AVG`, `SUM`).

**Example SQL:**
`SELECT AVG(total), COUNT(*) FROM orders GROUP BY product.category;`

In Elasticsearch, this translates to:

  * `FROM orders`: The index (`orders*`).
  * `AVG(total)`, `COUNT(*)`: These are **Metric Aggregations**. They calculate values.
  * `GROUP BY product.category`: This is a **Bucket Aggregation**. It groups documents into "buckets."

Aggregations are run alongside queries. This allows you to *first* filter your dataset and *then* run analytics on the results.

**Best Practice: `size: 0`**
When running an aggregation, you are usually interested in the *analytics*, not the individual documents (`hits`). By adding `"size": 0"` to your query, you tell Elasticsearch, "Do not return any `hits`, just give me the aggregation results." This is much faster and saves network bandwidth.

All labs in this section will be run in **Management -\> Dev Tools**.

-----

### 2\. Metric Aggregations (Topic 23)

**Concept:** A **Metric Aggregation** calculates a single numeric value based on a set of documents. These are the "math" functions.

The most common types are:

  * **`sum`**: The sum of all values.
  * **`avg`**: The average of all values.
  * **`min`**: The minimum value.
  * **`max`**: The maximum value.
  * **`value_count`**: A count of the documents that have a value for a specific field.

#### 🚀 Hands-On: Sales Report Statistics

**Task:** Get a single report of total sales, average sale price, and the highest/lowest sale from the `orders` index.

**Action:**

```http
POST /orders*/_search
{
  "size": 0, 
  "aggs": {
    "total_sales_volume": {
      "sum": {
        "field": "total"
      }
    },
    "average_sale": {
      "avg": {
        "field": "total"
      }
    },
    "highest_sale": {
      "max": {
        "field": "total"
      }
    },
    "lowest_sale": {
      "min": {
        "field": "total"
      }
    },
    "number_of_orders": {
      "value_count": {
        "field": "id"
      }
    }
  }
}
```

**Result Analysis:**
The response will have no `hits` (because of `size: 0`), but it will have a large `aggregations` object. This object contains the results for each of your named aggregations:

```json
"aggregations": {
  "lowest_sale": { "value": 5.99 },
  "average_sale": { "value": 75.43 },
  "total_sales_volume": { "value": 150860.23 },
  "number_of_orders": { "value": 2000 },
  "highest_sale": { "value": 249.99 }
}
```

-----

### 3\. Bucket Aggregations (Topic 24)

**Concept:** A **Bucket Aggregation** does not calculate a number; it *creates groups* of documents (or "buckets"). This is the `GROUP BY` clause. Each document is evaluated and placed into one or more buckets based on its field values.

#### `terms` Aggregation

This is the most common bucket aggregation. It groups documents by the *exact values* in a `keyword` field.

**Task:** Find the "Top 5 most popular product brands" from the `orders` index.
**Action:**

```http
POST /orders*/_search
{
  "size": 0,
  "aggs": {
    "top_brands": {
      "terms": {
        "field": "product.brand",
        "size": 5 
      }
    }
  }
}
```

**Result Analysis:**
This will return a `buckets` array, where each bucket is a brand and includes the `doc_count` (how many orders for that brand).

```json
"aggregations": {
  "top_brands": {
    "buckets": [
      { "key": "Active Life", "doc_count": 500 },
      { "key": "Modern Comfort", "doc_count": 450 },
      ... 
    ]
  }
}
```

#### `range` Aggregation

This groups documents into *custom, user-defined* ranges.

**Task:** Group `orders` into price buckets: "cheap" (\<= $50), "medium" ($50-$150), and "expensive" (\>= $150).
**Action:**

```http
POST /orders*/_search
{
  "size": 0,
  "aggs": {
    "price_groups": {
      "range": {
        "field": "total",
        "ranges": [
          { "to": 50.0 }, 
          { "from": 50.0, "to": 150.0 },
          { "from": 150.0 }
        ]
      }
    }
  }
}
```

**Result Analysis:**
This returns a `buckets` array. Each bucket is one of your ranges, showing the count of documents that fall into it.

```json
"aggregations": {
  "price_groups": {
    "buckets": [
      { "key": "*-50.0", "to": 50.0, "doc_count": 800 },
      { "key": "50.0-150.0", "from": 50.0, "to": 150.0, "doc_count": 700 },
      { "key": "150.0-*", "from": 150.0, "doc_count": 500 }
    ]
  }
}
```

#### `histogram` Aggregation

This groups documents into *fixed-interval* ranges. This is for `number` fields.

**Task:** Group `access-logs` by response time, in 100ms intervals.
**Action:**

```http
POST /access-logs*/_search
{
  "size": 0,
  "aggs": {
    "response_time_buckets": {
      "histogram": {
        "field": "response_time_ms",
        "interval": 100
      }
    }
  }
}
```

**Result Analysis:**
This will return buckets like `0.0`, `100.0`, `200.0`, etc., each with the `doc_count` of logs that fall into that 100ms "bucket."

-----

### 4\. Date Histogram Aggregation (Topic 25)

**Concept:** This is the single most important aggregation for time-series data (like logs). It is a `histogram` that works on `date` fields. It powers *every* line chart in Kibana. It allows you to create buckets for "per-minute," "hourly," "daily," "monthly," etc.

#### 🚀 Hands-On: Errors Per Day

**Task:** Find all `500` errors in the `access-logs` and show the *count* of errors per day.
**Action:** This query combines a `query` (to find the logs) with an `aggregation` (to analyze them).

```http
POST /access-logs*/_search
{
  "size": 0,
  "query": {
    "term": {
      "http.response.status_code": 500 
    }
  },
  "aggs": {
    "errors_over_time": {
      "date_histogram": {
        "field": "@timestamp",
        "calendar_interval": "day" 
      }
    }
  }
}
```

**Result Analysis:**
The response will show a `buckets` array. Each bucket is a day, showing the `doc_count` of `500` errors that occurred on that day.

```json
"aggregations": {
  "errors_over_time": {
    "buckets": [
      { "key_as_string": "2020-01-15T00:00:00.000Z", "key": 1579046400000, "doc_count": 1 },
      { "key_as_string": "2020-02-01T00:00:00.000Z", "key": 1580515200000, "doc_count": 1 }
    ]
  }
}
```

-----

### 5\. Nested Aggregations (Topic 26)

**Concept:** This is how you combine buckets and metrics. A "nested" aggregation is simply a *sub-aggregation* placed *inside* another bucket aggregation.

This allows you to answer complex questions, like the SQL query:
`SELECT product.category, AVG(total) FROM orders GROUP BY product.category;`

#### 🚀 Hands-On: Average Sale Price by Category

**Task:** Find the average sale price (`avg(total)`) for *each* product category (`group by product.category`).

**Action:**

1.  **Outer Agg (Bucket):** `GROUP BY product.category`
2.  **Inner Agg (Metric):** `AVG(total)`

<!-- end list -->

```http
POST /orders*/_search
{
  "size": 0,
  "aggs": {
    "by_category": {
      "terms": {
        "field": "product.category"
      },
      "aggs": { 
        "average_sale": {
          "avg": {
            "field": "total"
          }
        }
      }
    }
  }
}
```

**Result Analysis:**
The result is a list of buckets (categories). *Inside* each bucket, you will see the calculated `average_sale` for *only* the documents in that bucket.

```json
"aggregations": {
  "by_category": {
    "buckets": [
      {
        "key": "Electronics",
        "doc_count": 350,
        "average_sale": {
          "value": 189.50
        }
      },
      {
        "key": "Clothing",
        "doc_count": 700,
        "average_sale": {
          "value": 45.20
        }
      },
      ...
    ]
  }
}
```

This demonstrates the core power of aggregations: first **bucketing** (grouping) your data, then running **metrics** (calculations) on those buckets.