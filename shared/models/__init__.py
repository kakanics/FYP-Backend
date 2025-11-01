# Shared models for all microservices
from .base import Base, BaseModel
from .user import User
from .notification import Notification, NotificationStatus, NotificationType

# Make models available for import
__all__ = ['Base', 'BaseModel', 'User', 'Notification', 'NotificationStatus', 'NotificationType']