from sanic.response import json
from sanic import Sanic

app = Sanic("hello_example")


@app.get("/")
async def test(request):
    return json({"hello": "world"})


@app.get("/ping")
async def ping(request):
    return json({"result": "pong"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
