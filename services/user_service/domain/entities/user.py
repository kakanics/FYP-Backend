"""
User entity for the user service domain
"""
from dataclasses import dataclass
from typing import Optional
from datetime import datetime

@dataclass
class UserEntity:
    """Domain entity representing a user"""
    id: Optional[int] = None
    username: str = ""
    email: str = ""
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    is_active: bool = True
    age: Optional[int] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def get_full_name(self) -> str:
        """Business logic: get full name"""
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        return self.username
    
    def is_adult(self) -> bool:
        """Business logic: check if user is adult"""
        return self.age is not None and self.age >= 18
