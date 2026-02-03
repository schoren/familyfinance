package app

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"math/big"
	"net/http"
	"net/mail"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"google.golang.org/api/idtoken"
	"gorm.io/gorm"
)

var userColors = []string{
	"#EF4444", // Red
	"#F59E0B", // Amber
	"#10B981", // Emerald
	"#3B82F6", // Blue
	"#6366F1", // Indigo
	"#8B5CF6", // Violet
	"#EC4899", // Pink
	"#06B6D4", // Cyan
	"#F97316", // Orange
	"#84CC16", // Lime
}

func getRandomColor() string {
	// Select random color
	randIdx, _ := rand.Int(rand.Reader, big.NewInt(int64(len(userColors))))
	return userColors[randIdx.Int64()]
}

type Handlers struct {
	db           *gorm.DB
	googleAPIURL string
}

func NewHandlers(db *gorm.DB) *Handlers {
	return &Handlers{
		db:           db,
		googleAPIURL: "https://www.googleapis.com/oauth2/v3/userinfo",
	}
}

// ============================================================================
// HOUSEHOLDS
// ============================================================================

func (h *Handlers) CreateHousehold(c *gin.Context) {
	var household Household
	if err := c.ShouldBindJSON(&household); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.db.Create(&household).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create household"})
		return
	}

	h.createDefaultCashAccount(household.ID)

	c.JSON(http.StatusCreated, household)
}

