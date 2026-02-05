package app

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"database/sql/driver"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"strings"
)

// Encryption prefix to identify encrypted data
const encryptionPrefix = "enc:"

// GetEncryptionKey returns the encryption key from environment variables.
// It must be a 32-byte hex string (for AES-256).
func GetEncryptionKey() ([]byte, error) {
	keyHex := os.Getenv("ENCRYPTION_KEY")
	if keyHex == "" {
		return nil, fmt.Errorf("ENCRYPTION_KEY environment variable is not set")
	}
	key, err := hex.DecodeString(keyHex)
	if err != nil {
		return nil, fmt.Errorf("ENCRYPTION_KEY must be a valid hex string: %v", err)
	}
	if len(key) != 32 {
		return nil, fmt.Errorf("ENCRYPTION_KEY must be 32 bytes (64 hex characters) for AES-256")
	}
	return key, nil
}

// Encrypt encrypts plain text using AES-GCM and returns a string with "enc:<iv>:<ciphertext>" format.
func Encrypt(plainText string) (string, error) {
	if plainText == "" {
		return "", nil
	}

	key, err := GetEncryptionKey()
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	ciphertext := gcm.Seal(nil, nonce, []byte(plainText), nil)

	return fmt.Sprintf("%s%s:%s", encryptionPrefix, hex.EncodeToString(nonce), hex.EncodeToString(ciphertext)), nil
}

// Decrypt decrypts text in the format "enc:<iv>:<ciphertext>". If it doesn't have the prefix, it returns as is.
func Decrypt(input string) (string, error) {
	if !strings.HasPrefix(input, encryptionPrefix) {
		return input, nil
	}

	parts := strings.Split(input[len(encryptionPrefix):], ":")
	if len(parts) != 2 {
		return "", fmt.Errorf("invalid encrypted data format")
	}

	nonce, err := hex.DecodeString(parts[0])
	if err != nil {
		return "", fmt.Errorf("invalid nonce: %v", err)
	}

	ciphertext, err := hex.DecodeString(parts[1])
	if err != nil {
		return "", fmt.Errorf("invalid ciphertext: %v", err)
	}

	key, err := GetEncryptionKey()
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	plainText, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", fmt.Errorf("decryption failed: %v", err)
	}

	return string(plainText), nil
}

// HashSensitive returns a salted HMAC-SHA256 hash of a sensitive string for searchable lookups or grouping.
func HashSensitive(input string) string {
	if input == "" {
		return ""
	}
	input = strings.TrimSpace(input)
	input = strings.ToLower(input)
	key, _ := GetEncryptionKey()
	h := hmac.New(sha256.New, key)
	h.Write([]byte(input))
	return hex.EncodeToString(h.Sum(nil))
}

// SecretString is a custom GORM type that automatically encrypts/decrypts data.
type SecretString string

// Scan implements the sql.Scanner interface for GORM.
func (s *SecretString) Scan(value interface{}) error {
	if value == nil {
		*s = ""
		return nil
	}

	str, ok := value.(string)
	if !ok {
		return fmt.Errorf("failed to scan SecretString: value is not a string")
	}

	decrypted, err := Decrypt(str)
	if err != nil {
		return err
	}

	*s = SecretString(decrypted)
	return nil
}

// Value implements the driver.Valuer interface for GORM.
func (s SecretString) Value() (driver.Value, error) {
	if s == "" {
		return "", nil
	}

	encrypted, err := Encrypt(string(s))
	if err != nil {
		return nil, err
	}

	return encrypted, nil
}
