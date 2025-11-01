"""
User repository interface
"""
from abc import abstractmethod
from typing import List, Optional
from domain.repositories.base import BaseRepository
from domain.entities.user import UserEntity

class UserRepositoryInterface(BaseRepository):
    """Repository interface for user entities"""
    
    @abstractmethod
    def find_by_username(self, username: str) -> Optional[UserEntity]:
        """Find user by username"""
        pass
    
    @abstractmethod
    def find_by_email(self, email: str) -> Optional[UserEntity]:
        """Find user by email"""
        pass
    
    @abstractmethod
    def find_active_users(self) -> List[UserEntity]:
        """Find all active users"""
        pass
    
    @abstractmethod
    def username_exists(self, username: str) -> bool:
        """Check if username already exists"""
        pass
    
    @abstractmethod
    def email_exists(self, email: str) -> bool:
        """Check if email already exists"""
        pass
