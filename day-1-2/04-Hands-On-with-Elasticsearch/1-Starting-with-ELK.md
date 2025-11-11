# Beginner’s Elastic Stack

---

## 🚀 Step 1: Getting Cluster and Node Information

All the commands below should be executed directly inside the **Kibana Dev Tools Console**.

### ✅ Get Cluster Health

```http
GET _cluster/health
```

**Expected output:**
Displays the cluster’s health (`green`, `yellow`, or `red`), number of nodes, shards, and status.

### ✅ Get Node Stats

```http
GET _nodes/stats
```

**Expected output:**
Detailed statistics about each node (CPU, JVM, HTTP, indices, etc.).

💡 *Tip:* You can use the simplified API below for just basic node info:

```http
GET _nodes
```

---

## 🏗️ Step 2: Creating an Index (C — Create)

### Create an Index

```http
PUT favorite_candy
```

**Expected Response:**

```json
{
  "acknowledged": true,
  "shards_acknowledged": true,
  "index": "favorite_candy"
}
```

💡 *Note:* In Elasticsearch 9.x, you can also define **index settings and mappings** while creating:

```http
PUT favorite_candy
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "first_name": { "type": "keyword" },
      "candy": { "type": "text" }
    }
  }
}
```

---

## 🍭 Step 3: Indexing Documents

You can use either **POST** (auto-ID) or **PUT** (manual ID).

### Using `POST` (Auto ID)

```http
POST favorite_candy/_doc
{
  "first_name": "Lisa",
  "candy": "Sour Skittles"
}
```

### Using `PUT` (Custom ID)

```http
PUT favorite_candy/_doc/1
{
  "first_name": "John",
  "candy": "Starburst"
}
```

### Using `_create` to Avoid Overwrite

```http
PUT favorite_candy/_create/1
{
  "first_name": "Finn",
  "candy": "Jolly Ranchers"
}
```

**Expected Output (on conflict):**

```json
{
  "error": {
    "type": "version_conflict_engine_exception",
    "reason": "[_doc][1]: version conflict, document already exists"
  },
  "status": 409
}
```

---

## 🔍 Step 4: Reading Documents (R — Read)

### Get a Document by ID

```http
GET favorite_candy/_doc/1
```

**Expected Output:**
Returns full document content with metadata such as `_index`, `_id`, and `_version`.

### Get All Documents in an Index

```http
GET favorite_candy/_search
{
  "query": {
    "match_all": {}
  }
}
```

💡 *Pro Tip:* Add `"size": 100` if you want to see more results.

---

## ✏️ Step 5: Updating Documents (U — Update)

### Update Specific Fields

```http
POST favorite_candy/_update/1
{
  "doc": {
    "candy": "M&M's"
  }
}
```

### Add New Fields Dynamically

```http
POST favorite_candy/_update/1
{
  "doc": {
    "rating": 5,
    "sweet_level": "high"
  }
}
```

### Replace Entire Document (Overwriting)

```http
PUT favorite_candy/_doc/1
{
  "first_name": "John",
  "candy": "KitKat",
  "rating": 4
}
```

---

## 🗑️ Step 6: Deleting Documents (D — Delete)

### Delete a Specific Document

```http
DELETE favorite_candy/_doc/1
```

### Delete an Entire Index

```http
DELETE favorite_candy
```

💡 *Caution:* This removes all documents and cannot be undone.

---

## 🧩 Step 7: Hands-On Practice Assignment

Now that you know the fundamentals, complete the following challenge in your Kibana Dev Tools Console:

### 🧭 Assignment

1. **Create an index** named `destinations`.

   ```http
   PUT destinations
   ```

2. **Index five dream travel destinations** (name + country). Example:

   ```http
   POST destinations/_doc
   {
     "destination": "Bali",
     "country": "Indonesia"
   }

   POST destinations/_doc
   {
     "destination": "Kyoto",
     "country": "Japan"
   }

   POST destinations/_doc
   {
     "destination": "Santorini",
     "country": "Greece"
   }

   POST destinations/_doc
   {
     "destination": "Paris",
     "country": "France"
   }

   POST destinations/_doc
   {
     "destination": "Banff",
     "country": "Canada"
   }
   ```

3. **Read all documents**:

   ```http
   GET destinations/_search
   {
     "query": {
       "match_all": {}
     }
   }
   ```

4. **Update one document**:

   ```http
   POST destinations/_update/1
   {
     "doc": {
       "country": "Republic of Indonesia"
     }
   }
   ```

5. **Verify the updated record**:

   ```http
   GET destinations/_doc/1
   ```

6. **Delete one document**:

   ```http
   DELETE destinations/_doc/3
   ```

7. **Verify the remaining documents**:

   ```http
   GET destinations/_search
   {
     "query": {
       "match_all": {}
     }
   }
   ```

---

## Useful Commands for Exploration

### Get List of All Indices

```http
GET _cat/indices?v
```

### Get Document Count in an Index

```http
GET destinations/_count
```

### Get Index Mapping

```http
GET destinations/_mapping
```

### Refresh Index (Force Visibility of Recent Writes)

```http
POST destinations/_refresh
```

