LOAD CSV WITH HEADERS FROM 'file:///countries.csv' AS row
CREATE (:Country {
    country_id: toInteger(row.country_id),
    country_name: row.country_name,
    confederation: row.confederation
});


LOAD CSV WITH HEADERS FROM 'file:///competitions.csv' AS row
CREATE (:Competition {
    competition_id: row.competition_id,
    competition_code: row.competition_code,
    name: row.name,
    sub_type: row.sub_type,
    type: row.type,
    country_id: toInteger(row.country_id),
    domestic_league_code: row.domestic_league_code,
    url: row.url,
    is_major_national_league: row.is_major_national_league = "t"
});


LOAD CSV WITH HEADERS FROM 'file:///clubs.csv' AS row
CREATE (:Club {
    club_id: toInteger(row.club_id),
    club_code: row.club_code,
    name: row.name,
    domestic_competition_id: row.domestic_competition_id,
    squad_size: toInteger(row.squad_size),
    average_age: toFloat(row.average_age),
    stadium_id: toInteger(row.stadium_id)
});


LOAD CSV WITH HEADERS FROM 'file:///players.csv' AS row
CREATE (:Player {
    player_id: toInteger(row.player_id),
    name: row.name,
    country_of_birth: row.country_of_birth,
    date_of_birth: date(row.date_of_birth),
    current_club_id: toInteger(row.current_club_id),
    position: row.position,
    market_value_in_eur: toFloat(row.market_value_in_eur),
    highest_market_value_in_eur: toFloat(row.highest_market_value_in_eur)
});


LOAD CSV WITH HEADERS FROM 'file:///stadiums.csv' AS row
CREATE (:Stadium {
    stadium_id: toInteger(row.stadium_id),
    stadium_name: row.stadium_name
});


LOAD CSV WITH HEADERS FROM 'file:///games.csv' AS row
CREATE (:Game {
    game_id: toInteger(row.game_id),
    competition_id: row.competition_id,
    season: row.season,
    round: row.round,
    date: date(row.date),
    home_club_id: toInteger(row.home_club_id),
    away_club_id: toInteger(row.away_club_id),
    home_club_goals: toInteger(row.home_club_goals),
    away_club_goals: toInteger(row.away_club_goals),
    stadium_id: toInteger(row.stadium_id),
    attendance: toInteger(row.attendance)
});


LOAD CSV WITH HEADERS FROM 'file:///transfers.csv' AS row
CREATE (:Transfer {
    transfer_id: toInteger(row.transfer_id),
    player_id: toInteger(row.player_id),
    transfer_date: date(row.transfer_date),
    transfer_season: row.transfer_season,
    from_club_id: toInteger(row.from_club_id),
    to_club_id: toInteger(row.to_club_id),
    transfer_fee: toFloat(row.transfer_fee),
    market_value_in_eur: toFloat(row.market_value_in_eur)
});


MATCH (c:Country), (comp:Competition)
WHERE c.country_id = toInteger(comp.country_id)
CREATE (c)-[:HOSTS]->(comp);

MATCH (comp:Competition), (c:Club)
WHERE c.domestic_competition_id = comp.competition_id
CREATE (c)-[:PARTICIPATES_IN]->(comp);

MATCH (p:Player), (c:Club)
WHERE p.current_club_id = c.club_id
CREATE (p)-[:PLAYS_FOR]->(c);

MATCH (c:Club), (s:Stadium)
WHERE c.stadium_id = s.stadium_id
CREATE (c)-[:PLAYS_AT]->(s);

MATCH (g:Game), (c:Club)
WHERE g.home_club_id = c.club_id
CREATE (g)-[:HOME_TEAM]->(c);

MATCH (g:Game), (c:Club)
WHERE g.away_club_id = c.club_id
CREATE (g)-[:AWAY_TEAM]->(c);

MATCH (g:Game), (comp:Competition)
WHERE g.competition_id = comp.competition_id
CREATE (g)-[:BELONGS_TO]->(comp);

MATCH (t:Transfer), (p:Player)
WHERE t.player_id = p.player_id
CREATE (p)-[:WAS_TRANSFERRED]->(t);

MATCH (t:Transfer), (c:Club)
WHERE t.from_club_id = c.club_id
CREATE (t)-[:INITIATED_BY]->(c);

MATCH (t:Transfer), (c:Club)
WHERE t.to_club_id = c.club_id
CREATE (t)-[:FINALIZED_BY]->(c);

------- CONSTRAINTS ------

