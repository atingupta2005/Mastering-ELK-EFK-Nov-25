## 📅 Day 6: Query DSL (Beginner-Friendly)

### Introduction: KQL vs. Query DSL

This module moves from the Kibana-specific **KQL** (the text string you type in the Discover search bar) to the underlying, powerful **Query DSL (Domain Specific Language)**.

The Query DSL is the *actual query language* of Elasticsearch. It is a rich, JSON-based language that you use in **Dev Tools** or in your own applications. When you use KQL or Filter Pills in KibANA, Kibana is just a "query builder" that *translates* your clicks into this JSON Query DSL in the background.

All examples in this section are run from **Management -\> Dev Tools**.

-----

### 1\. `Match` Query Example (Topic 17)

**Concept:** The `match` query is the standard query for doing **full-text search** on `text` fields.

  * **What it does:** It takes your search input (e.g., "Login Failed"), runs it through the *same analyzer* as the field (e.g., `lowercase`, `standard tokenizer`), and then finds documents that match *any* of the resulting tokens (e.g., `[login]`, `[failed]`).
  * **Key Feature:** It calculates a **`_score`** (relevancy score) for each document.
  * **Use on:** `text` fields (like `message` or `url.original.text`).

#### 🚀 Hands-On: `match` Query

**Task:** Search the `access-logs*` index for all logs containing the words "File not found" in the `message` field.

```http
POST /access-logs*/_search
{
  "query": {
    "match": {
      "message": "File not found"
    }
  }
}
```

**Result Analysis:** This query is analyzed into the tokens `[file]`, `[not]`, `[found]`. It will return all logs that contain *any* of those words, ranking the ones that contain *all* of them higher. You will see `recap-004` ("File not found..."), `recap-014`, and `recap-015`.

-----

### 2\. `Term` Query Example (Topic 18)

**Concept:** The `term` query is the standard query for finding an **exact, un-analyzed value**.

  * **What it does:** It looks for the *exact token* you provide, with no analysis.
  * **Use on:** `keyword`, `number`, `date`, `boolean`, or `ip` fields.
  * **This is a critical concept:** You do *not* use a `term` query on a `text` field.

#### 🚀 Hands-On 1: `term` on a `keyword` (Correct Usage)

**Task:** Find all logs from the `frontend-web` service.

```http
POST /access-logs*/_search
{
  "query": {
    "term": {
      "service_name": "frontend-web"
    }
  }
}
```

*Result: This works perfectly and is very fast. It finds all documents where the `service_name` field is exactly "frontend-web".*

#### 🚀 Hands-On 2: `term` on a `long` (Correct Usage)

**Task:** Find all `404` errors.

```http
POST /access-logs*/_search
{
  "query": {
    "term": {
      "http.response.status_code": 404
    }
  }
}
```

*Result: This works perfectly. Note that `404` is a number, not a string (no quotes), because the field type is `long`.*

#### 🚀 Hands-On 3: `term` on a `text` (The "Why it Fails" Example)

**Task:** Find all logs with the message "File not found".

```http
POST /access-logs*/_search
{
  "query": {
    "term": {
      "message": "File not found" 
    }
  }
}
```

**Result: 0 hits.**
**Why?** The `message` field is `text`. It was analyzed and stored as `[file]`, `[not]`, `[found]`. The `term` query searched for the *single, exact token* "File not found" (with spaces and capitalization), which does not exist in the index. **This demonstrates why you *must* use `match` for `text` fields.**

-----

### 3\. `Range` Query (Date/Numeric) (Topic 19)

**Concept:** The `range` query finds documents with values that fall within a specified range. It uses the operators `gt` (greater than), `gte` (greater than or equal to), `lt` (less than), and `lte` (less than or equal to).

#### 🚀 Hands-On 1: `range` on a `long` (Numeric)

**Task:** Find all `access-logs` where the response body was large (e.g., between 5,000 and 15,000 bytes).

```http
POST /access-logs*/_search
{
  "query": {
    "range": {
      "http.response.body.bytes": {
        "gte": 5000,
        "lt": 15000
      }
    }
  }
}
```

*Result: This will find logs like `recap-003` (10500 bytes), but will exclude logs that are too large or too small.*

#### 🚀 Hands-On 2: `range` on a `float` (Numeric)

**Task:** Find all `orders` where the `total` sale was between $50 and $100.

```http
POST /orders*/_search
{
  "query": {
    "range": {
      "total": {
        "gte": 50.00,
        "lte": 100.00
      }
    }
  }
}
```

