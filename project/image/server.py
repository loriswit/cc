from urllib.error import HTTPError
from urllib.request import urlopen

from flask import Flask, Blueprint, make_response
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


# register routes with base URL
app.register_blueprint(api, url_prefix="/image/v1")

# start the server
if __name__ == "__main__":
    app.run(port=1080)
