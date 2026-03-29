-- ============================================================
-- AlloyDB Movie Intelligence Database
-- Natural Language to SQL using AlloyDB AI
-- Author: Shivain Gupta | Gen AI Academy APAC 2026
-- ============================================================

-- ── Step 1: Enable AlloyDB AI Extension ──────────────────────
-- Run this as a superuser/alloydbsuperuser
CREATE EXTENSION IF NOT EXISTS google_ml_integration CASCADE;
CREATE EXTENSION IF NOT EXISTS vector CASCADE;

-- ── Step 2: Grant permissions ─────────────────────────────────
GRANT EXECUTE ON FUNCTION embedding TO postgres;

-- ── Step 3: Create Custom Schema ─────────────────────────────
CREATE SCHEMA IF NOT EXISTS movies;

-- ── Step 4: Create Tables (custom schema - not from any lab) ──

-- Main movies table
CREATE TABLE IF NOT EXISTS movies.films (
    film_id       SERIAL PRIMARY KEY,
    title         VARCHAR(255)   NOT NULL,
    release_year  INTEGER        NOT NULL,
    genre         VARCHAR(100)   NOT NULL,
    director      VARCHAR(255)   NOT NULL,
    rating        NUMERIC(3,1)   CHECK (rating BETWEEN 0 AND 10),
    votes         INTEGER        DEFAULT 0,
    runtime_mins  INTEGER,
    language      VARCHAR(50)    DEFAULT 'English',
    country       VARCHAR(100),
    synopsis      TEXT,
    embedding     vector(768)    -- AlloyDB AI vector column for semantic search
);

-- Cast table
CREATE TABLE IF NOT EXISTS movies.cast_members (
    cast_id   SERIAL PRIMARY KEY,
    film_id   INTEGER REFERENCES movies.films(film_id) ON DELETE CASCADE,
    actor     VARCHAR(255) NOT NULL,
    role      VARCHAR(255),
    is_lead   BOOLEAN DEFAULT FALSE
);

-- Awards table
CREATE TABLE IF NOT EXISTS movies.awards (
    award_id    SERIAL PRIMARY KEY,
    film_id     INTEGER REFERENCES movies.films(film_id) ON DELETE CASCADE,
    award_name  VARCHAR(255) NOT NULL,
    category    VARCHAR(255),
    won         BOOLEAN DEFAULT FALSE,
    year        INTEGER
);

-- ── Step 5: Insert Custom Dataset (50 diverse films) ──────────

INSERT INTO movies.films
    (title, release_year, genre, director, rating, votes, runtime_mins, language, country, synopsis)
VALUES
-- Science Fiction
('Inception',           2010, 'Sci-Fi',   'Christopher Nolan',   8.8, 2400000, 148, 'English', 'USA',
 'A thief who steals corporate secrets through dream-sharing technology is given the task of planting an idea.'),
('Interstellar',        2014, 'Sci-Fi',   'Christopher Nolan',   8.6, 1900000, 169, 'English', 'USA',
 'A team of explorers travel through a wormhole in space to ensure humanity survival.'),
('The Matrix',          1999, 'Sci-Fi',   'Wachowski Sisters',   8.7, 1800000, 136, 'English', 'USA',
 'A hacker discovers the truth about the simulated reality and joins a rebellion against machines.'),
('Blade Runner 2049',   2017, 'Sci-Fi',   'Denis Villeneuve',    8.0, 550000,  164, 'English', 'USA',
 'A blade runner uncovers a secret that threatens the survival of what remains of civilization.'),
('Arrival',             2016, 'Sci-Fi',   'Denis Villeneuve',    7.9, 700000,  116, 'English', 'USA',
 'A linguist is recruited to help communicate with alien lifeforms after they arrive on Earth.'),
('2001: A Space Odyssey',1968,'Sci-Fi',   'Stanley Kubrick',     8.3, 700000,  149, 'English', 'USA',
 'A mysterious alien artifact sends a crew of astronauts on a journey beyond the infinite.'),
('Gravity',             2013, 'Sci-Fi',   'Alfonso Cuaron',      7.7, 870000,  91,  'English', 'USA',
 'Two astronauts work together to survive after an accident leaves them stranded in space.'),
('Ex Machina',          2014, 'Sci-Fi',   'Alex Garland',        7.7, 690000,  108, 'English', 'UK',
 'A programmer is invited to administer the Turing test to an AI with a humanoid robot.'),

