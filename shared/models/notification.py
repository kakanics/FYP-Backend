from sqlalchemy import Column, String, Boolean, Integer, Text, Enum, ForeignKey
from sqlalchemy.orm import relationship
from shared.models.base import BaseModel
import enum

class NotificationStatus(enum.Enum):
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    DELIVERED = "delivered"

class NotificationType(enum.Enum):
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"
    IN_APP = "in_app"

class Notification(BaseModel):
    __tablename__ = 'notifications'
    
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    notification_type = Column(Enum(NotificationType), nullable=False, default=NotificationType.EMAIL)
    status = Column(Enum(NotificationStatus), nullable=False, default=NotificationStatus.PENDING)
    recipient = Column(String(255), nullable=False)  
    extra_data = Column(Text, nullable=True)  
    sent_at = Column(Integer, nullable=True)  
    is_read = Column(Boolean, default=False, nullable=False)
    
    user = relationship("User", back_populates="notifications")
    
    def __repr__(self):
        return f"<Notification(id={self.id}, user_id={self.user_id}, type={self.notification_type.value}, status={self.status.value})>"
    
    def mark_as_sent(self):
        import time
        self.status = NotificationStatus.SENT
        self.sent_at = int(time.time())
    
    def mark_as_delivered(self):
        self.status = NotificationStatus.DELIVERED
    
    def mark_as_failed(self):
        self.status = NotificationStatus.FAILED
