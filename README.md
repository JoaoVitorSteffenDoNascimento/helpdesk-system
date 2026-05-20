# Help Desk System

A beginner-friendly full-stack Help Desk system built with Java 21, Spring Boot, Spring Cloud Gateway, MongoDB, React, Vite, Axios, Docker, and Docker Compose.

## Project Structure

```text
helpdesk-system/
  api-gateway/
  ticket-service/
  user-service/
  frontend/
  docker-compose.yml
```

## Services

| Service | Port | Description |
| --- | --- | --- |
| API Gateway | 8080 | Routes browser requests to backend services |
| Ticket Service | 8081 | Manages tickets, statuses, and comments |
| User Service | 8082 | Manages help desk users |
| Frontend | 5173 | React/Vite application |
| MongoDB | 27017 | Database for both backend services |

## API Gateway Routes

- `http://localhost:8080/tickets/**` routes to `ticket-service`
- `http://localhost:8080/users/**` routes to `user-service`

The frontend is configured to communicate only with `http://localhost:8080`.

## Run With Docker

From this folder:

```bash
docker compose up --build
```

Then open:

```text
http://localhost:5173
```

## Deploy To Azure Container Apps

This project includes a deployment script for Azure Container Apps. It does not require your local Docker Desktop daemon, because image builds run in Azure Container Registry.

Prerequisites:

- Azure CLI installed
- `az login` completed
- Active subscription selected

Run:

```powershell
cd "C:\Users\João Vitor Steffen\Downloads\helpdesk-system"
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-azure-container-apps.ps1
```

The script creates:

- Resource group: `rg-helpdesk-system`
- Azure Container Registry
- Azure Cosmos DB for MongoDB with free tier enabled
- Azure Container Apps environment
- Container apps for gateway, ticket service, user service, and frontend

To delete the Azure resources:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\delete-azure-resources.ps1
```

## Run Without Docker Or Installed Maven

You can run the project without installing Maven globally. The scripts in `scripts/` download a portable Maven copy into `.tools/` and use it only for this project.

You still need:

- Java 21 or newer
- Node.js/npm
- MongoDB running locally, a MongoDB Atlas connection string, or the portable MongoDB started by these scripts

### Option A: Local MongoDB

Run:

```powershell
cd "C:\Users\João Vitor Steffen\Downloads\helpdesk-system"
powershell -ExecutionPolicy Bypass -File .\scripts\run-all-local.ps1
```

If MongoDB is not already running on `mongodb://localhost:27017`, the script downloads and starts a portable MongoDB Server inside `.tools/`.

Open:

```text
http://localhost:5173
```

### Option B: MongoDB Atlas

Pass your MongoDB connection string:

```powershell
cd "C:\Users\João Vitor Steffen\Downloads\helpdesk-system"
powershell -ExecutionPolicy Bypass -File .\scripts\run-all-local.ps1 -MongoUri "mongodb+srv://USER:PASSWORD@CLUSTER.mongodb.net"
```

### Run Services One By One

In separate PowerShell terminals:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-service.ps1 -Service ticket-service
powershell -ExecutionPolicy Bypass -File .\scripts\run-service.ps1 -Service user-service
powershell -ExecutionPolicy Bypass -File .\scripts\run-service.ps1 -Service api-gateway
powershell -ExecutionPolicy Bypass -File .\scripts\run-frontend.ps1
```

To start only the portable MongoDB Server:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-mongodb.ps1
```

Keep the PowerShell window open while the services are running. Press `Ctrl+C` in that window to stop the local stack.

## Useful API Examples

Create a user:

```bash
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alex Johnson","email":"alex@example.com","role":"CUSTOMER"}'
```

Create a ticket:

```bash
curl -X POST http://localhost:8080/tickets \
  -H "Content-Type: application/json" \
  -d '{"title":"Cannot access account","description":"Password reset does not work.","priority":"HIGH","userId":"USER_ID_HERE"}'
```

Update ticket status:

```bash
curl -X PATCH http://localhost:8080/tickets/TICKET_ID_HERE/status \
  -H "Content-Type: application/json" \
  -d '{"status":"IN_PROGRESS"}'
```

Add a comment:

```bash
curl -X POST http://localhost:8080/tickets/TICKET_ID_HERE/comments \
  -H "Content-Type: application/json" \
  -d '{"author":"Support Agent","message":"We are checking this now."}'
```
