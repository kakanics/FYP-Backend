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
            print("✅ Migrations completed successfully")
        
        elif args.command == 'reset':
            print("Resetting database...")
            db_manager.reset_database()
            print("✅ Database reset completed")
        
        elif args.command == 'create-tables':
            print("Creating tables...")
            db_manager.create_tables()
            print("✅ Tables created successfully")
        
        elif args.command == 'drop-tables':
            print("Dropping tables...")
            db_manager.drop_tables()
            print("✅ Tables dropped successfully")
    
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
