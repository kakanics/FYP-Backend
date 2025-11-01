#!/usr/bin/env python3
import argparse
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from db_manager.manager import db_manager

def main():
    parser = argparse.ArgumentParser(description='Database Migration Manager')
    parser.add_argument('command', choices=['migrate', 'reset', 'create-tables', 'drop-tables'],
                       help='Migration command to execute')
    
    args = parser.parse_args()
    
    try:
        if args.command == 'migrate':
            db_manager.migrate()
            print("Migrations completed")
        
        elif args.command == 'reset':
            db_manager.reset_database()
            print("Database reset done")
        
        elif args.command == 'create-tables':
            db_manager.create_tables()
            print("Tables created")
        
        elif args.command == 'drop-tables':
            db_manager.drop_tables()
            print("Tables dropped")
    
    except Exception as e:
        print(f"{e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
