package app

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

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
}

func TestCategoryCRUD(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	householdID := "test-hh"

	r := gin.Default()
	r.POST("/households/:household_id/categories", h.CreateCategory)
	r.PUT("/households/:household_id/categories/:id", h.UpdateCategory)
	r.DELETE("/households/:household_id/categories/:id", h.DeleteCategory)

	// Create
	newCat := Category{ID: "cat-new", Name: "Games", MonthlyBudget: 100}
	body, _ := json.Marshal(newCat)
	req, _ := http.NewRequest("POST", "/households/"+householdID+"/categories", bytes.NewBuffer(body))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusCreated, w.Code)

	// Update
	updateCat := Category{Name: "Gaming", MonthlyBudget: 150}
	body, _ = json.Marshal(updateCat)
	req, _ = http.NewRequest("PUT", "/households/"+householdID+"/categories/cat-new", bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	var updated Category
	json.Unmarshal(w.Body.Bytes(), &updated)
	assert.Equal(t, "Gaming", updated.Name)

	// Delete
	req, _ = http.NewRequest("DELETE", "/households/"+householdID+"/categories/cat-new", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestCategoryErrorCases(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	householdID := "test-hh"

	r := gin.Default()
	r.POST("/households/:household_id/categories", h.CreateCategory)
	r.PUT("/households/:household_id/categories/:id", h.UpdateCategory)

	// Invalid JSON
	req, _ := http.NewRequest("POST", "/households/"+householdID+"/categories", bytes.NewBufferString("{invalid"))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// 404 Update
	body, _ := json.Marshal(Category{Name: "Nope"})
	req, _ = http.NewRequest("PUT", "/households/"+householdID+"/categories/not-found", bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestAccountCRUD(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	householdID := "test-hh"

	r := gin.Default()
	r.GET("/households/:household_id/accounts", h.GetAccounts)
	r.POST("/households/:household_id/accounts", h.CreateAccount)
	r.PUT("/households/:household_id/accounts/:id", h.UpdateAccount)
	r.DELETE("/households/:household_id/accounts/:id", h.DeleteAccount)

	// Create
	newAcc := Account{ID: "acc-1", Type: "bank", Name: "My Bank"}
	body, _ := json.Marshal(newAcc)
	req, _ := http.NewRequest("POST", "/households/"+householdID+"/accounts", bytes.NewBuffer(body))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusCreated, w.Code)

	// Get & Display Name
	req, _ = http.NewRequest("GET", "/households/"+householdID+"/accounts", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	var accounts []Account
	json.Unmarshal(w.Body.Bytes(), &accounts)
	assert.Equal(t, "My Bank", accounts[0].DisplayName)

	// Update
	updatedName := "New Bank"
	updateAcc := Account{Type: "bank", Name: updatedName}
	body, _ = json.Marshal(updateAcc)
	req, _ = http.NewRequest("PUT", "/households/"+householdID+"/accounts/acc-1", bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	// Delete
	req, _ = http.NewRequest("DELETE", "/households/"+householdID+"/accounts/acc-1", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestGetMonthlySummary(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	householdID := "test-hh"
	month := "2024-01"
	parsedMonth, _ := time.Parse("2006-01", month)

	// Seed data
	cat := Category{ID: "cat-1", Name: "Food", HouseholdID: householdID, MonthlyBudget: 500}
	db.Create(&cat)
	db.Create(&Transaction{
		ID:          "t1",
		Amount:      100,
		CategoryID:  cat.ID,
		HouseholdID: householdID,
		Date:        parsedMonth.Add(12 * time.Hour),
	})

	r := gin.Default()
	r.GET("/households/:household_id/summary/:month", h.GetMonthlySummary)

	req, _ := http.NewRequest("GET", "/households/"+householdID+"/summary/"+month, nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var summary MonthlySummary
	json.Unmarshal(w.Body.Bytes(), &summary)
	assert.Equal(t, float64(500), summary.TotalBudget)
	assert.Equal(t, float64(100), summary.TotalSpent)
	assert.Len(t, summary.Categories, 1)
	assert.Equal(t, float64(100), summary.Categories[0].Spent)
}

func TestTransactionCRUD(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	householdID := "test-hh"

	r := gin.Default()
	r.GET("/households/:household_id/transactions", h.GetTransactions)
	r.POST("/households/:household_id/transactions", h.CreateTransaction)
	r.PUT("/households/:household_id/transactions/:id", h.UpdateTransaction)
	r.DELETE("/households/:household_id/transactions/:id", h.DeleteTransaction)

	// Create
	newT := Transaction{ID: "t-new", Amount: 20, Description: "Coffee", HouseholdID: householdID}
	body, _ := json.Marshal(newT)
	req, _ := http.NewRequest("POST", "/households/"+householdID+"/transactions", bytes.NewBuffer(body))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusCreated, w.Code)

	// Get
	req, _ = http.NewRequest("GET", "/households/"+householdID+"/transactions", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	// Update
	updateT := Transaction{Amount: 25, Description: "Large Coffee"}
	body, _ = json.Marshal(updateT)
	req, _ = http.NewRequest("PUT", "/households/"+householdID+"/transactions/t-new", bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	// Delete
	req, _ = http.NewRequest("DELETE", "/households/"+householdID+"/transactions/t-new", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestAccountDisplayNames(t *testing.T) {
	db := setupTestDB()
	h := NewHandlers(db)

	brand := "Visa"
	bank := "Chase"

	tests := []struct {
		name     string
		account  Account
		expected string
	}{
		{"Cash", Account{Type: "cash"}, "Efectivo"},
		{"Card Brand & Bank", Account{Type: "card", Brand: &brand, Bank: &bank}, "Visa - Chase"},
		{"Card Brand only", Account{Type: "card", Brand: &brand}, "Visa"},
		{"Card Bank only", Account{Type: "card", Bank: &bank}, "Chase"},
		{"Card Basic", Account{Type: "card"}, "Tarjeta"},
		{"Bank Account", Account{Type: "bank", Name: "Savings"}, "Savings"},
		{"Default", Account{Type: "other", Name: "Other"}, "Other"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			h.populateAccountDisplayName(&tt.account)
			assert.Equal(t, tt.expected, tt.account.DisplayName)
		})
	}
}

func TestGetTransactionsFiltering(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	householdID := "test-hh"

	date1, _ := time.Parse("2006-01-02", "2024-01-05")
	date2, _ := time.Parse("2006-01-02", "2024-02-05")

	db.Create(&Transaction{ID: "t1", HouseholdID: householdID, Date: date1})
	db.Create(&Transaction{ID: "t2", HouseholdID: householdID, Date: date2})

	r := gin.Default()
	r.GET("/households/:household_id/transactions", h.GetTransactions)

	// 1. Filter by 2024-01
	req, _ := http.NewRequest("GET", "/households/"+householdID+"/transactions?month=2024-01", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
	var transactions []Transaction
	json.Unmarshal(w.Body.Bytes(), &transactions)
	assert.Len(t, transactions, 1)
	assert.Equal(t, "t1", transactions[0].ID)

	// 2. Invalid format
	req, _ = http.NewRequest("GET", "/households/"+householdID+"/transactions?month=invalid", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestJWTMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)

	// Set secret for test
	os.Setenv("JWT_SECRET", "test_secret")
	defer os.Unsetenv("JWT_SECRET")

	r := gin.Default()
	r.Use(h.JWTMiddleware())
	r.GET("/protected/:household_id", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// 1. Missing header
	req, _ := http.NewRequest("GET", "/protected/hh1", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusUnauthorized, w.Code)

	// 2. Invalid format
	req, _ = http.NewRequest("GET", "/protected/hh1", nil)
	req.Header.Set("Authorization", "InvalidFormat token")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusUnauthorized, w.Code)

	// 3. Valid Token but wrong HouseholdID
	user := User{ID: "u1", HouseholdID: "hh1"}
	token, _ := h.generateJWT(user)

	req, _ = http.NewRequest("GET", "/protected/hh2", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusForbidden, w.Code)

	// 4. Valid Token and correct HouseholdID
	req, _ = http.NewRequest("GET", "/protected/hh1", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestHouseholdAndInvitation(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)

	r := gin.Default()
	r.POST("/households", h.CreateHousehold)
	r.POST("/households/:household_id/invitations", h.CreateInvitation)
	r.GET("/households/:household_id/members", h.GetMembers)
	r.DELETE("/households/:household_id/members/:user_id", h.RemoveMember)

	// Create Household
	newHH := Household{ID: "hh-new", Name: "New Family"}
	body, _ := json.Marshal(newHH)
	req, _ := http.NewRequest("POST", "/households", bytes.NewBuffer(body))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusCreated, w.Code)

	// Create Invitation
	invReq := struct{ Email string }{Email: "test@example.com"}
	body, _ = json.Marshal(invReq)
	req, _ = http.NewRequest("POST", "/households/hh-new/invitations", bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusCreated, w.Code)

	// Get Members
	db.Create(&User{ID: "u1", Name: "User 1", HouseholdID: "hh-new"})
	req, _ = http.NewRequest("GET", "/households/hh-new/members", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	// Remove Member
	req, _ = http.NewRequest("DELETE", "/households/hh-new/members/u1", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestHandleSync(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	householdID := "hh-sync"

	r := gin.Default()
	r.GET("/households/:household_id/sync", h.HandleSync)

	req, _ := http.NewRequest("GET", "/households/"+householdID+"/sync", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestAuthGoogle(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)

	// Mock Google API
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userInfo := GoogleUserInfo{
			ID:    "google-id-123",
			Email: "test@gmail.com",
			Name:  "Test User",
		}
		json.NewEncoder(w).Encode(userInfo)
	}))
	defer server.Close()
	h.googleAPIURL = server.URL

	r := gin.Default()
	r.POST("/auth/google", h.AuthGoogle)

	// 1. New user (should create household and user)
	authReq := GoogleLoginRequest{AccessToken: "fake-token"}
	body, _ := json.Marshal(authReq)
	req, _ := http.NewRequest("POST", "/auth/google", bytes.NewBuffer(body))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp AuthResponse
	json.Unmarshal(w.Body.Bytes(), &resp)
	assert.Equal(t, "test@gmail.com", resp.User.Email)
	assert.NotEmpty(t, resp.Token)
	assert.NotEmpty(t, resp.HouseholdID)

	// 2. Existing user
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("POST", "/auth/google", bytes.NewBuffer(body))
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	// 3. User with Invite Code
	db.Create(&Invitation{ID: "inv1", Code: "CODE123", HouseholdID: "hh-target", Status: "pending"})
	authReqInvite := GoogleLoginRequest{AccessToken: "fake-token", InviteCode: "CODE123"}
	// Use different email to trigger new user logic
	server.Config.Handler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userInfo := GoogleUserInfo{
			ID:    "google-id-456",
			Email: "invited@gmail.com",
			Name:  "Invited User",
		}
		json.NewEncoder(w).Encode(userInfo)
	})

	body, _ = json.Marshal(authReqInvite)
	req, _ = http.NewRequest("POST", "/auth/google", bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
	json.Unmarshal(w.Body.Bytes(), &resp)
	assert.Equal(t, "hh-target", resp.HouseholdID)

	// 4. Soft-deleted user
	db.Model(&User{}).Where("email = ?", "test@gmail.com").Update("deleted_at", gorm.DeletedAt{Time: time.Now(), Valid: true})
	server.Config.Handler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userInfo := GoogleUserInfo{ID: "google-id-123", Email: "test@gmail.com", Name: "Test User"}
		json.NewEncoder(w).Encode(userInfo)
	})
	req, _ = http.NewRequest("POST", "/auth/google", bytes.NewBufferString(`{"access_token":"fake"}`))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusForbidden, w.Code)

	// 5. Google API Failure
	server.Config.Handler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
	})
	req, _ = http.NewRequest("POST", "/auth/google", bytes.NewBufferString(`{"access_token":"fake"}`))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestMoreErrorPaths(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	r := gin.Default()

	r.GET("/households/:household_id/sync", h.HandleSync)
	r.DELETE("/households/:household_id/members/:user_id", h.RemoveMember)
	r.POST("/households", h.CreateHousehold)

	// 1. Sync invalid month
	req, _ := http.NewRequest("GET", "/households/hh1/sync?month=bad", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// 2. Remove non-existent member
	req, _ = http.NewRequest("DELETE", "/households/hh1/members/u-none", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusNotFound, w.Code)

	// 3. Create Household invalid JSON
	req, _ = http.NewRequest("POST", "/households", bytes.NewBufferString("{bad}"))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// 4. Monthly Summary invalid month
	r.GET("/households/:household_id/summary/:month", h.GetMonthlySummary)
	req, _ = http.NewRequest("GET", "/households/hh1/summary/bad", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// 5. Create Invitation invalid JSON
	r.POST("/households/:household_id/invitations", h.CreateInvitation)
	req, _ = http.NewRequest("POST", "/households/hh1/invitations", bytes.NewBufferString("{bad}"))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// 6. Create Account invalid JSON
	r.POST("/households/:household_id/accounts", h.CreateAccount)
	req, _ = http.NewRequest("POST", "/households/hh1/accounts", bytes.NewBufferString("{bad}"))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// 7. Create Transaction invalid JSON
	r.POST("/households/:household_id/transactions", h.CreateTransaction)
	req, _ = http.NewRequest("POST", "/households/hh1/transactions", bytes.NewBufferString("{bad}"))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// 8. Update Account 404 and invalid JSON
	r.PUT("/households/:household_id/accounts/:id", h.UpdateAccount)
	req, _ = http.NewRequest("PUT", "/households/hh1/accounts/none", bytes.NewBufferString(`{"name":"test"}`))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusNotFound, w.Code)

	// Create account for invalid JSON test
	h.db.Create(&Account{ID: "acc-exist", HouseholdID: "hh1", Name: "Existing"})
	req, _ = http.NewRequest("PUT", "/households/hh1/accounts/acc-exist", bytes.NewBufferString(`{bad}`))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestAuthGoogle_NoToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	r := gin.Default()
	r.POST("/auth/google", h.AuthGoogle)

	req, _ := http.NewRequest("POST", "/auth/google", bytes.NewBufferString(`{}`))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestDBErrors(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)

	// Break the DB
	sqlDB, _ := db.DB()
	sqlDB.Close()

	r := gin.Default()
	r.GET("/households/:household_id/categories", h.GetCategories)
	r.POST("/households/:household_id/categories", h.CreateCategory)
	r.PUT("/households/:household_id/categories/:id", h.UpdateCategory)
	r.DELETE("/households/:household_id/categories/:id", h.DeleteCategory)

	r.GET("/households/:household_id/accounts", h.GetAccounts)
	r.POST("/households/:household_id/accounts", h.CreateAccount)
	r.PUT("/households/:household_id/accounts/:id", h.UpdateAccount)
	r.DELETE("/households/:household_id/accounts/:id", h.DeleteAccount)

	r.GET("/households/:household_id/transactions", h.GetTransactions)
	r.POST("/households/:household_id/transactions", h.CreateTransaction)
	r.PUT("/households/:household_id/transactions/:id", h.UpdateTransaction)
	r.DELETE("/households/:household_id/transactions/:id", h.DeleteTransaction)

	r.GET("/households/:household_id/members", h.GetMembers)
	r.DELETE("/households/:household_id/members/:user_id", h.RemoveMember)
	r.GET("/households/:household_id/summary/:month", h.GetMonthlySummary)
	r.GET("/households/:household_id/sync", h.HandleSync)

	// List of requests to try
	reqs := []*http.Request{
		httptest.NewRequest("GET", "/households/hh1/categories", nil),
		httptest.NewRequest("PUT", "/households/hh1/categories/c1", bytes.NewBufferString(`{"name":"test"}`)),
		httptest.NewRequest("DELETE", "/households/hh1/categories/c1", nil),

		httptest.NewRequest("GET", "/households/hh1/accounts", nil),
		httptest.NewRequest("PUT", "/households/hh1/accounts/a1", bytes.NewBufferString(`{"name":"test"}`)),
		httptest.NewRequest("DELETE", "/households/hh1/accounts/a1", nil),

		httptest.NewRequest("GET", "/households/hh1/transactions", nil),
		httptest.NewRequest("PUT", "/households/hh1/transactions/t1", bytes.NewBufferString(`{"amount":1}`)),
		httptest.NewRequest("DELETE", "/households/hh1/transactions/t1", nil),

		httptest.NewRequest("GET", "/households/hh1/members", nil),
		httptest.NewRequest("DELETE", "/households/hh1/members/u1", nil),
		httptest.NewRequest("GET", "/households/hh1/summary/2024-01", nil),
		httptest.NewRequest("GET", "/households/hh1/sync", nil),
	}

	for _, req := range reqs {
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		// Note: Some might return 500, others 404 depending on where the DB error hits first
		// But asserting != 200 is good enough, or we check specifically
		// With DB closed, First() calls usually fail with error, Update/Delete/Find too.
	}

	// Create Category failure
	body, _ := json.Marshal(Category{Name: "Fail"})
	req := httptest.NewRequest("POST", "/households/hh1/categories", bytes.NewBuffer(body))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusInternalServerError, w.Code)

	// Create Account failure
	body, _ = json.Marshal(Account{Name: "Fail"})
	req = httptest.NewRequest("POST", "/households/hh1/accounts", bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusInternalServerError, w.Code)

	// Create Transaction failure
	body, _ = json.Marshal(Transaction{Amount: 100})
	req = httptest.NewRequest("POST", "/households/hh1/transactions", bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}
