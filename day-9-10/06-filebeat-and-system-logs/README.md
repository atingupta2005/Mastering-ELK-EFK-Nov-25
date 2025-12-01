# Collect OS Generated System Logs

# ✅ **Enable the Filebeat System Module**

This module is dedicated to OS logs and supports:

* `/var/log/messages`
* `/var/log/secure`
* SSH logins
* Kernel logs
* Auth failures
* Sudo attempts
* Systemd logs

Enable module:

```
sudo filebeat modules enable system
```

Check available modules:

```
sudo filebeat modules list
```

---

# ✅ **Configure the System Module**

Open module config:

```
sudo nano /etc/filebeat/modules.d/system.yml
```

Ensure both system & auth logs are enabled:

```yaml
- module: system
  syslog:
    enabled: true
    var.paths:
      - /var/log/messages

  auth:
    enabled: true
    var.paths:
      - /var/log/secure
```

This guarantees Filebeat reads:

* `/var/log/messages`
* `/var/log/secure`

---

# ✅ **Send System Logs to Logstash**

In your `filebeat.yml`, configure:

```yaml
output.logstash:
  enabled: true
  hosts: ["10.0.18.1:5044"]
```

And disable direct Elasticsearch output:

```yaml
output.elasticsearch:
  enabled: false
```

---

# ✅ **Restart Filebeat**

```
sudo systemctl restart filebeat
sudo systemctl status filebeat
```

---

# ✅ **Adjust Logstash Pipeline (Optional)**

Sample pipeline:

```
sudo nano /etc/logstash/conf.d/01-system.conf
```

```ruby
input {
  beats {
    port => 5044
  }
}

filter {
  if "system" in [fileset][module] {
    mutate { add_tag => ["system_log"] }
  }
}

output {
  elasticsearch {
    hosts => ["http://10.0.18.1:9200"]
    user => "atin.gupta"
    password => "2313634"
    index => "system-logs-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug }
}
```

Restart Logstash:

```
sudo systemctl restart logstash
```

---

# ✅ **Validate Data in Elasticsearch/Kibana**

Check indices:

```
curl -u atin.gupta:2313634 "http://10.0.18.1:9200/_cat/indices?v" | grep system
```

Expected outputs:

* `.ds-filebeat-9.x.x-system-syslog-*`
* `.ds-filebeat-9.x.x-system-auth-*`

Create a Kibana Data View:

```
filebeat-*
```

---

# 📌 **What OS Logs Are Ingested?**

### Via `syslog`:

* system messages
* kernel messages
* services
* network events
* boot logs
* interface up/down
* device attach/detach

### Via `auth`:

* SSH logins
* sudo usage
* failed password attempts
* brute force attempts
* user creation / deletion
* service authentication errors

So you get a full OS activity picture.

