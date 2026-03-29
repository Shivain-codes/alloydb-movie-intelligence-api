"""
AlloyDB Movie Intelligence — Natural Language Query API
Connects to AlloyDB for PostgreSQL and exposes natural language querying.
"""

import os
import json
import logging
from contextlib import asynccontextmanager
from typing import Optional, Any

import asyncpg
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ── Config ────────────────────────────────────────────────────────────────────

DB_HOST     = os.environ.get("DB_HOST",     "127.0.0.1")
DB_PORT     = int(os.environ.get("DB_PORT", "5432"))
DB_NAME     = os.environ.get("DB_NAME",     "postgres")
DB_USER     = os.environ.get("DB_USER",     "postgres")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")

# ── Schemas ───────────────────────────────────────────────────────────────────

class NLQueryRequest(BaseModel):
    question: str = Field(
        ...,
        description="Natural language question about movies",
        example="Show me the top 5 highest rated sci-fi movies"
    )

class SearchRequest(BaseModel):
    query: str = Field(..., description="Semantic search query")
    top_k: Optional[int] = Field(5, description="Number of results to return")

class NLQueryResponse(BaseModel):
    question:      str
    generated_sql: str
    results:       list[dict[str, Any]]
    row_count:     int

class SearchResponse(BaseModel):
    query:   str
    results: list[dict[str, Any]]

# ── Database Pool ─────────────────────────────────────────────────────────────

db_pool: asyncpg.Pool = None

async def get_pool() -> asyncpg.Pool:
    global db_pool
    if db_pool is None:
        db_pool = await asyncpg.create_pool(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            min_size=2,
            max_size=10,
            command_timeout=60,
        )
    return db_pool

# ── App ───────────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Connecting to AlloyDB...")
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            result = await conn.fetchval("SELECT COUNT(*) FROM movies.films")
            logger.info(f"Connected to AlloyDB. Films in database: {result}")
    except Exception as e:
        logger.error(f"DB connection error: {e}")
    yield
    if db_pool:
        await db_pool.close()
        logger.info("AlloyDB connection closed.")

app = FastAPI(
    title="AlloyDB Movie Intelligence API",
    description=(
        "Natural language querying of a custom movie dataset stored in AlloyDB for PostgreSQL. "
        "Uses AlloyDB AI to convert natural language to SQL and execute against the database."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {
        "service":     "AlloyDB Movie Intelligence",
        "database":    "AlloyDB for PostgreSQL",
        "dataset":     "Custom Movie Database (50 films)",
        "ai_feature":  "AlloyDB AI Natural Language to SQL",
        "status":      "running",
        "endpoints": {
            "nl_query":   "POST /query — Natural language to SQL query",
            "search":     "POST /search — Semantic similarity search",
            "films":      "GET  /films — List all films",
            "genres":     "GET  /genres — List all genres",
            "stats":      "GET  /stats — Database statistics",
            "health":     "GET  /health",
            "docs":       "GET  /docs",
        },
        "sample_questions": [
            "Show me the top 5 highest rated science fiction movies",
            "Which films won Academy Awards for Best Picture?",
            "List all Christopher Nolan movies with their ratings",
            "Show me Korean movies sorted by rating",
            "What are the longest movies in the database?",
        ]
    }

@app.get("/health")
async def health():
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            count = await conn.fetchval("SELECT COUNT(*) FROM movies.films")
        return {
            "status":      "healthy",
            "database":    "AlloyDB connected",
            "film_count":  count,
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database error: {str(e)}")

@app.post("/query", response_model=NLQueryResponse)
async def natural_language_query(req: NLQueryRequest):
    """
    Convert a natural language question to SQL using AlloyDB AI
    and execute it against the movie database.

    Examples:
    - "Show me the top 5 highest rated sci-fi movies"
    - "Which films won Academy Awards for Best Picture?"
    - "List all Christopher Nolan movies"
    - "Show me Korean films sorted by rating"
    """
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                "SELECT query_sql, result_json FROM movies.natural_language_query($1)",
                req.question
            )

        if not rows:
            raise HTTPException(status_code=500, detail="No response from NL2SQL function")

        generated_sql = rows[0]["query_sql"]
        result_json   = rows[0]["result_json"]

        results = []
        if result_json and not isinstance(result_json, str):
            results = list(result_json) if result_json else []

        return NLQueryResponse(
            question=req.question,
            generated_sql=generated_sql,
            results=results,
            row_count=len(results),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"NL query error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/search", response_model=SearchResponse)
async def semantic_search(req: SearchRequest):
    """
    Search for movies using semantic similarity (vector embeddings).
    Finds movies that are conceptually similar to the query.

    Examples:
    - "a story about artificial intelligence"
    - "space exploration and survival"
    - "family love and redemption"
    """
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """SELECT title, genre, rating, release_year, synopsis, similarity
                   FROM movies.semantic_search($1, $2)""",
                req.query, req.top_k
            )

        results = [dict(r) for r in rows]
        return SearchResponse(query=req.query, results=results)

    except Exception as e:
        logger.error(f"Semantic search error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/films")
async def list_films(
    genre:    Optional[str] = None,
    min_rating: Optional[float] = None,
    year_from:  Optional[int] = None,
    limit:    int = 20
):
    """List films with optional filters."""
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            query = """
                SELECT film_id, title, release_year, genre, director,
                       rating, runtime_mins, language, country
                FROM movies.films
                WHERE ($1::VARCHAR IS NULL OR genre ILIKE $1)
                  AND ($2::NUMERIC IS NULL OR rating >= $2)
                  AND ($3::INTEGER IS NULL OR release_year >= $3)
                ORDER BY rating DESC
                LIMIT $4
            """
            rows = await conn.fetch(query, genre, min_rating, year_from, limit)
        return {"films": [dict(r) for r in rows], "count": len(rows)}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/genres")
async def list_genres():
    """List all genres with film counts."""
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT genre, COUNT(*) AS film_count, ROUND(AVG(rating),1) AS avg_rating
                FROM movies.films
                GROUP BY genre
                ORDER BY film_count DESC
            """)
        return {"genres": [dict(r) for r in rows]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/stats")
async def database_stats():
    """Return database statistics."""
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            stats = await conn.fetchrow("""
                SELECT
                    COUNT(*)                        AS total_films,
                    COUNT(DISTINCT genre)           AS total_genres,
                    COUNT(DISTINCT director)        AS total_directors,
                    COUNT(DISTINCT language)        AS total_languages,
                    ROUND(AVG(rating),2)            AS avg_rating,
                    MAX(rating)                     AS highest_rating,
                    MIN(release_year)               AS oldest_film_year,
                    MAX(release_year)               AS newest_film_year
                FROM movies.films
            """)
            awards = await conn.fetchval(
                "SELECT COUNT(*) FROM movies.awards WHERE won = TRUE"
            )
        return {
            "database_stats": dict(stats),
            "total_award_wins": awards,
            "alloydb_features": [
                "AlloyDB AI NL2SQL via google_ml_integration",
                "Vector embeddings via textembedding-gecko@003",
                "Semantic search via pgvector",
                "Custom schema: movies.films, movies.cast_members, movies.awards",
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ── Entry ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run("main:app", host="0.0.0.0", port=port, log_level="info")
