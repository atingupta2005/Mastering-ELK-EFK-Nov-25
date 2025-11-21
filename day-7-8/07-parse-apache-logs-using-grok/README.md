# Logstash + Grok Parsing for Apache Logs

---

# 1. Understanding Apache Logs

Apache access logs follow a standard format known as **Combined Log Format (CLF)**:

```
127.0.0.1 - james [21/Nov/2025:10:05:32 +0530] "GET /index.html HTTP/1.1" 200 1043 "-" "Mozilla/5.0"
```

### 📌 Breakdown

| Field                        | Meaning                   |
| ---------------------------- | ------------------------- |
| 127.0.0.1                    | Client IP                 |
| -                            | RFC1413 identity (unused) |
| james                        | Authenticated user        |
| [21/Nov/2025:10:05:32 +0530] | Timestamp                 |
| "GET /index.html HTTP/1.1"   | Request line              |
| 200                          | Status code               |
| 1043                         | Bytes returned            |
| "-"                          | Referrer                  |
| "Mozilla/5.0"                | User agent                |

---

# 2. Grok Pattern for Apache Logs

Elastic already provides a pre-defined Grok pattern:

```
%{COMBINEDAPACHELOG}
```

This expands into several sub-patterns:

* `%{IPORHOST:clientip}`
* `%{USER:ident}`
* `%{USER:auth}`
* `%{HTTPDATE:timestamp}`
* `%{WORD:verb}`
* `%{URIPATHPARAM:request}`
* `%{NUMBER:response}`
* `%{NUMBER:bytes}`
* `%{QS:referrer}`
* `%{QS:agent}`

---

# 3. Create Continuous Apache Log Generator (Dynamic Logs)

## Create directory

```
sudo mkdir -p /var/log/apachecustom
sudo chmod 777 /var/log/apachecustom
```

## Start real-time log generator

Run this script (as a normal user or root):

```
while true; do
  IP="192.168.$((RANDOM%255)).$((RANDOM%255))"
  USER=$(shuf -e admin guest john mary api-user -n 1)
  METHOD=$(shuf -e GET POST PUT DELETE PATCH -n 1)
  PATH=$(shuf -e / /home /login /api/user /api/order /dashboard /product?id=$((RANDOM%999)) -n 1)
  STATUS=$(shuf -e 200 201 204 301 400 401 403 404 500 503 -n 1)
  BYTES=$((RANDOM%5000+200))
  AGENT=$(shuf -e "Mozilla/5.0" "curl/7.68.0" "python-requests/2.28" "Java-http-client" -n 1)
  REF="-"

  TS=$(date '+%d/%b/%Y:%H:%M:%S %z')

  echo "$IP - $USER [$TS] \"$METHOD $PATH HTTP/1.1\" $STATUS $BYTES \"$REF\" \"$AGENT\"" \
    | sudo tee -a /var/log/apachecustom/access.log > /dev/null

  sleep 1
done
```

This produces one random Apache log entry every second.

---

# 3. Create Sample Apache Log File (Optional Static Logs)

Create a directory:

```
sudo mkdir -p /var/log/apachecustom
sudo chmod 777 /var/log/apachecustom
```

Create sample log file:

```
cat <<EOF > /var/log/apachecustom/access.log
127.0.0.1 - admin [21/Nov/2025:10:22:01 +0530] "GET /home HTTP/1.1" 200 532 "-" "Mozilla/5.0"
192.168.1.10 - - [21/Nov/2025:10:22:15 +0530] "POST /api/login HTTP/1.1" 401 210 "http://example.com" "curl/7.68.0"
10.0.18.5 - john [21/Nov/2025:10:22:35 +0530] "DELETE /api/user/42 HTTP/1.1" 204 0 "-" "python-requests/2.25"
EOF
```

---

# 4. Logstash Pipeline to Parse Apache Logs

Create Logstash pipeline file:

```
sudo nano /etc/logstash/conf.d/apache-grok.conf
```

Paste:

```
input {
  file {
    path => "/var/log/apachecustom/access.log"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
}

filter {
  grok {
    match => {
      "message" => "%{COMBINEDAPACHELOG}"
    }
  }

  # Convert fields to proper types
  mutate {
    convert => {
      "response" => "integer"
      "bytes" => "integer"
    }
  }

  # Parse timestamp
  date {
    match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss Z"]
    target => "@timestamp"
  }
}

output {
  elasticsearch {
    hosts => ["http://10.0.18.1:9200"]
    index => "apache-logs-%{+YYYY.MM.dd}"
    user => "your_username"
    password => "your_password"
  }

  stdout { codec => rubydebug }
}
```

Save & exit.

Restart Logstash:

```
sudo systemctl restart logstash
```

Check logs:

```
sudo journalctl -u logstash -f
```

---

# 5. Verify Parsing Output

You should see parsed fields like:

```
{
  "clientip" => "192.168.1.10",
  "verb"     => "POST",
  "request"  => "/api/login",
  "response" => 401,
  "bytes"    => 210,
  "agent"    => "\"curl/7.68.0\"",
  "referrer" => "\"http://example.com\""
}
```

If parsing fails, you will see:

```
"tags" => ["_grokparsefailure"]
```

---

# 6. Creating a Grok Filter Only for IP & Status Code

You can also extract only minimal information.

Example Log:

```
10.0.18.5 - - [21/Nov/2025:12:00:00 +0530] "GET /page HTTP/1.1" 404 512
```

Minimal Grok Pattern:

```
%{IP:client_ip} .* "%{WORD:method} %{DATA:url} HTTP/%{NUMBER:http_version}" %{NUMBER:status} %{NUMBER:bytes}
```

Create Logstash pipeline:

```
sudo nano /etc/logstash/conf.d/apache-minimal.conf
```

Paste:

```
input {
  file {
    path => "/var/log/apachecustom/access.log"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
}

filter {
  grok {
    match => {
      "message" => "%{IP:client_ip} .* \"%{WORD:method} %{DATA:url} HTTP/%{NUMBER:http_version}\" %{NUMBER:status} %{NUMBER:bytes}"
    }
  }

  mutate {
    convert => { "status" => "integer" }
  }
}

output {
  stdout { codec => rubydebug }
}
```

Restart Logstash:

```
sudo systemctl restart logstash
```

Expected output:

```
{
  "client_ip" => "10.0.18.5",
  "method"    => "GET",
  "url"       => "/page",
  "status"    => 404,
  "bytes"     => "512"
}
```

---

# 8. Create Data View in Kibana

1. Open **Kibana → Discover**
2. Click **Create Data View**
3. Name: `apache-logs`
4. Index pattern: `apache-logs-*`
5. Select `@timestamp` as time field
6. Save

You'll now see parsed fields:

* clientip
* status
* method
* request
* bytes
* useragent

---

# 9. Troubleshooting

### **1. `_grokparsefailure`** appears

Means the log doesn't match the pattern.

Fix:

```
stdout { codec => rubydebug }
```

Use an online grok debugger.

---

### **2. File not re-read**

File input remembers position using `sincedb`.

Fix:

```
sincedb_path => "/dev/null"
```

---

### **3. Logstash not reading file**

Check permissions:

```
sudo chmod 644 /var/log/apachecustom/access.log
```
