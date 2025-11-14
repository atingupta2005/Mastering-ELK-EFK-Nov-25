## 📅 Day 8: Hands-On with Filebeat & Logstash

**Objective:** This is a comprehensive, hands-on lab that demonstrates the two primary architectures for data ingestion.

1.  **Path 1:** Filebeat -\> Elasticsearch (Simple, fast, for pre-formatted data)
2.  **Path 2:** Filebeat -\> Logstash -\> Elasticsearch (Powerful, flexible, for complex data)

For this lab, we will install and configure Filebeat and Logstash on the **same CentOS server** as your Elasticsearch/Kibana node. In a production environment, these would be on separate machines.

**Prerequisite:**

  * Your Elasticsearch and Kibana services are running and accessible.
  * You have `sudo` access on your CentOS server.
  * The Elastic YUM repository is already configured (from the Elasticsearch install).

-----

### 1\. Install Filebeat on Local System (Topic 13)

First, we will install the Filebeat agent.

#### 🚀 Hands-On: Install Filebeat

1.  **Action:** Open your server's terminal.
2.  **Action:** Install the `filebeat` package using `yum`.
    ```bash
    sudo yum install filebeat
    ```
3.  **Action:** Enable the Filebeat service so it can start on boot.
    ```bash
    sudo systemctl enable filebeat
    ```

**Do not start the service yet.** We must configure it first.

-----

### 2\. Configure Filebeat to Read Log Files (Topic 14)

By default, Filebeat is configured to use "modules" to collect system logs. For this lab, we want to disable that and tell it to read a *specific* custom log file.

#### 🚀 Hands-On: Configure Filebeat Input

**Step 1: Create a Custom Log File to Monitor**

1.  **Action:** Let's create a new log file that our "custom application" will write to.
    ```bash
    sudo touch /var/log/my-app.log
    sudo chown root:root /var/log/my-app.log
    ```
2.  **Action:** Let's simulate our app writing two log lines to this file.
    ```bash
    sudo sh -c 'echo "2025-11-14T11:00:00 [INFO] Application started" >> /var/log/my-app.log'
    sudo sh -c 'echo "2025-11-14T11:01:00 [ERROR] Failed to connect to database" >> /var/log/my-app.log'
    ```

**Step 2: Disable Default Modules**

1.  **Action:** Filebeat loads extra configs from `/etc/filebeat/modules.d/`. We must disable the default `system.yml` module so we *only* get the logs we ask for.
    ```bash
    sudo mv /etc/filebeat/modules.d/system.yml /etc/filebeat/modules.d/system.yml.disabled
    ```

**Step 3: Edit the Main `filebeat.yml`**

1.  **Action:** Open the main configuration file with `vi`.
    ```bash
    sudo vi /etc/filebeat/filebeat.yml
    ```
2.  **Action:** Find the `filebeat.inputs:` section. It will be commented out.
3.  **Action:** Delete the example content and add the following configuration. This tells Filebeat to find and read our new log file.
    ```yml
    filebeat.inputs:
    - type: filestream
      id: my-app-logs
      enabled: true
      paths:
        - /var/log/my-app.log
    ```
      * **`type: filestream`**: This is the modern, correct input type for log files.
      * **`paths`**: The specific file(s) to monitor.

**Do not close the file yet.** We must now configure the *output*.

-----

### 3\. Send Data Directly to Elasticsearch (Topic 15)

First, we will test **Path 1**. We will tell Filebeat to send data directly to Elasticsearch.

#### 🚀 Hands-On: Configure the Elasticsearch Output

1.  **Action:** In your open `filebeat.yml` file, scroll down to the "Outputs" section.
2.  **Action:**
      * **Comment out** the `output.logstash:` section by adding a `#` to the front of the lines.
      * **Uncomment** the `output.elasticsearch:` section.
3.  **Action:** Edit the `output.elasticsearch:` section to look like this (assuming your Elasticsearch is on `localhost` and has security disabled for this lab):
    ```yml
    # ---------------------------- Logstash Output -----------------------------
    # output.logstash:
    #   hosts: ["localhost:5044"]

    # -------------------------- Elasticsearch Output --------------------------
    output.elasticsearch:
      hosts: ["http://localhost:9200"]
      index: "filebeat-direct-%{+YYYY.MM.dd}"
    ```
      * **`hosts`**: Points to your Elasticsearch server.
      * **`index`**: We set a custom index name, `filebeat-direct...`, so we can find this data easily in Kibana.
4.  **Action:** Save and quit the file (`:wq`).

**Step 2: Test and Run**

1.  **Action (Test):** Test your configuration for typos.
    ```bash
    sudo filebeat test config -e
    ```
    *Result: If you see "Config OK", you are good to go.*
2.  **Action (Run):** Start the Filebeat service.
    ```bash
    sudo systemctl start filebeat
    ```
