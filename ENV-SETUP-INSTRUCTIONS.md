# .env File Setup Instructions

## Issue

The `docker-compose.cluster.yml` file requires a `.env` file with `ELASTIC_VERSION` and password variables.

## Solution

Create a `.env` file in your `docker-elk` directory (or the directory where `docker-compose.cluster.yml` is located).

## Steps

### 1. Navigate to your docker-elk directory

```bash
cd ~/docker-elk
# OR
cd ~/Mastering-ELK-EFK-Nov-25/docker-elk
```

### 2. Create .env file

```bash
cat > .env << 'EOF'
# Elastic Stack Version
ELASTIC_VERSION=9.2.0

# Elasticsearch Passwords
ELASTIC_PASSWORD=changeme
LOGSTASH_INTERNAL_PASSWORD=changeme
KIBANA_SYSTEM_PASSWORD=changeme

# Beats Passwords (if using)
METRICBEAT_INTERNAL_PASSWORD=changeme
FILEBEAT_INTERNAL_PASSWORD=changeme
HEARTBEAT_INTERNAL_PASSWORD=changeme
MONITORING_INTERNAL_PASSWORD=changeme
BEATS_SYSTEM_PASSWORD=changeme
EOF
```

### 3. Verify .env file

```bash
cat .env
```

You should see all the variables listed above.

### 4. Now run docker-compose

```bash
docker compose -f docker-compose.cluster.yml --profile=setup up setup
docker compose -f docker-compose.cluster.yml up -d
```

## Alternative: Manual Creation

If the above doesn't work, create the file manually:

```bash
nano .env
```

Then paste:

```
ELASTIC_VERSION=9.2.0
ELASTIC_PASSWORD=changeme
LOGSTASH_INTERNAL_PASSWORD=changeme
KIBANA_SYSTEM_PASSWORD=changeme
METRICBEAT_INTERNAL_PASSWORD=changeme
FILEBEAT_INTERNAL_PASSWORD=changeme
HEARTBEAT_INTERNAL_PASSWORD=changeme
MONITORING_INTERNAL_PASSWORD=changeme
BEATS_SYSTEM_PASSWORD=changeme
```

Save and exit (Ctrl+X, then Y, then Enter).

## Version Compatibility

- **ELASTIC_VERSION=9.2.0** - Matches docker-elk default
- You can change this to any 9.x version (e.g., 9.1.0, 9.3.0)
- Make sure all components (Elasticsearch, Logstash, Kibana) use the same version

## Security Note

⚠️ **For production:** Change all passwords from `changeme` to strong, unique passwords.

