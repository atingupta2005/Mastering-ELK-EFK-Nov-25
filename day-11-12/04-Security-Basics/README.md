# Day 11 – Security Basics (Elasticsearch 9.x | CentOS)

---

## 1. Why Security Is Important in ELK

Elasticsearch and Kibana handle **sensitive data such as application logs, system logs, and user activity**. If security is not enabled:

* Anyone who knows the IP address can access your data
* Logs can be modified or deleted by unauthorized users
* Sensitive information can be leaked

### Simple Example

* A company stores production logs in Elasticsearch
* If security is disabled, any user on the network can access those logs
* This can expose:
  * User data
  * Error details
  * System information

So, **basic security is always required in production environments**.

---

## 2. Basic Authentication in Kibana

**Basic authentication** means users must provide a **username and password** to access Kibana.

When security is enabled:

* Kibana shows a **login page**
* Only authenticated users can view dashboards and logs

### Login Flow (Simple)

```
User → Kibana Login Page → Username & Password → Access Granted
```

### What Happens Without Authentication

```
User → Kibana URL → Direct Access to Dashboards (Unsafe)
```

---

## 3. User Roles Overview

A **role** defines what a user is allowed to do in Elasticsearch and Kibana.

Each role can control:

* Which indices a user can access
* Whether the user can read or write data
* Which Kibana features the user can use

### Important Built-In Roles in Elasticsearch/Kibana

#### 3.1 Superuser Role (`superuser`)

**Purpose:** Full administrative access to the entire cluster.

**Capabilities:**
* Full access to all indices (read, write, delete)
* Can manage users, roles, and permissions
* Can modify cluster settings
* Can view all Kibana features and dashboards
* Can create and delete indices

**Assigned to:** `elastic` user (default superuser)

**Usage:** Use for initial setup and administrative tasks. Avoid using for daily operations.

---

#### 3.2 Kibana System Role (`kibana_system`)

**Purpose:** Allows Kibana to communicate with Elasticsearch on behalf of users.

**Capabilities:**
* Can read cluster state and index metadata
* Can write to `.kibana*` indices (Kibana configuration)
* Can monitor cluster health
* Cannot access user data indices directly
* Cannot modify cluster settings

**Assigned to:** `kibana_system` user (used by Kibana service)

**Why Kibana uses `kibana_system` instead of `elastic`:**
* **Principle of Least Privilege:** Kibana doesn't need superuser permissions
* **Security:** If Kibana is compromised, attacker doesn't get full cluster access
* **Separation of Concerns:** Service accounts should have minimal required permissions
* **Audit Trail:** Actions performed by Kibana are clearly identifiable
---

#### 3.3 Logstash System Role (`logstash_system`)

**Purpose:** Allows Logstash to write data to Elasticsearch.

**Capabilities:**
* Can write to indices (index documents)
* Can read index templates
* Can monitor cluster health
* Cannot delete indices or modify cluster settings

**Assigned to:** `logstash_internal` user (used by Logstash service)

---

#### 3.4 Beats System Role (`beats_system`)

**Purpose:** Allows Beats (Filebeat, Metricbeat, etc.) to write data to Elasticsearch.

**Capabilities:**
* Can write to indices
* Can read index templates
* Cannot delete data or modify settings

**Assigned to:** `beats_system` user (used by Beats agents)

---

#### 3.5 Read-Only Role (`readonly`)

**Purpose:** Allows users to view data but not modify it.

**Capabilities:**
* Can read all indices
* Can view Kibana dashboards
* Cannot write, update, or delete data
* Cannot create indices

**Usage:** Assign to analysts, auditors, or stakeholders who only need to view data.

---

#### 3.6 Custom Roles

You can create custom roles with specific permissions:

* **Index-level access:** Restrict to specific index patterns (e.g., `app-logs-*`)
* **Field-level security:** Hide sensitive fields
* **Document-level security:** Filter documents based on user attributes

---

### Common Example Roles

* **Admin Role**
  * Full access to all indices
  * Can manage users and settings

* **Read‑Only Role**
  * Can only view data
  * Cannot delete or modify logs

* **Application User Role**
  * Can access only application‑specific indices

---

### Simple Role Assignment Flow

