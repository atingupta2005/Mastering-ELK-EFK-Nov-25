# Day 12 – Advanced Security (Elasticsearch 9.x | CentOS)

## 1. API Keys for Secure Ingestion

API keys provide an alternative to username/password authentication for programmatic access.

### 1.1 Why API Keys Are Used

**Advantages:**
* **Security:** Avoid storing usernames and passwords in scripts or configuration files
* **Flexibility:** Easy to create and revoke without changing user passwords
* **Scope Control:** Can be restricted to specific indices or operations
* **Expiration:** Can be set to expire automatically
* **Common Usage:** Standard method for ingestion tools (Filebeat, Logstash, custom applications)

**When to use API keys:**
* Application-to-Elasticsearch communication
* Automated scripts and tools
* Third-party integrations
* When you need temporary access

**When to use username/password:**
* Interactive user access
* Kibana login
* Administrative tasks

---

### 1.2 Create a Simple API Key

**Method 1: Using curl (from host)**

Create an API key using the `elastic` user:

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_security/api_key" \
  -H "Content-Type: application/json" \
  -d '{ "name": "my-api-key" }'
```

**Command explanation:**
* `curl`: Command-line HTTP client
* `-u elastic:changeme`: Basic authentication (username:password)
* `-X POST`: HTTP POST method
* `_security/api_key`: API endpoint for creating API keys
* `-H "Content-Type: application/json"`: Set request header for JSON content
* `-d '{ "name": "my-api-key" }'`: Request body with API key name
* **Purpose:** Generate an API key for secure programmatic access

**Response example:**
```json
{
  "id": "VuaCfGcBCdbkQm-e5aOx",
  "name": "my-api-key",
  "api_key": "ui2lp2axTNmsyakw9tvNnw",
  "encoded": "VuaCfGcBCdbkQm-e5aOx:ui2lp2axTNmsyakw9tvNnw"
}
```

**Important:** Save the `id` and `api_key` values immediately. You cannot retrieve them later.

---

### 1.3 Encode the API Key

API keys must be base64-encoded before use.

**Method 1: Using echo and base64**

```bash
echo -n 'VuaCfGcBCdbkQm-e5aOx:ui2lp2axTNmsyakw9tvNnw' | base64
```


### 1.4 Create API Key with Expiration

API keys can be set to expire automatically:

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_security/api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "temporary-key",
    "expiration": "7d"
  }'
```

---

### 1.5 Use API Key for Authentication

**Send document using API key:**

```bash
curl -X POST "http://localhost:9200/api-demo/_doc" \
  -H "Authorization: ApiKey VnVhQ2ZHY0JDZGJrUW0tZTVhT3g6dWkybHAyYXhUTm1zeWFrdzl0dk5udw==" \
  -H "Content-Type: application/json" \
  -d '{ "message": "log sent using api key" }'
```

---

### 1.6 Verify API Key Works

**Test API key authentication:**

```bash
curl -H "Authorization: ApiKey VnVhQ2ZHY0JDZGJrUW0tZTVhT3g6dWkybHAyYXhUTm1zeWFrdzl0dk5udw==" \
  http://localhost:9200
```

---

### 1.7 List and Manage API Keys

**List all API keys:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_security/api_key?pretty"
```

**Revoke API key:**

```bash
curl -u elastic:changeme -X DELETE "http://localhost:9200/_security/api_key?id=VuaCfGcBCdbkQm-e5aOx"
```

### 1.8 Use API Key in Filebeat Configuration

API keys are commonly used in Beats configuration:

**Example Filebeat configuration:**

```yaml
output.elasticsearch:
  hosts: ["http://localhost:9200"]
  api_key: "VnVhQ2ZHY0JDZGJrUW0tZTVhT3g6dWkybHAyYXhUTm1zeWFrdzl0dk5udw=="
```
---

## 2. Document-Level Security (DLS)

Document-Level Security (DLS) restricts access to specific documents based on user attributes or document fields.

### 2.1 What DLS Does

DLS allows you to:
* Filter documents based on user identity
* Hide documents from users who shouldn't see them
* Control access at the document level (not just index level)

### 2.2 Simple DLS Example

**Create role with DLS:**

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/_security/role/sales_team" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": [
      {
        "names": ["sales-*"],
        "privileges": ["read"],
        "query": {
          "term": {
            "department": "{{_user.metadata.department}}"
          }
        }
      }
    ]
  }'
```

**Command explanation:**
* `PUT _security/role/sales_team`: Create or update role
* `"query"`: Document-level security query
* `"{{_user.metadata.department}}"`: User metadata variable
* **Purpose:** Users can only see documents where `department` field matches their metadata
* **How it works:** Elasticsearch automatically filters documents based on the query

**Assign role to user:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_security/user/sales_user" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "secure_password",
    "roles": ["sales_team"],
    "metadata": {
      "department": "sales"
    }
  }'
```

---

## 3. Field-Level Security (FLS)

Field-Level Security (FLS) restricts access to specific fields within documents.

### 3.1 What FLS Does

FLS allows you to:
* Hide sensitive fields from users
* Show only specific fields
* Control field visibility based on user roles

### 3.2 Simple FLS Example

**Create role with FLS:**

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/_security/role/analyst" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": [
      {
        "names": ["logs-*"],
        "privileges": ["read"],
        "field_security": {
          "grant": ["message", "timestamp", "level"],
          "except": ["password", "ssn", "credit_card"]
        }
      }
    ]
  }'
```

