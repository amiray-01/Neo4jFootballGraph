------ Creating tables countries and competitions------

CREATE TABLE countries (
    country_id INT PRIMARY KEY,
    country_name VARCHAR(50) NOT NULL,
    confederation VARCHAR(50)
);

CREATE TABLE competitions (
    competition_id VARCHAR(10) PRIMARY KEY,
    competition_code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    sub_type VARCHAR(50),
    type VARCHAR(50),
    country_id INT,
    domestic_league_code VARCHAR(10),
    url TEXT,
    is_major_national_league BOOLEAN,
    CONSTRAINT fk_country FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

CREATE TEMP TABLE temp_competitions (
    competition_id VARCHAR(10),
    competition_code VARCHAR(50),
    name VARCHAR(100),
    sub_type VARCHAR(50),
    type VARCHAR(50),
    country_id INT,
    country_name VARCHAR(50),
    domestic_league_code VARCHAR(10),
    confederation VARCHAR(50),
    url TEXT,
    is_major_national_league BOOLEAN
);

COPY temp_competitions(competition_id, competition_code, name, sub_type, type, country_id, country_name, domestic_league_code, confederation, url, is_major_national_league)
FROM '/Users/yanisamira/Downloads/data/competitions.csv'
DELIMITER ','
CSV HEADER;

------ Inserting data into countries and competitions tables ------

INSERT INTO countries (country_id, country_name, confederation)
SELECT DISTINCT country_id, country_name, confederation
FROM temp_competitions
WHERE country_id IS NOT NULL
and country_name is not null;

INSERT INTO competitions (competition_id, competition_code, name, sub_type, type, country_id, domestic_league_code, url, is_major_national_league)
SELECT t.competition_id, t.competition_code, t.name, t.sub_type, t.type, t.country_id, t.domestic_league_code, t.url, t.is_major_national_league
FROM temp_competitions t
Right Join countries c on t.country_id = c.country_id;

------ Creating tables stadiums, clubs ------
CREATE TABLE stadiums (
    stadium_id SERIAL PRIMARY KEY,
    stadium_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE clubs (
    club_id INT PRIMARY KEY,
    club_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    domestic_competition_id VARCHAR(10) REFERENCES competitions(competition_id) ON DELETE SET NULL,
    squad_size INT CHECK (squad_size >= 0),
    average_age NUMERIC CHECK (average_age >= 0),
    stadium_id INT REFERENCES stadiums(stadium_id) ON DELETE SET NULL
);

CREATE TEMP TABLE temp_clubs (
    club_id INT,
    club_code VARCHAR(50),
    name VARCHAR(100),
    domestic_competition_id VARCHAR(10),
    stadium_name VARCHAR(100),
    squad_size INT,
    average_age NUMERIC
);

COPY temp_clubs(club_id, club_code, name, domestic_competition_id, stadium_name, squad_size, average_age)
FROM '/Users/yanisamira/Downloads/data/clubs_cleaned.csv'
DELIMITER ','
CSV HEADER;

------ Inserting data into stadiums and clubs tables ------

INSERT INTO stadiums (stadium_name)
SELECT DISTINCT stadium_name
FROM temp_clubs
WHERE stadium_name IS NOT NULL;

INSERT INTO clubs (club_id, club_code, name, domestic_competition_id, squad_size, average_age, stadium_id)
SELECT 
    t.club_id,
    t.club_code,
    t.name,
    t.domestic_competition_id,
    t.squad_size,
    t.average_age,
    s.stadium_id
FROM temp_clubs t
LEFT JOIN stadiums s ON t.stadium_name = s.stadium_name;

------ Creating table players ------

CREATE TEMP TABLE temp_players (
    player_id INT,
    name VARCHAR(100),
    country_of_birth VARCHAR(50),
    date_of_birth DATE,
    current_club_id INT,
    position VARCHAR(50),
    market_value_in_eur NUMERIC,
    highest_market_value_in_eur NUMERIC
);
COPY temp_players FROM '/Users/yanisamira/Downloads/data/players_cleaned.csv' DELIMITER ',' CSV HEADER;


CREATE TABLE players (
    player_id INT PRIMARY KEY,
    name VARCHAR(100),
    country_of_birth VARCHAR(50),
    date_of_birth DATE,
    current_club_id INT REFERENCES clubs(club_id) ON DELETE SET NULL,
    position VARCHAR(50),
    market_value_in_eur INT NOT NULL,
    highest_market_value_in_eur INT NOT NULL,
    CHECK (market_value_in_eur >= 0),
    CHECK (highest_market_value_in_eur >= 0),
    CHECK (market_value_in_eur <= highest_market_value_in_eur)
);

------ Inserting data into players table ------

INSERT INTO players (
    player_id,
    name,
    country_of_birth,
    date_of_birth,
    current_club_id,
    position,
    market_value_in_eur,
    highest_market_value_in_eur
)
SELECT 
    player_id,
    name,
    country_of_birth,
    date_of_birth,
    current_club_id,
    position,
    market_value_in_eur,
    highest_market_value_in_eur
FROM temp_players
WHERE market_value_in_eur IS NOT NULL
  AND highest_market_value_in_eur IS NOT NULL;


------ Creating table games ------

CREATE TABLE games (
    game_id INT PRIMARY KEY,
    competition_id VARCHAR(10) REFERENCES competitions(competition_id) ON DELETE SET NULL,
    season VARCHAR(20),
    round VARCHAR(50),
    date DATE NOT NULL,
    home_club_id INT REFERENCES clubs(club_id) ON DELETE CASCADE,
    away_club_id INT REFERENCES clubs(club_id) ON DELETE CASCADE,
    home_club_goals INT CHECK (home_club_goals >= 0),
    away_club_goals INT CHECK (away_club_goals >= 0),
    stadium_id INT REFERENCES stadiums(stadium_id) ON DELETE SET NULL,
    attendance INT CHECK (attendance >= 0),
    CHECK (home_club_id <> away_club_id)
);

CREATE TEMP TABLE temp_games (
    game_id INT PRIMARY KEY,
    competition_id VARCHAR(10),
    season VARCHAR(20),
    round VARCHAR(50),
    date DATE NOT NULL,
    home_club_id INT,
    away_club_id INT,
    home_club_goals INT CHECK (home_club_goals >= 0),
    away_club_goals INT CHECK (away_club_goals >= 0),
    stadium VARCHAR(100),
    attendance INT CHECK (attendance >= 0)
);

COPY temp_games FROM '/Users/yanisamira/Downloads/data/games_cleaned.csv' DELIMITER ',' CSV HEADER;

------ Inserting data into games table ------

INSERT INTO games (game_id, competition_id, season, round, date, home_club_id, away_club_id, home_club_goals, away_club_goals, stadium_id, attendance)
SELECT
    tg.game_id,
    tg.competition_id,
    tg.season,
    tg.round,
    tg.date,
    tg.home_club_id,
    tg.away_club_id,
    tg.home_club_goals,
    tg.away_club_goals,
    s.stadium_id,
    tg.attendance
FROM temp_games tg
LEFT JOIN competitions c ON tg.competition_id = c.competition_id
LEFT JOIN clubs hc ON tg.home_club_id = hc.club_id
LEFT JOIN clubs ac ON tg.away_club_id = ac.club_id
LEFT JOIN stadiums s ON tg.stadium = s.stadium_name
WHERE c.competition_id IS NOT NULL
  AND hc.club_id IS NOT NULL
  AND ac.club_id IS NOT NULL
  AND s.stadium_id IS NOT NULL;

------ Creating table transfers ------

CREATE TEMP TABLE temp_transfers (
    player_id INT,
    transfer_date DATE,
    transfer_season VARCHAR(20),
    from_club_id INT,
    to_club_id INT,
    transfer_fee NUMERIC,
    market_value_in_eur NUMERIC
);

COPY temp_transfers FROM '/Users/yanisamira/Downloads/data/transfers_cleaned.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE transfers (
    transfer_id SERIAL PRIMARY KEY,
    player_id INT REFERENCES players(player_id) ON DELETE CASCADE,
    transfer_date DATE NOT NULL,
    transfer_season VARCHAR(20),
    from_club_id INT REFERENCES clubs(club_id) ON DELETE SET NULL,
    to_club_id INT REFERENCES clubs(club_id) ON DELETE SET NULL,
    transfer_fee NUMERIC CHECK (transfer_fee >= 0),
    market_value_in_eur NUMERIC CHECK (market_value_in_eur >= 0)
);

------ Inserting data into transfers table ------

INSERT INTO transfers (player_id, transfer_date, transfer_season, from_club_id, to_club_id, transfer_fee, market_value_in_eur)
SELECT
    tt.player_id,
    tt.transfer_date,
    tt.transfer_season,
    tt.from_club_id,
    tt.to_club_id,
    tt.transfer_fee,
    tt.market_value_in_eur
FROM temp_transfers tt
LEFT JOIN players p ON tt.player_id = p.player_id
LEFT JOIN clubs fc ON tt.from_club_id = fc.club_id
LEFT JOIN clubs tc ON tt.to_club_id = tc.club_id
WHERE p.player_id IS NOT NULL
  AND fc.club_id IS NOT NULL
  AND tc.club_id IS NOT NULL
  AND tt.transfer_fee IS NOT NULL
  AND tt.market_value_in_eur IS NOT NULL;

------ Exporting data ------
COPY (SELECT * FROM competitions) TO '/Users/yanisamira/Desktop/data/competitions.csv' DELIMITER ',' CSV HEADER;
COPY (SELECT * FROM clubs) TO '/Users/yanisamira/Desktop/data/clubs.csv' DELIMITER ',' CSV HEADER;
COPY (SELECT * FROM players) TO '/Users/yanisamira/Desktop/data/players.csv' DELIMITER ',' CSV HEADER;
COPY (SELECT * FROM games) TO '/Users/yanisamira/Desktop/data/games.csv' DELIMITER ',' CSV HEADER;
COPY (SELECT * FROM transfers) TO '/Users/yanisamira/Desktop/data/transfers.csv' DELIMITER ',' CSV HEADER;
COPY (SELECT * FROM stadiums) TO '/Users/yanisamira/Desktop/data/stadiums.csv' DELIMITER ',' CSV HEADER;
COPY (SELECT * FROM stadiums) TO '/Users/yanisamira/Desktop/data/countries.csv' DELIMITER ',' CSV HEADER;


------ Indexes ------


CREATE INDEX IF NOT EXISTS competition_type_index 
ON competitions (type);

CREATE INDEX IF NOT EXISTS club_name_index 
ON clubs (name);

CREATE INDEX IF NOT EXISTS player_position_index 
ON players (position);

CREATE INDEX IF NOT EXISTS game_season_index 
ON games (season);

CREATE INDEX IF NOT EXISTS transfer_fee_index 
ON transfers (transfer_fee);

CREATE INDEX IF NOT EXISTS player_current_club_id_index 
ON players (current_club_id);

CREATE INDEX IF NOT EXISTS player_market_value_in_eur_index 
ON players (market_value_in_eur);
