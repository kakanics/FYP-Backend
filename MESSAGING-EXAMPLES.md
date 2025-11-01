# 🧪 NATS Messaging Examples & Testing

This file contains practical examples of how to test the NATS messaging system between services.

## 🚀 Quick Test Commands

### 1. Check Service Health

```bash
# Test Service
curl http://localhost:30003/api/v1/health

# Notification Service  
curl http://localhost:30084/api/v1/health

# User Service
curl http://localhost:30002/api/v1/health
```

### 2. Test NATS Messaging Examples

#### Send a Demo Message (Test Service)

```bash
curl -X POST http://localhost:30003/api/v1/demo/send-message \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "demo.test",
    "message": "Hello from API test!"
  }'
```

#### Trigger Notification (Test Service → Notification Service)

```bash
curl -X POST http://localhost:30003/api/v1/demo/trigger-notification \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "message": "Your order has been processed!"
  }'
```

#### Broadcast User Event (Test Service)

```bash
curl -X POST http://localhost:30003/api/v1/demo/user-event \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "created",
    "user_data": {
      "user_id": "user456",
      "email": "newuser@example.com",
      "name": "Jane Doe"
    }
  }'
```

### 3. Notification Service Examples

#### Send Direct Notification

```bash
curl -X POST http://localhost:30084/api/v1/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user789",
    "message": "Welcome to our platform!",
    "type": "welcome"
  }'
```

#### Broadcast Message to All Services

```bash
curl -X POST http://localhost:30084/api/v1/broadcast \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "system.announcement",
    "message": "System maintenance scheduled for tonight"
  }'
```

#### Request User Info (Inter-service Communication)

```bash
curl http://localhost:30084/api/v1/request-user-info/user123
```

## 📡 NATS Message Flow Examples

### Example 1: User Registration Flow

```
1. User Service → Creates new user
2. User Service → Publishes "user.created" event
3. Notification Service → Receives event
4. Notification Service → Sends welcome email
5. Notification Service → Sends push notification
```

**Test this flow:**

```bash
# Step 1: Simulate user creation
curl -X POST http://localhost:30003/api/v1/demo/user-event \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "created",
    "user_data": {
      "user_id": "newuser001",
      "email": "newuser@example.com",
      "name": "New User"
    }
  }'

# Step 2: Check if notification service would handle it
curl -X POST http://localhost:30084/api/v1/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "newuser001",
    "message": "Welcome! Your account has been created.",
    "type": "welcome"
  }'
```

### Example 2: Payment Processing

```
1. Payment Service → Processes payment
2. Payment Service → Publishes "payment.completed"
3. User Service → Updates user credits
4. Notification Service → Sends confirmation
```

**Test this flow:**

```bash
# Step 1: Simulate payment completion
curl -X POST http://localhost:30003/api/v1/demo/send-message \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "payment.completed",
    "message": {
      "user_id": "user123",
      "amount": 99.99,
      "transaction_id": "txn_001"
    }
  }'

# Step 2: Send payment confirmation
curl -X POST http://localhost:30084/api/v1/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "message": "Payment of $99.99 processed successfully!",
    "type": "success"
  }'
```

## 🔍 Monitor NATS

### View NATS Dashboard

```bash
open http://localhost:30822
```

### Check NATS Service Status

```bash
kubectl get pods | grep nats
kubectl logs -f <nats-pod-name>
```

## 📊 Real-Time Message Patterns

### 1. Pub/Sub Pattern (Event Broadcasting)

**Publisher** (any service):
```python
await messenger.publish_message('user.created', user_data)
```

**Subscribers** (multiple services can listen):
```python
await messenger.subscribe_to_subject('user.created', handle_user_created)
```

### 2. Request-Response Pattern

**Requester**:
```python
response = await messenger.request_response('user.get', {'user_id': '123'})
```

**Responder**:
```python
async def handle_user_request(data, sender, timestamp):
    user_id = data['user_id']
    user_data = get_user_from_db(user_id)
    return user_data
```

## 🧪 Test Different Message Types

### 1. Simple Event

```bash
curl -X POST http://localhost:30003/api/v1/demo/send-message \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "order.placed",
    "message": {"order_id": "ord_123", "user_id": "user456"}
  }'
```

### 2. System Alert

```bash
curl -X POST http://localhost:30084/api/v1/broadcast \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "system.alert",
    "message": "Database connection restored"
  }'
```

### 3. User Activity

```bash
curl -X POST http://localhost:30003/api/v1/demo/user-event \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "login",
    "user_data": {"user_id": "user789", "ip": "192.168.1.1"}
  }'
```

## 📈 Performance Testing

### Load Test Message Publishing

```bash
# Send 100 messages quickly
for i in {1..100}; do
  curl -X POST http://localhost:30003/api/v1/demo/send-message \
    -H "Content-Type: application/json" \
    -d "{\"subject\": \"load.test\", \"message\": \"Message $i\"}" &
done
wait
```

### Monitor Message Throughput

```bash
# Check NATS stats
curl http://localhost:30822/varz
```

## 🐛 Debugging Tips

### 1. Check Service Logs

```bash
kubectl logs -f deployment/notification-service
kubectl logs -f deployment/test-service
```

### 2. Verify NATS Connection

```bash
kubectl exec -it deployment/notification-service -- env | grep NATS
```

### 3. Test Network Connectivity

```bash
kubectl exec -it deployment/test-service -- nc -zv nats-service 4222
```

## 🎯 Production Considerations

1. **Message Persistence**: Configure NATS JetStream for message durability
2. **Authentication**: Add NATS authentication for security
3. **Monitoring**: Set up proper metrics and alerting
4. **Error Handling**: Implement dead letter queues for failed messages
5. **Rate Limiting**: Prevent message flooding

## 🔗 Useful Resources

- **NATS Monitoring**: http://localhost:30822
- **Kubernetes Dashboard**: `kubectl proxy` then http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
- **Service Health Endpoints**: `http://localhost:30XXX/api/v1/health`
