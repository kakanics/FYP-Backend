"""
User repository implementation using SQLAlchemy
"""
import sys
import os

# Add shared components to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')))

from typing import List, Optional
from sqlalchemy.orm import Session
from shared.models.user import User
from domain.repositories.user_repository import UserRepositoryInterface
from domain.entities.user import UserEntity
from infrastructure.adapters.repository import SQLAlchemyRepository

class UserRepository(SQLAlchemyRepository, UserRepositoryInterface):
    """SQLAlchemy implementation of user repository"""
    
    def __init__(self, session: Session):
        super().__init__(session, User)
    
    def _model_to_entity(self, user_model: User) -> UserEntity:
        """Convert SQLAlchemy model to domain entity"""
        return UserEntity(
            id=user_model.id,
            username=user_model.username,
            email=user_model.email,
            first_name=user_model.first_name,
            last_name=user_model.last_name,
            is_active=user_model.is_active,
            age=user_model.age,
            created_at=user_model.created_at,
            updated_at=user_model.updated_at
        )
    
    def _entity_to_model(self, user_entity: UserEntity) -> User:
        """Convert domain entity to SQLAlchemy model"""
        return User(
            id=user_entity.id,
            username=user_entity.username,
            email=user_entity.email,
            first_name=user_entity.first_name,
            last_name=user_entity.last_name,
            is_active=user_entity.is_active,
            age=user_entity.age
        )
    
    def find_by_id(self, entity_id: int) -> Optional[UserEntity]:
        """Find user by ID"""
        user_model = super().find_by_id(entity_id)
        return self._model_to_entity(user_model) if user_model else None
    
    def find_all(self) -> List[UserEntity]:
        """Find all users"""
        user_models = super().find_all()
        return [self._model_to_entity(model) for model in user_models]
    
    def save(self, entity: UserEntity) -> UserEntity:
        """Save user entity"""
        user_model = self._entity_to_model(entity)
        saved_model = super().save(user_model)
        return self._model_to_entity(saved_model)
    
    def find_by_username(self, username: str) -> Optional[UserEntity]:
        """Find user by username"""
        user_model = self.session.query(User).filter(User.username == username).first()
        return self._model_to_entity(user_model) if user_model else None
    
    def find_by_email(self, email: str) -> Optional[UserEntity]:
        """Find user by email"""
        user_model = self.session.query(User).filter(User.email == email).first()
        return self._model_to_entity(user_model) if user_model else None
    
    def find_active_users(self) -> List[UserEntity]:
        """Find all active users"""
        user_models = self.session.query(User).filter(User.is_active == True).all()
        return [self._model_to_entity(model) for model in user_models]
    
    def username_exists(self, username: str) -> bool:
        """Check if username already exists"""
        return self.session.query(User).filter(User.username == username).first() is not None
    
    def email_exists(self, email: str) -> bool:
        """Check if email already exists"""
        return self.session.query(User).filter(User.email == email).first() is not None
