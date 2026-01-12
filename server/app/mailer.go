package app

import (
	"fmt"
	"net/smtp"
	"os"
)

func (h *Handlers) SendInvitationEmail(to, code string) error {
	host := os.Getenv("SMTP_HOST")
	port := os.Getenv("SMTP_PORT")
	user := os.Getenv("SMTP_USER")
	pass := os.Getenv("SMTP_PASS")
	from := os.Getenv("SMTP_FROM")
	appURL := os.Getenv("APP_URL")

	if from == "" {
		from = "noreply@family-finance.local"
	}

	subject := "Te han invitado a unirte a un hogar en Family Finance"
	body := fmt.Sprintf("Hola!\n\nTe han invitado a compartir los gastos de un hogar en Family Finance.\n\nPara unirte, haz click en el siguiente enlace o usa el código de invitación al loguearte: %s\n\nLink: %s/invite?code=%s\n\n¡Te esperamos!", code, appURL, code)

	message := []byte(fmt.Sprintf("To: %s\r\n"+
		"Subject: %s\r\n"+
		"\r\n"+
		"%s\r\n", to, subject, body))

	auth := smtp.PlainAuth("", user, pass, host)

	if user == "" && pass == "" {
		auth = nil // For local development with Mailpit if no auth is set
	}

	addr := fmt.Sprintf("%s:%s", host, port)
	err := smtp.SendMail(addr, auth, from, []string{to}, message)
	if err != nil {
		return fmt.Errorf("failed to send email: %v", err)
	}

	return nil
}
