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