**Command explanation:**
* `"field_security"`: Define field-level access control
* `"grant"`: Fields users can see
* `"except"`: Fields to hide (even if in grant list)
* **Purpose:** Users can see `message`, `timestamp`, `level` but not `password`, `ssn`, `credit_card`

**Grant all fields except specific ones:**

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/_security/role/restricted_reader" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": [
      {
        "names": ["logs-*"],
        "privileges": ["read"],
        "field_security": {
          "grant": ["*"],
          "except": ["password", "ssn"]
        }
      }
    ]
  }'
```

---

## 4. Security Settings in Configuration Files

### 4.1 Elasticsearch Security Settings

**File location:** `elasticsearch/config/elasticsearch.yml`

**Key security settings:**

```yaml
## Security
xpack.security.enabled: true
xpack.security.enrollment.enabled: true

## API Key Settings
xpack.security.authc.api_key.enabled: true
xpack.security.authc.api_key.cache.ttl: 1h
xpack.security.authc.api_key.cache.max_keys: 10000

## Audit Logging
xpack.security.audit.enabled: false
xpack.security.audit.logfile.events.include: ["access_denied", "authentication_failed"]
```

**Settings explanation:**

* `xpack.security.enabled: true`
  * **Purpose:** Enable X-Pack security features
  * **Required:** Must be `true` for authentication

* `xpack.security.authc.api_key.enabled: true`
  * **Purpose:** Enable API key authentication
  * **Default:** `true` (enabled by default)

* `xpack.security.authc.api_key.cache.ttl: 1h`
  * **Purpose:** How long API keys are cached in memory
  * **Default:** `1h` (1 hour)
  * **Note:** Longer TTL improves performance but uses more memory

* `xpack.security.authc.api_key.cache.max_keys: 10000`
  * **Purpose:** Maximum number of API keys to cache
  * **Default:** `10000`
  * **Note:** Adjust based on number of active API keys

* `xpack.security.audit.enabled: false`
  * **Purpose:** Enable security audit logging
  * **Values:** `true` or `false`
  * **Note:** Enable in production to track security events

* `xpack.security.audit.logfile.events.include: [...]`
  * **Purpose:** Which security events to log
  * **Options:** `access_denied`, `authentication_failed`, `authentication_success`, `access_granted`
  * **Purpose:** Track failed login attempts and access denials

---

### 4.2 View Security Settings

**Check current security settings:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/settings?include_defaults=true&filter_path=**.security&pretty"
```

**Command explanation:**
* `_cluster/settings`: Cluster settings API
* `include_defaults=true`: Include default values
* `filter_path=**.security`: Filter to show only security-related settings
* `?pretty`: Format JSON output
* **Purpose:** View all security-related configuration

---

## 5. Security Best Practices

### 5.1 API Key Best Practices

* **Use restricted API keys:** Grant only necessary permissions
* **Set expiration:** Use expiration for temporary access
* **Rotate regularly:** Revoke and recreate API keys periodically
* **Store securely:** Keep API keys in secure storage (not in code repositories)
* **Monitor usage:** Regularly review API key usage and revoke unused ones

### 5.2 General Security Best Practices

* **Enable HTTPS:** Use TLS/SSL in production
* **Strong passwords:** Use complex passwords for all users
* **Principle of least privilege:** Grant minimum required permissions
* **Regular audits:** Review user access and permissions regularly
* **Enable audit logging:** Track security events in production

---

## 6. Troubleshooting

### 6.1 API Key Issues

**Problem: API key authentication fails**

```bash
# Test API key
curl -H "Authorization: ApiKey <BASE64_KEY>" http://localhost:9200

# Check API key details
curl -u elastic:changeme -X GET "http://localhost:9200/_security/api_key?id=<KEY_ID>&pretty"
```

**Common issues:**
* API key expired → Create new API key
* API key revoked → Check if key was deleted
* Incorrect encoding → Verify base64 encoding
* Wrong format → Ensure format is `ApiKey <base64_encoded_id:key>`

### 6.2 DLS/FLS Issues

**Problem: Users can't see expected documents/fields**

```bash
# Check user's roles
curl -u elastic:changeme -X GET "http://localhost:9200/_security/user/<username>?pretty"

# Check role definition
curl -u elastic:changeme -X GET "http://localhost:9200/_security/role/<role_name>?pretty"
```

**Common issues:**
* DLS query too restrictive → Review query logic
* Missing user metadata → Ensure user has required metadata
* Field names don't match → Verify field names in documents

---

## Verification Commands

**Check Elasticsearch service:**

```bash
docker compose ps elasticsearch
```

**Command explanation:**
* `ps`: List running containers
* **Purpose:** Verify Elasticsearch is running

**Test API key authentication:**

```bash
curl -H "Authorization: ApiKey <BASE64_ENCODED_KEY>" http://localhost:9200
```

**List all API keys:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_security/api_key?pretty"
```

**Check cluster security status:**

```bash
curl -u elastic:changeme http://localhost:9200/_security/_authenticate?pretty
```

**Command explanation:**
* `_security/_authenticate`: Authenticate current user
* **Purpose:** Verify authentication is working and see current user details

---
