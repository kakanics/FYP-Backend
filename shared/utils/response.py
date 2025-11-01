from flask import jsonify
from typing import Any, Dict, Optional

class APIResponse:
    @staticmethod
    def success(data: Any = None, message: str = "Success", status_code: int = 200):
        response = {
            "success": True,
            "message": message,
            "data": data
        }
        return jsonify(response), status_code
    
    @staticmethod
    def error(message: str = "An error occurred", status_code: int = 400, errors: Optional[Dict] = None):
        response = {
            "success": False,
            "message": message
        }
        if errors:
            response["errors"] = errors
        return jsonify(response), status_code
    
    @staticmethod
    def not_found(message: str = "Resource not found"):
        return APIResponse.error(message, 404)
    
    @staticmethod
    def unauthorized(message: str = "Unauthorized"):
        return APIResponse.error(message, 401)
    
    @staticmethod
    def forbidden(message: str = "Forbidden"):
        return APIResponse.error(message, 403)
    
    @staticmethod
    def validation_error(errors: Dict, message: str = "Validation failed"):
        return APIResponse.error(message, 422, errors)
