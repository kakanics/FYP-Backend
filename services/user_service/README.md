# user-service

A Flask microservice built with hexagonal architecture.

## Architecture

This service follows the hexagonal architecture pattern with the following structure:

- **Domain**: Core business logic and entities
- **Application**: Use cases and DTOs
- **Infrastructure**: External adapters (database, web, etc.)

## Getting Started

### Prerequisites

- Python 3.11+
- PostgreSQL
- Docker (optional)

### Installation

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. Initialize database:
   ```bash
   python ../../db_manager/cli.py migrate
   ```

4. Run the service:
   ```bash
   python app.py
   ```

The service will be available at `http://localhost:8081`

### Using Docker

1. Run with docker-compose:
   ```bash
   docker-compose up --build
   ```

## API Endpoints

- `GET /api/v1/health` - Health check
- `GET /api/v1/` - Service information

## Development

### Adding New Features

1. Define domain entities in `domain/entities/`
2. Create repository interfaces in `domain/repositories/`
3. Implement use cases in `application/use_cases/`
4. Add DTOs in `application/dto/`
5. Implement infrastructure adapters in `infrastructure/adapters/`
6. Add web controllers in `infrastructure/web/controllers.py`

### Database Migrations

Run migrations using the shared database manager:

```bash
# Run migrations
python ../../db_manager/cli.py migrate

# Reset database
python ../../db_manager/cli.py reset
```
