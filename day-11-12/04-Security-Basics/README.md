# Day 11 – Security Basics (Elasticsearch 9.x | CentOS)

> **Note for docker-elk users:**
> - All commands should be run from the `docker-elk` directory
> - Default credentials: `elastic:changeme` (update if changed in `.env`)
> - Config files: `elasticsearch/config/` and `kibana/config/` directories
> - Use `docker compose` commands for Elasticsearch/Kibana

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

So, **basic security is always required in real environments**.

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

## 5. Enabling Password Authentication (Basic)

Elasticsearch provides built‑in **password‑based authentication** for securing the cluster.

### What This Does

* Enables user login using username and password
* Secures both Elasticsearch and Kibana
* Prevents anonymous access

---

### Step 1 – Verify That Security Is Enabled

Open the Elasticsearch configuration file (from docker-elk directory):

```bash
nano elasticsearch/config/elasticsearch.yml
```

Ensure this setting is present (enabled by default in docker-elk):

```yaml
xpack.security.enabled: true
```

Restart Elasticsearch after making changes (from docker-elk directory):

```bash
docker compose restart elasticsearch
```

---

### Step 2 – Set Built‑In User Passwords

For docker-elk, passwords are managed via `.env` file and setup container.

To reset passwords (from docker-elk directory):

```bash
docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user elastic
docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user logstash_internal
docker compose exec elasticsearch bin/elasticsearch-reset-password --batch --user kibana_system
```

Then update the `.env` file with the new passwords and restart services:

```bash
docker compose restart logstash kibana
```

Built‑in users include:

* `elastic` (superuser)
* `kibana_system` (used by Kibana)
* `logstash_internal` (used by Logstash)

---

### Step 3 – Configure Kibana to Use Authentication

Edit Kibana configuration file (from docker-elk directory):

```bash
nano kibana/config/kibana.yml
```

Verify the following (should already be configured):

```yaml
elasticsearch.username: "kibana_system"
elasticsearch.password: "${KIBANA_SYSTEM_PASSWORD}"
```

The password is read from the `.env` file. Restart Kibana (from docker-elk directory):

```bash
docker compose restart kibana
```

---

### Step 4 – Verify Login in Kibana

* Open Kibana in browser
* Login page should appear
* Login using the `elastic` user

---

## Verification Commands

Check Elasticsearch status (from docker-elk directory):

```bash
docker compose ps elasticsearch
```

Check Kibana status (from docker-elk directory):

```bash
docker compose ps kibana
```

Test authentication using curl:

```bash
curl -u elastic:changeme http://localhost:9200
```

---
