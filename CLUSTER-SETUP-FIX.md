# Fix: docker-compose.cluster.yml Setup Error

## Problem

You're getting this error:
```
unable to prepare context: path "/home/student/Mastering-ELK-EFK-Nov-25/setup" not found
```

## Root Cause

The `docker-compose.cluster.yml` file requires the **docker-elk repository structure** (setup/, elasticsearch/, logstash/, kibana/ directories), but you're trying to run it from the `Mastering-ELK-EFK-Nov-25` directory which doesn't have these.

## Solution

You have two options:

### Option 1: Use docker-compose.cluster.yml in docker-elk directory (Recommended)

1. **Navigate to your docker-elk directory:**
   ```bash
   cd ~/docker-elk
   ```

2. **Copy the cluster compose file to docker-elk:**
   ```bash
   # Copy from your Mastering-ELK-EFK-Nov-25 directory
   cp ~/Mastering-ELK-EFK-Nov-25/docker-compose.cluster.yml .
   
   # OR if you have it in the current workspace, copy it manually
   ```

3. **Copy the Elasticsearch config files:**
   ```bash
   # Create config files if they don't exist
   mkdir -p elasticsearch/config
   
   # Copy the cluster-specific configs
   cp ~/Mastering-ELK-EFK-Nov-25/elasticsearch/config/elasticsearch-master.yml elasticsearch/config/
   cp ~/Mastering-ELK-EFK-Nov-25/elasticsearch/config/elasticsearch-data.yml elasticsearch/config/
   cp ~/Mastering-ELK-EFK-Nov-25/elasticsearch/config/elasticsearch-coordinating.yml elasticsearch/config/
   ```

4. **Create .env file in docker-elk directory:**
   ```bash
   cd ~/docker-elk
   cat > .env << 'EOF'
   ELASTIC_VERSION=9.2.0
   ELASTIC_PASSWORD=changeme
   LOGSTASH_INTERNAL_PASSWORD=changeme
   KIBANA_SYSTEM_PASSWORD=changeme
   METRICBEAT_INTERNAL_PASSWORD=changeme
   FILEBEAT_INTERNAL_PASSWORD=changeme
   HEARTBEAT_INTERNAL_PASSWORD=changeme
   MONITORING_INTERNAL_PASSWORD=changeme
   BEATS_SYSTEM_PASSWORD=changeme
   EOF
   ```

5. **Run the cluster setup:**
   ```bash
   docker compose -f docker-compose.cluster.yml --profile=setup up setup
   docker compose -f docker-compose.cluster.yml up -d
   ```

### Option 2: Create docker-elk structure in Mastering-ELK-EFK-Nov-25 (Not Recommended)

This would require cloning docker-elk inside your repo, which is messy. **Option 1 is better.**

## Quick Setup Script

Run this from your home directory:

```bash
#!/bin/bash

# Navigate to docker-elk
cd ~/docker-elk

# Create .env file
cat > .env << 'EOF'
ELASTIC_VERSION=9.2.0
ELASTIC_PASSWORD=changeme
LOGSTASH_INTERNAL_PASSWORD=changeme
KIBANA_SYSTEM_PASSWORD=changeme
METRICBEAT_INTERNAL_PASSWORD=changeme
FILEBEAT_INTERNAL_PASSWORD=changeme
HEARTBEAT_INTERNAL_PASSWORD=changeme
MONITORING_INTERNAL_PASSWORD=changeme
BEATS_SYSTEM_PASSWORD=changeme
EOF

# Copy cluster compose file (if you have it)
# cp ~/Mastering-ELK-EFK-Nov-25/docker-compose.cluster.yml .

# Copy config files (if you have them)
# mkdir -p elasticsearch/config
# cp ~/Mastering-ELK-EFK-Nov-25/elasticsearch/config/elasticsearch-*.yml elasticsearch/config/

echo "Setup complete! Now run:"
echo "  docker compose -f docker-compose.cluster.yml --profile=setup up setup"
echo "  docker compose -f docker-compose.cluster.yml up -d"
```

## Verify Directory Structure

Your `~/docker-elk` directory should have:
```
docker-elk/
├── docker-compose.yml          (original)
├── docker-compose.cluster.yml  (new cluster version)
├── .env                        (new - you create this)
├── setup/                      (from docker-elk repo)
├── elasticsearch/
│   └── config/
│       ├── elasticsearch.yml
│       ├── elasticsearch-master.yml      (new)
│       ├── elasticsearch-data.yml        (new)
│       └── elasticsearch-coordinating.yml (new)
├── logstash/
│   ├── config/
│   └── pipeline/
└── kibana/
    └── config/
```

## After Setup

Once the cluster is running, you can:
- Access Elasticsearch: `http://localhost:9200` (master node)
- Access Kibana: `http://localhost:5601`
- Check cluster: `curl -u elastic:changeme http://localhost:9200/_cat/nodes?v`

