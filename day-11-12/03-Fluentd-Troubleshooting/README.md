# Day 11 – Fluentd Troubleshooting (Elasticsearch 9.x | CentOS)

---

## 1. Common Fluentd Configuration Errors

Fluentd issues are most often caused by **small mistakes in the configuration file**.

---

### 1.1 Syntax Errors in fluentd.conf

**Problem:**

* Fluentd does not start after editing `fluentd.conf`
* Service status shows `failed`

**Check:**

```bash
sudo systemctl status fluentd.service
```

**Solution:**

* Open the file and check for:

  * Missing `<source>` or `</source>`
  * Missing `<match>` or `</match>`
  * Extra or missing angle brackets `< >`

```bash
sudo vi /etc/fluent/fluentd.conf
```

After fixing, restart:

```bash
sudo systemctl restart fluentd.service
```

---

### 1.2 Wrong File Path in Input Plugin

**Problem:**

* No logs appear in Elasticsearch

**Common Cause:**

* Log file path in `path` is incorrect

**Check:**

```bash
ls -l /var/log/myapp/app.log
```

**Fix:**

* Correct the path in the `<source>` block

---

### 1.3 Permission Issues on Log Files

**Problem:**

* Fluentd cannot read the log file

**Check error in logs:**

```bash
sudo tail -f /var/log/fluent/fluentd.log
```

**Solution:**

```bash
sudo chmod 644 /var/log/myapp/app.log
sudo chown fluent:fluent /var/log/myapp/app.log
```

---

## 2. Debugging Fluentd Using Logs

Fluentd writes its own logs which are very useful for debugging.

---

### 2.1 Fluentd Log Location

```text
/var/log/fluent/fluentd.log
```

---

### 2.2 View Fluentd Logs in Real-Time

```bash
sudo tail -f /var/log/fluent/fluentd.log
```

Look for:

* `error` messages
* `warn` messages
* Plugin loading failures

---

### 2.3 Restart Fluentd After Every Change

Always restart after modifying the configuration:

```bash
sudo systemctl restart fluentd.service
```

Then re-check status:

```bash
sudo systemctl status fluentd.service
```

---

## 3. Resolving Plugin Conflicts

Fluentd works using plugins. Sometimes plugins may be missing or incompatible.

---

### 3.1 Check Installed Plugins

```bash
sudo /opt/fluent/bin/fluent-gem list
```

Look for:

```text
fluent-plugin-elasticsearch
```

---

### 3.2 Install Missing Plugin

If the Elasticsearch plugin is missing:

```bash
sudo /opt/fluent/bin/fluent-gem install fluent-plugin-elasticsearch
```

Restart Fluentd after installation:

```bash
sudo systemctl restart fluentd.service
```

---

### 3.3 Version Mismatch Issues

**Problem:**

* Fluentd output plugin fails to send data

**Solution:**

* Update the plugin to the latest available version

```bash
sudo /opt/fluent/bin/fluent-gem update fluent-plugin-elasticsearch
sudo systemctl restart fluentd.service
```

---

## 4. Basic Data Flow Troubleshooting Checklist

Use this simple checklist when logs are not reaching Elasticsearch:

1. Is Fluentd service running?
2. Is the input file path correct?
3. Does Fluentd have permission to read the file?
4. Is Elasticsearch running on port 9200?
5. Is the Elasticsearch output plugin installed?
6. Did you restart Fluentd after changes?

---

## Verification Commands

Check Fluentd service:

```bash
sudo systemctl status fluentd.service
```

Check Fluentd logs:

```bash
sudo tail -f /var/log/fluent/fluentd.log
```

Check Elasticsearch availability:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200"
```

Check indices:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

---
