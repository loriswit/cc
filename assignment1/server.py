from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import os


def toHTMLList(items):
    return "<ul>" + "".join({"<li><strong>{}</strong>: {}</li>".format(k, v) for k, v in items}) + "</ul>"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        req = urlparse(self.path)

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

        qs = parse_qs(req.query)
        html = (
            "<h2>Path</h2><p>" + req.path + "</p>" +
            "<h2>Query</h2>" + toHTMLList(qs.items()) +
            "<h2>Environment</h2>" + toHTMLList(os.environ.items()))

        self.wfile.write(html.encode("utf8"))


port = 3333
server = HTTPServer(("", port), Handler)

try:
    print("Listening on port", port)
    server.serve_forever()
except KeyboardInterrupt:
    pass

server.server_close()
print("Good bye")