CREATE CONSTRAINT country_id_unique IF NOT EXISTS
FOR (c:Country)
REQUIRE c.country_id IS UNIQUE;


CREATE CONSTRAINT competition_id_unique IF NOT EXISTS
FOR (comp:Competition)
REQUIRE comp.competition_id IS UNIQUE;


CREATE CONSTRAINT club_id_unique IF NOT EXISTS
FOR (c:Club)
REQUIRE c.club_id IS UNIQUE;


CREATE CONSTRAINT player_id_unique IF NOT EXISTS
FOR (p:Player)
REQUIRE p.player_id IS UNIQUE;


CREATE CONSTRAINT stadium_id_unique IF NOT EXISTS
FOR (s:Stadium)
REQUIRE s.stadium_id IS UNIQUE;


CREATE CONSTRAINT game_id_unique IF NOT EXISTS
FOR (g:Game)
REQUIRE g.game_id IS UNIQUE;


CREATE CONSTRAINT transfer_id_unique IF NOT EXISTS
FOR (t:Transfer)
REQUIRE t.transfer_id IS UNIQUE;


CREATE CONSTRAINT competition_name_exists IF NOT EXISTS
FOR (comp:Competition)
REQUIRE comp.name IS NOT NULL;

CREATE CONSTRAINT player_name_exists IF NOT EXISTS
FOR (p:Player)
REQUIRE p.name IS NOT NULL;

CREATE CONSTRAINT player_current_club_id_exists IF NOT EXISTS
FOR (p:Player)
REQUIRE p.current_club_id IS NOT NULL;

CREATE CONSTRAINT stadium_name_exists IF NOT EXISTS
FOR (s:Stadium)
REQUIRE s.stadium_name IS NOT NULL;

CREATE CONSTRAINT country_name_exists IF NOT EXISTS
FOR (c:Country)
REQUIRE c.country_name IS NOT NULL;

------- INDEXES ------
CREATE INDEX competition_type_index IF NOT EXISTS
FOR (comp:Competition)
ON (comp.type);

CREATE INDEX club_name_index IF NOT EXISTS
FOR (c:Club)
ON (c.name);

CREATE INDEX player_position_index IF NOT EXISTS
FOR (p:Player)
ON (p.position);

CREATE INDEX game_season_index IF NOT EXISTS
FOR (g:Game)
ON (g.season);

CREATE INDEX transfer_fee_index IF NOT EXISTS
FOR (t:Transfer)
ON (t.transfer_fee);

CREATE INDEX IF NOT EXISTS FOR (p:Player) ON (p.current_club_id);

CREATE INDEX IF NOT EXISTS FOR (p:Player) ON (p.market_value_in_eur);


CREATE FULLTEXT INDEX country_fulltext_index IF NOT EXISTS
FOR (c:Country)
ON EACH [c.country_name];

CREATE FULLTEXT INDEX player_fulltext_index IF NOT EXISTS
FOR (p:Player)
ON EACH [p.name, p.country_of_birth];

CREATE FULLTEXT INDEX player_position_fulltext_index IF NOT EXISTS
FOR (p:Player)
ON EACH [p.position];


------- REQUETES ------

1.1 MATCH (c:Club)
WHERE NOT EXISTS {
  MATCH (c)<-[:HOME_TEAM]-(:Game)
}
RETURN c.name AS ClubsWithoutHomeGames;

1.2 SELECT c.name AS ClubsWithoutHomeGames
FROM clubs c
WHERE NOT EXISTS (
  SELECT *
  FROM games g
  WHERE g.home_club_id = c.club_id
);

2.1 MATCH (comp:Competition)
OPTIONAL MATCH (comp)<-[:PARTICIPATES_IN]-(club:Club)
RETURN comp.name AS CompetitionName, COUNT(club) AS ClubCount;

2.2 SELECT comp.name AS CompetitionName,
       COUNT(c.club_id) AS ClubCount
FROM competitions comp
LEFT JOIN clubs c
ON comp.competition_id = c.domestic_competition_id
GROUP BY comp.name;

-- trouvons les clubs qui ont au moins un joueur français ayant fait l’objet d’un transfert supérieur à 50 millions d’euros
3.1 MATCH (c:Club), (p:Player)
WHERE EXISTS {
  MATCH (c)<-[:PLAYS_FOR]-(p)
  WHERE p.country_of_birth = "France" 
    AND EXISTS {
      MATCH (p)-[:WAS_TRANSFERRED]->(t:Transfer)
      WHERE t.transfer_fee > 50000000
    }
}
RETURN c.name AS clubName, p.name

