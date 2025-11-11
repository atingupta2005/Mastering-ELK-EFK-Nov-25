# 🧩 Hands-on Exercises on Kibana — Weblogs Data and Common Operations

## 30️⃣ Loading Sample Data (Weblogs)

> Kibana provides built-in sample datasets (like “Sample Web Logs”) that help in exploring dashboards and search features.

### **Steps (through Kibana GUI)**

1. Navigate to **Home → Try sample data → Add Sample Web Logs**
2. This loads the index **`kibana_sample_data_logs`** with about **14,000 log documents**.
3. Confirm in **Stack Management → Index Management** that the index exists.

---

### ✅ **Alternate Method: Load Your Own Logs Using DevTools**

If you have a custom logs JSON file, you can create and index it manually:

```bash
# Create an index for custom web logs
PUT weblogs_custom
{
  "mappings": {
    "properties": {
      "timestamp": {"type": "date"},
      "ip": {"type": "ip"},
      "extension": {"type": "keyword"},
      "response": {"type": "integer"},
      "geo": {
        "properties": {
          "src": {"type": "keyword"},
          "dest": {"type": "keyword"},
          "coordinates": {"type": "geo_point"}
        }
      },
      "url": {"type": "text"},
      "bytes": {"type": "long"},
      "tags": {"type": "keyword"}
    }
  }
}
```

```bash
# Index a few sample log documents
POST weblogs_custom/_bulk
{"index":{}}
{"timestamp":"2025-11-11T09:25:00Z","ip":"192.168.1.10","extension":"jpg","response":200,"geo":{"src":"IN","dest":"US","coordinates":{"lat":28.6139,"lon":77.2090}},"url":"/images/home.jpg","bytes":15328,"tags":["photo","cdn"]}
{"index":{}}
{"timestamp":"2025-11-11T09:27:00Z","ip":"10.10.10.20","extension":"html","response":404,"geo":{"src":"FR","dest":"IN","coordinates":{"lat":48.8566,"lon":2.3522}},"url":"/index.html","bytes":512,"tags":["error","frontend"]}
```

---

## 31️⃣ Creating an Index Pattern in Kibana

> You need an index pattern to explore data in **Discover**, **Visualize**, or **Dashboard**.

### **Steps**

1. Go to **Stack Management → Data Views (Index Patterns)**
2. Click **“Create Data View”**
3. Enter `weblogs*` as the pattern (to include both `kibana_sample_data_logs` and `weblogs_custom`)
4. Choose the **timestamp field** (`@timestamp` or `timestamp`)
5. Save the Data View.

---

## 32️⃣ Filtering Documents in Kibana (Discover View)

### 🧭 **Option 1: Using Filter Controls**

* In **Discover**, select the index pattern `weblogs*`
* Use the filter bar:

  * Add filter → `response` → `is` → `404`
  * Add filter → `geo.src` → `is one of` → `IN`, `US`
* You’ll now see filtered log results.

### 🧩 **Option 2: Using KQL (Kibana Query Language)**

```kql
response:200 AND extension:"jpg" AND geo.src:"IN"
```

### 🧩 **Option 3: Lucene Query (if KQL disabled)**

```lucene
response:200 AND extension:jpg AND geo.src:IN
```

### 🧩 **Option 4: Time Range Filters**

In the top-right **time picker**, filter logs for last 15 minutes or a custom date range.

---

## 33️⃣ Export Search Results to CSV

> Exporting to CSV is very handy for sharing results or offline analysis.

### **Steps**

1. Go to **Discover → Select your Data View**
2. Apply filters and KQL as needed
3. Click the **“Share” → “CSV Reports”** option
4. Choose **“Generate CSV”**

   * Optionally, select “All fields” or “Displayed columns only”
5. Kibana will generate and show a **download link** in the **Stack Management → Reporting → Reports** section.

> 🧠 *Tip:* You can also schedule automatic CSV exports using **Reporting Jobs** in Kibana.

---

## 34️⃣ Troubleshooting Common Startup Errors

> These are some of the most frequent issues students or new ELK users face during hands-on sessions.

---

### ⚠️ **Error 1: Kibana or Elasticsearch Not Starting**

**Symptom:** Service fails with `Address already in use` or `port 5601/9200 is busy`.

**Fix:**

```bash
# Check which process is using the port
sudo lsof -i :5601
sudo lsof -i :9200

# Kill the process or change port in config
sudo kill -9 <pid>
```

Or modify ports in:

* `elasticsearch.yml` → `http.port: 9201`
* `kibana.yml` → `server.port: 5602`

---

### ⚠️ **Error 2: “Unable to connect to Elasticsearch”**

**Reason:** Kibana cannot reach Elasticsearch (wrong URL or service down).

**Fix in kibana.yml:**

```yaml
elasticsearch.hosts: ["http://localhost:9200"]
```

Then restart:

```bash
sudo systemctl restart kibana
```

---

### ⚠️ **Error 3: Memory or JVM Heap Issue**

**Symptom:** Elasticsearch fails with “OutOfMemoryError: Java heap space”

**Fix:**
Edit `jvm.options`:

```bash
-Xms1g
-Xmx1g
```

Set both values equal and restart Elasticsearch.

---

### ⚠️ **Error 4: Index Creation or Mapping Conflict**

**Symptom:** “mapper_parsing_exception” when loading data.

**Fix:**

1. Delete the conflicting index:

   ```bash
   DELETE weblogs_custom
   ```
2. Recreate with correct mappings (see step 30 above).

---

### ⚠️ **Error 5: CSV Export Fails or Missing Data**

**Reason:** Reporting feature disabled or too large dataset.

**Fix:**

* Enable reporting in Kibana config:

  ```yaml
  xpack.reporting.enabled: true
  ```
* Use smaller time ranges or limit displayed columns.

