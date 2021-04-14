import http
import os
from time import sleep

import pymysql.cursors
from flask import Flask, request, jsonify, Blueprint, g
from flask_cors import CORS
from pymysql import OperationalError

app = Flask(__name__)

# allow cross-origin requests
CORS(app)

# database connection
while True:
    try:
        db = pymysql.connect(
            host=os.environ["DB_HOST"],
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASS"],
            database=os.environ["DB_DBNAME"],
            cursorclass=pymysql.cursors.DictCursor)
        break
    except OperationalError:
        # if connection failed, retry after 3 seconds
        sleep(3)

# store fields from watches table, used for validation
with db.cursor() as cur:
    cur.execute("show columns from watches")
    fields = [col["Field"] for col in cur.fetchall()]

# define API routes
api = Blueprint("watch-info-service", __name__)


# POST /watch: add a new watch to the store
@api.route("/watch", methods=["POST"])
def create():
    if not request.json:
        return "body must be in JSON format", http.HTTPStatus.BAD_REQUEST

    # all fields are required
    missing = set(fields) - set(request.json.keys())
    if missing:
        return f"missing fields: {missing}", http.HTTPStatus.BAD_REQUEST

    with db.cursor() as cursor:
        query = f"insert into watches ({','.join(fields)}) values ({','.join(['%s'] * len(fields))})"
        cursor.execute(query, [request.json[col] for col in fields])

    db.commit()
    return "", http.HTTPStatus.OK


# GET /watch/{sku}: return watch data
@api.route("/watch/<sku>")
def read(sku):
    with db.cursor() as cursor:
        cursor.execute("select * from watches where sku = %s", sku)
        watch = cursor.fetchone()
        response = jsonify(watch) if watch else ("", http.HTTPStatus.NOT_FOUND)

    # cache if found
    g.cache = watch is not None
    return response


# PUT /watch/{sku}: updates a watch in the store with form data
@api.route("/watch/<sku>", methods=["PUT"])
def update(sku):
    if not request.json:
        return "body must be in JSON format", http.HTTPStatus.BAD_REQUEST

    # only keep valid properties
    updates = [f"{key}='{value}'" for key, value in request.json.items() if key in fields]

    with db.cursor() as cursor:
        affected = cursor.execute(f"update watches set {','.join(updates)} where sku = %s", sku)

    db.commit()
    return ("", http.HTTPStatus.OK) if affected > 0 else ("", http.HTTPStatus.NOT_FOUND)


# DELETE/watch/{sku}: deletes a watch
@api.route("/watch/<sku>", methods=["DELETE"])
def delete(sku):
    with db.cursor() as cursor:
        affected = cursor.execute(f"delete from watches where sku = %s", sku)

    db.commit()
    return ("", http.HTTPStatus.OK) if affected > 0 else ("", http.HTTPStatus.NOT_FOUND)


# GET /watch/complete-sku/{prefix}: get list of SKUs matching a prefix
@api.route("/watch/complete-sku/<prefix>")
def complete(prefix):
    with db.cursor() as cursor:
        cursor.execute(f"select * from watches where sku like '{prefix}%' limit 100")
        response = jsonify(cursor.fetchall())

    g.cache = True
    return response


# GET /watch/find: finds watches by any criteria
@api.route("/watch/find")
def find():
    with db.cursor() as cursor:
        # partial sku
        sku = request.args.get("sku") or ""
        conditions = [f"sku like '%{sku}%'"]

        # generate query search conditions
        parameters = ["type", "status", "gender", "year"]
        conditions.extend([f"{p}='{arg}'" for p in parameters if (arg := request.args.get(p))])

        cursor.execute(f"select * from watches where {' and '.join(conditions)} limit 100")
        response = jsonify(cursor.fetchall())

    g.cache = True
    return response


# no cache control by default
@api.before_request
def before():
    g.cache = False


# set cache control if required
@api.after_request
def cache(response):
    if g.cache:
        response.cache_control.max_age = 3600
    return response


# register routes with base URL
app.register_blueprint(api, url_prefix="/info/v1")

# start the server
if __name__ == "__main__":
    app.run(port=1080)