#### 🚀 Hands-On 3: `range` on a `date`

**Task:** Find all `access-logs` from a specific 1-minute window.

```http
POST /access-logs*/_search
{
  "query": {
    "range": {
      "@timestamp": {
        "gte": "2020-01-15T11:00:00Z", 
        "lte": "2020-01-15T11:01:00Z",
        "format": "strict_date_optional_time"
      }
    }
  }
}
```

*(Note: Adjust the date to match your data. This is the JSON equivalent of using the Kibana Time Picker.)*

-----

### 4\. `Boolean` Query (AND/OR/NOT) (Topic 20)

**Concept:** The `bool` query is the most important query. It is a "container" query that lets you combine other queries (like `match`, `term`, or `range`) using logical clauses.

  * `must`: **(AND)** The clause *must* match. Contributes to the `_score`.
  * `should`: **(OR)** One or more of these clauses *should* match. Contributes to the `_score`.
  * `must_not`: **(NOT)** The clause *must not* match. Does not contribute to `_score`.
  * `filter`: **(AND)** The clause *must* match, but in a "filter context." (See next topic).

#### 🚀 Hands-On 1: `bool` with `must` (AND)

**Task:** Find all `orders` from the "Electronics" category (adjust value) AND from a "male" customer.

```http
POST /orders*/_search
{
  "query": {
    "bool": {
      "must": [
        { "term": { "product.category": "Electronics" } },
        { "term": { "customer.gender": "male" } }
      ]
    }
  }
}
```

#### 🚀 Hands-On 2: `bool` with `should` (OR)

**Task:** Find all `access-logs` with a status code of `500` OR `503`.

```http
POST /access-logs*/_search
{
  "query": {
    "bool": {
      "should": [
        { "term": { "http.response.status_code": 500 } },
        { "term": { "http.response.status_code": 503 } }
      ],
      "minimum_should_match": 1 
    }
  }
}
```

*Note: `minimum_should_match: 1` is crucial; it means "at least one of the `should` clauses must be true."*

#### 🚀 Hands-On 3: `bool` with `must_not` (NOT)

**Task:** Find all `access-logs` from `Chrome` users that were *NOT* `200` (OK).

```http
POST /access-logs*/_search
{
  "query": {
    "bool": {
      "must": [
        { "term": { "user_agent.name": "Chrome" } }
      ],
      "must_not": [
        { "term": { "http.response.status_code": 200 } }
      ]
    }
  }
}
```

-----

### 5\. Filtering vs. Querying Difference (Topic 21)

This is the most important performance concept in Elasticsearch.

When you use a `bool` query, you can place your clauses in either a `must` or a `filter` block. Both act as an `AND` operator, but they behave *very* differently.

  * **Query Context (`must` or `should` clauses):**

      * **The Question:** "How *relevant* is this document to the search?"
      * **The Work:** It performs a "scoring" search. It calculates a `_score` (relevancy) for every matching document. This requires CPU.
      * **Use For:** Full-text searches (e.g., `match` queries on `text` fields like `message`).

  * **Filter Context (`filter` or `must_not` clauses):**

      * **The Question:** "Does this document match? (Yes/No)"
      * **The Work:** It performs an "exact" search. It does **not** calculate a `_score`. It is a simple "Yes/No" check.
      * **The "Magic":** Because it's a simple Yes/No check, Elasticsearch can **cache** the results. The *second* time you run this query, the answer is returned instantly from memory.
      * **Use For:** All structured data (e.g., `term` or `range` queries on `keyword`, `number`, `date`, or `ip` fields).

**Rule of Thumb: Filter everything you can, query only when you must.**

#### 🚀 Hands-On: The "Professional" `bool` Query

**Task:** Find all `access-logs` that:

1.  Contain the `text` "failed" (This requires *querying*).
2.  Are from the `service_name` "payment-service" (This should be *filtered*).
3.  Have a `status_code` of `500` (This should be *filtered*).

**The Correct, Performant Query:**

```http
POST /access-logs*/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "message": "failed" } }  <-- The "query" part (slower, scoring)
      ],
      "filter": [
        { "term": { "service_name": "payment-service" } },  <-- The "filter" part (fast, cached)
        { "term": { "http.response.status_code": 500 } }   <-- The "filter" part (fast, cached)
      ]
    }
  }
}
```

**Result:** This is the most efficient query. Elasticsearch will *first* use the fast, cached filters to find all `500` errors from the `payment-service`. Then, *only* on that tiny subset of documents, it will run the "slower" `match` query for "failed".