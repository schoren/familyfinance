package app

import (
	"time"

	"gorm.io/gorm"
)

var Entities = []any{
	&Household{},
	&User{},
	&Account{},
	&Category{},
	&Transaction{},
	&Invitation{},
}

type Household struct {
	ID        string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	Name      string         `gorm:"type:varchar(255)" json:"name"`
}

type User struct {
	ID          string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
	Email       string         `gorm:"type:varchar(255);unique" json:"email"`
	GoogleID    string         `gorm:"type:varchar(255);index" json:"google_id"`
	Name        string         `gorm:"type:varchar(255)" json:"name"`
	PictureURL  string         `gorm:"type:text" json:"picture_url"`
	Color       string         `gorm:"type:varchar(7)" json:"color"`
	HouseholdID string         `gorm:"type:varchar(255)" json:"household_id"`
}

type Account struct {
	ID          string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
	Type        string         `gorm:"type:varchar(255)" json:"type"`
	Name        string         `gorm:"type:varchar(255)" json:"name"`
	Brand       *string        `gorm:"type:varchar(255)" json:"brand,omitempty"`
	Bank        *string        `gorm:"type:varchar(255)" json:"bank,omitempty"`
	DisplayName string         `gorm:"-" json:"display_name"`
	HouseholdID string         `gorm:"type:varchar(255)" json:"household_id"`
}

type Category struct {
	ID            string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"-"`
	Name          string         `gorm:"type:varchar(255)" json:"name"`
	MonthlyBudget float64        `gorm:"type:decimal(10,2)" json:"monthly_budget"`
	IsActive      bool           `gorm:"type:boolean;default:true" json:"is_active"`
	HouseholdID   string         `gorm:"type:varchar(255)" json:"household_id"`
}

type Transaction struct {
	ID                    string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt             time.Time      `json:"created_at"`
	UpdatedAt             time.Time      `json:"updated_at"`
	DeletedAt             gorm.DeletedAt `gorm:"index" json:"-"`
	AccountID             string         `gorm:"type:varchar(255)" json:"account_id"`
	CategoryID            string         `gorm:"type:varchar(255)" json:"category_id"`
	UserID                string         `gorm:"type:varchar(255)" json:"user_id"`
	User                  User           `gorm:"foreignKey:UserID" json:"user"`
	Amount                float64        `gorm:"type:decimal(10,2)" json:"amount"`
	Date                  time.Time      `gorm:"type:timestamp" json:"date"`
	Description           string         `gorm:"type:varchar(255)" json:"note"`
	HouseholdID           string         `gorm:"type:varchar(255)" json:"household_id"`
	ReplacedTransactionID *string        `gorm:"type:varchar(255)" json:"-"`
}

type Invitation struct {
	ID          string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
	Code        string         `gorm:"type:varchar(255);unique;index" json:"code"`
	Email       string         `gorm:"type:varchar(255)" json:"email"`
	HouseholdID string         `gorm:"type:varchar(255)" json:"household_id"`
	Status      string         `gorm:"type:varchar(50);default:'pending'" json:"status"` // pending, accepted, expired
}
