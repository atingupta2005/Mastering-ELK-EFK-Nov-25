## 🎬 **Deleting Documents from an Index (`movies`)**

We’ll use a sample index:

```bash
Index: movies
```

---

### 🧩 **1️⃣ Delete a Single Document by ID**

This is the most common and direct way to delete a document.

```json
DELETE movies/_doc/1
```

#### ✅ What it does:

* Deletes the document with `_id = 1` from the `movies` index.
* Returns a response with `result: "deleted"` if successful.

#### 🧾 Example Response:

```json
{
  "_index": "movies",
  "_id": "1",
  "_version": 2,
  "result": "deleted",
  "_shards": { "total": 2, "successful": 1, "failed": 0 }
}
```

---

### 🧩 **2️⃣ Delete by Query (Conditional Deletion)**

You can delete documents **matching specific criteria** using the `_delete_by_query` API.

```json
POST movies/_delete_by_query
{
  "query": {
    "match": {
      "genre": "Action"
    }
  }
}
```

#### ✅ What it does:

Deletes **all documents** where the `genre` field contains `"Action"`.

#### 💡 Tip:

Always **preview first** with `_search` before deleting:

```json
GET movies/_search
{
  "query": {
    "match": { "genre": "Action" }
  }
}
```

---

### 🧩 **3️⃣ Delete by Range (e.g., old movies)**

You can use range queries to delete data by year, rating, or timestamp.

```json
POST movies/_delete_by_query
{
  "query": {
    "range": {
      "release_year": {
        "lt": 1980
      }
    }
  }
}
```

#### ✅ What it does:

Deletes all movies released **before 1980**.

---

### 🧩 **4️⃣ Delete by Multiple Conditions**

Use a `bool` query to combine filters (e.g., genre + rating).

```json
POST movies/_delete_by_query
{
  "query": {
    "bool": {
      "must": [
        { "match": { "genre": "Comedy" } },
        { "range": { "rating": { "lt": 5 } } }
      ]
    }
  }
}
```

#### ✅ What it does:

Deletes all movies that are:

* Genre = Comedy
* Rating < 5

---

### 🧩 **5️⃣ Delete All Documents (but keep the index)**

If you want to **clear all data** without removing the index mapping:

```json
POST movies/_delete_by_query
{
  "query": {
    "match_all": {}
  }
}
```

#### ✅ What it does:

Deletes every document but keeps:

* Index structure
* Mappings
* Settings

This is great for **resetting training data**.

---

### 🧩 **6️⃣ Delete the Entire Index**

If you want to completely remove the index (including mapping and data):

```json
DELETE movies
```

#### ✅ What it does:

* Permanently removes the entire index `movies`.
* Use this with caution! ⚠️

---

### 🧩 **7️⃣ Delete Using IDs in Bulk**

If you want to delete multiple specific documents by ID:

```json
POST _bulk
{ "delete": { "_index": "movies", "_id": "1" } }
{ "delete": { "_index": "movies", "_id": "3" } }
{ "delete": { "_index": "movies", "_id": "5" } }
```

#### ✅ What it does:

Deletes all the specified documents in one request — **faster and more efficient** than multiple DELETE calls.

---

### 🧩 **8️⃣ Delete Using Script (Advanced)**

If you want fine-grained control, you can use the `_update_by_query` API with a script to check conditions and delete selectively.

```json
POST movies/_update_by_query
{
  "script": {
    "source": "if (ctx._source.rating < 4) { ctx.op = 'delete' }"
  },
  "query": {
    "match_all": {}
  }
}
```

#### ✅ What it does:

Deletes all movies with a `rating` lower than 4.

---

## 🔍 **9️⃣ Verify Deletions**

After any delete operation, confirm results:

```json
GET movies/_count
```

or

```json
GET movies/_search
{
  "query": {
    "match_all": {}
  }
}
```
