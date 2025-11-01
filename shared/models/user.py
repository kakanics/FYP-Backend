from sqlalchemy import Column, String, Boolean, Integer
from sqlalchemy.orm import relationship
from shared.models.base import BaseModel

class User(BaseModel):
    __tablename__ = 'users'
    
    username = Column(String(80), unique=True, nullable=False)
    email = Column(String(120), unique=True, nullable=False)
    first_name = Column(String(50), nullable=True)
    last_name = Column(String(50), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    age = Column(Integer, nullable=True)
    
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(username='{self.username}', email='{self.email}')>"
    
    def to_dict(self):
        data = super().to_dict()
        return data
