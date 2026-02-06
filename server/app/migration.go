package app

import (
	"log"

	"gorm.io/gorm"
)

// MigrateToEncryption handles encrypting existing plain-text data in the database.
func MigrateToEncryption(db *gorm.DB) error {
	log.Println("🔍 Checking for data migration to encryption...")

	// 1. Household names
	var households []Household
	db.Find(&households)
	for _, h := range households {
		// Just saving will trigger the Value() method of SecretString
		// We use Select to only update the encrypted fields and UpdatedAt
		if err := db.Select("Name", "UpdatedAt").Save(&h).Error; err != nil {
			return err
		}
	}

	// 2. User data
	var users []User
	db.Find(&users)
	for _, u := range users {
		if err := db.Select("Email", "EmailHash", "Name", "UpdatedAt").Save(&u).Error; err != nil {
			return err
		}
	}

	// 3. Accounts
	var accounts []Account
	db.Find(&accounts)
	for _, a := range accounts {
		if err := db.Select("Name", "Brand", "Bank", "UpdatedAt").Save(&a).Error; err != nil {
			return err
		}
	}

	// 4. Categories
	var categories []Category
	db.Find(&categories)
	for _, c := range categories {
		if err := db.Select("Name", "UpdatedAt").Save(&c).Error; err != nil {
			return err
		}
	}

	// 5. Transactions
	var transactions []Transaction
	db.Find(&transactions)
	for _, t := range transactions {
		if err := db.Select("Description", "DescriptionHash", "UpdatedAt").Save(&t).Error; err != nil {
			return err
		}
	}

	// 6. Invitations
	var invitations []Invitation
	db.Find(&invitations)
	for _, i := range invitations {
		if err := db.Select("Email", "EmailHash", "UpdatedAt").Save(&i).Error; err != nil {
			return err
		}
	}

	log.Println("✅ Encryption migration check completed")
	return nil
}
