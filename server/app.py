import os
from sanic import Sanic
from sanic.request import Request
from sanic.response import HTTPResponse, json
from aredis import StrictRedis

REDIS_URL = os.getenv("HELLO_DOCKER_REDIS_URL") or "redis://host.docker.internal?db=0"
HOST = os.getenv("HELLO_DOCKER_HOST") or "0.0.0.0"
if port := os.getenv("HELLO_DOCKER_PORT"):
    PORT = int(port)
else:
    PORT = 5000


app = Sanic("hello_docker")
client = StrictRedis.from_url(REDIS_URL, decode_responses=True)


@app.get("/")
async def test(_: Request) -> HTTPResponse:
    return json({"hello": "world"})


@app.get("/ping")
async def ping(_: Request) -> HTTPResponse:
    return json({"result": "pong"})


@app.get("/foo")
async def getfoo(_: Request) -> HTTPResponse:
    value = await client.get('foo')
    return json({"result": value})


@app.get("/set_foo")
async def setfoo(request: Request) -> HTTPResponse:
    value = request.args.get("value", "")
    await client.set('foo', value)
    return json({"result": "ok"})


if __name__ == "__main__":
    print(f"use redis @{REDIS_URL}")
    print(f"start @{HOST}:{PORT}")
    app.run(host=HOST, port=PORT)
