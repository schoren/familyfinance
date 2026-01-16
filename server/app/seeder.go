package app

import (
	"log"
	"time"

	"gorm.io/gorm"
)

func SeedData(db *gorm.DB, householdID string) error {
	log.Printf("🌱 Seeding database for household: %s", householdID)

	// Users
	users := []User{
		{
			ID:          "test-user-id",
			Email:       "demo@keda.app",
			Name:        "Demo User",
			GoogleID:    "google-id-1",
			PictureURL:  "https://lh3.googleusercontent.com/a-/ALV-UjWqgX8g_Xg_Xg_Xg_Xg_Xg_Xg_Xg_Xg=s96-c",
			Color:       "blue",
			HouseholdID: householdID,
		},
		{
			ID:          "user-2",
			Email:       "partner@keda.app",
			Name:        "Partner",
			GoogleID:    "google-id-2",
			Color:       "green",
			HouseholdID: householdID,
		},
		{
			ID:          "user-3",
			Email:       "kid@keda.app",
			Name:        "Kid",
			GoogleID:    "google-id-3",
			Color:       "orange",
			HouseholdID: householdID,
		},
	}

	for _, u := range users {
		if err := db.FirstOrCreate(&u, User{ID: u.ID}).Error; err != nil {
			return err
		}
	}

	// Household (ensure it exists if not created by user trigger)
	household := Household{
		ID:   householdID,
		Name: "Familia Demo",
	}
	if err := db.FirstOrCreate(&household, Household{ID: householdID}).Error; err != nil {
		return err
	}

	// Accounts
	walletID := "account-wallet"
	bankID := "account-bank"
	accounts := []Account{
		{
			ID:          walletID,
			Type:        "cash",
			Name:        "Billetera",
			HouseholdID: householdID,
		},
		{
			ID:          bankID,
			Type:        "bank",
			Name:        "Santander",
			Brand:       stringPtr("visa"),
			Bank:        stringPtr("santander"),
			HouseholdID: householdID,
		},
	}

	for _, a := range accounts {
		if err := db.FirstOrCreate(&a, Account{ID: a.ID}).Error; err != nil {
			return err
		}
	}

	// Categories
	catGroceriesID := "cat-groceries"
	catUtilitiesID := "cat-utilities"
	catEntertainmentID := "cat-entertainment"
	catTransportID := "cat-transport"

	categories := []Category{
		{ID: catGroceriesID, Name: "Supermercado", MonthlyBudget: 500.00, IsActive: true, HouseholdID: householdID},
		{ID: catUtilitiesID, Name: "Servicios", MonthlyBudget: 150.00, IsActive: true, HouseholdID: householdID},
		{ID: catEntertainmentID, Name: "Entretenimiento", MonthlyBudget: 100.00, IsActive: true, HouseholdID: householdID},
		{ID: catTransportID, Name: "Transporte", MonthlyBudget: 80.00, IsActive: true, HouseholdID: householdID},
	}

	for _, c := range categories {
		if err := db.FirstOrCreate(&c, Category{ID: c.ID}).Error; err != nil {
			return err
		}
	}

	// Transactions
	// We use FirstOrCreate based on ID to avoid duplicates on restart
	transactions := []Transaction{
		// Today
		{ID: "tx-1", AccountID: walletID, CategoryID: catGroceriesID, UserID: "test-user-id", Amount: 45.50, Date: time.Now(), Description: "Compra semanal", HouseholdID: householdID},
		{ID: "tx-2", AccountID: bankID, CategoryID: catUtilitiesID, UserID: "test-user-id", Amount: 30.00, Date: time.Now(), Description: "Luz", HouseholdID: householdID},
		
		// Yesterday
		{ID: "tx-3", AccountID: walletID, CategoryID: catTransportID, UserID: "user-2", Amount: 5.00, Date: time.Now().AddDate(0, 0, -1), Description: "Uber", HouseholdID: householdID},
		{ID: "tx-4", AccountID: bankID, CategoryID: catGroceriesID, UserID: "user-2", Amount: 12.30, Date: time.Now().AddDate(0, 0, -1), Description: "Panaderia", HouseholdID: householdID},

		// 3 Days ago
		{ID: "tx-5", AccountID: walletID, CategoryID: catEntertainmentID, UserID: "user-3", Amount: 15.00, Date: time.Now().AddDate(0, 0, -3), Description: "Cine", HouseholdID: householdID},
	}

	for _, t := range transactions {
		if err := db.FirstOrCreate(&t, Transaction{ID: t.ID}).Error; err != nil {
			return err
		}
	}

	log.Println("✅ Database seeded successfully")
	return nil
}

func stringPtr(s string) *string {
	return &s
}