-- Drama
('The Shawshank Redemption', 1994, 'Drama', 'Frank Darabont',    9.3, 2700000, 142, 'English', 'USA',
 'Two imprisoned men bond over years, finding solace and eventual redemption through acts of decency.'),
('Schindlers List',     1993, 'Drama',    'Steven Spielberg',    9.0, 1400000, 195, 'English', 'USA',
 'A businessman saves the lives of over a thousand Jewish refugees during the Holocaust.'),
('Forrest Gump',        1994, 'Drama',    'Robert Zemeckis',     8.8, 2100000, 142, 'English', 'USA',
 'A slow-witted man witnesses and unwittingly influences several defining historical events.'),
('Parasite',            2019, 'Drama',    'Bong Joon-ho',        8.5, 980000,  132, 'Korean',  'South Korea',
 'A poor family schemes to become employed by a wealthy family, leading to unexpected consequences.'),
('The Godfather',       1972, 'Drama',    'Francis Ford Coppola',9.2, 1800000, 175, 'English', 'USA',
 'The aging patriarch of a crime dynasty transfers control to his reluctant son.'),
('Whiplash',            2014, 'Drama',    'Damien Chazelle',     8.5, 870000,  106, 'English', 'USA',
 'A promising young drummer enrolls in a music conservatory where he is mentored by a ruthless instructor.'),
('12 Angry Men',        1957, 'Drama',    'Sidney Lumet',        9.0, 850000,  96,  'English', 'USA',
 'A jury holdout attempts to prevent a miscarriage of justice by forcing a re-examination of the case.'),

-- Action
('The Dark Knight',     2008, 'Action',   'Christopher Nolan',   9.0, 2700000, 152, 'English', 'USA',
 'Batman battles the Joker, a criminal mastermind who wants to plunge Gotham into anarchy.'),
('Mad Max: Fury Road',  2015, 'Action',   'George Miller',       8.1, 940000,  120, 'English', 'Australia',
 'In a post-apocalyptic wasteland, Max teams with a rebel warrior to flee a warlord.'),
('John Wick',           2014, 'Action',   'Chad Stahelski',      7.4, 790000,  101, 'English', 'USA',
 'An ex-hitman comes out of retirement to track down the gangsters who killed his dog.'),
('Gladiator',           2000, 'Action',   'Ridley Scott',        8.5, 1500000, 155, 'English', 'USA',
 'A betrayed Roman general becomes a gladiator and seeks revenge against the corrupt emperor.'),
('Kill Bill Vol. 1',    2003, 'Action',   'Quentin Tarantino',   8.1, 1100000, 111, 'English', 'USA',
 'After being left for dead, a former assassin seeks revenge on those who betrayed her.'),

-- Comedy
('The Grand Budapest Hotel', 2014, 'Comedy', 'Wes Anderson',     8.1, 780000,  99,  'English', 'USA',
 'A legendary concierge and his lobby boy become entangled in the theft of a priceless painting.'),
('Superbad',            2007, 'Comedy',   'Greg Mottola',        7.6, 670000,  113, 'English', 'USA',
 'Two high school best friends plan to supply alcohol for a party and get into misadventures.'),
('The Big Lebowski',    1998, 'Comedy',   'Coen Brothers',       8.1, 790000,  117, 'English', 'USA',
 'An easy-going bowler is mistaken for a millionaire and gets dragged into a convoluted kidnapping scheme.'),
('Knives Out',          2019, 'Comedy',   'Rian Johnson',        7.9, 650000,  130, 'English', 'USA',
 'A detective investigates the death of a crime novelist and uncovers a complex web of deception.'),

-- Horror
('Get Out',             2017, 'Horror',   'Jordan Peele',        7.7, 700000,  104, 'English', 'USA',
 'A Black man visits his white girlfriends parents for the weekend and discovers disturbing secrets.'),
('Hereditary',          2018, 'Horror',   'Ari Aster',           7.3, 400000,  127, 'English', 'USA',
 'A family unravels dark and disturbing secrets after the death of their secretive grandmother.'),
('The Silence of the Lambs', 1991, 'Horror', 'Jonathan Demme',   8.6, 1400000, 118, 'English', 'USA',
 'An FBI cadet must receive the help of an imprisoned cannibal killer to catch another serial killer.'),
('A Quiet Place',       2018, 'Horror',   'John Krasinski',      7.5, 530000,  90,  'English', 'USA',
 'A family struggles to survive in a post-apocalyptic world inhabited by blind monsters with acute hearing.'),

