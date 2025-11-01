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
