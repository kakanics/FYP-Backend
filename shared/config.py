import os
from dataclasses import dataclass, field

@dataclass
class DatabaseConfig:
    url: str = os.getenv('DATABASE_URL', 'mysql+pymysql://root:password@localhost:3306/flask_services')
    echo: bool = os.getenv('DB_ECHO', 'False').lower() == 'true'

@dataclass
class BaseServiceConfig:
    debug: bool = os.getenv('DEBUG', 'False').lower() == 'true'
    testing: bool = os.getenv('TESTING', 'False').lower() == 'true'
    secret_key: str = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    
    # Server configuration
    host: str = os.getenv('HOST', '0.0.0.0')
    port: int = int(os.getenv('PORT', '8080'))
    
    # Database
    database: DatabaseConfig = field(default_factory=DatabaseConfig)
    
    # Service discovery
    service_registry_url: str = os.getenv('SERVICE_REGISTRY_URL', 'http://localhost:8500')
