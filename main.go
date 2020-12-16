package main

import "github.com/gin-gonic/gin"

func main() {
	r := gin.Default()

	// 提供 unicode 实体
	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"hello": "world",
		})
	})

	// 提供字面字符
	r.GET("/ping", func(c *gin.Context) {
		c.PureJSON(200, gin.H{
			"result": "pong",
		})
	})

	// 监听并在 0.0.0.0:8080 上启动服务
	r.Run(":5000")
}
