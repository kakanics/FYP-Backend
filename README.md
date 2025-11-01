# Flask Microservices with Hexagonal Architecture

This project provides a comprehensive framework for building Flask microservices using hexagonal architecture principles. It includes a command-line tool for generating services, shared components, and database management utilities.

## Features

- **Service Generator**: Automated creation of Flask services with hexagonal architecture
- **Shared Components**: Common models, utilities, and configuration across all services
- **Database Management**: Centralized database migration and management system
- **Hexagonal Architecture**: Clean separation of concerns with domain, application, and infrastructure layers

## Project Structure

```
Backend/
├── createService.sh          # Service generator script
├── manage_db.sh             # Database management utility
├── demo.sh                  # Demo script
├── shared/                  # Shared components
│   ├── models/             # Shared database models
│   │   ├── base.py        # Base model with common fields
│   │   └── user.py        # Example user model
│   ├── utils/             # Shared utilities
│   │   └── response.py    # API response formatter
│   └── config.py          # Shared configuration
├── db_manager/             # Database migration utilities
│   ├── manager.py         # Database manager class
│   └── cli.py             # Migration CLI tool
├── services/              # Individual microservices
│   └── <service_name>/    # Generated services
└── docker-compose.yml     # Global PostgreSQL setup
```

### Generated Service Structure (Hexagonal Architecture)

Each service follows this structure:

```
services/<service_name>/
├── app.py                    # Main Flask application
├── requirements.txt          # Service dependencies
├── .env                     # Environment variables
├── Dockerfile               # Docker configuration
├── docker-compose.yml       # Service-specific compose
├── domain/                  # Domain layer (business logic)
│   ├── entities/           # Domain entities
│   ├── repositories/       # Repository interfaces
│   └── services/           # Domain services
├── application/            # Application layer
│   ├── dto/               # Data Transfer Objects
│   ├── ports/             # Application ports
│   └── use_cases/         # Use cases (application services)
└── infrastructure/        # Infrastructure layer
    ├── adapters/          # Infrastructure adapters
    ├── database/          # Database configuration
    └── web/               # Web controllers
```

## Quick Start

### Prerequisites

- Python 3.11+
- MySQL 
- Docker
- Git

### 1. Creating a Service

```bash
./createService.sh <name> <port>
```

Run database migrations:

```bash
./manage_db.sh migrate
```

### 4. Test Services

```bash
# Health check
curl http://localhost:8081/api/v1/health

# Service info
curl http://localhost:8081/api/v1/

```

### Dependency Flow

```
Infrastructure → Application → Domain
```

- Domain layer has no dependencies
- Application layer depends only on domain
- Infrastructure layer implements domain interfaces

### Shared Configuration

Global settings in `shared/config.py`:

## API Documentation

### Standard Endpoints

Every service includes:

- `GET /api/v1/health` - Health check
- `GET /api/v1/` - Service information

### Response Format

```json
{
  "success": true,
  "message": "Success",
  "data": { ... }
}
```

Error responses:

```json
{
  "success": false,
  "message": "Error description",
  "errors": { ... }
}
```

### Debugging

Enable debug mode in `.env`:
```bash
DEBUG=True
```