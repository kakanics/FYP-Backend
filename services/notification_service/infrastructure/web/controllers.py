import sys
import os
import asyncio

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

@bp.route('/send-notification', methods=['POST'])
def send_notification_endpoint():
    """Example: Send notification via NATS messaging"""
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        message = data.get('message')
        notification_type = data.get('type', 'info')
        
        if not user_id or not message:
            return APIResponse.error("user_id and message are required", 400)
        
        # Send notification via NATS (async in background)
        try:
            from infrastructure.messaging import send_notification
            
            # Run async function in a thread (simplified approach)
            import threading
            def send_async():
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                loop.run_until_complete(send_notification(user_id, message, notification_type))
                loop.close()
            
            thread = threading.Thread(target=send_async)
            thread.start()
            
            return APIResponse.success({
                "message": "Notification sent via NATS",
                "user_id": user_id,
                "type": notification_type
            })
            
        except ImportError:
            # Fallback if NATS not available
            return APIResponse.success({
                "message": "Notification would be sent (NATS not available)",
                "user_id": user_id,
                "type": notification_type
            })
            
    except Exception as e:
        return APIResponse.error(f"Failed to send notification: {str(e)}", 500)

@bp.route('/broadcast', methods=['POST'])
def broadcast_message():
    """Example: Broadcast message to all services"""
    try:
        data = request.get_json()
        subject = data.get('subject', 'general.broadcast')
        message = data.get('message')
        
        if not message:
            return APIResponse.error("message is required", 400)
        
        try:
            from infrastructure.messaging import messenger
            
            # Send broadcast message
            def send_async():
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                loop.run_until_complete(messenger.publish_message(subject, {"broadcast": message}))
                loop.close()
            
            thread = threading.Thread(target=send_async)
            thread.start()
            
            return APIResponse.success({
                "message": f"Broadcast sent to {subject}",
                "content": message
            })
            
        except ImportError:
            return APIResponse.success({
                "message": "Broadcast would be sent (NATS not available)",
                "content": message
            })
            
    except Exception as e:
        return APIResponse.error(f"Failed to broadcast: {str(e)}", 500)

@bp.route('/request-user-info/<user_id>', methods=['GET'])
def request_user_info(user_id):
    """Example: Request user info from user service via NATS"""
    try:
        from infrastructure.messaging import get_user_info
        
        def get_user_async():
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            result = loop.run_until_complete(get_user_info(user_id))
            loop.close()
            return result
        
        import threading
        import queue
        
        result_queue = queue.Queue()
        
        def run_async():
            try:
                result = get_user_async()
                result_queue.put(result)
            except Exception as e:
                result_queue.put({"error": str(e)})
        
        thread = threading.Thread(target=run_async)
        thread.start()
        thread.join(timeout=6)  # Wait max 6 seconds
        
        if not result_queue.empty():
            result = result_queue.get()
            if result and "error" not in result:
                return APIResponse.success({
                    "message": "User info retrieved via NATS",
                    "user_info": result
                })
            else:
                return APIResponse.error(f"Failed to get user info: {result.get('error', 'timeout')}", 500)
        else:
            return APIResponse.error("Request timeout", 504)
            
    except ImportError:
        return APIResponse.success({
            "message": "Would request user info via NATS (not available)",
            "user_id": user_id
        })