from sanic import Sanic
from sanic.request import Request
from sanic.response import HTTPResponse, json

app = Sanic("hello_example")


@app.get("/")
async def test(_: Request) -> HTTPResponse:
    return json({"hello": "world"})


@app.get("/ping")
async def ping(_: Request) -> HTTPResponse:
    return json({"result": "pong"})


app.run(host="0.0.0.0", port=5000)
