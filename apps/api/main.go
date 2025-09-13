package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()

	router.GET("/health", func(c *gin.Context) {
		data := gin.H{"lang": "GO语言"}
		c.AsciiJSON(http.StatusOK, data)
	})

	err := router.Run(":8080")
	if err != nil {
		log.Fatal("error on starting api")
	}
}
