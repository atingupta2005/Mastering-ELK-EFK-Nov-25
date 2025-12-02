# Troubleshooting: Cluster Setup Error

## Error Message
```
unable to prepare context: path "/home/student/Mastering-ELK-EFK-Nov-25/setup" not found
```

## Diagnostic Steps

### Step 1: Verify Current Directory

```bash
# Check where you are
pwd

# Should show: /home/student/docker-elk
# If it shows Mastering-ELK-EFK-Nov-25, you're in the wrong place!
```

### Step 2: Verify Required Directories Exist

```bash
# Check if setup directory exists
ls -la setup/

# Check all required directories
ls -d setup elasticsearch logstash kibana

# If any are missing, you need to clone/update docker-elk
```

### Step 3: Check if docker-compose.cluster.yml is in Current Directory

```bash
# List files in current directory
ls -la docker-compose*.yml

# Should show both:
# - docker-compose.yml (original)
# - docker-compose.cluster.yml (cluster version)
```

### Step 4: Verify .env File Exists

```bash
# Check if .env file exists
ls -la .env

# If it doesn't exist, create it:
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

## Common Issues & Fixes

### Issue 1: setup/ Directory Missing

**Symptom:** Error says "path .../setup not found"

**Fix:**
```bash
cd ~/docker-elk

# Check if setup exists
ls setup/

# If it doesn't exist, you need to:
# 1. Make sure you cloned docker-elk correctly
# 2. Or re-clone it:
cd ~
rm -rf docker-elk
git clone https://github.com/deviantony/docker-elk.git
cd docker-elk
```

### Issue 2: Wrong docker-compose.cluster.yml File

**Symptom:** File might have wrong paths

**Fix:**
```bash
# Verify the file uses relative paths
grep -n "context:" docker-compose.cluster.yml

# Should show:
# context: setup/
# context: elasticsearch/
# context: logstash/
# context: kibana/

# If it shows absolute paths, the file is wrong
```

### Issue 3: .env File Missing or Wrong Location

**Symptom:** Warnings about ELASTIC_VERSION not set

**Fix:**
```bash
# Make sure .env is in docker-elk directory
cd ~/docker-elk
cat .env

# Should show ELASTIC_VERSION=9.2.0
# If not, create it (see Step 4 above)
```

## Complete Verification Checklist

Run these commands and verify all pass:

```bash
cd ~/docker-elk

# ✅ Check 1: Current directory
echo "Current directory: $(pwd)"
# Should show: /home/student/docker-elk

# ✅ Check 2: Required directories exist
[ -d setup ] && echo "✓ setup/ exists" || echo "✗ setup/ MISSING"
[ -d elasticsearch ] && echo "✓ elasticsearch/ exists" || echo "✗ elasticsearch/ MISSING"
[ -d logstash ] && echo "✓ logstash/ exists" || echo "✗ logstash/ MISSING"
[ -d kibana ] && echo "✓ kibana/ exists" || echo "✗ kibana/ MISSING"

# ✅ Check 3: Compose files exist
[ -f docker-compose.yml ] && echo "✓ docker-compose.yml exists" || echo "✗ docker-compose.yml MISSING"
[ -f docker-compose.cluster.yml ] && echo "✓ docker-compose.cluster.yml exists" || echo "✗ docker-compose.cluster.yml MISSING"

# ✅ Check 4: .env file exists
[ -f .env ] && echo "✓ .env exists" || echo "✗ .env MISSING"

# ✅ Check 5: .env has ELASTIC_VERSION
grep -q "ELASTIC_VERSION" .env && echo "✓ .env has ELASTIC_VERSION" || echo "✗ .env missing ELASTIC_VERSION"
```

## If setup/ Directory is Missing

If the `setup/` directory doesn't exist, you need to get it from docker-elk:

```bash
cd ~/docker-elk

# Check what you have
ls -la

# If setup/ is missing, you might have an incomplete clone
# Re-clone docker-elk:
cd ~
rm -rf docker-elk
git clone https://github.com/deviantony/docker-elk.git
cd docker-elk

# Verify setup directory exists
ls -la setup/
```

## Quick Fix Script

Run this to check and fix everything:

```bash
#!/bin/bash

cd ~/docker-elk || { echo "ERROR: ~/docker-elk directory not found!"; exit 1; }

echo "Checking setup..."

# Check directories
for dir in setup elasticsearch logstash kibana; do
    if [ ! -d "$dir" ]; then
        echo "ERROR: $dir/ directory missing!"
        echo "You need to clone docker-elk repository first:"
        echo "  cd ~"
        echo "  git clone https://github.com/deviantony/docker-elk.git"
        exit 1
    fi
done

# Check .env
if [ ! -f .env ]; then
    echo "Creating .env file..."
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
    echo "✓ .env file created"
else
    echo "✓ .env file exists"
fi

# Check docker-compose.cluster.yml
if [ ! -f docker-compose.cluster.yml ]; then
    echo "ERROR: docker-compose.cluster.yml not found!"
    echo "Copy it from Mastering-ELK-EFK-Nov-25 directory"
    exit 1
else
    echo "✓ docker-compose.cluster.yml exists"
fi

echo ""
echo "All checks passed! You can now run:"
echo "  docker compose -f docker-compose.cluster.yml --profile=setup up setup"
```

Save this as `check-setup.sh` and run:
```bash
chmod +x check-setup.sh
./check-setup.sh
```

