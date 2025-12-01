# Multi-Node Elasticsearch Cluster Setup Guide

## Overview

This enhanced docker-compose configuration creates a **multi-node Elasticsearch cluster** suitable for hands-on exercises in **Days 9-12**, covering:

- **Day 9-10**: Cluster architecture, sharding, replication, performance tuning
- **Day 11-12**: Security, monitoring, and maintenance

## Cluster Architecture

The cluster consists of:

1. **Master Node** (`elasticsearch-master`)
   - Role: Master + Data + Ingest
   - Port: 9200 (main API access)
   - Manages cluster state and can store data

2. **Data Node 1** (`elasticsearch-data-1`)
   - Role: Data + Ingest
   - Port: 9201 (monitoring)
   - Stores primary and replica shards

3. **Data Node 2** (`elasticsearch-data-2`)
   - Role: Data + Ingest
   - Port: 9202 (monitoring)
   - Stores primary and replica shards

4. **Coordinating Node** (`elasticsearch-coordinating`)
   - Role: Coordinating only (no data, no master)
   - Port: 9203 (client connections)
   - Routes requests to data nodes

5. **Logstash** (unchanged)
   - Connects to cluster via master node

6. **Kibana** (updated)
   - Connects to coordinating node for better load distribution

## Setup Instructions

### Step 1: Create Configuration Files

Create the following Elasticsearch config files:

```bash
# Master node config
cp elasticsearch/config/elasticsearch.yml elasticsearch/config/elasticsearch-master.yml

# Data node config
cp elasticsearch/config/elasticsearch.yml elasticsearch/config/elasticsearch-data.yml

# Coordinating node config
cp elasticsearch/config/elasticsearch.yml elasticsearch/config/elasticsearch-coordinating.yml
```

The config files are already created in this setup.

### Step 2: Initialize the Cluster

```bash
# Run setup (one-time initialization)
docker compose -f docker-compose.cluster.yml --profile=setup up setup

# Start the cluster
docker compose -f docker-compose.cluster.yml up -d
```

### Step 3: Verify Cluster Health

```bash
# Check cluster health
curl -u elastic:changeme http://localhost:9200/_cluster/health?pretty

# List all nodes
curl -u elastic:changeme http://localhost:9200/_cat/nodes?v

# Check node roles
curl -u elastic:changeme http://localhost:9200/_cat/nodes?v&h=name,node.role,master
```

Expected output should show:
- 1 master node
- 2 data nodes
- 1 coordinating node
- Cluster status: **green** (after all nodes join)

## Hands-On Exercises

### Day 9-10: Cluster Architecture

#### Exercise 1: View Node Types

```bash
curl -u elastic:changeme http://localhost:9200/_cat/nodes?v&h=name,node.role,master
```

**Expected Output:**
```
name                      node.role master
elasticsearch-master      dimr      *
elasticsearch-data-1      di        -
elasticsearch-data-2      di        -
elasticsearch-coordinating -        -
```

**Explanation:**
- `d` = data node
- `i` = ingest node
- `m` = master-eligible
- `r` = remote cluster client
- `*` = current master

#### Exercise 2: Create Index with Replicas

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/test-cluster" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 2,
    "number_of_replicas": 1
  }
}'
```

#### Exercise 3: View Shard Distribution

```bash
curl -u elastic:changeme http://localhost:9200/_cat/shards/test-cluster?v
```

**Expected:** Shards distributed across data nodes, replicas on different nodes.

#### Exercise 4: Test Coordinating Node

```bash
# Connect via coordinating node
curl -u elastic:changeme http://localhost:9203/_cat/nodes?v

# Search via coordinating node
curl -u elastic:changeme http://localhost:9203/test-cluster/_search?pretty
```

### Day 9-10: Sharding & Replication

#### Exercise 1: Create Multi-Shard Index

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/lab-logs" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1
  }
}'
```

#### Exercise 2: Verify Shard Placement

```bash
curl -u elastic:changeme http://localhost:9200/_cat/shards/lab-logs?v&h=index,shard,prirep,state,node
```

**Expected:** 3 primary shards + 3 replica shards = 6 total shards distributed across 2 data nodes.

#### Exercise 3: Simulate Node Failure

```bash
# Stop one data node
docker compose -f docker-compose.cluster.yml stop elasticsearch-data-1

# Check cluster health (should be yellow)
curl -u elastic:changeme http://localhost:9200/_cluster/health?pretty

# Restart the node
docker compose -f docker-compose.cluster.yml start elasticsearch-data-1

# Wait for recovery (should return to green)
curl -u elastic:changeme http://localhost:9200/_cluster/health?pretty
```

### Day 10: Performance Tuning