3.2 SELECT 
    c1.name AS ClubName,
    s.stadium_name AS StadiumName,
    comp.name AS CompetitionName
FROM clubs c1
JOIN stadiums s ON c1.stadium_id = s.stadium_id
JOIN clubs c2 ON s.stadium_id = c2.stadium_id
JOIN competitions comp ON c2.domestic_competition_id = comp.competition_id
WHERE c1.club_id <> c2.club_id;


4.1 ---Utiliser WITH pour filtrer les résultats d’un agrégat
MATCH (p:Player)-[:PLAYS_FOR]->(c:Club)
WITH c, count(p) AS nbPlayers
WHERE nbPlayers < 30
RETURN c.name AS clubName, nbPlayers
ORDER BY nbPlayers DESC;

4.2 -- Identifier les clubs qui participent à des compétitions majeures et leur attribuer une propriété
MATCH (club:Club)-[:PARTICIPATES_IN]->(comp:Competition)
WHERE comp.is_major_national_league = true
WITH DISTINCT club
SET club.is_major_participant = true
RETURN club.name AS ClubName, club.is_major_participant;

5 --Identifier les compétitions et leurs clubs
MATCH (comp:Competition)<-[:BELONGS_TO]-(g:Game)-[:HOME_TEAM|:AWAY_TEAM]->(club:Club)
WITH comp, COUNT(DISTINCT club) AS ClubCount, COLLECT(club.name) AS ClubNames
RETURN comp.name AS CompetitionName, ClubCount, ClubNames;

6 --Regrouper les joueurs par club, puis les afficher individuellement
MATCH (club:Club)<-[:PLAYS_FOR]-(player:Player)
WITH club.name AS ClubName, COLLECT(player.name) AS PlayerNames
UNWIND PlayerNames AS PlayerName
RETURN ClubName, PlayerName;

7 -- Reduce : Calculer la somme des valeurs marchandes des joueurs d’un club
-- Pourquoi elle est problématique :
-- Formation de grandes listes : La fonction COLLECT génère une liste contenant toutes les valeurs marchandes des joueurs pour chaque club.
-- Traitement séquentiel : REDUCE parcourt chaque élément de la liste pour calculer la somme. Cela peut devenir inefficace si la liste contient un grand nombre d’éléments.
MATCH (club:Club)<-[:PLAYS_FOR]-(player:Player)
WITH club, COLLECT(player.market_value_in_eur) AS PlayerValues
RETURN club.name AS ClubName, 
       REDUCE(total = 0, value IN PlayerValues | total + value) AS TotalMarketValue;

7.1 -- Calcul des produits
-- Pourquoi elle est problématique :
-- Croissance exponentielle : La multiplication des valeurs marchandes dans REDUCE peut générer des nombres extrêmement grands (voire infiniment grands), ce qui risque de causer des erreurs de débordement.
-- Complexité mémoire : Comme dans la première requête, la construction d’une liste avec COLLECT peut poser des problèmes de performance pour les graphes de grande taille.
MATCH (club:Club)<-[:PLAYS_FOR]-(player:Player)
WITH club, COLLECT(player.market_value_in_eur) AS PlayerValues
RETURN club.name AS ClubName, 
       REDUCE(product = 1, value IN PlayerValues | product * value) AS ProductMarketValue;

7.2 -- Recommandations étudiées dans l’article : Privilégier les agrégats directs comme SUM ou AVG
-- Remplacer reduce + collect par SUM
MATCH (club:Club)<-[:PLAYS_FOR]-(player:Player)
RETURN club.name AS ClubName, 
       SUM(player.market_value_in_eur) AS TotalMarketValue;


8 -- obtenir les joueurs ou clubs participant à des compétitions majeures, avec un filtre sur un attribut
CALL {
    MATCH (p:Player)-[:PLAYS_FOR]->(c:Club)-[:PARTICIPATES_IN]->(comp:Competition)
    WHERE comp.is_major_national_league = true
    RETURN p.name AS name, 'Player' AS type, comp.name AS competition
    UNION
    MATCH (c:Club)-[:PARTICIPATES_IN]->(comp:Competition)
    WHERE comp.is_major_national_league = true
    RETURN c.name AS name, 'Club' AS type, comp.name AS competition
}
WITH name, type, competition
WHERE competition = 'premier-league'
RETURN name, type, competition
ORDER BY type, name;

9.1 -- Trouver les joueurs qui ont au moins un transfert avec un montant (transfer_fee) supérieur à 20 millions d’euros avec any()
MATCH (p:Player)-[:WAS_TRANSFERRED]->(t:Transfer)
WITH p, collect(t.transfer_fee) AS fees
WHERE any(fee IN fees WHERE fee > 20000000)
RETURN p.name AS playerName, fees

