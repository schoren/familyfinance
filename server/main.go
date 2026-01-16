package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/schoren/keda/server/app"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var (
	db      *gorm.DB
	Version = "dev"
)

func main() {
	r := gin.Default()

	// Configure CORS
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	initDB()

	// Initialize handlers
	handlers := app.NewHandlers(db)

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// Version
	r.GET("/version", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"version": Version})
	})

	// Authentication
	r.POST("/auth/google", handlers.AuthGoogle)

	// Test-only authentication (only enabled when TEST_MODE=true)
	if os.Getenv("TEST_MODE") == "true" {
		log.Println("⚠️  TEST MODE ENABLED - Test authentication endpoint available at /auth/test-login")
		r.POST("/auth/test-login", handlers.TestLogin)
	}

	// Households
	r.POST("/households", handlers.CreateHousehold)

	// Scoped routes
	h := r.Group("/households/:household_id")
	h.Use(handlers.JWTMiddleware())
	{
		// Legacy sync endpoint (for backwards compatibility)
		h.GET("/sync", handlers.HandleSync)

		// Invitations
		h.POST("/invites", handlers.CreateInvitation)

		// Members
		h.GET("/members", handlers.GetMembers)
		h.DELETE("/members/:user_id", handlers.RemoveMember)

		// Categories
		h.GET("/categories", handlers.GetCategories)
		h.POST("/categories", handlers.CreateCategory)
		h.PUT("/categories/:id", handlers.UpdateCategory)
		h.DELETE("/categories/:id", handlers.DeleteCategory)
		h.GET("/categories/:id/suggested-notes", handlers.GetSuggestedNotes)

		// Accounts
		h.GET("/accounts", handlers.GetAccounts)
		h.POST("/accounts", handlers.CreateAccount)
		h.PUT("/accounts/:id", handlers.UpdateAccount)
		h.DELETE("/accounts/:id", handlers.DeleteAccount)

		// Transactions
		h.GET("/transactions", handlers.GetTransactions)
		h.POST("/transactions", handlers.CreateTransaction)
		h.PUT("/transactions/:id", handlers.UpdateTransaction)
		h.DELETE("/transactions/:id", handlers.DeleteTransaction)

		// Monthly summary
		h.GET("/summary/:month", handlers.GetMonthlySummary)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8090"
	}
	log.Printf("Server version: %s", Version)
	log.Printf("Server running on port %s", port)
	r.Run(":" + port)
}

func initDB() {
	var err error
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=UTC",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		os.Getenv("DB_PORT"),
	)

	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Could not connect to database: %v", err)
	}

	log.Println("Successfully connected to database")

	// Run GORM Migrations
	if err := db.AutoMigrate(app.Entities...); err != nil {
		log.Fatalf("Could not run migrations: %v", err)
	}

	// Seed data if in TEST_MODE
	if os.Getenv("TEST_MODE") == "true" {
		householdID := os.Getenv("TEST_HOUSEHOLD_ID")
		if householdID == "" {
			householdID = "test-household-id"
		}
		if err := app.SeedData(db, householdID); err != nil {
			log.Printf("⚠️  Failed to seed data: %v", err)
		}
	}
}
