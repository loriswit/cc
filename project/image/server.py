import http
import re
from urllib.error import HTTPError
from urllib.request import urlopen

from flask import Flask, Blueprint, make_response, Response, request
from flask_cors import CORS

app = Flask(__name__)

# allow cross-origin requests
CORS(app)

# define API routes
api = Blueprint("watch-image-service", __name__)


# GET /get/{sku}: return watch image
@api.route("/watch/<sku>")
def read(sku):
    base_url = "https://s3-eu-west-1.amazonaws.com/cloudcomputing-2018/project1/images/"
    try:
        image = urlopen(base_url + sku + ".png")
        response = make_response(image.read())
        response.headers.set("Content-Type", "image/png")
        return response
    except HTTPError as e:
        return "", e.code


@api.after_request
def cache(response: Response):
    # generate etag from body
    response.add_etag()

    # don't send image if unchanged
    if "If-None-Match" in request.headers:
        # split request etags and remove quotes
        matches = [match.replace("\"", "") for match in re.split(",\\s*", request.headers["If-None-Match"])]
        (etag, weak) = response.get_etag()
        if etag in matches:
            return make_response("", http.HTTPStatus.NOT_MODIFIED)

    # expire after one hour
    response.cache_control.max_age = 3600
    return response


# register routes with base URL
app.register_blueprint(api, url_prefix="/image/v1")

# start the server
if __name__ == "__main__":
    app.run(port=1080)