#### Exercise 1: Monitor Node Load

```bash
# Check node stats
curl -u elastic:changeme http://localhost:9200/_nodes/stats?pretty

# Check indexing rate per node
curl -u elastic:changeme http://localhost:9200/_nodes/stats/indices/indexing?pretty
```

#### Exercise 2: Test Load Distribution

```bash
# Bulk index documents
for i in {1..1000}; do
  curl -u elastic:changeme -X POST "http://localhost:9203/load-test/_doc" \
    -H 'Content-Type: application/json' \
    -d "{\"id\":$i,\"message\":\"test $i\"}"
done

# Check which nodes handled the load
curl -u elastic:changeme http://localhost:9200/_cat/shards/load-test?v&h=index,shard,node
```

### Day 11-12: Monitoring & Maintenance

#### Exercise 1: Cluster Health Monitoring

```bash
# Detailed cluster health
curl -u elastic:changeme http://localhost:9200/_cluster/health?pretty

# Node-level health
curl -u elastic:changeme http://localhost:9200/_cat/nodes?v&h=name,heap.percent,ram.percent,cpu,load_1m,node.role
```

#### Exercise 2: Shard Allocation

```bash
# View shard allocation details
curl -u elastic:changeme http://localhost:9200/_cat/allocation?v

# Check unassigned shards
curl -u elastic:changeme http://localhost:9200/_cat/shards?v&h=index,shard,prirep,state,unassigned.reason
```

## Configuration Details

### Memory Requirements

- **Master Node**: 512MB heap
- **Data Nodes**: 512MB heap each
- **Coordinating Node**: 256MB heap
- **Total**: ~2.5GB RAM minimum

### Port Mapping

| Service | Port | Purpose |
|---------|------|---------|
| elasticsearch-master | 9200 | Main API access |
| elasticsearch-data-1 | 9201 | Monitoring (optional) |
| elasticsearch-data-2 | 9202 | Monitoring (optional) |
| elasticsearch-coordinating | 9203 | Client connections |
| Logstash | 5044, 9600 | Beats input, monitoring |
| Kibana | 5601 | Web UI |

### Network Discovery

The cluster uses **unicast discovery** with seed hosts:
- `elasticsearch-master`
- `elasticsearch-data-1`
- `elasticsearch-data-2`

All nodes are configured as initial master nodes for cluster formation.

## Troubleshooting

### Cluster Not Forming

```bash
# Check if all nodes are running
docker compose -f docker-compose.cluster.yml ps

# Check logs
docker compose -f docker-compose.cluster.yml logs elasticsearch-master
docker compose -f docker-compose.cluster.yml logs elasticsearch-data-1
```

### Yellow Cluster Status

Yellow status means:
- All primary shards are allocated
- Some replica shards are missing (normal with 2 data nodes and replica=1)

To fix:
- Add more data nodes, OR
- Reduce replica count: `curl -u elastic:changeme -X PUT "http://localhost:9200/_settings" -H 'Content-Type: application/json' -d'{"index":{"number_of_replicas":0}}'`

### Node Not Joining Cluster

1. Check network connectivity:
   ```bash
   docker compose -f docker-compose.cluster.yml exec elasticsearch-data-1 ping elasticsearch-master
   ```

2. Verify discovery settings in config files

3. Check for port conflicts

## Switching Between Configurations

### Use Single-Node (Original)

```bash
docker compose up -d
```

### Use Multi-Node Cluster

```bash
docker compose -f docker-compose.cluster.yml up -d
```

### Stop Cluster

```bash
docker compose -f docker-compose.cluster.yml down

# To remove volumes (clean slate)
docker compose -f docker-compose.cluster.yml down -v
```

## Additional Notes

1. **First startup** may take 1-2 minutes for all nodes to join
2. **Cluster health** will be yellow initially (normal with 2 data nodes)
3. **Coordinating node** is optional but recommended for production-like setup
4. **Memory settings** can be adjusted in docker-compose.cluster.yml if needed
5. **Data persistence** - each node has its own volume

## Exercises Compatibility

All exercises in Days 9-12 are now compatible with this multi-node setup:

✅ **Day 9-10/07-cluster-architecture** - Can demonstrate all node types
✅ **Day 9-10/08-Sharding-Replication** - Can show shard distribution across nodes
✅ **Day 9-10/09-Performance-Tuning** - Can test load distribution
✅ **Day 9-10/10-Monitoring-Cluster-Health** - Can monitor multi-node cluster
✅ **Day 9-10/11-Hands-On** - All hands-on exercises work
✅ **Day 11-12/06-Monitoring-Maintenance** - Can monitor cluster health, nodes, shards