9.2 -- repérer des clubs qui ont exactement un joueur brésilien avec single()
MATCH (c:Club)<-[:PLAYS_FOR]-(p:Player)
WITH c, collect(p.country_of_birth) AS nationalities
WHERE single(nat IN nationalities WHERE nat = "Brazil")
RETURN c.name AS clubName



10 -- REC : pour un joueur donné, on veut récupérer tous les clubs dans lesquels il a joué en explorant la table des transferts
WITH RECURSIVE clubs_for_player AS (
    SELECT
        p.player_id,
        p.current_club_id AS club_id,
        1 AS level
    FROM players p
    WHERE p.player_id = 288230

    UNION ALL

    SELECT
        cfp.player_id,
        CASE
            WHEN t.from_club_id = cfp.club_id THEN t.to_club_id
            ELSE t.from_club_id
        END AS club_id,
        cfp.level + 1
    FROM clubs_for_player cfp
    JOIN transfers t
         ON (t.from_club_id = cfp.club_id OR t.to_club_id = cfp.club_id)
         AND t.player_id = cfp.player_id
    WHERE cfp.level < 20
)

SELECT DISTINCT
    cfp.player_id,
    c.club_id,
    c.name AS club_name
FROM clubs_for_player cfp
JOIN clubs c ON cfp.club_id = c.club_id
ORDER BY cfp.player_id, club_name;


-- Version Cypher

MATCH (p:Player {player_id: 288230})
      -[:WAS_TRANSFERRED*0..]->(t:Transfer)
      -[:INITIATED_BY|FINALIZED_BY]->(otherClub:Club)
RETURN DISTINCT otherClub.name AS clubName
ORDER BY clubName;


11 -- SQL > Cypher

EXPLAIN ANALYZE
SELECT c.name,
SUM(p.market_value_in_eur) AS total_value
FROM players p
JOIN clubs c ON p.current_club_id = c.club_id
GROUP BY c.name
ORDER BY total_value DESC
LIMIT 10;

PROFILE
MATCH (p:Player)-[:PLAYS_FOR]->(c:Club)
RETURN c.name AS clubName,
SUM(p.market_value_in_eur) AS total_value
ORDER BY total_value DESC
LIMIT 10;


-- PART 3

-- Projection du graphe Club–Player
CALL gds.graph.project(
    'clubs_and_players_graph',
    ['Club', 'Player'],           
    {
        PLAYS_FOR: {           
            orientation: 'NATURAL' 
        }
    }
)
YIELD graphName, nodeCount, relationshipCount
RETURN graphName, nodeCount, relationshipCount;


CALL gds.pageRank.stream('clubs_and_players_graph')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS Name, score
ORDER BY score DESC
LIMIT 10;

-- Projection du graphe de transferts
CALL gds.graph.project(
    'transfers_graph',
    ['Player', 'Club', 'Transfer'],
    {
        WAS_TRANSFERRED: { type: 'WAS_TRANSFERRED', orientation: 'UNDIRECTED' },
        FINALIZED_BY: { type: 'FINALIZED_BY', orientation: 'UNDIRECTED' },
        INITIATED_BY: { type: 'INITIATED_BY', orientation: 'UNDIRECTED' }
    }
);

CALL gds.degree.mutate('transfers_graph', {
    mutateProperty: 'degreeCentrality'
});

-- Projection du graphe de transferts pondéré (Clubs)
CALL gds.graph.project.cypher(
  'transfers_graph_weighted',
  'MATCH (n) WHERE n:Club RETURN id(n) AS id',
  'MATCH (c1:Club)<-[init:INITIATED_BY]-(t:Transfer)-[final:FINALIZED_BY]->(c2:Club)
   RETURN id(c1) AS source, id(c2) AS target, t.transfer_fee AS weight'
)

CALL gds.pageRank.stream(
  'transfers_graph_weighted',
  {
    relationshipWeightProperty: 'weight'
  }
)
YIELD nodeId, score
RETURN nodeId, gds.util.asNode(nodeId).name AS clubName, score
ORDER BY score DESC
LIMIT 10;

CALL gds.pageRank.write(
  'transfers_graph_weighted',
  {
    relationshipWeightProperty: 'weight',
    writeProperty: 'pagerankWeighted'
  }
)
YIELD nodePropertiesWritten;

MATCH (c:Club)
RETURN c.name, c.pagerankWeighted
ORDER BY c.pagerankWeighted DESC
LIMIT 10;

