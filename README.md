# AlloyDB Movie Intelligence API

FastAPI service for querying a movie dataset in AlloyDB for PostgreSQL using:
- Natural language to SQL (via AlloyDB AI)
- Semantic similarity search (via pgvector embeddings)

## What This Project Contains

- `main.py`: FastAPI app with API endpoints and async PostgreSQL pool.
- `setup.sql`: Full database bootstrap (schema, sample data, indexes, NL2SQL + semantic search functions, embeddings, view).
- `sample_queries.sql`: Example NL2SQL calls for demos.
- `requirements.txt`: Python dependencies.
- `Dockerfile`: Container image for local run or Cloud Run deploy.
- `SETUP.md`: Detailed AlloyDB + Cloud Run deployment walkthrough.

## API Endpoints

- `GET /`: Service metadata and example questions
- `GET /health`: DB connectivity check + film count
- `POST /query`: Natural language to SQL and result execution
- `POST /search`: Semantic movie search by meaning
- `GET /films`: List films with optional filters
- `GET /genres`: Genre counts and average ratings
- `GET /stats`: Aggregate dataset stats
- `GET /docs`: Swagger UI

## Environment Variables

The app reads these values at startup:

- `DB_HOST` (default: `127.0.0.1`)
- `DB_PORT` (default: `5432`)
- `DB_NAME` (default: `movies_db`)
- `DB_USER` (default: `postgres`)
- `DB_PASSWORD` (default: empty)
- `PORT` (default: `8080`)

## Local Development

### 1. Create virtual environment and install dependencies

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Prepare database

Run `setup.sql` against your AlloyDB/PostgreSQL database:

```bash
psql -h <DB_HOST> -U <DB_USER> -d <DB_NAME> -f setup.sql
```

### 3. Start the API

```bash
python main.py
```

Open docs at: `http://localhost:8080/docs`

## Docker

### Build

```bash
docker build -t alloydb-movies:latest .
```

### Run

```bash
docker run --rm -p 8080:8080 \
  -e DB_HOST=<DB_HOST> \
  -e DB_PORT=5432 \
  -e DB_NAME=movies_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=<DB_PASSWORD> \
  alloydb-movies:latest
```

## Example Requests

### Natural language query

```bash
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -d '{"question":"Show me the top 5 highest rated science fiction movies"}'
```

### Semantic search

```bash
curl -X POST http://localhost:8080/search \
  -H "Content-Type: application/json" \
  -d '{"query":"a story about artificial intelligence and robots", "top_k": 5}'
```

## Notes

- `setup.sql` uses AlloyDB-specific features (`google_ml_integration`, `embedding`, `vector`).
- `SETUP.md` includes Cloud Run deployment commands and networking notes.
