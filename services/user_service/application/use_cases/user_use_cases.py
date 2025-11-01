"""
User use cases (application services)
"""
from typing import List, Optional
from domain.entities.user import UserEntity
from domain.repositories.user_repository import UserRepositoryInterface
from application.dto.user_dto import CreateUserDTO, UpdateUserDTO, UserResponseDTO

class UserUseCases:
    """Use cases for user management"""
    
    def __init__(self, user_repository: UserRepositoryInterface):
        self.user_repository = user_repository
    
    def create_user(self, create_dto: CreateUserDTO) -> UserResponseDTO:
        """Create a new user"""
        # Validate business rules
        if self.user_repository.username_exists(create_dto.username):
            raise ValueError("Username already exists")
        
        if self.user_repository.email_exists(create_dto.email):
            raise ValueError("Email already exists")
        
        # Create domain entity
        user_entity = UserEntity(
            username=create_dto.username,
            email=create_dto.email,
            first_name=create_dto.first_name,
            last_name=create_dto.last_name,
            age=create_dto.age,
            is_active=True
        )
        
        # Save and return
        saved_user = self.user_repository.save(user_entity)
        return UserResponseDTO.from_entity(saved_user)
    
    def get_user_by_id(self, user_id: int) -> Optional[UserResponseDTO]:
        """Get user by ID"""
        user_entity = self.user_repository.find_by_id(user_id)
        return UserResponseDTO.from_entity(user_entity) if user_entity else None
    
    def get_user_by_username(self, username: str) -> Optional[UserResponseDTO]:
        """Get user by username"""
        user_entity = self.user_repository.find_by_username(username)
        return UserResponseDTO.from_entity(user_entity) if user_entity else None
    
    def get_all_users(self) -> List[UserResponseDTO]:
        """Get all users"""
        user_entities = self.user_repository.find_all()
        return [UserResponseDTO.from_entity(entity) for entity in user_entities]
    
    def get_active_users(self) -> List[UserResponseDTO]:
        """Get all active users"""
        user_entities = self.user_repository.find_active_users()
        return [UserResponseDTO.from_entity(entity) for entity in user_entities]
    
    def update_user(self, user_id: int, update_dto: UpdateUserDTO) -> Optional[UserResponseDTO]:
        """Update user"""
        user_entity = self.user_repository.find_by_id(user_id)
        if not user_entity:
            return None
        
        # Update entity with provided values
        if update_dto.first_name is not None:
            user_entity.first_name = update_dto.first_name
        if update_dto.last_name is not None:
            user_entity.last_name = update_dto.last_name
        if update_dto.age is not None:
            user_entity.age = update_dto.age
        if update_dto.is_active is not None:
            user_entity.is_active = update_dto.is_active
        
        # Save and return
        updated_user = self.user_repository.save(user_entity)
        return UserResponseDTO.from_entity(updated_user)
    
    def delete_user(self, user_id: int) -> bool:
        """Delete user"""
        return self.user_repository.delete(user_id)
    
    def deactivate_user(self, user_id: int) -> Optional[UserResponseDTO]:
        """Deactivate user instead of deleting"""
        update_dto = UpdateUserDTO(is_active=False)
        return self.update_user(user_id, update_dto)
