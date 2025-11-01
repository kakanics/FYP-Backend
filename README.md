# Flask Microservices with Hexagonal Architecture

This project provides a comprehensive framework for building Flask microservices using hexagonal architecture principles. It includes a command-line tool for generating services, shared components, and database management utilities.

## 🚀 Features

- **Service Generator**: Automated creation of Flask services with hexagonal architecture
- **Shared Components**: Common models, utilities, and configuration across all services
- **Database Management**: Centralized database migration and management system
- **Hexagonal Architecture**: Clean separation of concerns with domain, application, and infrastructure layers
- **Docker Support**: Ready-to-use Docker configurations for each service
- **API Standards**: Consistent API response formatting and error handling

## 📁 Project Structure

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

## 🏃‍♂️ Quick Start

### Prerequisites

- Python 3.11+
- PostgreSQL (or Docker for containerized setup)
- Git

### 1. Creating Your First Service

Use the service generator to create a new microservice:

```bash
./createService.sh user-service 8081
```

This creates a complete Flask service with:
- Hexagonal architecture structure
- Database integration
- Docker configuration
- API endpoints with health checks
- Comprehensive documentation

### 2. Database Setup

Start PostgreSQL database:

```bash
# Using Docker (recommended)
docker-compose up postgres -d

# Or use the database management utility
./manage_db.sh status
```

Run database migrations:

```bash
./manage_db.sh migrate
```

### 3. Install Dependencies and Run Service

```bash
cd services/user_service
pip install -r requirements.txt
python app.py
```

Your service will be available at `http://localhost:8081`

### 4. Test Your Service

```bash
# Health check
curl http://localhost:8081/api/v1/health

# Service info
curl http://localhost:8081/api/v1/

# If using the example user service
curl -X POST http://localhost:8081/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "johndoe", "email": "john@example.com"}'
```

## 🛠️ Advanced Usage

### Creating Multiple Services

Create a complete microservices ecosystem:

```bash
./createService.sh user-service 8081
./createService.sh product-service 8082
./createService.sh order-service 8083
./createService.sh notification-service 8084
```

### Database Management

The project includes a comprehensive database management utility:

```bash
# Check database status
./manage_db.sh status

# Run migrations
./manage_db.sh migrate

# Reset database (careful!)
./manage_db.sh reset

# Create tables only
./manage_db.sh create-tables
```

### Running the Demo

Experience the full workflow with the demo script:

```bash
./demo.sh
```

This will:
1. Create multiple services
2. Set up the database
3. Install dependencies
4. Start all services
5. Run API tests

## 🏗️ Architecture Deep Dive

### Hexagonal Architecture Principles

Each service follows hexagonal (ports and adapters) architecture:

1. **Domain Layer**: Core business logic, entities, and repository interfaces
2. **Application Layer**: Use cases, DTOs, and application services
3. **Infrastructure Layer**: Database adapters, web controllers, external integrations

### Dependency Flow

```
Infrastructure → Application → Domain
```

- Domain layer has no dependencies
- Application layer depends only on domain
- Infrastructure layer implements domain interfaces

### Example: Adding a New Feature

1. **Define Domain Entity** (`domain/entities/product.py`):
```python
@dataclass
class ProductEntity:
    id: Optional[int] = None
    name: str = ""
    price: float = 0.0
    description: Optional[str] = None
```

2. **Create Repository Interface** (`domain/repositories/product_repository.py`):
```python
class ProductRepositoryInterface(BaseRepository):
    @abstractmethod
    def find_by_name(self, name: str) -> Optional[ProductEntity]:
        pass
```

3. **Implement Use Case** (`application/use_cases/product_use_cases.py`):
```python
class ProductUseCases:
    def create_product(self, create_dto: CreateProductDTO) -> ProductResponseDTO:
        # Business logic here
        pass
```

4. **Add Infrastructure** (`infrastructure/adapters/product_repository.py`):
```python
class ProductRepository(SQLAlchemyRepository, ProductRepositoryInterface):
    # Implementation
    pass
```

5. **Create Web Controller** (`infrastructure/web/controllers.py`):
```python
@bp.route('/products', methods=['POST'])
def create_product():
    # Web layer implementation
    pass
```

## 🐳 Docker Support

Each generated service includes Docker support:

### Single Service
```bash
cd services/user_service
docker-compose up --build
```

### All Services with Shared Database
```bash
# Start shared database
docker-compose up postgres -d

# Build and run each service
cd services/user_service && docker-compose up --build -d
cd ../product_service && docker-compose up --build -d
```

## 🔧 Configuration

### Environment Variables

Each service supports these environment variables:

```bash
DEBUG=True
SECRET_KEY=your-secret-key
DATABASE_URL=postgresql://user:pass@localhost:5432/db
SERVICE_NAME=your-service-name
SERVICE_PORT=8081
```

### Shared Configuration

Global settings in `shared/config.py`:

```python
@dataclass
class BaseServiceConfig:
    debug: bool = os.getenv('DEBUG', 'False').lower() == 'true'
    database: DatabaseConfig = DatabaseConfig()
    service_registry_url: str = os.getenv('SERVICE_REGISTRY_URL', 'http://localhost:8500')
```

## 📚 API Documentation

### Standard Endpoints

Every service includes:

- `GET /api/v1/health` - Health check
- `GET /api/v1/` - Service information

### Response Format

All APIs use consistent response formatting:

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

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the hexagonal architecture patterns
4. Add tests for new features
5. Submit a pull request

## 📝 Best Practices

1. **Domain-First Design**: Start with domain entities and business logic
2. **Interface Segregation**: Keep repository interfaces focused and specific
3. **Dependency Injection**: Use constructor injection for dependencies
4. **Error Handling**: Use domain exceptions and proper HTTP status codes
5. **Testing**: Write tests for each layer independently
6. **Documentation**: Document business rules and API endpoints

## 🔍 Troubleshooting

### Common Issues

1. **Import Errors**: Ensure all `__init__.py` files are present
2. **Database Connection**: Check PostgreSQL is running and credentials are correct
3. **Port Conflicts**: Ensure each service uses a unique port
4. **Path Issues**: Services use relative imports; run from service directory

### Debugging

Enable debug mode in `.env`:
```bash
DEBUG=True
```

Check logs for detailed error information.

## 📄 License

This project is open source and available under the MIT License.
