from flask import Flask, jsonify, Response
from tornado.wsgi import WSGIContainer
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
app = Flask(__name__)


@app.route('/', methods=['GET'])
def test() -> Response:
    return jsonify({"hello": "world"})


@app.route('/ping', methods=['GET'])
def ping() -> Response:
    return jsonify({"result": "pong"})


try:
    http_server = HTTPServer(WSGIContainer(app))
    http_server.listen(5000)
    print("service start @0.0.0:5000")
    IOLoop.instance().start()
except KeyboardInterrupt:
    print("service stopping by user")
except Exception as e:
    raise e
finally:
    print("service stoped!")
