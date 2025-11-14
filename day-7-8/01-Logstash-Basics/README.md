## 📅 Day 4: Logstash Basics

### 1\. What is Logstash?

Logstash is a **server-side data processing pipeline**. It is the "L" in the original ELK Stack and a core component of the modern Elastic Stack.

Its primary purpose is to **ingest**, **transform**, and **ship** data. While lightweight shippers like Filebeat (part of the Elastic Agent) are designed to *collect* data, Logstash is a "heavyweight" tool designed for *complex processing*.

Logstash runs on the Java Virtual Machine (JVM) and uses a pluggable framework. It is most famous for its ability to parse unstructured, messy log data into the clean, structured JSON format that Elasticsearch requires.

**Core Use Cases:**

  * **Parsing:** Converting a single log line (e.g., `192.168.1.1 GET /login 200`) into a structured JSON object (e.g., `{ "client_ip": "192.168.1.1", "http_method": "GET", ... }`).
  * **Enriching:** Adding new information to a log. For example, taking the `client_ip` and using a filter to add geographic data (`client.geo.city_name: "Noida"`).
  * **Normalizing:** Cleaning up data. For example, renaming a field (`host` -\> `host.name`), removing sensitive fields (`"password": "..." -> "password": "[REDACTED]`), or converting data types (`"http_status_code": "200"` -\> `"http_status_code": 200`).
  * **Routing:** Sending different data to different destinations (e.g., "prod" logs go to a "prod" index, "dev" logs go to a "dev" index).

### 2\. Logstash Architecture (Input → Filter → Output)

The Logstash pipeline is the core concept. A pipeline has three stages, which are defined in a configuration file: **input**, **filter**, and **output**.

1.  **Input:** This stage is responsible for *ingesting* data. An input plugin receives or collects data from a source. A pipeline can have multiple inputs.
2.  **Filter:** This is the *processing* stage where data is transformed. Filters are applied in order. This stage is optional, but it is the primary reason Logstash is used.
3.  **Output:** This stage is responsible for *shipping* the processed data to a destination. A pipeline can have multiple outputs.

**Text Diagram of the Data Flow:**
`[Data Source] -> [Input Plugin] -> [Filter Plugin(s)] -> [Output Plugin] -> [Data Destination]`

### 3\. Installing Logstash (Basic Setup)

Logstash is installed on a central server, separate from your data shippers (Elastic Agents) and your Elasticsearch cluster.

#### 🚀 Hands-On: Install Logstash (CentOS)

1.  **Add the Elastic Repository (if not already added):**
    Logstash uses the same YUM repository as Elasticsearch. If you are on the same server, you can skip this. If not, add the key and repo file:

    ```bash
    sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

    sudo vi /etc/yum.repos.d/elastic-9.x.repo
    ```

    (Paste the same `[elastic-9.x]` repo configuration used for Elasticsearch).

2.  **Install the Logstash Package:**

    ```bash
    sudo yum install logstash
    ```

3.  **Key Directories to Know:**

      * **Configuration:** `/etc/logstash/conf.d/` (This is where you put your `.conf` pipeline files).
      * **Binaries:** `/usr/share/logstash/bin/` (This is where the `logstash` executable lives).
      * **Logs:** `/var/log/logstash/` (This is where Logstash writes its *own* operational logs, useful for debugging).

**Important:** Do not `start` the Logstash service yet. It will not do anything without a configuration file.

### 4\. Logstash Configuration File Structure

Logstash is configured using simple text files ending in `.conf`, located in `/etc/logstash/conf.d/`.

The structure of a `.conf` file directly maps to the pipeline architecture:

```conf
# This is a comment
input {
  # ... Input plugin configuration ...
}

filter {
  # ... Filter plugin(s) configuration ...
}

output {
  # ... Output plugin configuration ...
}
```

#### 🚀 Hands-On: "Hello World" Pipeline (Test your install)

This is the most basic pipeline to verify Logstash is working. It reads from your keyboard (`stdin`) and writes to your screen (`stdout`).

1.  **Action:** Create your first configuration file.

    ```bash
    sudo vi /etc/logstash/conf.d/01-hello.conf
    ```

2.  **Action:** Paste the following content:

    ```conf
    input {
      stdin { }
    }

    output {
      stdout {
        codec => rubydebug
      }
    }
    ```

      * `codec => rubydebug`: This is a special formatter that prints the *full JSON structure* of the event, which is extremely helpful for debugging.

3.  **Action:** Run this config file *directly* from the command line.

      * **Note:** We use `sudo -u logstash` to run as the correct user.

    <!-- end list -->

    ```bash
    sudo -u logstash /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/01-hello.conf
    ```

4.  **Action:** Wait for Logstash to start (it can take 30-60 seconds). You will see "Pipeline started".

