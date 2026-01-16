package app

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestMandatoryCashAccountRules(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB()
	h := NewHandlers(db)
	householdID := "test-hh"

	r := gin.Default()
	r.POST("/households", h.CreateHousehold)
	r.POST("/households/:household_id/accounts", h.CreateAccount)
	r.PUT("/households/:household_id/accounts/:id", h.UpdateAccount)
	r.DELETE("/households/:household_id/accounts/:id", h.DeleteAccount)
	r.GET("/households/:household_id/accounts", h.GetAccounts)

	// 1. Verify Household creation auto-creates a cash account
	newHH := Household{ID: householdID, Name: "Test Family"}
	body, _ := json.Marshal(newHH)
	req, _ := http.NewRequest("POST", "/households", bytes.NewBuffer(body))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusCreated, w.Code)

	req, _ = http.NewRequest("GET", "/households/"+householdID+"/accounts", nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	var accounts []Account
	json.Unmarshal(w.Body.Bytes(), &accounts)
	assert.Len(t, accounts, 1)
	assert.Equal(t, "cash", accounts[0].Type)
	assert.Equal(t, "Cash", accounts[0].Name)
	cashAccountID := accounts[0].ID

	// 2. Verify we cannot create another cash account
	anotherCash := Account{Name: "Another Cash", Type: "cash"}
	body, _ = json.Marshal(anotherCash)
	req, _ = http.NewRequest("POST", "/households/"+householdID+"/accounts", bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// 3. Verify we cannot edit the cash account
	updateAcc := Account{Name: "New Name", Type: "bank"}
	body, _ = json.Marshal(updateAcc)
	req, _ = http.NewRequest("PUT", "/households/"+householdID+"/accounts/"+cashAccountID, bytes.NewBuffer(body))
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusForbidden, w.Code)

	// 4. Verify we cannot delete the cash account
	req, _ = http.NewRequest("DELETE", "/households/"+householdID+"/accounts/"+cashAccountID, nil)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusForbidden, w.Code)
}
