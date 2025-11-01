"""
NATS Messaging Utility for Inter-Service Communication

This module provides easy-to-use functions for publishing and subscribing to messages
using NATS messaging system in a microservices architecture.
"""

import asyncio
import json
import os
from typing import Dict, Any, Callable, Optional
from nats.aio.client import Client as NATS
import logging

logger = logging.getLogger(__name__)

class NATSMessenger:
    """NATS messaging client for microservice communication"""
    
    def __init__(self):
        self.nc = NATS()
        self.nats_url = os.getenv('NATS_URL', 'nats://localhost:4222')
        self.service_name = os.getenv('SERVICE_NAME', 'unknown-service')
        
    async def connect(self):
        """Connect to NATS server"""
        try:
            await self.nc.connect(self.nats_url)
            logger.info(f"Connected to NATS at {self.nats_url}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to NATS: {e}")
            return False
    
    async def disconnect(self):
        """Disconnect from NATS server"""
        if self.nc.is_connected:
            await self.nc.close()
            logger.info("Disconnected from NATS")
    
    async def publish_message(self, subject: str, message: Dict[Any, Any], reply_to: Optional[str] = None):
        """
        Publish a message to a subject
        
        Args:
            subject: NATS subject (e.g., 'user.created', 'notification.send')
            message: Dictionary containing the message data
            reply_to: Optional reply subject for request-response pattern
        """
        try:
            if not self.nc.is_connected:
                await self.connect()
            
            # Add metadata
            envelope = {
                'sender': self.service_name,
                'timestamp': asyncio.get_event_loop().time(),
                'data': message
            }
            
            message_bytes = json.dumps(envelope).encode()
            
            if reply_to:
                await self.nc.publish(subject, message_bytes, reply=reply_to)
            else:
                await self.nc.publish(subject, message_bytes)
                
            logger.info(f"Published message to {subject}: {message}")
            
        except Exception as e:
            logger.error(f"Failed to publish message to {subject}: {e}")
    
    async def subscribe_to_subject(self, subject: str, handler: Callable):
        """
        Subscribe to a subject and handle incoming messages
        
        Args:
            subject: NATS subject to subscribe to
            handler: Async function to handle incoming messages
        """
        try:
            if not self.nc.is_connected:
                await self.connect()
            
            async def message_handler(msg):
                try:
                    # Decode message
                    envelope = json.loads(msg.data.decode())
                    
                    # Extract data and metadata
                    sender = envelope.get('sender', 'unknown')
                    timestamp = envelope.get('timestamp', 0)
                    data = envelope.get('data', {})
                    
                    logger.info(f"Received message from {sender} on {subject}")
                    
                    # Call the handler
                    response = await handler(data, sender, timestamp)
                    
                    # If message expects a reply and handler returns data
                    if msg.reply and response:
                        reply_envelope = {
                            'sender': self.service_name,
                            'timestamp': asyncio.get_event_loop().time(),
                            'data': response
                        }
                        reply_bytes = json.dumps(reply_envelope).encode()
                        await self.nc.publish(msg.reply, reply_bytes)
                        
                except Exception as e:
                    logger.error(f"Error handling message on {subject}: {e}")
            
            # Subscribe to the subject
            await self.nc.subscribe(subject, cb=message_handler)
            logger.info(f"Subscribed to {subject}")
            
        except Exception as e:
            logger.error(f"Failed to subscribe to {subject}: {e}")
    
    async def request_response(self, subject: str, request: Dict[Any, Any], timeout: float = 5.0):
        """
        Send a request and wait for response (request-response pattern)
        
        Args:
            subject: NATS subject to send request to
            request: Request data
            timeout: Timeout in seconds
            
        Returns:
            Response data or None if timeout/error
        """
        try:
            if not self.nc.is_connected:
                await self.connect()
            
            # Create request envelope
            envelope = {
                'sender': self.service_name,
                'timestamp': asyncio.get_event_loop().time(),
                'data': request
            }
            
            request_bytes = json.dumps(envelope).encode()
            
            # Send request and wait for response
            response_msg = await self.nc.request(subject, request_bytes, timeout=timeout)
            
            # Decode response
            response_envelope = json.loads(response_msg.data.decode())
            
            logger.info(f"Received response from {subject}")
            return response_envelope.get('data', {})
            
        except Exception as e:
            logger.error(f"Request to {subject} failed: {e}")
            return None

# Global messenger instance
messenger = NATSMessenger()

# Convenience functions for common messaging patterns

async def send_notification(user_id: str, message: str, type: str = "info"):
    """Send a notification message"""
    await messenger.publish_message('notification.send', {
        'user_id': user_id,
        'message': message,
        'type': type
    })

async def send_user_event(event_type: str, user_data: Dict[Any, Any]):
    """Send user-related events (created, updated, deleted)"""
    await messenger.publish_message(f'user.{event_type}', user_data)

async def send_email(to_email: str, subject: str, body: str):
    """Send email request"""
    await messenger.publish_message('email.send', {
        'to': to_email,
        'subject': subject,
        'body': body
    })

async def get_user_info(user_id: str) -> Optional[Dict[Any, Any]]:
    """Request user information from user service"""
    return await messenger.request_response('user.get', {'user_id': user_id})

# Example handlers for different message types

async def handle_user_created(data: Dict[Any, Any], sender: str, timestamp: float):
    """Handle user created events"""
    user_id = data.get('user_id')
    email = data.get('email')
    
    print(f"New user created: {user_id} ({email})")
    
    # Send welcome notification
    await send_notification(
        user_id, 
        "Welcome to our platform! 🎉", 
        "welcome"
    )
    
    # Send welcome email
    await send_email(
        email,
        "Welcome to Our Platform",
        f"Hello! Your account has been created successfully."
    )

async def handle_notification_request(data: Dict[Any, Any], sender: str, timestamp: float):
    """Handle notification send requests"""
    user_id = data.get('user_id')
    message = data.get('message')
    notification_type = data.get('type', 'info')
    
    print(f"Sending {notification_type} notification to {user_id}: {message}")
    
    # Here you would implement actual notification logic
    # (push notifications, in-app notifications, etc.)
    
    return {'status': 'sent', 'notification_id': f'notif_{user_id}_{timestamp}'}

# Example setup function for a service
async def setup_message_handlers():
    """Setup message handlers for this service"""
    
    # Connect to NATS
    await messenger.connect()
    
    # Subscribe to relevant topics based on service type
    service_name = os.getenv('SERVICE_NAME', '')
    
    if 'notification' in service_name:
        # Notification service handles notification requests
        await messenger.subscribe_to_subject('notification.send', handle_notification_request)
        await messenger.subscribe_to_subject('user.created', handle_user_created)
        
    elif 'user' in service_name:
        # User service might handle user info requests
        async def handle_user_info_request(data: Dict[Any, Any], sender: str, timestamp: float):
            user_id = data.get('user_id')
            # Return user info (this would query your database)
            return {
                'user_id': user_id,
                'email': f'user{user_id}@example.com',
                'name': f'User {user_id}'
            }
        
        await messenger.subscribe_to_subject('user.get', handle_user_info_request)
    
    print(f"Message handlers setup for {service_name}")

# Example usage in Flask app
def start_messaging_background_task():
    """Start messaging in background (call this from Flask app startup)"""
    import threading
    
    def run_messaging():
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        loop.run_until_complete(setup_message_handlers())
        loop.run_forever()
    
    thread = threading.Thread(target=run_messaging, daemon=True)
    thread.start()
