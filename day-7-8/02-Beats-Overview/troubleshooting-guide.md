Below is a **complete, clean, organized troubleshooting guide** for Filebeat + Elasticsearch 9.x

---

# ✅ **FILEBEAT 9.x TROUBLESHOOTING GUIDE**

### *Covers Filebeat → Elasticsearch Data Stream Ingestion Issues*

### *Based on actual working session & real commands executed*

---

# 🔹 **1. Verify Filebeat Installation**

### Check version

```
filebeat version
```

### Check service status

```
sudo systemctl status filebeat
```

If Filebeat is failed / restarting → config contains errors.

---

# 🔹 **2. Validate Filebeat Configuration**

### Open filebeat.yml

```
sudo nano /etc/filebeat/filebeat.yml
```

### Test config syntax (VERY IMPORTANT)

```
sudo filebeat test config
```

Expected:

```
Config OK
```

If not OK → fix indentation or YAML syntax errors.

---

# 🔹 **3. Restart Filebeat Properly**

Always run:

```
sudo systemctl daemon-reload
sudo systemctl restart filebeat
sudo systemctl status filebeat
```

Use `daemon-reload` after modifying systemd unit files or environment.

---

# 🔹 **4. Check Filebeat Logs (Main Debug Step)**

### Follow logs in real-time

```
sudo journalctl -u filebeat -f
```

Look for messages like:

#### Success indicators:

```
Input 'filestream' starting
Harvester started
Connection to Elasticsearch established
events: added 500
events: acked 500
```

#### Problems:

```
file is too small to be ingested
Exiting: data path already locked by another beat
error loading config file
authentication error (401)
```

---

# 🔹 **5. Fixing “file is too small to be ingested”**

This warning:

```
file is too small to be ingested, needs 1024 bytes
```

Occurs **even if your file is 100 KB**, because Filebeat 9.x filestream:

* Reads only first 1024 bytes for fingerprint
* If the file changed (append only) but fingerprint same → ignored
* Deletes old file reference from registry only after rollover

### ✔ FIX — Force Filebeat to rescan EVERYTHING

```
sudo systemctl stop filebeat
sudo rm -rf /var/lib/filebeat/registry
```

### ✔ FIX — Set smaller fingerprint length (recommended)

```yaml
prospector.scanner.fingerprint.length: 64
prospector.scanner.fingerprint.offset: 0
```

### ✔ FIX — Use exact file paths (NOT wildcards)

```yaml
paths:
  - /var/log/myapp/app.log
  - /var/log/myapp/app.json
```

---

# 🔹 **6. Fixing “data path already locked by another beat”**

This happens when running both:

* Filebeat service
* `filebeat -e` in foreground

Fix:

```
sudo systemctl stop filebeat
sudo rm -f /var/lib/filebeat/filebeat.lock
```

Then:

```
sudo filebeat -e
```

or restart service.

---

# 🔹 **7. Elasticsearch Connectivity Troubleshooting**

### Test Elasticsearch output from Filebeat

```
sudo filebeat test output
```

Possible results:

### ❌ Authentication issue:

```
missing authentication credentials
```

Fix: Pass username/password in filebeat.yml

```yaml
output.elasticsearch:
  hosts: ["http://10.0.18.1:9200"]
  username: "atin.gupta"
  password: "2313634"
```

### ❌ Connection refused:

→ Elasticsearch is not running or wrong IP.

### ✔ Successful:

```
connection to Elasticsearch established
```

---

# 🔹 **8. Check Indices in Elasticsearch**

### IMPORTANT: Must authenticate

```
curl -u atin.gupta:2313634 -X GET "http://10.0.18.1:9200/_cat/indices?v"
```

---

# 🔹 **9. When You See ONLY .ds-* Indices (Data Streams)**

Filebeat 9.x uses **data streams by default**.

Your backing index will be like:

```
.ds-filebeat-9.2.1-000001
```

### This is perfectly OK.

To view hidden indices:

```
curl -u user:pass -X GET "http://10.0.18.1:9200/_cat/indices?include_hidden=true&v"
```

### To view data streams:

```
curl -u user:pass -X GET "http://10.0.18.1:9200/_cat/data_stream?v"
```

---

# 🔹 **10. Creating Data View in Kibana for .ds Data Streams**

**DO NOT** create a dataview using `.ds-filebeat-*`.

Instead use:

```
filebeat-*
```

### Steps:

1. Kibana → Discover
2. Create Data View
3. Name:

   ```
   filebeat-*
   ```
4. Time field:

   ```
   @timestamp
   ```

---

# 🔹 **11. Debugging Filebeat Not Reading Log Files**

### Check if file exists & grows

```
ls -alh /var/log/myapp
```

### Watch logs

```
tail -f /var/log/myapp/app.log
```

### Ensure permissions

```
sudo chmod 666 /var/log/myapp/app.log
sudo chmod 666 /var/log/myapp/app.json
```

---

# 🔹 **12. Fixing Script Writing Not Working**

When shell prints logs on screen instead of redirecting to file:

### Reason:

* Pasted script had invisible characters
* Redirection (`>>`) broken
* Script not executed in root shell

### Fix:

Create script file:

```
nano /root/gen.sh
```

Paste clean script and run:

```
bash /root/gen.sh
```

### Alternate fix (works even without root):

```
echo "text" | sudo tee -a /var/log/myapp/app.log
```

---

# 🔹 **13. Log Generator Script (Working Version)**

```
while true; do
  LEVEL=$(shuf -e INFO WARN ERROR DEBUG TRACE -n 1)
  USER=$(shuf -e admin user1 user2 guest api-service backend-service -n 1)
  ACTION=$(shuf -e login logout update delete create read write access modify execute -n 1)
  IP="192.168.$((RANDOM%255)).$((RANDOM%255))"
  ID=$((RANDOM % 100000))
  TS="$(date '+%Y-%m-%d %H:%M:%S')"
  TS_JSON="$(date '+%Y-%m-%dT%H:%M:%S')"

  echo "$TS $LEVEL user=$USER action=$ACTION ip=$IP record_id=$ID" | sudo tee -a /var/log/myapp/app.log > /dev/null
  echo "{\"timestamp\":\"$TS_JSON\",\"level\":\"$LEVEL\",\"user\":\"$USER\",\"action\":\"$ACTION\",\"ip\":\"$IP\",\"record_id\":$ID}" | sudo tee -a /var/log/myapp/app.json > /dev/null

  for i in {1..10}; do
    LEVEL2=$(shuf -e INFO WARN ERROR DEBUG -n 1)
    echo "$TS $LEVEL2 burst_log=true id=$RANDOM message=\"Auto-generated log entry\"" | sudo tee -a /var/log/myapp/app.log > /dev/null
  done

  sleep 1
done
```

---

# 🔹 **14. Full Command History (Cleaned & Explained)**

### Installation & config

```
filebeat version
sudo systemctl status filebeat
sudo nano /etc/filebeat/filebeat.yml
sudo mkdir -p /var/log/myapp
sudo touch /var/log/myapp/app.log
```

### Debugging Elasticsearch indexing

```
curl -u atin.gupta:2313634 -X GET "http://10.0.18.1:9200/_cat/indices?v"
```

### Debugging Filebeat runtime

```
sudo journalctl -u filebeat -f
sudo filebeat test output
sudo filebeat test config
```

### Resetting registry

```
sudo systemctl stop filebeat
sudo rm -rf /var/lib/filebeat/registry
sudo systemctl start filebeat
```

### Debugging lock issue

```
sudo rm -f /var/lib/filebeat/filebeat.lock
```
