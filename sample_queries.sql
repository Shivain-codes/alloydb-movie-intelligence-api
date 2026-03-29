-- ============================================================
-- Sample Natural Language Queries — Demonstration
-- AlloyDB Movie Intelligence Database
-- ============================================================

-- These queries demonstrate the NL2SQL capability of AlloyDB AI.
-- Each shows the natural language input and the equivalent SQL
-- that AlloyDB AI generates and executes automatically.

-- ─────────────────────────────────────────────────────────────
-- QUERY 1: Top rated films by genre
-- NL Input: "Show me the top 5 highest rated science fiction movies"
-- ─────────────────────────────────────────────────────────────
SELECT * FROM movies.natural_language_query(
    'Show me the top 5 highest rated science fiction movies'
);
-- Expected SQL output:
-- SELECT title, release_year, director, rating, runtime_mins
-- FROM movies.films
-- WHERE genre = 'Sci-Fi'
-- ORDER BY rating DESC
-- LIMIT 5;

-- ─────────────────────────────────────────────────────────────
-- QUERY 2: Award-winning films
-- NL Input: "Which films won Academy Awards for Best Picture?"
-- ─────────────────────────────────────────────────────────────
SELECT * FROM movies.natural_language_query(
    'Which films won Academy Awards for Best Picture?'
);
-- Expected SQL output:
-- SELECT f.title, f.release_year, f.director, f.rating, a.year
-- FROM movies.films f
-- JOIN movies.awards a ON a.film_id = f.film_id
-- WHERE a.award_name = 'Academy Award'
--   AND a.category = 'Best Picture'
--   AND a.won = TRUE
-- ORDER BY a.year DESC
-- LIMIT 20;

-- ─────────────────────────────────────────────────────────────
-- QUERY 3: Director filmography
-- NL Input: "List all Christopher Nolan movies with their ratings"
-- ─────────────────────────────────────────────────────────────
SELECT * FROM movies.natural_language_query(
    'List all Christopher Nolan movies with their ratings'
);

-- ─────────────────────────────────────────────────────────────
-- QUERY 4: International films
-- NL Input: "Show me movies that are not in English sorted by rating"
-- ─────────────────────────────────────────────────────────────
SELECT * FROM movies.natural_language_query(
    'Show me movies that are not in English sorted by rating'
);

-- ─────────────────────────────────────────────────────────────
-- QUERY 5: Long movies
-- NL Input: "What are the 10 longest movies in the database?"
-- ─────────────────────────────────────────────────────────────
SELECT * FROM movies.natural_language_query(
    'What are the 10 longest movies in the database?'
);

-- ─────────────────────────────────────────────────────────────
-- QUERY 6: Specific actor
-- NL Input: "Which movies feature Leonardo DiCaprio?"
-- ─────────────────────────────────────────────────────────────
SELECT * FROM movies.natural_language_query(
    'Which movies feature Leonardo DiCaprio?'
);

-- ─────────────────────────────────────────────────────────────
-- QUERY 7: High rated recent films
-- NL Input: "Show me drama movies from after 2010 with rating above 8"
-- ─────────────────────────────────────────────────────────────
SELECT * FROM movies.natural_language_query(
    'Show me drama movies from after 2010 with rating above 8'
);

-- ─────────────────────────────────────────────────────────────
-- QUERY 8: Semantic Search (vector similarity)
-- NL Input: Conceptual search using embeddings
-- ─────────────────────────────────────────────────────────────
SELECT * FROM movies.semantic_search(
    'a story about artificial intelligence and robots', 5
);

SELECT * FROM movies.semantic_search(
    'space exploration and survival in outer space', 5
);

SELECT * FROM movies.semantic_search(
    'crime family and organized crime drama', 5
);

-- ─────────────────────────────────────────────────────────────
-- Verify database statistics
-- ─────────────────────────────────────────────────────────────
SELECT * FROM movies.film_summary ORDER BY rating DESC LIMIT 10;
