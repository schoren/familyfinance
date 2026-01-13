# Family Finance

A simple application to manage family finances, allowing expense tracking by categories and collaboration between household members.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Getting Started (Docker Compose)

The fastest way to run the project is using Docker Compose. This will spin up both the server and the client, as well as a PostgreSQL database and a mail server for testing (Mailpit).

### 1. Configure Environment Variables

First, copy the `.env.example` file to `.env`:

```bash
cp .env.example .env
```

Then, edit the `.env` file with your settings. It is important to configure at least the `JWT_SECRET` and Google credentials if you wish to use Google authentication.

### 2. Run with Docker Compose

From the root of the project, run:

```bash
docker-compose up -d --build
```

### 3. Access the Application

Once the containers are running:

- **Frontend (Web):** [http://localhost:8080](http://localhost:8080)
- **Backend (API):** [http://localhost:8090](http://localhost:8090)
- **Mailpit (Mail Interface):** [http://localhost:8025](http://localhost:8025)

## Local Development

If you prefer to run the services independently for development:

### Backend
The server is developed in Go. You can find more details in the `/server` directory.

### Frontend
The client is a Flutter application. You can find more details in the `/client` directory.

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for more details.
