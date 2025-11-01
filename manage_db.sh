#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_usage() {
    echo "Commands:"
    echo "  migrate       - Run database migrations"
    echo "  reset         - Reset database (drop and recreate all tables)"
    echo "  create-tables - Create all tables"
    echo "  drop-tables   - Drop all tables"
    echo "  status        - Check database connection and table status"
}

run_migration_command() {
    local cmd=$1
    echo -e "${BLUE}[INFO]${NC} Running database command: $cmd"
    
    if ./venv/bin/python db_manager/cli.py "$cmd"; then
        echo -e "${GREEN}[SUCCESS]${NC} Command '$cmd' completed successfully"
    else
        echo -e "${RED}[ERROR]${NC} Command '$cmd' failed"
        exit 1
    fi
}

check_database_status() {
    echo -e "${BLUE}[INFO]${NC} Checking database status..."
    ./venv/bin/python -c "
import sys
import os
sys.path.insert(0, os.path.abspath('.'))

try:
    from db_manager.manager import db_manager
    from shared.models.base import Base
    
    # Test connection
    with db_manager.engine.connect() as conn:
        print('Database connection: OK')
    
    # Check if tables exist
    from sqlalchemy import inspect
    inspector = inspect(db_manager.engine)
    table_names = inspector.get_table_names()
    print(f'Tables found: {len(table_names)}')
    for table in table_names:
        print(f'  - {table}')
    
    # Check models
    tables_in_metadata = Base.metadata.tables.keys()
    print(f'Models defined: {len(tables_in_metadata)}')
    for table in tables_in_metadata:
        print(f'  - {table}')
        
except Exception as e:
    sys.exit(1)
"
}

if [ $# -eq 0 ]; then
    print_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    migrate)
        run_migration_command "migrate"
        ;;
    reset)
        echo -e "${YELLOW}[WARNING]${NC} This will delete all data in the database!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_migration_command "reset"
        else
            echo "Operation cancelled."
        fi
        ;;
    create-tables)
        run_migration_command "create-tables"
        ;;
    drop-tables)
        echo -e "${YELLOW}[WARNING]${NC} This will drop all tables!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_migration_command "drop-tables"
        else
            echo "Operation cancelled."
        fi
        ;;
    status)
        check_database_status
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unknown command: $COMMAND"
        print_usage
        exit 1
        ;;
esac