-- Animation
('Spirited Away',       2001, 'Animation','Hayao Miyazaki',      8.6, 820000,  125, 'Japanese','Japan',
 'A ten-year-old girl wanders into a world ruled by gods, witches and spirits.'),
('The Lion King',       1994, 'Animation','Roger Allers',        8.5, 1000000, 88,  'English', 'USA',
 'A young lion prince flees his kingdom after the murder of his father by his uncle.'),
('WALL-E',              2008, 'Animation','Andrew Stanton',      8.4, 1100000, 98,  'English', 'USA',
 'A small waste-collecting robot inadvertently embarks on a space journey that will determine the fate of humanity.'),
('Up',                  2009, 'Animation','Pete Docter',         8.2, 1100000, 96,  'English', 'USA',
 'An elderly widower and a young scout travel to South America in a balloon-lifted house.'),
('Spider-Man: Into the Spider-Verse', 2018, 'Animation', 'Bob Persichetti', 8.4, 620000, 117, 'English', 'USA',
 'Teen Miles Morales becomes Spider-Man of his universe and meets alternate versions of the hero.'),

-- Thriller
('Gone Girl',           2014, 'Thriller', 'David Fincher',       8.1, 940000,  149, 'English', 'USA',
 'A man becomes the prime suspect when his wife mysteriously disappears on their anniversary.'),
('Se7en',               1995, 'Thriller', 'David Fincher',       8.6, 1600000, 127, 'English', 'USA',
 'Two detectives hunt a serial killer who uses the seven deadly sins as motifs in his crimes.'),
('Prisoners',           2013, 'Thriller', 'Denis Villeneuve',    8.1, 780000,  153, 'English', 'USA',
 'A father takes matters into his own hands after his daughter and friend go missing.'),
('Memento',             2000, 'Thriller', 'Christopher Nolan',   8.4, 1200000, 113, 'English', 'USA',
 'A man with short-term memory loss attempts to track down his wifes murderer.'),
('Oldboy',              2003, 'Thriller', 'Park Chan-wook',      8.1, 620000,  120, 'Korean',  'South Korea',
 'After being imprisoned for 15 years, a man seeks revenge and tries to unravel the mystery.'),

-- Romance
('La La Land',          2016, 'Romance',  'Damien Chazelle',     8.0, 870000,  128, 'English', 'USA',
 'A jazz pianist and an aspiring actress fall in love while pursuing their dreams in Los Angeles.'),
('Before Sunrise',      1995, 'Romance',  'Richard Linklater',   8.1, 350000,  101, 'English', 'USA',
 'A young American man and a French woman meet on a train and spend one night together in Vienna.'),
('Eternal Sunshine of the Spotless Mind', 2004, 'Romance', 'Michel Gondry', 8.3, 1000000, 108, 'English', 'USA',
 'A couple undergo a procedure to have each other erased from their memories after a painful breakup.'),

-- Documentary
('Free Solo',           2018, 'Documentary', 'Elizabeth Chai Vasarhelyi', 8.2, 120000, 100, 'English', 'USA',
 'A documentary about rock climber Alex Honnold as he attempts to free solo climb El Capitan.'),
('13th',                2016, 'Documentary', 'Ava DuVernay',     8.2, 110000,  100, 'English', 'USA',
 'An exploration of race, justice and mass incarceration in the United States.'),

-- International
('City of God',         2002, 'Crime',    'Fernando Meirelles',  8.6, 820000,  130, 'Portuguese','Brazil',
 'The story of the rise of organized crime in the Cidade de Deus suburb of Rio de Janeiro.'),
('Amelie',              2001, 'Romance',  'Jean-Pierre Jeunet',  8.3, 830000,  122, 'French',  'France',
 'A whimsical Parisian woman decides to change the lives of those around her for the better.'),
('Pan''s Labyrinth',    2006, 'Fantasy',  'Guillermo del Toro',  8.2, 730000,  118, 'Spanish', 'Spain',
 'In post-Civil War Spain, a girl escapes into an eerie but alluring fantasy world.'),
('Crouching Tiger Hidden Dragon', 2000, 'Action', 'Ang Lee',     7.9, 400000,  120, 'Mandarin','Taiwan',
 'Two master martial artists compete for a stolen sword while a young noble pursues her dreams.');

