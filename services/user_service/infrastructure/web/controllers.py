import sys
import os

# Add shared components to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')))

from flask import Blueprint, request, jsonify
from shared.utils.response import APIResponse
from infrastructure.database.connection import get_db_session
from infrastructure.adapters.user_repository import UserRepository
from application.use_cases.user_use_cases import UserUseCases
from application.dto.user_dto import CreateUserDTO, UpdateUserDTO

# Create blueprint for this service
bp = Blueprint('api', __name__)

def get_user_use_cases():
    """Dependency injection for user use cases"""
    session = next(get_db_session())
    user_repository = UserRepository(session)
    return UserUseCases(user_repository)

@bp.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return APIResponse.success({"status": "healthy"})

@bp.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return APIResponse.success({"message": f"Welcome to {os.getenv('SERVICE_NAME', 'Flask Service')}"})

# User endpoints
@bp.route('/users', methods=['GET'])
def get_users():
    """Get all users"""
    try:
        use_cases = get_user_use_cases()
        users = use_cases.get_all_users()
        return APIResponse.success([user.__dict__ for user in users])
    except Exception as e:
        return APIResponse.error(str(e), 500)

@bp.route('/users/active', methods=['GET'])
def get_active_users():
    """Get all active users"""
    try:
        use_cases = get_user_use_cases()
        users = use_cases.get_active_users()
        return APIResponse.success([user.__dict__ for user in users])
    except Exception as e:
        return APIResponse.error(str(e), 500)

@bp.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Get user by ID"""
    try:
        use_cases = get_user_use_cases()
        user = use_cases.get_user_by_id(user_id)
        if user:
            return APIResponse.success(user.__dict__)
        return APIResponse.not_found("User not found")
    except Exception as e:
        return APIResponse.error(str(e), 500)

@bp.route('/users/username/<username>', methods=['GET'])
def get_user_by_username(username):
    """Get user by username"""
    try:
        use_cases = get_user_use_cases()
        user = use_cases.get_user_by_username(username)
        if user:
            return APIResponse.success(user.__dict__)
        return APIResponse.not_found("User not found")
    except Exception as e:
        return APIResponse.error(str(e), 500)

@bp.route('/users', methods=['POST'])
def create_user():
    """Create a new user"""
    try:
        data = request.get_json()
        if not data:
            return APIResponse.error("Request body is required", 400)
        
        # Validate required fields
        required_fields = ['username', 'email']
        for field in required_fields:
            if field not in data:
                return APIResponse.error(f"Field '{field}' is required", 400)
        
        create_dto = CreateUserDTO(
            username=data['username'],
            email=data['email'],
            first_name=data.get('first_name'),
            last_name=data.get('last_name'),
            age=data.get('age')
        )
        
        use_cases = get_user_use_cases()
        user = use_cases.create_user(create_dto)
        return APIResponse.success(user.__dict__, "User created successfully", 201)
    
    except ValueError as e:
        return APIResponse.error(str(e), 400)
    except Exception as e:
        return APIResponse.error(str(e), 500)

@bp.route('/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    """Update user"""
    try:
        data = request.get_json()
        if not data:
            return APIResponse.error("Request body is required", 400)
        
        update_dto = UpdateUserDTO(
            first_name=data.get('first_name'),
            last_name=data.get('last_name'),
            age=data.get('age'),
            is_active=data.get('is_active')
        )
        
        use_cases = get_user_use_cases()
        user = use_cases.update_user(user_id, update_dto)
        if user:
            return APIResponse.success(user.__dict__, "User updated successfully")
        return APIResponse.not_found("User not found")
    
    except Exception as e:
        return APIResponse.error(str(e), 500)

@bp.route('/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Delete user"""
    try:
        use_cases = get_user_use_cases()
        if use_cases.delete_user(user_id):
            return APIResponse.success(None, "User deleted successfully")
        return APIResponse.not_found("User not found")
    except Exception as e:
        return APIResponse.error(str(e), 500)

@bp.route('/users/<int:user_id>/deactivate', methods=['POST'])
def deactivate_user(user_id):
    """Deactivate user"""
    try:
        use_cases = get_user_use_cases()
        user = use_cases.deactivate_user(user_id)
        if user:
            return APIResponse.success(user.__dict__, "User deactivated successfully")
        return APIResponse.not_found("User not found")
    except Exception as e:
        return APIResponse.error(str(e), 500)
