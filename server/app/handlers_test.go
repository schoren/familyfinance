package app

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB() *gorm.DB {
	db, _ := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	db.AutoMigrate(Entities...)
	return db
}

func TestGetCategories(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)

	householdID := "test-household"
	db.Create(&Category{ID: "cat-1", Name: "Food", HouseholdID: householdID, MonthlyBudget: 500})
	db.Create(&Category{ID: "cat-2", Name: "Rent", HouseholdID: householdID, MonthlyBudget: 1000})

	r := gin.Default()
	r.GET("/households/:household_id/categories", h.GetCategories)

	req, _ := http.NewRequest("GET", "/households/"+householdID+"/categories", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var categories []Category
	err := json.Unmarshal(w.Body.Bytes(), &categories)
	assert.NoError(t, err)
	assert.Len(t, categories, 2)
	assert.Equal(t, "Food", categories[0].Name)
}

func TestCreateCategory(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)

	householdID := "test-household"
	r := gin.Default()
	r.POST("/households/:household_id/categories", h.CreateCategory)

	newCat := Category{
		Name:          "Utilities",
		MonthlyBudget: 200,
	}
	body, _ := json.Marshal(newCat)
	req, _ := http.NewRequest("POST", "/households/"+householdID+"/categories", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)

	var created Category
	json.Unmarshal(w.Body.Bytes(), &created)
	assert.Equal(t, "Utilities", created.Name)
	assert.Equal(t, householdID, created.HouseholdID)

	var dbCat Category
	db.First(&dbCat, "name = ?", "Utilities")
	assert.Equal(t, float64(200), dbCat.MonthlyBudget)
}

func TestGetAccounts(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)

	householdID := "test-household"
	db.Create(&Account{ID: "acc-1", Type: "cash", Name: "My Wallet", HouseholdID: householdID})

	r := gin.Default()
	r.GET("/households/:household_id/accounts", h.GetAccounts)

	req, _ := http.NewRequest("GET", "/households/"+householdID+"/accounts", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var accounts []Account
	json.Unmarshal(w.Body.Bytes(), &accounts)
	assert.Len(t, accounts, 1)
	assert.Equal(t, "Efectivo", accounts[0].DisplayName)
}