-- Insert cast members
INSERT INTO movies.cast_members (film_id, actor, role, is_lead) VALUES
(1,  'Leonardo DiCaprio', 'Cobb',         TRUE),
(1,  'Joseph Gordon-Levitt','Arthur',     FALSE),
(2,  'Matthew McConaughey','Cooper',      TRUE),
(2,  'Anne Hathaway',    'Brand',         FALSE),
(3,  'Keanu Reeves',     'Neo',           TRUE),
(3,  'Laurence Fishburne','Morpheus',     FALSE),
(9,  'Tim Robbins',      'Andy Dufresne', TRUE),
(9,  'Morgan Freeman',   'Ellis Boyd',    FALSE),
(13, 'Marlon Brando',    'Vito Corleone', TRUE),
(13, 'Al Pacino',        'Michael Corleone', FALSE),
(16, 'Christian Bale',   'Bruce Wayne',   TRUE),
(16, 'Heath Ledger',     'The Joker',     FALSE),
(12, 'Song Kang-ho',     'Ki-taek',       TRUE),
(30, 'Daveigh Chase',    'Chihiro',       TRUE);

-- Insert awards
INSERT INTO movies.awards (film_id, award_name, category, won, year) VALUES
(9,  'Academy Award',    'Best Picture',       FALSE, 1995),
(10, 'Academy Award',    'Best Picture',       TRUE,  1994),
(13, 'Academy Award',    'Best Picture',       TRUE,  1973),
(16, 'Academy Award',    'Best Supporting Actor', TRUE, 2009),
(12, 'Academy Award',    'Best Picture',       TRUE,  2020),
(12, 'Academy Award',    'Best Director',      TRUE,  2020),
(27, 'Academy Award',    'Best Picture',       TRUE,  1992),
(30, 'Academy Award',    'Best Animated Feature', TRUE, 2003),
(44, 'Academy Award',    'Best Documentary',   TRUE,  2019);

-- ── Step 6: Create indexes for performance ────────────────────
CREATE INDEX IF NOT EXISTS idx_films_genre        ON movies.films(genre);
CREATE INDEX IF NOT EXISTS idx_films_year         ON movies.films(release_year);
CREATE INDEX IF NOT EXISTS idx_films_rating       ON movies.films(rating DESC);
CREATE INDEX IF NOT EXISTS idx_films_director     ON movies.films(director);
CREATE INDEX IF NOT EXISTS idx_cast_film          ON movies.cast_members(film_id);
CREATE INDEX IF NOT EXISTS idx_awards_film        ON movies.awards(film_id);

-- ── Step 7: Create NL2SQL function using AlloyDB AI ───────────
-- This function takes a natural language question and converts it to SQL,
-- then executes it and returns results.