3.  **Action (Verify):** Check the Filebeat logs to see it running.
    ```bash
    sudo journalctl -u filebeat -f
    ```
    *You should see messages about "Harvester started" and "Connected to Elasticsearch".*

-----

### 4\. Send Data Via Logstash (Topic 16)

Now, we will test **Path 2**. We will re-route our data through Logstash. This requires two steps:

1.  Create a Logstash pipeline to *receive* the data.
2.  Re-configure Filebeat to *send* data to Logstash.

#### 🚀 Hands-On: Configure and Run the Logstash Pipeline

**Step 1: Install Logstash**

1.  **Action:** If you haven't already, install Logstash.
    ```bash
    sudo yum install logstash
    ```

**Step 2: Create a Logstash Pipeline for Beats**

1.  **Action:** Create a new Logstash configuration file.
    ```bash
    sudo vi /etc/logstash/conf.d/02-beats-input.conf
    ```
2.  **Action:** Paste the following configuration. This tells Logstash to **listen on port 5044** (the standard for Beats), add a *new field* to prove it worked, and send the data to a *new index*.
    ```conf
    input {
      beats {
        port => 5044
      }
    }

    filter {
      # This filter adds a new field, so we can prove
      # the log passed through Logstash.
      mutate {
        add_field => { "pipeline_path" => "filebeat-to-logstash" }
      }
    }

    output {
      elasticsearch {
        hosts => ["http://localhost:9200"]
        index => "logstash-from-beats-%{+YYYY.MM.dd}"
      }
    }
    ```
3.  **Action:** Start the Logstash service.
    ```bash
    sudo systemctl enable logstash
    sudo systemctl start logstash
    ```
    *(Logstash can take 1-2 minutes to start up. Use `sudo systemctl status logstash` to check on it.)*

**Step 3: Re-configure Filebeat to Send to Logstash**

1.  **Action:** Go back and edit your Filebeat config.
    ```bash
    sudo vi /etc/filebeat/filebeat.yml
    ```
2.  **Action:** Go to the "Outputs" section.
3.  **Action:**
      * **Uncomment** the `output.logstash:` section.
      * **Comment out** the `output.elasticsearch:` section.
4.  **Action:** Your configuration should now look like this:
    ```yml
    # ---------------------------- Logstash Output -----------------------------
    output.logstash:
      hosts: ["localhost:5044"]

    # -------------------------- Elasticsearch Output --------------------------
    # output.elasticsearch:
    #   hosts: ["http://localhost:9200"]
    #   index: "filebeat-direct-%{+YYYY.MM.dd}"
    ```
5.  **Action:** Save and quit the file (`:wq`).

**Step 4: Restart Filebeat**

1.  **Action:** Filebeat must be restarted to load the new config.
    ```bash
    sudo systemctl restart filebeat
    ```

**Step 5: Add a New Log Line**

1.  **Action:** Filebeat has already sent the first two log lines (to Path 1). Let's add a *new* line to our log file, which Filebeat will detect and send down Path 2.
    ```bash
    sudo sh -c 'echo "2025-11-14T11:05:00 [WARN] This log went through Logstash" >> /var/log/my-app.log'
    ```

-----

### 5\. Explore Logs Ingested in Kibana Discover (Topic 17)

Now we go to Kibana to verify *both* paths worked.

#### 🚀 Hands-On: Explore in Kibana

**Step 1: Create Index Pattern for Path 1**

1.  **Action:** Go to **Stack Management** -\> **Index Patterns** -\> **Create index pattern**.
2.  **Name:** `filebeat-direct-*`
3.  **Next step**, select **`@timestamp`** as the time field, and **Create**.
4.  **Action:** Go to **Discover**. Select the `filebeat-direct-*` pattern.
5.  **Analyze:** You will see the *first two* log lines:
      * `"message": "2025-11-14T11:00:00 [INFO] Application started"`
      * `"message": "2025-11-14T11:01:00 [ERROR] Failed to connect to database"`
      * Note that the `message` is a single, unparsed line. Filebeat just shipped the raw string.

**Step 2: Create Index Pattern for Path 2**

1.  **Action:** Go to **Stack Management** -\> **Index Patterns** -\> **Create index pattern**.
2.  **Name:** `logstash-from-beats-*`
3.  **Next step**, select **`@timestamp`** as the time field, and **Create**.
4.  **Action:** Go to **Discover**. Select the new `logstash-from-beats-*` pattern.
5.  **Analyze:** You will see the *third* log line you added:
      * `"message": "2025-11-14T11:05:00 [WARN] This log went through Logstash"`
6.  **Action: The Final Proof:**
      * Expand this log document by clicking the `>` caret.
      * Scroll through the **Table** of fields.
      * **Result:** You will see a field: **`pipeline_path: "filebeat-to-logstash"`**.
      * This *proves* the log was successfully received by Filebeat, sent to Logstash, processed by the `mutate` filter, and then indexed into Elasticsearch.

You have now successfully configured and verified both primary ingestion architectures.