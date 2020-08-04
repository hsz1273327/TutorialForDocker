'use strict'

const port = process.env.PORT || 3001

const koa = require('koa')
let app = koa()

const path = require('path')

const logger = require('koa-logger2')
let log_middleware = logger('ip [day/month/year:time zone] "method url protocol/httpVer" status size "referer" "userAgent" duration ms custom[unpacked]')

const route = require('koa-route')
const render = require('koa-swig')
app.context.render = render({
  root: path.join(__dirname, 'views'),
  autoescape: true,
  cache: 'memory', // disable, set to false
  ext: 'html',
  filters: {
  formatVersion: function(version) {
    return '@v' + version;
  }
}
})
const error = require('koa-error')

app.use(error({
  template: path.join(__dirname, './error.html')
}))
app.use(log_middleware.gen)
app.use(route.get('/',
    function*(){
        yield this.render('index')
    })
).use(route.get('/user/:user',
    function*(user){
        console.log(user);
        yield this.render('user',{user:user})
    })
)

app.listen(port, function() {
    console.log('started at %s:  - port:%s', new Date, port)
})
