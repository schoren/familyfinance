package app

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestEncryption(t *testing.T) {
	testKey := "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	os.Setenv("ENCRYPTION_KEY", testKey)
	defer os.Unsetenv("ENCRYPTION_KEY")

	plainText := "Hola Keda!"

	// Test Encrypt
	encrypted, err := Encrypt(plainText)
	assert.NoError(t, err)
	assert.Contains(t, encrypted, "enc:")
	assert.NotEqual(t, plainText, encrypted)

	// Test Decrypt
	decrypted, err := Decrypt(encrypted)
	assert.NoError(t, err)
	assert.Equal(t, plainText, decrypted)

	// Test non-encrypted input
	plain, err := Decrypt("not encrypted")
	assert.NoError(t, err)
	assert.Equal(t, "not encrypted", plain)
}

func TestEncryptionDeterministic(t *testing.T) {
	testKey := "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	os.Setenv("ENCRYPTION_KEY", testKey)
	defer os.Unsetenv("ENCRYPTION_KEY")

	plainText := "Same content"

	enc1, _ := Encrypt(plainText)
	enc2, _ := Encrypt(plainText)

	// IVs must be different for every encryption call
	assert.NotEqual(t, enc1, enc2)

	dec1, _ := Decrypt(enc1)
	dec2, _ := Decrypt(enc2)
	assert.Equal(t, plainText, dec1)
	assert.Equal(t, plainText, dec2)
}

func TestHashSensitive(t *testing.T) {
	testKey := "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	os.Setenv("ENCRYPTION_KEY", testKey)
	defer os.Unsetenv("ENCRYPTION_KEY")

	email := "Test@Example.Com "
	hash1 := HashSensitive(email)
	hash2 := HashSensitive("test@example.com")

	assert.NotEmpty(t, hash1)
	assert.Equal(t, hash1, hash2) // Should be case-insensitive and trimmed
}
