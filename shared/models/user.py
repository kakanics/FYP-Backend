"""
Example user model - demonstrates how to extend the shared base model
Place this in shared/models/ to make it available to all services
"""
from sqlalchemy import Column, String, Boolean, Integer
from shared.models.base import BaseModel

class User(BaseModel):
    __tablename__ = 'users'
    
    username = Column(String(80), unique=True, nullable=False)
    email = Column(String(120), unique=True, nullable=False)
    first_name = Column(String(50), nullable=True)
    last_name = Column(String(50), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    age = Column(Integer, nullable=True)
    
    def __repr__(self):
        return f"<User(username='{self.username}', email='{self.email}')>"
    
    def to_dict(self):
        """Override base to_dict to customize serialization"""
        data = super().to_dict()
        # Remove sensitive information if needed
        return data