CALL gds.louvain.stream(
  'transfers_graph_weighted',
  {
    relationshipWeightProperty: 'weight'

  }
)
YIELD nodeId, communityId
RETURN nodeId, gds.util.asNode(nodeId).name AS clubName, communityId
ORDER BY communityId, clubName;


CALL gds.louvain.write(
  'transfers_graph_weighted',
  {
    relationshipWeightProperty: 'weight',
    writeProperty: 'communityWeighted'
  }
)
YIELD communityCount, modularity, ranLevels;

MATCH (c:Club)
RETURN c.name, c.communityWeighted
ORDER BY c.communityWeighted;

-- PCC
MATCH path = shortestPath((player1:Player)-[*]-(player2:Player))
WHERE player1.name = "Lionel Messi" AND player2.name = "Cristiano Ronaldo"
RETURN path, length(path) AS PathLength;

WITH RECURSIVE paths AS (
    SELECT
        p1.player_id AS start_player,
        p2.player_id AS end_player,
        ARRAY[p1.player_id, p1.current_club_id] AS path,
        0 AS level,
        p1.current_club_id = p2.current_club_id AS end_reached
    FROM players p1, players p2
    WHERE p1.name = 'Lionel Messi' AND p2.name = 'Cristiano Ronaldo'

    UNION ALL

    SELECT
        sp.start_player,
        sp.end_player,
        array_append(sp.path, t.to_club_id) AS path,
        sp.level + 1 AS level,
        t.to_club_id = (SELECT current_club_id FROM players WHERE name = 'Cristiano Ronaldo') AS end_reached
    FROM paths sp
    JOIN transfers t ON sp.path[array_length(sp.path, 1)] = t.from_club_id
    WHERE t.to_club_id != ALL(sp.path
    AND sp.level < 3
))

SELECT *
FROM paths
WHERE end_reached = TRUE
ORDER BY level ASC
LIMIT 1;

-- Djikstra
CALL gds.graph.project.cypher(
  'TransferGraphDijkstra',

  'MATCH (c:Club) 
   RETURN c.club_id AS id',

  'MATCH (c1:Club)<-[:INITIATED_BY]-(t:Transfer)-[:FINALIZED_BY]->(c2:Club)
   WHERE t.transfer_fee IS NOT NULL
   RETURN c1.club_id AS source,
          c2.club_id AS target,
          t.transfer_fee AS weight'
)

CALL gds.shortestPath.dijkstra.stream('TransferGraphDijkstra', {
  sourceNode: 583,
  targetNode: 985,
  relationshipWeightProperty: 'weight'
})
YIELD index, sourceNode, targetNode, totalCost, nodeIds, costs
RETURN index,
       sourceNode,  
       targetNode,
       totalCost,
       nodeIds,
       costs
ORDER BY index;
-- pour verif
MATCH (start:Club {club_id: 583})<-[:INITIATED_BY]-(t:Transfer)-[:FINALIZED_BY]->(c:Club)
RETURN start.club_id AS startClub, t.transfer_fee AS fee, c.club_id AS nextClub
ORDER BY fee
LIMIT 20


WITH RECURSIVE paths (node, path, cost, rnk, lev) AS (
    SELECT
        t.to_club_id AS node,
        CONCAT(t.from_club_id, '->', t.to_club_id) AS path,
        t.transfer_fee AS cost,
        CAST(1 AS bigint) AS rnk,
        CAST(1 AS bigint) AS lev
    FROM transfers t
    WHERE t.from_club_id = 583
      AND t.transfer_fee IS NOT NULL

    UNION ALL

    SELECT
        t.to_club_id AS node,
        p.path || '->' || t.to_club_id,
        p.cost + t.transfer_fee AS cost,
        RANK() OVER (
            PARTITION BY t.to_club_id
            ORDER BY p.cost + t.transfer_fee
        )::bigint AS rnk,
        (p.lev + 1)::bigint AS lev
    FROM paths p
    JOIN transfers t ON t.from_club_id = p.node
    WHERE p.rnk = 1
      AND t.transfer_fee IS NOT NULL
),
paths_ranked AS (
    SELECT
        lev,
        node,
        path,
        cost,
        RANK() OVER (
            PARTITION BY node
            ORDER BY cost
        ) AS rnk_t
    FROM paths
    WHERE rnk = 1
)
SELECT
    node,
    path,
    cost,
    lev
FROM paths_ranked
WHERE rnk_t = 1
  AND node = 985
ORDER BY cost
LIMIT 1;