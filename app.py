from flask import Flask, jsonify
from neo4j import GraphDatabase

app = Flask(__name__)

driver = GraphDatabase.driver("neo4j://localhost:7687", auth=("neo4j", "mdp"))

@app.route("/ping", methods=["GET"])
def ping():
    return {"status": "ok"}, 200

@app.route("/clubs/pagerank", methods=["GET"])
def clubs_pagerank():
    with driver.session() as session:
        session.run("""
            CALL gds.pageRank.write('transfers_graph_weighted', {
                relationshipWeightProperty: 'weight',
                writeProperty: 'pagerankWeighted'
            })
        """)

        result = session.run("""
            MATCH (c:Club)
            RETURN c.name AS clubName, c.pagerankWeighted AS score
            ORDER BY score DESC
            LIMIT 5
        """)

        data = []
        for record in result:
            data.append({
                "clubName": record["clubName"],
                "score": record["score"]
            })

    return jsonify(data), 200


@app.route("/clubs/louvain", methods=["GET"])
def clubs_louvain():
    with driver.session() as session:
        session.run("""
            CALL gds.louvain.write('transfers_graph_weighted', {
                relationshipWeightProperty: 'weight',
                writeProperty: 'communityWeighted'
            })
        """)

        result = session.run("""
            MATCH (c:Club)
            WITH c.communityWeighted AS communityId, collect(c.name) AS clubs
            RETURN communityId, size(clubs) AS size, clubs
            ORDER BY size DESC
            LIMIT 5
        """)

        data = []
        for record in result:
            data.append({
                "communityId": record["communityId"],
        "size": record["size"],
        "clubs": record["clubs"]
    })

    return jsonify(data), 200

if __name__ == "__main__":
    app.run(debug=True, port=5001)