func (h *Handlers) CreateInvitation(c *gin.Context) {
	householdID := c.Param("household_id")

	var req struct {
		Email string `json:"email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate email
	if _, err := mail.ParseAddress(req.Email); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid email address"})
		return
	}

	// Check for duplicate pending invitation
	var existingInvitation Invitation
	if err := h.db.Where("household_id = ? AND email = ? AND status = ?", householdID, req.Email, "pending").First(&existingInvitation).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Invitation already pending for this email"})
		return
	}

	// Generate a 6-char random hex code
	b := make([]byte, 3)
	if _, err := rand.Read(b); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate invitation code"})
		return
	}
	code := hex.EncodeToString(b)

	invitation := Invitation{
		ID:          uuid.New().String(),
		Code:        code,
		Email:       req.Email,
		HouseholdID: householdID,
		Status:      "pending",
	}

	if err := h.db.Create(&invitation).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create invitation"})
		return
	}

	// Send email asyc
	go func() {
		err := h.SendInvitationEmail(req.Email, code)
		if err != nil {
			log.Printf("Error sending invitation email to %s: %v", req.Email, err)
		}
	}()

	c.JSON(http.StatusCreated, invitation)
}

// ============================================================================
// MEMBERS
// ============================================================================

type MemberResponse struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	Email      string `json:"email"`
	PictureURL string `json:"picture_url"`
	Color      string `json:"color"`
	Status     string `json:"status"` // "active" or "pending"
	InviteCode string `json:"invite_code,omitempty"`
}

func (h *Handlers) GetMembers(c *gin.Context) {
	householdID := c.Param("household_id")

	// 1. Get Users (active members)
	var users []User
	if err := h.db.Where("household_id = ?", householdID).Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch members"})
		return
	}

	// 2. Get Pending Invitations
	var invitations []Invitation
	if err := h.db.Where("household_id = ? AND status = ?", householdID, "pending").Find(&invitations).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch invitations"})
		return
	}

	// 3. Combine
	var response []MemberResponse

	for _, user := range users {
		response = append(response, MemberResponse{
			ID:         user.ID,
			Name:       user.Name,
			Email:      user.Email,
			PictureURL: user.PictureURL,
			Color:      user.Color,
			Status:     "active",
		})
	}

	for _, invite := range invitations {
		// Invitations only have email, no name yet
		response = append(response, MemberResponse{
			ID:         invite.ID,
			Name:       "Invitado", // Placeholder
			Email:      invite.Email,
			Status:     "pending",
			InviteCode: invite.Code,
		})
	}

	c.JSON(http.StatusOK, response)
}

func (h *Handlers) RemoveMember(c *gin.Context) {
	householdID := c.Param("household_id")
	targetID := c.Param("user_id") // Can be user_id or invitation_id

	// 1. Check if it's an invitation
	var invitation Invitation
	if err := h.db.Where("id = ? AND household_id = ?", targetID, householdID).First(&invitation).Error; err == nil {
		// Found invitation, delete it (hard delete or soft depending on struct, struct has DeletedAt so soft)
		if err := h.db.Delete(&invitation).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove invitation"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Invitation removed"})
		return
	}

	// 2. Check if it's a user
	var user User
	if err := h.db.Where("id = ? AND household_id = ?", targetID, householdID).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Member or invitation not found"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		}
		return
	}

	// Soft delete the user
	if err := h.db.Delete(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove member"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Member removed"})
}

// ============================================================================
// CATEGORIES
// ============================================================================

func (h *Handlers) GetCategories(c *gin.Context) {
	householdID := c.Param("household_id")
	categories := []Category{}
	if err := h.db.Where("household_id = ?", householdID).Find(&categories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}
	c.JSON(http.StatusOK, categories)
}

func (h *Handlers) CreateCategory(c *gin.Context) {
	householdID := c.Param("household_id")
	var category Category
	if err := c.ShouldBindJSON(&category); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if category.ID == "" {
		category.ID = uuid.New().String()
	}
	category.HouseholdID = householdID
	if err := h.db.Create(&category).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create category"})
		return
	}

	c.JSON(http.StatusCreated, category)
}

func (h *Handlers) UpdateCategory(c *gin.Context) {
	householdID := c.Param("household_id")
	id := c.Param("id")

	var category Category
	if err := h.db.Where("household_id = ?", householdID).First(&category, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Category not found"})
		return
	}

	var updates Category
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update fields
	category.Name = updates.Name
	category.MonthlyBudget = updates.MonthlyBudget
	category.IsActive = updates.IsActive

	if err := h.db.Save(&category).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update category"})
		return
	}

	c.JSON(http.StatusOK, category)
}

func (h *Handlers) DeleteCategory(c *gin.Context) {
	householdID := c.Param("household_id")
	id := c.Param("id")

	if err := h.db.Where("household_id = ?", householdID).Delete(&Category{}, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete category"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Category deleted"})
}

// ============================================================================
// ACCOUNTS
// ============================================================================

func (h *Handlers) GetAccounts(c *gin.Context) {
	householdID := c.Param("household_id")
	accounts := []Account{}
	if err := h.db.Where("household_id = ?", householdID).Find(&accounts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch accounts"})
		return
	}
	for i := range accounts {
		h.populateAccountDisplayName(&accounts[i])
	}
	c.JSON(http.StatusOK, accounts)
}

func (h *Handlers) CreateAccount(c *gin.Context) {
	householdID := c.Param("household_id")
	var account Account
	if err := c.ShouldBindJSON(&account); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if account.Type == "cash" {
		var count int64
		h.db.Model(&Account{}).Where("household_id = ? AND type = ?", householdID, "cash").Count(&count)
		if count > 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot create additional cash accounts"})
			return
		}
	}

	if account.ID == "" {
		account.ID = uuid.New().String()
	}
	account.HouseholdID = householdID
	if err := h.db.Create(&account).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create account"})
		return
	}

	h.populateAccountDisplayName(&account)
	c.JSON(http.StatusCreated, account)
}

func (h *Handlers) UpdateAccount(c *gin.Context) {
	householdID := c.Param("household_id")
	id := c.Param("id")

	var updates Account
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var existing Account
	if err := h.db.First(&existing, "id = ? AND household_id = ?", id, householdID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Account not found"})
		return
	}

	if existing.Type == "cash" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Cannot edit mandatory cash account"})
		return
	}

	// Update fields
	existing.Type = updates.Type
	existing.Name = updates.Name
	existing.Brand = updates.Brand
	existing.Bank = updates.Bank

	if err := h.db.Save(&existing).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update account"})
		return
	}

	h.populateAccountDisplayName(&existing)
	c.JSON(http.StatusOK, existing)
}

func (h *Handlers) createDefaultCashAccount(householdID string) {
	cashAccount := Account{
		ID:          uuid.New().String(),
		HouseholdID: householdID,
		Type:        "cash",
		Name:        "Cash",
	}
	if err := h.db.Create(&cashAccount).Error; err != nil {
		log.Printf("Warning: Failed to create default cash account for household %s: %v", householdID, err)
	}
}

func (h *Handlers) populateAccountDisplayName(a *Account) {
	switch a.Type {
	case "cash":
		a.DisplayName = "Cash"
	case "card":
		brand := ""
		if a.Brand != nil {
			brand = *a.Brand
		}
		bank := ""
		if a.Bank != nil {
			bank = *a.Bank
		}
		if brand != "" && bank != "" {
			a.DisplayName = brand + " - " + bank
		} else if brand != "" {
			a.DisplayName = brand
		} else if bank != "" {
			a.DisplayName = bank
		} else {
			a.DisplayName = "Card"
		}
	case "bank":
		a.DisplayName = a.Name
	default:
		a.DisplayName = a.Name
	}
}

func (h *Handlers) DeleteAccount(c *gin.Context) {
	householdID := c.Param("household_id")
	id := c.Param("id")

	var account Account
	if err := h.db.First(&account, "id = ? AND household_id = ?", id, householdID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Account not found"})
		return
	}

	if account.Type == "cash" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Cannot delete mandatory cash account"})
		return
	}

	if err := h.db.Delete(&account).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete account"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Account deleted"})
}

// ============================================================================
// TRANSACTIONS
// ============================================================================

func (h *Handlers) GetTransactions(c *gin.Context) {
	householdID := c.Param("household_id")
	monthStr := c.Query("month")
	transactions := []Transaction{}

	query := h.db.Preload("User").Where("household_id = ?", householdID).Order("date DESC, created_at DESC")
	if monthStr != "" {
		parsed, err := time.Parse("2006-01", monthStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid month format. Use YYYY-MM"})
			return
		}
		startOfMonth := parsed
		endOfMonth := startOfMonth.AddDate(0, 1, 0)
		query = query.Where("date >= ? AND date < ?", startOfMonth, endOfMonth)
	}

	if err := query.Find(&transactions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch transactions"})
		return
	}

	c.JSON(http.StatusOK, transactions)
}

func (h *Handlers) GetSuggestedNotes(c *gin.Context) {
	householdID := c.Param("household_id")
	categoryID := c.Param("id")

	var notes []string
	err := h.db.Model(&Transaction{}).
		Select("description").
		Where("household_id = ? AND category_id = ? AND description != ''", householdID, categoryID).
		Group("description").
		Order("MAX(created_at) DESC").
		Limit(50).
		Pluck("description", &notes).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch suggested notes"})
		return
	}

	// Remove empty or redundant notes if any (redundant should be handled by DISTINCT)
	c.JSON(http.StatusOK, notes)
}

func (h *Handlers) CreateTransaction(c *gin.Context) {
	householdID := c.Param("household_id")
	var transaction Transaction
	if err := c.ShouldBindJSON(&transaction); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if transaction.ID == "" {
		transaction.ID = uuid.New().String()
	}
	transaction.HouseholdID = householdID
	transaction.Date = transaction.Date.UTC()

	userID, _ := c.Get("user_id")
	if id, ok := userID.(string); ok {
		transaction.UserID = id
	}

	if err := h.db.Create(&transaction).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create transaction"})
		return
	}

	// Preload user for consistent frontend experience
	h.db.Preload("User").First(&transaction, "id = ?", transaction.ID)

	c.JSON(http.StatusCreated, transaction)
}

func (h *Handlers) UpdateTransaction(c *gin.Context) {
	householdID := c.Param("household_id")
	id := c.Param("id")

	var transaction Transaction
	if err := h.db.Where("household_id = ?", householdID).First(&transaction, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Transaction not found"})
		return
	}

	var updates Transaction
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update fields
	transaction.AccountID = updates.AccountID
	transaction.CategoryID = updates.CategoryID
	transaction.Amount = updates.Amount
	transaction.Date = updates.Date.UTC()
	transaction.Description = updates.Description

	if err := h.db.Save(&transaction).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update transaction"})
		return
	}

	// Preload user for consistent frontend experience
	h.db.Preload("User").First(&transaction, "id = ?", transaction.ID)

	c.JSON(http.StatusOK, transaction)
}

func (h *Handlers) DeleteTransaction(c *gin.Context) {
	householdID := c.Param("household_id")
	id := c.Param("id")

	if err := h.db.Where("household_id = ?", householdID).Delete(&Transaction{}, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete transaction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Transaction deleted"})
}

// ============================================================================
// MONTHLY SUMMARY
// ============================================================================

type CategorySummary struct {
	ID        string  `json:"id"`
	Name      string  `json:"name"`
	Budget    float64 `json:"budget"`
	Spent     float64 `json:"spent"`
	Remaining float64 `json:"remaining"`
}

type MonthlySummary struct {
	Month       string            `json:"month"`
	TotalBudget float64           `json:"total_budget"`
	TotalSpent  float64           `json:"total_spent"`
	Categories  []CategorySummary `json:"categories"`
}

func (h *Handlers) GetMonthlySummary(c *gin.Context) {
	householdID := c.Param("household_id")
	monthStr := c.Param("month")
	if monthStr == "" {
		now := time.Now()
		monthStr = now.Format("2006-01")
	}

	parsed, err := time.Parse("2006-01", monthStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid month format. Use YYYY-MM"})
		return
	}

	startOfMonth := parsed
	endOfMonth := startOfMonth.AddDate(0, 1, 0)

	// Get all categories for this household
	var categories []Category
	if err := h.db.Where("household_id = ?", householdID).Find(&categories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}

	// Calculate summary for each category
	var categorySummaries []CategorySummary
	var totalBudget, totalSpent float64

	for _, cat := range categories {
		var spent float64
		h.db.Model(&Transaction{}).
			Where("category_id = ? AND date >= ? AND date < ?", cat.ID, startOfMonth, endOfMonth).
			Select("COALESCE(SUM(amount), 0)").
			Scan(&spent)

		categorySummaries = append(categorySummaries, CategorySummary{
			ID:        cat.ID,
			Name:      cat.Name,
			Budget:    cat.MonthlyBudget,
			Spent:     spent,
			Remaining: cat.MonthlyBudget - spent,
		})

		totalBudget += cat.MonthlyBudget
		totalSpent += spent
	}

	summary := MonthlySummary{
		Month:       monthStr,
		TotalBudget: totalBudget,
		TotalSpent:  totalSpent,
		Categories:  categorySummaries,
	}

	c.JSON(http.StatusOK, summary)
}

func (h *Handlers) GetRecommendations(c *gin.Context) {
	householdID := c.Param("household_id")

	// Default to previous month
	now := time.Now()
	firstOfCurrentMonth := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	startOfPrevMonth := firstOfCurrentMonth.AddDate(0, -1, 0)
	endOfPrevMonth := firstOfCurrentMonth

	// Get all categories for this household
	var categories []Category
	if err := h.db.Where("household_id = ?", householdID).Find(&categories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}

	type Suggestion struct {
		CategoryID string  `json:"category_id"`
		Category   string  `json:"category"`
		Action     string  `json:"action"`
		Amount     float64 `json:"amount"`
	}

	suggestions := []Suggestion{}

	for _, cat := range categories {
		if cat.MonthlyBudget == 0 {
			continue
		}

		var spent float64
		h.db.Model(&Transaction{}).
			Where("category_id = ? AND date >= ? AND date < ?", cat.ID, startOfPrevMonth, endOfPrevMonth).
			Select("COALESCE(SUM(amount), 0)").
			Scan(&spent)

		delta := (spent - cat.MonthlyBudget) / cat.MonthlyBudget
		if delta > 0.1 || delta < -0.1 {
			action := "increase"
			if spent < cat.MonthlyBudget {
				action = "decrease"
			}

			// Round spent to nearest 10
			roundedAmount := math.Round(spent/10) * 10

			suggestions = append(suggestions, Suggestion{
				CategoryID: cat.ID,
				Category:   cat.Name,
				Action:     action,
				Amount:     roundedAmount,
			})
		}
	}

	c.JSON(http.StatusOK, gin.H{"suggestions": suggestions})
}

// ============================================================================
// SYNC (Legacy endpoint - keep for backwards compatibility)
// ============================================================================

func (h *Handlers) HandleSync(c *gin.Context) {
	householdID := c.Param("household_id")
	monthStr := c.Query("month")
	var startOfMonth, endOfMonth time.Time
	now := time.Now()

	if monthStr == "" {
		startOfMonth = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	} else {
		parsed, err := time.Parse("2006-01", monthStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid month format. Use YYYY-MM"})
			return
		}
		startOfMonth = parsed
	}
	endOfMonth = startOfMonth.AddDate(0, 1, 0)

	accounts := []Account{}
	if err := h.db.Where("household_id = ?", householdID).Find(&accounts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch accounts"})
		return
	}

	categories := []Category{}
	if err := h.db.Where("household_id = ?", householdID).Find(&categories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}

	transactions := []Transaction{}
	if err := h.db.Preload("User").Where("household_id = ? AND date >= ? AND date < ?", householdID, startOfMonth, endOfMonth).Order("date DESC, created_at DESC").Find(&transactions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch transactions"})
		return
	}

	for i := range accounts {
		h.populateAccountDisplayName(&accounts[i])
	}

	c.JSON(http.StatusOK, gin.H{
		"accounts":     accounts,
		"categories":   categories,
		"transactions": transactions,
	})
}

func (h *Handlers) JWTMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		// Expected format: "Bearer <token>"
		tokenString := ""
		if len(authHeader) > 7 && authHeader[:7] == "Bearer " {
			tokenString = authHeader[7:]
		} else {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization format"})
			c.Abort()
			return
		}

		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			secret = "default_secret_change_me"
		}

		// Bypass for TEST_MODE
		if os.Getenv("TEST_MODE") == "true" && tokenString == "test-mode-dummy-token" {
			// Use configured test household or default
			householdID := os.Getenv("TEST_HOUSEHOLD_ID")
			if householdID == "" {
				householdID = "test-household-id"
			}

			// Set context with test user details
			c.Set("user_id", "test-user-id")
			c.Set("household_id", householdID)
			c.Next()
			return
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return []byte(secret), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		claims := token.Claims.(jwt.MapClaims)
		tokenHouseholdID := claims["household_id"].(string)
		userID := claims["user_id"].(string)

		// 1. Verify user exists and is active (not soft-deleted)
		var user User
		if err := h.db.First(&user, "id = ?", userID).Error; err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User no longer exists or access revoked"})
			c.Abort()
			return
		}

		// 2. Verify user still belongs to the household in the token
		if user.HouseholdID != tokenHouseholdID {
			c.JSON(http.StatusForbidden, gin.H{"error": "User is no longer a member of this household"})
			c.Abort()
			return
		}

		// 3. Check if the household_id in the URL matches the verified household_id
		urlHouseholdID := c.Param("household_id")
		if urlHouseholdID != "" && urlHouseholdID != tokenHouseholdID {
			c.JSON(http.StatusForbidden, gin.H{"error": "Access denied to this household"})
			c.Abort()
			return
		}

		c.Set("user_id", userID)
		c.Set("household_id", tokenHouseholdID)

		c.Next()
	}
}

// ============================================================================
// AUTHENTICATION
// ============================================================================

type GoogleLoginRequest struct {
	IDToken     string `json:"id_token"`
	AccessToken string `json:"access_token"`
	InviteCode  string `json:"invite_code"`
}

type AuthResponse struct {
	Token       string `json:"token"`
	User        User   `json:"user"`
	HouseholdID string `json:"household_id"`
}

func (h *Handlers) AuthGoogle(c *gin.Context) {
	var req GoogleLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	googleClientID := os.Getenv("GOOGLE_CLIENT_ID")
	if googleClientID == "" {
		log.Println("WARNING: GOOGLE_CLIENT_ID is not set")
	}

	var email, name, googleID, pictureURL string

	if req.IDToken != "" {
		payload, err := idtoken.Validate(c.Request.Context(), req.IDToken, googleClientID)
		if err == nil {
			email = payload.Claims["email"].(string)
			name = payload.Claims["name"].(string)
			googleID = payload.Subject
			if pic, ok := payload.Claims["picture"].(string); ok {
				pictureURL = pic
			}
		}
	}

	// Fallback to AccessToken (common in Web)
	if email == "" && req.AccessToken != "" {
		userInfo, err := h.fetchGoogleUserInfo(req.AccessToken)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid Google access token"})
			return
		}
		email = userInfo.Email
		name = userInfo.Name
		googleID = userInfo.ID
		pictureURL = userInfo.Picture
	}

	if email == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "No valid token provided"})
		return
	}

	var user User
	// Check if user exists (including soft deleted)
	result := h.db.Unscoped().Where("email = ?", email).First(&user)

	if result.Error == gorm.ErrRecordNotFound {
		// Really New User logic (Create Household, etc.)
		householdID := ""

		// Check if there is an invite code
		if req.InviteCode != "" {
			var invitation Invitation
			if err := h.db.Where("code = ? AND status = ?", req.InviteCode, "pending").First(&invitation).Error; err == nil {
				householdID = invitation.HouseholdID
				// Mark invitation as accepted
				invitation.Status = "accepted"
				h.db.Save(&invitation)
			}
		}

		if householdID == "" {
			// Create new household if no valid invite code
			household := Household{
				ID:   uuid.New().String(),
				Name: name + "'s Household",
			}

			if err := h.db.Create(&household).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create household"})
				return
			}
			householdID = household.ID
			h.createDefaultCashAccount(householdID)
		}

		user = User{
			ID:          uuid.New().String(),
			Email:       email,
			Name:        name,
			GoogleID:    googleID,
			PictureURL:  pictureURL,
			Color:       getRandomColor(),
			HouseholdID: householdID,
		}

		if err := h.db.Create(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
			return
		}
	} else if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	} else {
		// User found (might be deleted)
		if user.DeletedAt.Valid {
			c.JSON(http.StatusForbidden, gin.H{"error": "User account has been deleted. Contact support to restore."})
			return
		}
		// Update user info if it changed
		needsUpdate := false
		if user.Name != name {
			user.Name = name
			needsUpdate = true
		}
		if user.PictureURL != pictureURL && pictureURL != "" {
			user.PictureURL = pictureURL
			needsUpdate = true
		}
		if user.Color == "" {
			user.Color = getRandomColor()
			needsUpdate = true
		}
		if needsUpdate {
			h.db.Save(&user)
		}
	}

	// Generate JWT
	token, err := h.generateJWT(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, AuthResponse{
		Token:       token,
		User:        user,
		HouseholdID: user.HouseholdID,
	})
}

func (h *Handlers) generateJWT(user User) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "default_secret_change_me"
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":      user.ID,
		"household_id": user.HouseholdID,
		"exp":          time.Now().Add(time.Hour * 24 * 30).Unix(), // 30 days
	})

	return token.SignedString([]byte(secret))
}

type GoogleUserInfo struct {
	ID      string `json:"id"`
	Email   string `json:"email"`
	Name    string `json:"name"`
	Picture string `json:"picture"`
}

func (h *Handlers) fetchGoogleUserInfo(accessToken string) (*GoogleUserInfo, error) {
	resp, err := http.Get(h.googleAPIURL + "?access_token=" + accessToken)
	if err != nil {
		return nil, err
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch user info: %v", resp.Status)
	}

	var userInfo GoogleUserInfo
	if err := json.NewDecoder(resp.Body).Decode(&userInfo); err != nil {
		return nil, err
	}

	return &userInfo, nil
}
