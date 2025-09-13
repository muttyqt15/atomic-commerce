package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
	db "github.com/muttyqt15/atomic-commerce/packages/database/generated"
)

func main() {
	fmt.Println("Starting worker service...")
	ctx := context.Background()
	conn, err := pgxpool.New(ctx, "postgres://user:password@localhost:5432/merchdrop?sslmode=disable")

	if err != nil {
		log.Fatal("[-] cannot connect to database", err)
	}
	defer conn.Close()

	database := db.New(conn)
	_, err = database.CreateUser(ctx, db.CreateUserParams{Name: "Qin", Email: "test@gmail.com", PasswordHash: "Pass"})
}
