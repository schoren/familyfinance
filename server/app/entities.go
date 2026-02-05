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
	Name      SecretString   `gorm:"type:text" json:"name"`
}

type User struct {
	ID        string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	Email     SecretString   `gorm:"type:text" json:"email"`
	// EmailHash stores a salted HMAC-SHA256 hash of the email.
	// This allows for searchable lookups (e.g. login) without exposing the plaintext email in database indexes.
	EmailHash   string       `gorm:"type:varchar(255);unique;index" json:"-"`
	GoogleID    string       `gorm:"type:varchar(255);index" json:"google_id"`
	Name        SecretString `gorm:"type:text" json:"name"`
	PictureURL  string       `gorm:"type:text" json:"picture_url"`
	Color       string       `gorm:"type:varchar(7)" json:"color"`
	HouseholdID string       `gorm:"type:varchar(255)" json:"household_id"`
}

func (u *User) BeforeSave(tx *gorm.DB) error {
	u.EmailHash = HashSensitive(string(u.Email))
	return nil
}

type Account struct {
	ID          string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
	Type        string         `gorm:"type:varchar(255)" json:"type"`
	Name        SecretString   `gorm:"type:text" json:"name"`
	Brand       *SecretString  `gorm:"type:text" json:"brand,omitempty"`
	Bank        *SecretString  `gorm:"type:text" json:"bank,omitempty"`
	DisplayName string         `gorm:"-" json:"display_name"`
	HouseholdID string         `gorm:"type:varchar(255)" json:"household_id"`
}

type Category struct {
	ID            string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"-"`
	Name          SecretString   `gorm:"type:text" json:"name"`
	MonthlyBudget float64        `gorm:"type:decimal(10,2)" json:"monthly_budget"`
	IsActive      bool           `gorm:"type:boolean;default:true" json:"is_active"`
	HouseholdID   string         `gorm:"type:varchar(255)" json:"household_id"`
}

type Transaction struct {
	ID          string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
	AccountID   string         `gorm:"type:varchar(255)" json:"account_id"`
	CategoryID  string         `gorm:"type:varchar(255)" json:"category_id"`
	UserID      string         `gorm:"type:varchar(255)" json:"user_id"`
	User        *User          `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Amount      float64        `gorm:"type:decimal(10,2)" json:"amount"`
	Date        time.Time      `gorm:"type:timestamp" json:"date"`
	Description SecretString   `gorm:"type:text" json:"note"`
	// DescriptionHash stores a salted HMAC-SHA256 hash of the description.
	// This allows for efficient grouping and suggested notes in the database
	// while maintaining encryption at rest for the actual description content.
	DescriptionHash       string  `gorm:"type:varchar(255);index" json:"-"`
	HouseholdID           string  `gorm:"type:varchar(255)" json:"household_id"`
	ReplacedTransactionID *string `gorm:"type:varchar(255)" json:"-"`
}

func (t *Transaction) BeforeSave(tx *gorm.DB) error {
	t.DescriptionHash = HashSensitive(string(t.Description))
	return nil
}

type Invitation struct {
	ID        string         `gorm:"type:varchar(255);primaryKey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	Code      string         `gorm:"type:varchar(255);unique;index" json:"code"`
	Email     SecretString   `gorm:"type:text" json:"email"`
	// EmailHash stores a salted HMAC-SHA256 hash of the email.
	// This allows for searchable lookups without exposing the plaintext email in database indexes.
	EmailHash   string `gorm:"type:varchar(255);index" json:"-"`
	HouseholdID string `gorm:"type:varchar(255)" json:"household_id"`
	Status      string `gorm:"type:varchar(50);default:'pending'" json:"status"` // pending, accepted, expired
}

func (i *Invitation) BeforeSave(tx *gorm.DB) error {
	i.EmailHash = HashSensitive(string(i.Email))
	return nil
}
