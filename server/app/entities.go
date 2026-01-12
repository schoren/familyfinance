package app

import (
	"time"

	"gorm.io/gorm"
)

var Entities = []any{
	&Account{},
	&Category{},
	&Transaction{},
}

type Account struct {
	gorm.Model
	Type  string `gorm:"type:varchar(255)" json:"type"`
	Name  string `gorm:"type:varchar(255)" json:"name"`
	Brand string `gorm:"type:varchar(255)" json:"brand"`
	Card  string `gorm:"type:varchar(255)" json:"card"`
}

type Category struct {
	gorm.Model
	Name          string  `gorm:"type:varchar(255)" json:"name"`
	MonthlyBudget float64 `gorm:"type:decimal(10,2)" json:"monthly_budget"`
	IsActive      bool    `gorm:"type:boolean" json:"is_active"`
}

type Transaction struct {
	gorm.Model
	AccountID   uint      `gorm:"type:integer" json:"account_id"`
	CategoryID  uint      `gorm:"type:integer" json:"category_id"`
	Amount      float64   `gorm:"type:decimal(10,2)" json:"amount"`
	Date        time.Time `gorm:"type:timestamp" json:"date"`
	Description string    `gorm:"type:varchar(255)" json:"description"`
}
