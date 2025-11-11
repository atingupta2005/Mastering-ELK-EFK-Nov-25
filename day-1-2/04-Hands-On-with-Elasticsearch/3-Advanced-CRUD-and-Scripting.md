# 🎬 Hands-On Workshop: Advanced CRUD, Bulk, and Scripting
## 🧱 1. Indexing Documents

### 🎬 Index a Movie Document with an Identifier

```json
PUT movies/_doc/1
{
  "title": "The Godfather",
  "synopsis": "The aging patriarch of an organized crime dynasty transfers control of his empire to his reluctant son"
}
```

✅ **Explanation:**

* `PUT` creates the document with a specific ID.
* `_doc` is the default document type.

---

### ✍️ Post a Movie Review Without Specifying an ID

```json
POST movies_reviews/_doc
{
  "movie": "The Godfather",
  "user": "Peter Piper",
  "rating": 4.5,
  "remarks": "The movie started with a classic touch and powerful dialogues."
}
```

✅ **Explanation:**
Elasticsearch auto-generates the ID when you use `POST`.

---

### ⚠️ Overriding Existing Movie Document

```json
PUT movies/_doc/1
{
  "tweet": "Elasticsearch in Action 2e is here!"
}
```

✅ **Note:**
This will **overwrite** the existing movie document since ID `1` already exists.

---

## 🚫 2. Preventing Document Overwrites Using `_create`

```json
PUT movies/_create/100
{
  "title": "Mission: Impossible",
  "director": "Brian De Palma"
}
```

### Attempt to Override Existing ID

```json
PUT movies/_create/100
{
  "tweet": "A movie with popcorn is so cool!"
}
```

✅ **Expected Result:**
This should **fail** with a `409 conflict` error, protecting the existing document.

---

## ⚙️ 3. Cluster Configuration

### Disable Auto Index Creation

```json
PUT _cluster/settings
{
  "persistent": {
    "action.auto_create_index": "false"
  }
}
```

✅ **Why:** Prevents accidental creation of indices due to typos in index names.

---

## 🧩 4. Multi-Document Operations

### Get Multiple Documents Using `_mget`

```json
GET movies/_mget
{
  "ids": ["1", "12", "19", "34"]
}
```

---

### Fetch Documents from Multiple Indices

```json
GET _mget
{
  "docs": [
    { "_index": "classic_movies", "_id": 11 },
    { "_index": "international_movies", "_id": 22 },
    { "_index": "top100_movies", "_id": 33 }
  ]
}
```

---

## 🕵️ 5. Querying by IDs

```json
GET classic_movies/_search
{
  "query": {
    "ids": {
      "values": [1, 2, 3, 4]
    }
  }
}
```

✅ Useful when you need to fetch multiple documents directly by their IDs.

---

## ✏️ 6. Updating Documents

### Add New Fields to an Existing Document

```json
POST movies/_update/1
{
  "doc": {
    "actors": ["Marlon Brando", "Al Pacino", "James Caan"],
    "director": "Francis Ford Coppola"
  }
}
```

---

### Modify an Existing Field

```json
POST movies/_update/1
{
  "doc": {
    "title": "The Godfather (Original)"
  }
}
```

---

### Append Values to Array Fields

```json
POST movies/_update/1
{
  "doc": {
    "actors": ["Marlon Brando", "Al Pacino", "James Caan", "Robert Duvall"]
  }
}
```

---

## 💡 7. Scripted Updates

### Add New Actor via Script

```json
POST movies/_update/1
{
  "script": {
    "source": "ctx._source.actors.add('Diane Keaton')"
  }
}
```

---

### Remove Actor Using Script

```json
POST movies/_update/1
{
  "script": {
    "source": "ctx._source.actors.remove(ctx._source.actors.indexOf('Diane Keaton'))"
  }
}
```

---

### Add or Remove Fields Dynamically

```json
POST movies/_update/1
{
  "script": {
    "source": "ctx._source.imdb_user_rating = 9.2"
  }
}
```

Remove an existing field:

```json
POST movies/_update/1
{
  "script": {
    "source": "ctx._source.remove('metacritic_rating')"
  }
}
```

---

### Add Multiple Fields in One Go

```json
POST movies/_update/1
{
  "script": {
    "source": """
    ctx._source.runtime_in_minutes = 175;
    ctx._source.metacritic_rating = 100;
    ctx._source.tomatometer = 97;
    ctx._source.boxoffice_gross_in_millions = 134.8;
    """
  }
}
```

---

### Conditional Script Update

```json
POST movies/_update/1
{
  "script": {
    "source": """
    if (ctx._source.boxoffice_gross_in_millions > 125) {
      ctx._source.blockbuster = true;
    } else {
      ctx._source.blockbuster = false;
    }
    """
  }
}
```

---

### Parameterized Script

```json
POST movies/_update/1
{
  "script": {
    "source": """
    if (ctx._source.boxoffice_gross_in_millions > params.gross_threshold) {
      ctx._source.blockbuster = true;
    } else {
      ctx._source.blockbuster = false;
    }
    """,
    "params": {
      "gross_threshold": 150
    }
  }
}
```

---

## 🔁 8. Upsert Operations

```json
POST movies/_update/5
{
  "script": {
    "source": "ctx._source.gross_earnings = '357.1m'"
  },
  "upsert": {
    "title": "Top Gun",
    "gross_earnings": "357.5m"
  }
}
```

---

## 🛠️ 9. Delete Operations

### Delete by ID

```json
DELETE movies/_doc/1
```

---

### Delete by Query

Add sample docs first:

```json
PUT movies/_doc/101
{
  "title": "Jaws",
  "director": "Steven Spielberg",
  "gross_earnings_in_millions": 355
}
PUT movies/_doc/102
{
  "title": "Jaws II",
  "director": "Steven Spielberg",
  "gross_earnings_in_millions": 375
}
PUT movies/_doc/103
{
  "title": "Jaws III",
  "director": "Steven Spielberg",
  "gross_earnings_in_millions": 300
}
```

Now delete by range query:

```json
POST movies/_delete_by_query
{
  "query": {
    "range": {
      "gross_earnings_in_millions": { "gt": 350, "lt": 400 }
    }
  }
}
```

---

## 🧮 10. Bulk Operations

### Basic Bulk Insert

```json
POST _bulk
{"index": {"_index": "movies", "_id": "100"}}
{"title": "Mission Impossible", "release_date": "1996-07-05"}
```

---

### Bulk Insert Multiple Movies

```json
POST movies/_bulk
{"index": {}}
{"title": "Mission Impossible"}
{"index": {}}
{"title": "Mission Impossible II"}
{"index": {}}
{"title": "Mission Impossible III"}
{"index": {}}
{"title": "Mission Impossible - Ghost Protocol"}
```

---

### Bulk Update Example

```json
POST _bulk
{"update": {"_index": "movies", "_id": "200"}}
{"doc": {"director": "Brett Ratner", "actors": ["Jackie Chan", "Chris Tucker"]}}
```

---

### Bulk with Mixed Entities (Advanced)

```json
POST _bulk
{"index": {"_index": "books"}}
{"title": "Elasticsearch in Action"}
{"create": {"_index": "flights", "_id": "101"}}
{"title": "London to Bucharest"}
{"index": {"_index": "pets"}}
{"name": "Milly", "age_months": 18}
{"delete": {"_index": "movies", "_id": "101"}}
{"update": {"_index": "movies", "_id": "1"}}
{"doc": {"title": "The Godfather (Original)"}}
```