```
User → Assigned Role → Permissions Applied → Access Controlled
```

---

## 4. Index‑Level Access Control

**Index‑level access control** means restricting users to **only specific indices**.

### Why It Is Needed

* Different teams should see only their own data
* Security team should not see finance logs
* Developers should not access system logs

### Simple Example

* User A → Can access: `app-logs-*`
* User B → Can access: `system-logs-*`

User A **cannot see** `system-logs-*`.
User B **cannot see** `app-logs-*`.

---

### ASCII Diagram – Index‑Level Access

```
User A → app-logs-*  (Allowed)
User A → system-logs-* (Denied)

User B → system-logs-* (Allowed)
User B → app-logs-*  (Denied)
```

---

## 5. Enabling Password Authentication

Elasticsearch provides built‑in **password‑based authentication** for securing the cluster.

### What This Does

* Enables user login using username and password
* Secures both Elasticsearch and Kibana
* Prevents anonymous access

---

### Step 1 – Verify That Security Is Enabled

**Method 1: Edit config file directly (preferred)**

Open the Elasticsearch configuration file (from docker-elk directory):

```bash
nano elasticsearch/config/elasticsearch.yml
```

**Command explanation:**
* `nano`: Text editor for editing files
* `elasticsearch/config/elasticsearch.yml`: Path to Elasticsearch configuration file
* **Purpose:** Verify or enable security settings

Ensure this setting is present (enabled by default in docker-elk):

```yaml
xpack.security.enabled: true
```

**Method 2: Exec into container and edit**

If you need to edit from within the container:

```bash
docker compose exec elasticsearch bash
```

**Command explanation:**
* `docker compose exec`: Execute a command in a running container
* `elasticsearch`: Service name
* `bash`: Start an interactive bash shell
* **Purpose:** Access the container's filesystem and tools

Once inside the container:

```bash
nano /usr/share/elasticsearch/config/elasticsearch.yml
```

**Command explanation:**
* `/usr/share/elasticsearch/config/elasticsearch.yml`: Config file path inside container
* **Purpose:** Edit configuration from within container

Verify the setting:

```yaml
xpack.security.enabled: true
```

Exit the container:

```bash
exit
```

**Restart Elasticsearch after making changes:**

From docker-elk directory:

```bash
docker compose restart elasticsearch
```

**Command explanation:**
* `docker compose restart`: Restart a service
* `elasticsearch`: Service name
* **Purpose:** Apply configuration changes

---

### Step 2 – Set Built‑In User Passwords

For docker-elk, passwords are managed via `.env` file and setup container.

**Method 1: Using docker compose exec (recommended)**

Reset passwords (from docker-elk directory):

```bash
docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user elastic
```

**Command explanation:**
* `docker compose exec elasticsearch`: Execute command in Elasticsearch container
* `bin/elasticsearch-reset-password`: Elasticsearch utility for resetting passwords
* `--batch`: Non-interactive mode (generates random password)
* `--user elastic`: User to reset password for
* **Purpose:** Generate a new password for the elastic user
* **Output:** Displays the new password - save it immediately

Reset other built-in users:

```bash
docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user logstash_internal
docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user kibana_system
```

**Command explanation:**
* `logstash_internal`: User for Logstash service authentication
* `kibana_system`: User for Kibana service authentication
* **Purpose:** Set passwords for service accounts

**Method 2: Interactive password reset (from within container)**

If you need to set a specific password:

```bash
docker compose exec -it elasticsearch bash
bin/elasticsearch-reset-password --interactive --user elastic
```

**Command explanation:**
* `-it`: Interactive terminal mode
* `--interactive`: Prompts for new password
* **Purpose:** Set a custom password interactively

**Update `.env` file:**

After resetting passwords, update the `.env` file with the new passwords:

```bash
nano .env
```

Update these variables:

```bash
ELASTIC_PASSWORD=<new_elastic_password>
LOGSTASH_INTERNAL_PASSWORD=<new_logstash_password>
KIBANA_SYSTEM_PASSWORD=<new_kibana_password>
```

**Restart services to apply new passwords:**

```bash
docker compose restart logstash kibana
```

**Command explanation:**
* Restarts Logstash and Kibana so they use the new passwords from `.env`
* **Purpose:** Apply password changes to services

