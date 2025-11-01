#!/bin/bash

# Flask Service Generator with Hexagonal Architecture
# Usage: ./createService.sh serviceName port

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [ $# -ne 2 ]; then
    print_error "Usage: $0 <serviceName> <port>"
    print_info "Example: $0 user-service 8081"
    exit 1
fi

SERVICE_NAME=$1
PORT=$2

if [[ ! $SERVICE_NAME =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    print_error "Service name must start with a letter and contain only letters, numbers, hyphens, and underscores"
    exit 1
fi

if [[ ! $PORT =~ ^[0-9]+$ ]] || [ $PORT -lt 1024 ] || [ $PORT -gt 65535 ]; then
    print_error "Port must be a number between 1024 and 65535"
    exit 1
fi

SNAKE_CASE_NAME=$(echo "$SERVICE_NAME" | sed 's/-/_/g' | tr '[:upper:]' '[:lower:]')

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"

print_info "Creating Flask service: $SERVICE_NAME on port $PORT"
create_shared_components() {
    print_info "Setting up shared components..."
    mkdir -p "$BASE_DIR/shared/models"
    if [ ! -f "$BASE_DIR/shared/__init__.py" ]; then
        touch "$BASE_DIR/shared/__init__.py"
    fi
    if [ ! -f "$BASE_DIR/shared/models/__init__.py" ]; then
        touch "$BASE_DIR/shared/models/__init__.py"
    fi
    
    mkdir -p "$BASE_DIR/db_manager"
    if [ ! -f "$BASE_DIR/db_manager/__init__.py" ]; then
        touch "$BASE_DIR/db_manager/__init__.py"
    fi
    
    if [ ! -f "$BASE_DIR/db_manager/manager.py" ]; then
        cat > "$BASE_DIR/db_manager/manager.py" << 'EOF'
import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add shared components to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from shared.models.base import Base

class DatabaseManager:
    def __init__(self, database_url=None):
        if database_url:
            self.database_url = database_url
        else:
            # Build database URL from environment variables
            db_host = os.getenv('DB_HOST', 'localhost')
            db_port = os.getenv('DB_PORT', '3306')
            db_name = os.getenv('DB_NAME', 'flask_services')
            db_user = os.getenv('DB_USER', 'root')
            db_password = os.getenv('DB_PASSWORD', '')
            
            # Fallback to DATABASE_URL if provided
            self.database_url = os.getenv(
                'DATABASE_URL',
                f'mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'
            )
        self.engine = create_engine(self.database_url)
        self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
    
    def create_tables(self):
        """Create all tables defined in models"""
        Base.metadata.create_all(bind=self.engine)
    
    def drop_tables(self):
        """Drop all tables"""
        Base.metadata.drop_all(bind=self.engine)
    
    def get_session(self):
        """Get database session"""
        return self.SessionLocal()
    
    def execute_sql(self, sql_query):
        """Execute raw SQL query"""
        with self.engine.connect() as connection:
            return connection.execute(text(sql_query))
    
    def migrate(self):
        """Run migrations"""
        self.create_tables()
    
    def reset_database(self):
        """Reset database - drop and recreate all tables"""
        self.drop_tables()
        self.create_tables()

# Global database manager instance
db_manager = DatabaseManager()
EOF
    fi
    
    if [ ! -f "$BASE_DIR/db_manager/cli.py" ]; then
        cat > "$BASE_DIR/db_manager/cli.py" << 'EOF'
#!/usr/bin/env python3
import argparse
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from db_manager.manager import db_manager

def main():
    parser = argparse.ArgumentParser(description='Database Migration Manager')
    parser.add_argument('command', choices=['migrate', 'reset', 'create-tables', 'drop-tables'],
                       help='Migration command to execute')
    
    args = parser.parse_args()
    
    try:
        if args.command == 'migrate':
            print("Running migrations...")
            db_manager.migrate()
            print("Migrations completed successfully")
        
        elif args.command == 'reset':
            print("Resetting database...")
            db_manager.reset_database()
            print("Database reset completed")
        
        elif args.command == 'create-tables':
            print("Creating tables...")
            db_manager.create_tables()
            print("Tables created successfully")
        
        elif args.command == 'drop-tables':
            print("Dropping tables...")
            db_manager.drop_tables()
            print("Tables dropped successfully")
    
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
EOF
        chmod +x "$BASE_DIR/db_manager/cli.py"
    fi
    
    print_success "Shared components created/updated"
}

create_service() {
    SERVICE_DIR="$BASE_DIR/services/$SNAKE_CASE_NAME"
    
    print_info "Creating service directory structure..."
    mkdir -p "$SERVICE_DIR"/{domain/{entities,repositories,services},infrastructure/{adapters,database,web},application/{dto,ports,use_cases}}
    find "$SERVICE_DIR" -type d -exec touch {}/__init__.py \;
    cat > "$SERVICE_DIR/infrastructure/database/connection.py" << 'EOF'
import sys
import os

# Add shared components to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')))

from db_manager.manager import db_manager

def get_db_session():
    """Get database session"""
    session = db_manager.get_session()
    try:
        yield session
    finally:
        session.close()

def init_db():
    """Initialize database"""
    db_manager.create_tables()
EOF
    
    cat > "$SERVICE_DIR/infrastructure/web/controllers.py" << 'EOF'
import sys
import os

# Add shared components to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')))

from flask import Blueprint, request
from shared.utils.response import APIResponse

# Create blueprint for this service
bp = Blueprint('api', __name__)

@bp.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return APIResponse.success({"status": "healthy"})

@bp.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return APIResponse.success({"message": f"Welcome to {os.getenv('SERVICE_NAME', 'Flask Service')}"})
EOF
    
    cat > "$SERVICE_DIR/app.py" << EOF
import sys
import os

# Add shared components to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from flask import Flask
from flask_cors import CORS
from shared.config import BaseServiceConfig
from shared.utils.response import APIResponse
from infrastructure.web.controllers import bp
from infrastructure.database.connection import init_db

def create_app(config=None):
    app = Flask(__name__)
    
    # Load configuration
    config = config or BaseServiceConfig()
    app.config['DEBUG'] = config.debug
    app.config['TESTING'] = config.testing
    app.config['SECRET_KEY'] = config.secret_key
    
    # Set service name for identification
    os.environ['SERVICE_NAME'] = '$SERVICE_NAME'
    
    # Enable CORS
    CORS(app)
    
    # Initialize database
    init_db()
    
    # Register blueprints
    app.register_blueprint(bp, url_prefix='/api/v1')
    
    # Global error handlers
    @app.errorhandler(404)
    def not_found(error):
        return APIResponse.not_found("Endpoint not found")
    
    @app.errorhandler(500)
    def internal_error(error):
        return APIResponse.error("Internal server error", 500)
    
    @app.errorhandler(Exception)
    def handle_exception(e):
        return APIResponse.error(str(e), 500)
    
    return app

if __name__ == '__main__':
    app = create_app()
    config = BaseServiceConfig()
    app.run(host=config.host, port=config.port, debug=config.debug)
EOF
    
    cat > "$SERVICE_DIR/requirements.txt" << 'EOF'
Flask==2.3.3
Flask-CORS==4.0.0
SQLAlchemy==2.0.21
PyMySQL==1.1.0
cryptography==41.0.4
python-dotenv==1.0.0
EOF
    
    cat > "$SERVICE_DIR/.env" << EOF
DEBUG=True
SECRET_KEY=dev-secret-key-change-in-production
DATABASE_URL=mysql+pymysql://root:password@localhost:3306/flask_services
SERVICE_NAME=$SERVICE_NAME
PORT=$PORT
NATS_URL=nats://localhost:4222
NATS_HOST=localhost
NATS_PORT=4222

# Database configuration will be inherited from parent .env
# DB_HOST=localhost
# DB_PORT=3306
# DB_NAME=flask_services
# DB_USER=root
# DB_PASSWORD=your_password_here
EOF
    
    print_success "Service '$SERVICE_NAME' created successfully at $SERVICE_DIR"
}

main() {
    print_info "Starting Flask service creation..."
    if [ -d "$BASE_DIR/services/$SNAKE_CASE_NAME" ]; then
        print_warning "Service '$SNAKE_CASE_NAME' already exists. Do you want to overwrite it? (y/N)"
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            print_info "Service creation cancelled."
            exit 0
        fi
        rm -rf "$BASE_DIR/services/$SNAKE_CASE_NAME"
    fi
    
    create_shared_components
    create_service
    
    print_success "Service '$SERVICE_NAME' has been created successfully!"
    print_info "Your service will be available at: http://localhost:$PORT"
    print_info "Health check: http://localhost:$PORT/api/v1/health"
}

main
