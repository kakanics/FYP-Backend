import sys
import os

# Add shared components to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')))

from flask import Blueprint, request
from shared.utils.response import APIResponse

# Create blueprint for this service
bp = Blueprint('api', __name__)

@bp.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return APIResponse.success({"status": "healthy"})

@bp.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return APIResponse.success({"message": f"Welcome to {os.getenv('SERVICE_NAME', 'Flask Service')}"})

@bp.route('/demo/send-message', methods=['POST'])
def demo_send_message():
    """Demo: Send a message via NATS"""
    try:
        data = request.get_json() or {}
        subject = data.get('subject', 'demo.test')
        message = data.get('message', 'Hello from test service!')
        
        # Simulate sending message via NATS
        print(f"📡 Sending message to {subject}: {message}")
        
        # In a real implementation, you would use:
        # from infrastructure.messaging import messenger
        # asyncio.run(messenger.publish_message(subject, {"message": message}))
        
        return APIResponse.success({
            "status": "sent",
            "subject": subject,
            "message": message,
            "note": "NATS messaging example - install nats-py to enable"
        })
        
    except Exception as e:
        return APIResponse.error(f"Failed to send message: {str(e)}", 500)

@bp.route('/demo/trigger-notification', methods=['POST'])
def demo_trigger_notification():
    """Demo: Trigger a notification to another service"""
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id', 'demo_user')
        message = data.get('message', 'Test notification from test service')
        
        print(f"🔔 Triggering notification for user {user_id}: {message}")
        
        # This would send a notification request to the notification service
        # await messenger.publish_message('notification.send', {
        #     'user_id': user_id,
        #     'message': message,
        #     'type': 'info'
        # })
        
        return APIResponse.success({
            "status": "notification_triggered",
            "user_id": user_id,
            "message": message,
            "note": "Would send to notification service via NATS"
        })
        
    except Exception as e:
        return APIResponse.error(f"Failed to trigger notification: {str(e)}", 500)

@bp.route('/demo/user-event', methods=['POST'])
def demo_user_event():
    """Demo: Simulate user event that other services can listen to"""
    try:
        data = request.get_json() or {}
        event_type = data.get('event_type', 'created')
        user_data = data.get('user_data', {
            'user_id': 'demo_123',
            'email': 'demo@example.com',
            'name': 'Demo User'
        })
        
        print(f"👤 Broadcasting user event: {event_type}")
        print(f"   Data: {user_data}")
        
        # This would broadcast to all interested services
        # await messenger.publish_message(f'user.{event_type}', user_data)
        
        return APIResponse.success({
            "status": "event_broadcasted",
            "event_type": event_type,
            "user_data": user_data,
            "note": f"Would broadcast 'user.{event_type}' to all services"
        })
        
    except Exception as e:
        return APIResponse.error(f"Failed to broadcast event: {str(e)}", 500)