**Built‑in users include:**

* `elastic` (superuser) - Full administrative access
* `kibana_system` (used by Kibana) - Kibana service account
* `logstash_internal` (used by Logstash) - Logstash service account

---

### Step 3 – Configure Kibana to Use Authentication

**Why Kibana needs authentication:**

Kibana must authenticate with Elasticsearch to:
* Read cluster metadata
* Store Kibana configuration (saved objects, dashboards)
* Execute queries on behalf of logged-in users
* Monitor cluster health

**Why `kibana_system` instead of `elastic`:**

1. **Security Best Practice:** Service accounts should have minimal required permissions
2. **Principle of Least Privilege:** `kibana_system` role has only the permissions Kibana needs
3. **Audit Trail:** Actions performed by Kibana are clearly identifiable in logs
4. **Risk Mitigation:** If Kibana is compromised, attacker doesn't get superuser access

**How it works:**

```
User logs into Kibana → Kibana authenticates user with Elasticsearch → 
Kibana uses kibana_system credentials for internal operations → 
User's permissions are checked for data access
```

**Edit Kibana configuration file:**

**Method 1: Edit config file directly (preferred)**

From docker-elk directory:

```bash
nano kibana/config/kibana.yml
```

**Command explanation:**
* `nano`: Text editor
* `kibana/config/kibana.yml`: Kibana configuration file path
* **Purpose:** Configure Kibana authentication settings

Verify the following (should already be configured):

```yaml
elasticsearch.username: "kibana_system"
elasticsearch.password: "${KIBANA_SYSTEM_PASSWORD}"
```

**Configuration explanation:**
* `elasticsearch.username`: Username Kibana uses to authenticate with Elasticsearch
* `elasticsearch.password`: Password (read from `.env` file via `${KIBANA_SYSTEM_PASSWORD}`)
* **Purpose:** Allows Kibana to connect to Elasticsearch securely

---

### Understanding Why Kibana Needs Its Own Credentials

**Common Confusion:** "If users log in with their own credentials, why does Kibana need `kibana_system` credentials?"

**Answer:** Kibana needs its own credentials because there are **two separate authentication flows** that happen at different times and for different purposes.

---

#### Two Authentication Flows Explained

**1. Service Authentication (Kibana → Elasticsearch)**
- **When:** Before any user logs in, during Kibana startup, and continuously in the background
- **Who:** Kibana service itself
- **Credentials Used:** `kibana_system` user
- **Purpose:** Kibana's internal operations

**2. User Authentication (User → Kibana → Elasticsearch)**
- **When:** When a user logs into Kibana UI
- **Who:** The actual user (e.g., `elastic`, `app_user`, etc.)
- **Credentials Used:** User's own credentials
- **Purpose:** Access user data and perform user actions

---

#### What Kibana Does With `kibana_system` Credentials

**Before any user logs in:**

1. **Kibana startup:**
   ```
   Kibana starts → Uses kibana_system credentials → Connects to Elasticsearch → 
   Checks cluster health → Loads Kibana configuration
   ```

2. **Reading cluster metadata:**
   ```
   Kibana needs to know: What indices exist? What fields are available? 
   → Uses kibana_system credentials to query Elasticsearch metadata
   ```

3. **Storing Kibana's own data:**
   ```
   User creates a dashboard → Kibana stores it in .kibana* indices → 
   Uses kibana_system credentials to write
   ```

**While users are logged in:**

4. **Validating user credentials:**
   ```
   User enters username/password in Kibana UI → 
   Kibana uses kibana_system credentials to make authentication request to Elasticsearch → 
   Elasticsearch validates user credentials → Returns user's roles/permissions
   ```

---

#### Summary: Why Both Are Needed

| Operation | Credentials Used | Why |
|-----------|-----------------|-----|
| Kibana startup | `kibana_system` | Kibana needs to connect before any user logs in |
| User login validation | `kibana_system` | Kibana makes the authentication request on behalf of user |
| Reading cluster metadata | `kibana_system` | Kibana needs to know what indices/fields exist |
| Saving dashboards/visualizations | `kibana_system` | Kibana stores its own configuration data |
| User queries data | User's credentials | User's permissions are checked for data access |
| User creates index | User's credentials | User's permissions are checked for write operations |