CREATE OR REPLACE FUNCTION movies.natural_language_query(user_question TEXT)
RETURNS TABLE (
    query_sql     TEXT,
    result_json   JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    generated_sql  TEXT;
    schema_context TEXT;
    prompt         TEXT;
    result_data    JSONB;
BEGIN
    -- Build schema context for the LLM
    schema_context := '
    Database schema for a movie database:

    TABLE movies.films:
      film_id (SERIAL PRIMARY KEY)
      title (VARCHAR) - movie title
      release_year (INTEGER) - year of release
      genre (VARCHAR) - genre: Sci-Fi, Drama, Action, Comedy, Horror, Animation, Thriller, Romance, Documentary, Crime, Fantasy
      director (VARCHAR) - director name
      rating (NUMERIC 0-10) - IMDb-style rating
      votes (INTEGER) - number of votes
      runtime_mins (INTEGER) - duration in minutes
      language (VARCHAR) - original language
      country (VARCHAR) - country of production
      synopsis (TEXT) - movie description

    TABLE movies.cast_members:
      cast_id (SERIAL PRIMARY KEY)
      film_id (INTEGER FK to films)
      actor (VARCHAR) - actor name
      role (VARCHAR) - character name
      is_lead (BOOLEAN) - whether lead role

    TABLE movies.awards:
      award_id (SERIAL PRIMARY KEY)
      film_id (INTEGER FK to films)
      award_name (VARCHAR) - e.g. Academy Award
      category (VARCHAR) - e.g. Best Picture
      won (BOOLEAN) - whether won
      year (INTEGER) - award year
    ';

    -- Build the prompt for AlloyDB AI
    prompt := schema_context || '

    Convert this natural language question into a valid PostgreSQL SQL query.
    Return ONLY the SQL query, no explanation, no markdown, no backticks.
    Always use the schema prefix movies. for all tables.
    Always include a LIMIT 20 unless a specific number is requested.

    Question: ' || user_question;

    -- Call AlloyDB AI (google_ml_integration) to generate SQL
    SELECT google_ml.predict_row(
        model_id    => 'text-bison@002',
        request_body => json_build_object(
            'instances', json_build_array(
                json_build_object('prompt', prompt)
            ),
            'parameters', json_build_object(
                'temperature', 0.1,
                'maxOutputTokens', 512
            )
        )::json
    )::jsonb -> 'predictions' -> 0 -> 'content'
    INTO generated_sql;

    -- Clean up the generated SQL
    generated_sql := TRIM(generated_sql);
    generated_sql := REPLACE(generated_sql, '"', '');
    generated_sql := REPLACE(generated_sql, E'\n', ' ');

    -- Execute the generated SQL and capture results as JSON
    EXECUTE 'SELECT jsonb_agg(row_to_json(t)) FROM (' || generated_sql || ') t'
    INTO result_data;

    -- Return both the generated SQL and the results
    RETURN QUERY SELECT generated_sql, COALESCE(result_data, '[]'::jsonb);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT
        'ERROR: ' || SQLERRM,
        ('{"error": "' || SQLERRM || '"}')::jsonb;
END;
$$;

-- ── Step 8: Create semantic search function using embeddings ──
CREATE OR REPLACE FUNCTION movies.semantic_search(search_query TEXT, top_k INTEGER DEFAULT 5)
RETURNS TABLE (
    title        VARCHAR,
    genre        VARCHAR,
    rating       NUMERIC,
    release_year INTEGER,
    synopsis     TEXT,
    similarity   FLOAT
)
LANGUAGE plpgsql
AS $$
DECLARE
    query_embedding vector(768);
BEGIN
    -- Generate embedding for the search query
    SELECT embedding('textembedding-gecko@003', search_query)
    INTO query_embedding;

    -- Find most similar movies using cosine similarity
    RETURN QUERY
    SELECT
        f.title,
        f.genre,
        f.rating,
        f.release_year,
        f.synopsis,
        1 - (f.embedding <=> query_embedding) AS similarity
    FROM movies.films f
    WHERE f.embedding IS NOT NULL
    ORDER BY f.embedding <=> query_embedding
    LIMIT top_k;
END;
$$;

-- ── Step 9: Populate embeddings for existing films ────────────
-- Generate vector embeddings for semantic search
UPDATE movies.films
SET embedding = embedding('textembedding-gecko@003', synopsis)
WHERE synopsis IS NOT NULL
  AND embedding IS NULL;

-- ── Step 10: Sample Natural Language Queries to demonstrate ───
-- These show the system working end-to-end

-- Query 1: Top rated sci-fi movies
SELECT * FROM movies.natural_language_query(
    'Show me the top 5 highest rated science fiction movies'
);

-- Query 2: Recent award-winning films
SELECT * FROM movies.natural_language_query(
    'Which films won Academy Awards for Best Picture?'
);

-- Query 3: Movies by a specific director
SELECT * FROM movies.natural_language_query(
    'List all movies directed by Christopher Nolan with their ratings'
);

-- Query 4: International films
SELECT * FROM movies.natural_language_query(
    'Show me movies that are not in English, sorted by rating'
);

-- Query 5: Semantic search
SELECT * FROM movies.semantic_search(
    'a story about artificial intelligence and robots', 5
);

-- ── Step 11: Create a helpful view for reporting ──────────────
CREATE OR REPLACE VIEW movies.film_summary AS
SELECT
    f.film_id,
    f.title,
    f.release_year,
    f.genre,
    f.director,
    f.rating,
    f.runtime_mins,
    f.language,
    f.country,
    COUNT(DISTINCT c.cast_id)  AS cast_count,
    COUNT(DISTINCT a.award_id) AS award_nominations,
    COUNT(DISTINCT CASE WHEN a.won THEN a.award_id END) AS awards_won
FROM movies.films f
LEFT JOIN movies.cast_members c ON c.film_id = f.film_id
LEFT JOIN movies.awards a ON a.film_id = f.film_id
GROUP BY f.film_id, f.title, f.release_year, f.genre, f.director,
         f.rating, f.runtime_mins, f.language, f.country;

-- Verify setup
SELECT
    'Setup Complete!' AS status,
    COUNT(*) AS total_films,
    COUNT(DISTINCT genre) AS genres,
    COUNT(DISTINCT director) AS directors,
    AVG(rating)::NUMERIC(3,1) AS avg_rating
FROM movies.films;
