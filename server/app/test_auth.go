package app

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// TestLogin is a test-only endpoint that creates/authenticates users without Google OAuth
// Only enabled when TEST_MODE environment variable is set to "true"
func (h *Handlers) TestLogin(c *gin.Context) {
	// Double-check TEST_MODE is enabled
	if os.Getenv("TEST_MODE") != "true" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Test login only available in test mode"})
		return
	}

	var req struct {
		Email      string `json:"email" binding:"required"`
		Name       string `json:"name" binding:"required"`
		InviteCode string `json:"invite_code"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if user already exists
	var user User
	result := h.db.Where("email = ?", req.Email).First(&user)

	if result.Error == nil {
		// User exists, generate token and return
		token, err := h.generateJWT(user)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"token":        token,
			"user":         user,
			"household_id": user.HouseholdID,
		})
		return
	}

	// User doesn't exist, create new user
	var householdID string

	// Check for invitation code
	if req.InviteCode != "" {
		var invitation Invitation
		if err := h.db.Where("code = ? AND status = ?", req.InviteCode, "pending").First(&invitation).Error; err == nil {
			householdID = invitation.HouseholdID
			invitation.Status = "accepted"
			h.db.Save(&invitation)
		}
	}

	// If no invitation or invitation not found, create new household
	if householdID == "" {
		household := Household{
			ID:   uuid.New().String(),
			Name: req.Name + "'s Household",
		}
		if err := h.db.Create(&household).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create household"})
			return
		}
		householdID = household.ID
		h.createDefaultCashAccount(householdID)
	}

	// Create new user
	newUser := User{
		ID:          uuid.New().String(),
		Email:       req.Email,
		Name:        req.Name,
		HouseholdID: householdID,
	}

	if err := h.db.Create(&newUser).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	// Generate JWT token
	token, err := h.generateJWT(newUser)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token":        token,
		"user":         newUser,
		"household_id": newUser.HouseholdID,
	})
}