**Restart Kibana:**

From docker-elk directory:

```bash
docker compose restart kibana
```

---

### Step 4 – Verify Login in Kibana

* Open Kibana in browser: `http://localhost:5601`
* Login page should appear
* Login using the `elastic` user and password from `.env` file

---

## 6. Security Settings in Configuration Files

### 6.1 Elasticsearch Security Settings

**File location:** `elasticsearch/config/elasticsearch.yml`

**Key security settings:**

```yaml
## Security
xpack.security.enabled: true
xpack.security.enrollment.enabled: true

## X-Pack Security
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false
```

**Settings explanation:**

* `xpack.security.enabled: true`
  * **Purpose:** Enables X-Pack security features (authentication, authorization)
  * **Required:** Must be `true` for password authentication

* `xpack.security.enrollment.enabled: true`
  * **Purpose:** Enables automatic enrollment of new nodes into the cluster
  * **Usage:** Simplifies adding new nodes securely

* `xpack.security.http.ssl.enabled: false`
  * **Purpose:** Controls HTTPS encryption for HTTP API (REST API)
  * **Values:** `true` for HTTPS, `false` for HTTP
  * **Note:** Set to `true` in production for encrypted communication

* `xpack.security.transport.ssl.enabled: false`
  * **Purpose:** Controls TLS encryption for inter-node communication
  * **Values:** `true` for encrypted transport, `false` for unencrypted
  * **Note:** Set to `true` in production for secure cluster communication

---

### 6.2 Kibana Security Settings

**File location:** `kibana/config/kibana.yml`

**Key security settings:**

```yaml
server.ssl.enabled: false
elasticsearch.username: "kibana_system"
elasticsearch.password: "${KIBANA_SYSTEM_PASSWORD}"
```

**Settings explanation:**

* `server.ssl.enabled: false`
  * **Purpose:** Enables HTTPS for Kibana web interface
  * **Values:** `true` for HTTPS, `false` for HTTP
  * **Note:** Set to `true` in production

* `elasticsearch.username: "kibana_system"`
  * **Purpose:** Username for Kibana to authenticate with Elasticsearch
  * **Required:** Must match a valid Elasticsearch user

* `elasticsearch.password: "${KIBANA_SYSTEM_PASSWORD}"`
  * **Purpose:** Password for Kibana authentication
  * **Source:** Read from `.env` file or environment variable

---

## 7. HTTPS/TLS Configuration (Optional)

HTTPS encrypts communication between clients and Elasticsearch/Kibana, protecting credentials and data in transit.

### 7.1 Enable HTTPS in Elasticsearch

**Step 1: Generate certificates (from within container)**

```bash
docker compose exec elasticsearch bash
bin/elasticsearch-certutil ca --out /usr/share/elasticsearch/config/ca.p12 --pass ""
bin/elasticsearch-certutil cert --ca /usr/share/elasticsearch/config/ca.p12 --ca-pass "" --out /usr/share/elasticsearch/config/elastic-cert.p12 --pass ""
exit
```

**Command explanation:**
* `elasticsearch-certutil`: Elasticsearch certificate generation utility
* `ca`: Create Certificate Authority
* `cert`: Create node certificate
* `--out`: Output file path
* `--pass "":` No password protection (for simplicity)
* **Purpose:** Generate self-signed certificates for HTTPS

**Step 2: Update Elasticsearch config**

Edit `elasticsearch/config/elasticsearch.yml`:

```yaml
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: certs/elastic-cert.p12
xpack.security.http.ssl.keystore.type: PKCS12
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.keystore.path: certs/elastic-cert.p12
xpack.security.transport.ssl.keystore.type: PKCS12
```

**Step 3: Restart Elasticsearch**

```bash
docker compose restart elasticsearch
```

**Step 4: Test HTTPS connection**

```bash
curl -u elastic:changeme -k https://localhost:9200
```

**Command explanation:**
* `-k`: Ignore certificate verification (for self-signed certs)
* `https://`: Use HTTPS protocol
* **Purpose:** Verify HTTPS is working

---

### 7.2 Enable HTTPS in Kibana

**Step 1: Copy certificate to Kibana**

