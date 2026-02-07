package app

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestMigrateToEncryptionWithFakes(t *testing.T) {
	// 1. Setup
	testKey := "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	_, err := SetupEncryption(testKey)
	require.NoError(t, err)

	// Use SQLite in-memory
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	// Enable foreign keys in SQLite
	db.Exec("PRAGMA foreign_keys = ON")

	// Migrate schema
	err = db.AutoMigrate(Entities...)
	require.NoError(t, err)

	// 2. Seed data that would normally fail
	householdID := uuid.New().String()
	db.Create(&Household{ID: householdID, Name: "Test Household"})

	categoryID := uuid.New().String()
	db.Create(&Category{ID: categoryID, HouseholdID: householdID, Name: "Test Category"})

	accountID := uuid.New().String()
	db.Create(&Account{ID: accountID, HouseholdID: householdID, Name: "Test Account", Type: "bank"})

	txID := uuid.New().String()

	// Disable FKs temporarily to insert the "invalid" state (empty user_id)
	db.Exec("PRAGMA foreign_keys = OFF")
	db.Exec("INSERT INTO transactions (id, created_at, updated_at, account_id, category_id, user_id, amount, date, description, description_hash, household_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
		txID, time.Now(), time.Now(), accountID, categoryID, "", 59600.0, time.Now(), "Initial Note", "", householdID)

	// Re-enable FKs. Now any UPDATE that touches user_id='' will fail.
	db.Exec("PRAGMA foreign_keys = ON")

	// 3. Run migration
	err = MigrateToEncryption(db)

	// If the migration uses selective updates, it should NOT try to update user_id='',
	// and thus should not trigger a FK violation.
	assert.NoError(t, err)

	// 4. Verify encryption occurred for description
	var migratedTx Transaction
	err = db.First(&migratedTx, "id = ?", txID).Error
	require.NoError(t, err)

	// The database should now have "enc:..." in the description column (if we read it raw)
	var rawDescription string
	db.Raw("SELECT description FROM transactions WHERE id = ?", txID).Scan(&rawDescription)
	assert.Contains(t, rawDescription, "enc:")

	// GORM should decrypt it automatically via SecretString Scan
	assert.Equal(t, "Initial Note", string(migratedTx.Description))
	assert.NotEmpty(t, migratedTx.DescriptionHash)
}
