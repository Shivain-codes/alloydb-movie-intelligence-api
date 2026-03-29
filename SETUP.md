# AlloyDB Movie Intelligence — Setup Guide

## Step-by-Step Deployment

---

### 1. Create AlloyDB Cluster

```bash
gcloud alloydb clusters create movies-cluster \
  --region=us-central1 \
  --password=YOUR_STRONG_PASSWORD \
  --project=YOUR_PROJECT_ID
```

### 2. Create AlloyDB Instance

```bash
gcloud alloydb instances create movies-instance \
  --cluster=movies-cluster \
  --region=us-central1 \
  --instance-type=PRIMARY \
  --cpu-count=2 \
  --project=YOUR_PROJECT_ID
```

### 3. Get AlloyDB IP

```bash
gcloud alloydb instances describe movies-instance \
  --cluster=movies-cluster \
  --region=us-central1 \
  --format="value(ipAddress)"
```

### 4. Create Database

```bash
# Connect via Cloud Shell or a VM in the same VPC
psql -h ALLOYDB_IP -U postgres -c "CREATE DATABASE movies_db;"
```

### 5. Run setup.sql

```bash
psql -h ALLOYDB_IP -U postgres -d movies_db -f setup.sql
```

This will:
- Enable AlloyDB AI extensions (google_ml_integration, vector)
- Create the movies schema with 3 tables
- Insert 50 films with cast and awards
- Create NL2SQL and semantic search functions
- Generate vector embeddings for all films

### 6. Deploy API to Cloud Run

```bash
export PROJECT_ID=your-project-id
export ALLOYDB_IP=your-alloydb-ip

# Build
gcloud builds submit --tag gcr.io/$PROJECT_ID/alloydb-movies:latest .

# Deploy
gcloud run deploy alloydb-movies \
  --image gcr.io/$PROJECT_ID/alloydb-movies:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --set-env-vars "DB_HOST=$ALLOYDB_IP,DB_NAME=movies_db,DB_USER=postgres,DB_PASSWORD=YOUR_PASSWORD" \
  --vpc-connector your-vpc-connector
```

### 7. Test Natural Language Queries

```bash
BASE_URL=https://YOUR_CLOUD_RUN_URL

# NL to SQL query
curl -X POST $BASE_URL/query \
  -H "Content-Type: application/json" \
  -d '{"question": "Show me top 5 highest rated sci-fi movies"}'

# Semantic search
curl -X POST $BASE_URL/search \
  -H "Content-Type: application/json" \
  -d '{"query": "artificial intelligence and robots", "top_k": 5}'

# Stats
curl $BASE_URL/stats
```
