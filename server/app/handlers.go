package app

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"google.golang.org/api/idtoken"
	"gorm.io/gorm"
)

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

func (h *Handlers) GetMembers(c *gin.Context) {
	householdID := c.Param("household_id")
	var users []User
	if err := h.db.Where("household_id = ?", householdID).Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch members"})
		return
	}
	c.JSON(http.StatusOK, users)
}

func (h *Handlers) RemoveMember(c *gin.Context) {
	householdID := c.Param("household_id")
	userID := c.Param("user_id")

	// Verify user belongs to household
	var user User
	if err := h.db.Where("id = ? AND household_id = ?", userID, householdID).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Member not found"})
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

	var account Account
	if err := h.db.Where("household_id = ?", householdID).First(&account, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Account not found"})
		return
	}

	var updates Account
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update fields
	account.Type = updates.Type
	account.Name = updates.Name
	account.Brand = updates.Brand
	account.Bank = updates.Bank

	if err := h.db.Save(&account).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update account"})
		return
	}

	h.populateAccountDisplayName(&account)
	c.JSON(http.StatusOK, account)
}

func (h *Handlers) populateAccountDisplayName(a *Account) {
	switch a.Type {
	case "cash":
		a.DisplayName = "Efectivo"
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
			a.DisplayName = "Tarjeta"
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

	if err := h.db.Where("household_id = ?", householdID).Delete(&Account{}, "id = ?", id).Error; err != nil {
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

	query := h.db.Where("household_id = ?", householdID)
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

func (h *Handlers) CreateTransaction(c *gin.Context) {
	householdID := c.Param("household_id")
	var transaction Transaction
	if err := c.ShouldBindJSON(&transaction); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	transaction.HouseholdID = householdID
	if err := h.db.Create(&transaction).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create transaction"})
		return
	}

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
	transaction.Date = updates.Date
	transaction.Description = updates.Description

	if err := h.db.Save(&transaction).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update transaction"})
		return
	}

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
	if err := h.db.Where("household_id = ? AND date >= ? AND date < ?", householdID, startOfMonth, endOfMonth).Find(&transactions).Error; err != nil {
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

		// Check if the household_id in the URL matches the one in the token
		urlHouseholdID := c.Param("household_id")
		if urlHouseholdID != "" && urlHouseholdID != tokenHouseholdID {
			c.JSON(http.StatusForbidden, gin.H{"error": "Access denied to this household"})
			c.Abort()
			return
		}

		c.Set("user_id", claims["user_id"])
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

	var email, name, googleID string

	if req.IDToken != "" {
		payload, err := idtoken.Validate(c.Request.Context(), req.IDToken, googleClientID)
		if err == nil {
			email = payload.Claims["email"].(string)
			name = payload.Claims["name"].(string)
			googleID = payload.Subject
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
		}

		user = User{
			ID:          uuid.New().String(),
			Email:       email,
			Name:        name,
			GoogleID:    googleID,
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
	ID    string `json:"id"`
	Email string `json:"email"`
	Name  string `json:"name"`
}

func (h *Handlers) fetchGoogleUserInfo(accessToken string) (*GoogleUserInfo, error) {
	resp, err := http.Get(h.googleAPIURL + "?access_token=" + accessToken)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch user info: %v", resp.Status)
	}

	var userInfo GoogleUserInfo
	if err := json.NewDecoder(resp.Body).Decode(&userInfo); err != nil {
		return nil, err
	}

	return &userInfo, nil
}
