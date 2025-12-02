# Quick Start: Multi-Node Cluster Setup

## ⚠️ IMPORTANT: Where to Run Commands

**You MUST run docker-compose commands from the `~/docker-elk` directory, NOT from `Mastering-ELK-EFK-Nov-25`.**

## Step-by-Step Setup

### Step 1: Go to docker-elk Directory

```bash
cd ~/docker-elk
```

### Step 2: Copy Required Files

If you have `docker-compose.cluster.yml` and config files in `Mastering-ELK-EFK-Nov-25`:

```bash
# Copy cluster compose file
cp ~/Mastering-ELK-EFK-Nov-25/docker-compose.cluster.yml .

# Copy Elasticsearch config files
cp ~/Mastering-ELK-EFK-Nov-25/elasticsearch/config/elasticsearch-master.yml elasticsearch/config/
cp ~/Mastering-ELK-EFK-Nov-25/elasticsearch/config/elasticsearch-data.yml elasticsearch/config/
cp ~/Mastering-ELK-EFK-Nov-25/elasticsearch/config/elasticsearch-coordinating.yml elasticsearch/config/
```

### Step 3: Create .env File

```bash
# Make sure you're in ~/docker-elk directory
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
```

### Step 4: Verify You're in the Right Directory

```bash
# Check you're in docker-elk
pwd
# Should show: /home/student/docker-elk

# Verify required directories exist
ls -d setup elasticsearch logstash kibana
# Should show all 4 directories
```

### Step 5: Run Setup

```bash
# Run setup (one-time initialization)
docker compose -f docker-compose.cluster.yml --profile=setup up setup

# Start the cluster
docker compose -f docker-compose.cluster.yml up -d
```

## Verify It's Working

```bash
# Check cluster health
curl -u elastic:changeme http://localhost:9200/_cluster/health?pretty

# List all nodes
curl -u elastic:changeme http://localhost:9200/_cat/nodes?v
```

## Common Mistakes

❌ **Wrong:** Running from `Mastering-ELK-EFK-Nov-25` directory
```bash
cd ~/Mastering-ELK-EFK-Nov-25
docker compose -f docker-compose.cluster.yml up  # ❌ ERROR
```

✅ **Correct:** Running from `docker-elk` directory
```bash
cd ~/docker-elk
docker compose -f docker-compose.cluster.yml up  # ✅ WORKS
```

## Directory Structure Required

```
~/docker-elk/                          ← You must be HERE
├── docker-compose.yml                 (original)
├── docker-compose.cluster.yml         (cluster version)
├── .env                               (you create this)
├── setup/                             (from docker-elk repo)
│   ├── entrypoint.sh
│   ├── lib.sh
│   └── roles/
├── elasticsearch/
│   └── config/
│       ├── elasticsearch.yml
│       ├── elasticsearch-master.yml
│       ├── elasticsearch-data.yml
│       └── elasticsearch-coordinating.yml
├── logstash/
│   ├── config/
│   └── pipeline/
└── kibana/
    └── config/
```

## If You Don't Have docker-elk Cloned

```bash
# Clone docker-elk repository
cd ~
git clone https://github.com/deviantony/docker-elk.git
cd docker-elk

# Then follow steps 2-5 above
```