```bash
docker compose cp elasticsearch:/usr/share/elasticsearch/config/ca.p12 ./kibana/config/
```

**Command explanation:**
* `docker compose cp`: Copy files between host and container
* **Purpose:** Share certificate with Kibana

**Step 2: Update Kibana config**

Edit `kibana/config/kibana.yml`:

```yaml
server.ssl.enabled: true
server.ssl.keystore.path: /usr/share/kibana/config/ca.p12
elasticsearch.hosts: ["https://elasticsearch:9200"]
elasticsearch.ssl.certificateAuthorities: ["/usr/share/kibana/config/ca.p12"]
```

**Step 3: Restart Kibana**

```bash
docker compose restart kibana
```

**Step 4: Access Kibana via HTTPS**

Open browser: `https://localhost:5601` (accept self-signed certificate warning)

---

## 8. Additional Security Features

### 8.1 API Keys

**Purpose:** Alternative to username/password for programmatic access.

**Create API key:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_security/api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-api-key",
    "expiration": "30d"
  }'
```

**Command explanation:**
* `-X POST`: HTTP POST method
* `_security/api_key`: API endpoint for creating API keys
* `"name"`: Descriptive name for the key
* `"expiration"`: Optional expiration time (e.g., "30d" for 30 days)
* **Purpose:** Generate an API key for secure programmatic access

**Use API key:**

```bash
curl -H "Authorization: ApiKey <base64_encoded_key>" http://localhost:9200/_cluster/health
```

---

### 8.2 Role-Based Access Control (RBAC)

**Create custom role:**

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/_security/role/app_logs_reader" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": [
      {
        "names": ["app-logs-*"],
        "privileges": ["read"]
      }
    ]
  }'
```

**Command explanation:**
* `PUT`: Create or update resource
* `_security/role/app_logs_reader`: Role name
* `"indices"`: Define index-level permissions
* `"names"`: Index pattern to apply permissions to
* `"privileges"`: Allowed actions (read, write, delete, etc.)
* **Purpose:** Create a role with restricted index access

**Assign role to user:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_security/user/app_user" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "secure_password",
    "roles": ["app_logs_reader"]
  }'
```

**Command explanation:**
* `POST`: Create new user
* `_security/user/app_user`: Username
* `"password"`: User's password
* `"roles"`: List of roles to assign
* **Purpose:** Create a user with specific role permissions

---

### 8.3 Field-Level Security

**Restrict access to specific fields:**

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/_security/role/restricted_reader" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": [
      {
        "names": ["logs-*"],
        "privileges": ["read"],
        "field_security": {
          "grant": ["message", "timestamp"],
          "except": ["password", "ssn"]
        }
      }
    ]
  }'
```

**Command explanation:**
* `"field_security"`: Define field-level access control
* `"grant"`: Fields users can see
* `"except"`: Fields to hide (even if in grant list)
* **Purpose:** Hide sensitive fields from users

---

## Verification Commands

**Check Elasticsearch status:**

```bash
docker compose ps elasticsearch
```

**Command explanation:**
* `ps`: List running containers
* **Purpose:** Verify Elasticsearch is running

**Check Kibana status:**

```bash
docker compose ps kibana
```

**Test authentication using curl:**

```bash
curl -u elastic:changeme http://localhost:9200
```

**Command explanation:**
* `curl`: Command-line HTTP client
* `-u elastic:changeme`: Basic authentication (username:password)
* `http://localhost:9200`: Elasticsearch endpoint
* **Purpose:** Verify authentication is working

**Check cluster health (authenticated):**

```bash
curl -u elastic:changeme http://localhost:9200/_cluster/health?pretty
```

**Command explanation:**
* `_cluster/health`: Cluster health API endpoint
* `?pretty`: Format JSON output
* **Purpose:** Verify cluster is healthy and authentication works

**List all users:**

```bash
curl -u elastic:changeme http://localhost:9200/_security/user?pretty
```

**Command explanation:**
* `_security/user`: List all users
* **Purpose:** Verify users are configured correctly

**List all roles:**

```bash
curl -u elastic:changeme http://localhost:9200/_security/role?pretty
```

**Command explanation:**
* `_security/role`: List all roles
* **Purpose:** Verify roles are configured correctly

---
