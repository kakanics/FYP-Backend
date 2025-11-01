"""
User DTOs for the application layer
"""
from dataclasses import dataclass
from typing import Optional
from application.dto.base import BaseDTO

@dataclass
class CreateUserDTO:
    """DTO for creating a new user"""
    username: str
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    age: Optional[int] = None

@dataclass  
class UpdateUserDTO:
    """DTO for updating a user"""
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    age: Optional[int] = None
    is_active: Optional[bool] = None

@dataclass
class UserResponseDTO(BaseDTO):
    """DTO for user responses"""
    username: str = ""
    email: str = ""
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    is_active: bool = True
    age: Optional[int] = None
    
    @classmethod
    def from_entity(cls, user_entity):
        """Create DTO from domain entity"""
        return cls(
            id=user_entity.id,
            username=user_entity.username,
            email=user_entity.email,
            first_name=user_entity.first_name,
            last_name=user_entity.last_name,
            is_active=user_entity.is_active,
            age=user_entity.age,
            created_at=user_entity.created_at,
            updated_at=user_entity.updated_at
        )