5.  **Action:** Type `Hello World` and press **Enter**.

6.  **Analyze the Result:** Logstash will process your input and print the full event to the screen as a structured object:

    ```json
    {
        "message": "Hello World",
      "@version": "1",
          "host": "your-centos-server.local",
    "@timestamp": "2025-11-14T12:00:00.000Z"
    }
    ```

      * Logstash automatically adds metadata like `@timestamp` and `host`. Your typed "Hello World" was put into the `message` field.

7.  Press `CTRL+C` to stop Logstash.

### 5\. Common Inputs (file, beats, stdin) (Topic 5)

The `input {}` block defines where data comes from.

  * **`stdin` (Standard Input):**

      * **Use:** Debugging and testing (as seen in the lab above).
      * **Code:** `input { stdin { } }`

  * **`file`:**

      * **Use:** Reading directly from a log file on the Logstash server. This is a "classic" setup. Logstash handles file rotation and remembers its position (`sincedb`).
      * **Code:**
        ```conf
        input {
          file {
            path => "/var/log/my-app/app.log"
            start_position => "beginning"
          }
        }
        ```

  * **`beats`:**

      * **Use:** This is the **modern, production** method. You do *not* read files directly. Instead, you have 100 servers running Filebeat (Elastic Agent), and they all *ship* their logs to this Logstash server. This input plugin opens a port (e.g., 5044) to listen for that incoming Beats traffic.
      * **Code:**
        ```conf
        input {
          beats {
            port => 5044
          }
        }
        ```

### 6\. Common Outputs (Elasticsearch, stdout) (Topic 6)

The `output {}` block defines where the processed data goes.

  * **`stdout` (Standard Output):**

      * **Use:** Debugging. Prints the final, processed event to your console.
      * **Code:**
        ```conf
        output {
          stdout { codec => rubydebug }
        }
        ```

  * **`elasticsearch`:**

      * **Use:** This is the **production** output. It sends the data to your Elasticsearch cluster.
      * **Code:**
        ```conf
        output {
          elasticsearch {
            hosts => ["http://localhost:9200"]
            index => "access-logs-%{+YYYY.MM.dd}"
          }
        }
        ```
      * **Key Parameters:**
          * `hosts`: An array of your Elasticsearch node addresses.
          * `index`: The name of the index to write to. Notice the `%{+YYYY.MM.dd}` pattern. This tells Logstash to automatically create **time-based indices**, such as `access-logs-2025.11.14`.

### 7\. Common Filters (grok, mutate, date) (Topic 7)

This is the `filter {}` block, the most powerful stage. Filters transform the data.

  * **`mutate`:**

      * **Use:** The "Swiss Army Knife" for simple, fast transformations.
      * **Code:**
        ```conf
        filter {
          mutate {
            # Rename a field
            rename => { "http_host" => "http.request.referrer" }
            # Add a new field
            add_field => { "environment" => "production" }
            # Remove sensitive or useless fields
            remove_field => [ "password", "debug_info" ]
            # Convert a data type (e.g., from your access-logs schema)
            convert => { "http.response.status_code" => "integer" }
          }
        }
        ```

  * **`date`:**

      * **Use:** To parse a custom date from your log message and use it as the main `@timestamp`. If your log is from 3 days ago, you need the `@timestamp` to be 3 days ago.
      * **Code:** (Assumes your log has a field `log_date: "Nov 14 2025 12:30:01"`)
        ```conf
        filter {
          date {
            match => [ "log_date", "MMM dd yyyy HH:mm:ss" ]
            target => "@timestamp"
          }
        }
        ```

  * **`grok`:**

      * **Use:** The "superstar" of Logstash. It uses regular expressions (regex) to parse an unstructured `message` string into a fully structured object. This is how you *create* the fields for your `access-logs` schema.
      * **The Problem:** `message: "198.51.100.1 GET /login 401 55"`
      * **The Goal:**
        ```json
        {
          "client_ip": "198.51.100.1",
          "http_method": "GET",
          "url_path": "/login",
          "http_status_code": 401,
          "bytes": 55
        }
        ```
      * **The `grok` Pattern:** Grok uses built-in patterns: `%{IP}`, `%{WORD}`, `%{URIPATH}`, `%{NUMBER}`.
      * **The Code:**
        ```conf
        filter {
          grok {
            match => { 
              "message" => "%{IP:client.ip} %{WORD:http.request.method} %{URIPATH:url.path} %{NUMBER:http.response.status_code:int} %{NUMBER:http.response.body.bytes:int}"
            }
          }
        }
        ```
      * **Explanation:**
          * `%{IP:client.ip}`: Find an IP address and save it to a new field called `client.ip`.
          * `%{NUMBER:http.response.status_code:int}`: Find a NUMBER, save it as `http.response.status_code`, and automatically convert it to an `int`(integer).