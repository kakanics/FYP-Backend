# 🚀 Streamlined Development Workflow

Your optimized setup for local development with Docker NATS messaging.

## 📋 Quick Start

### 1. Start Everything
```bash
./dev.sh start
```
This will:
- ✅ Start NATS server in Docker
- ✅ Open separate terminal windows for each service
- ✅ Each service runs locally with its own virtual environment

### 2. Check Status
```bash
./dev.sh status
```

### 3. Stop Everything
```bash
./dev.sh stop
```

## 🔧 What You Get

### NATS Messaging (Docker)
- **Client**: `nats://localhost:4222`
- **Monitoring**: http://localhost:8222
- **Container**: Isolated, consistent, easy to restart

### Services (Local)
- **User Service**: http://localhost:8081/api/v1/
- **Notification Service**: http://localhost:8084/api/v1/
- **Each service**: Own terminal window + virtual environment

## 💡 Individual Commands

### NATS Management
```bash
./start_nats.sh start      # Start NATS in Docker
./start_nats.sh stop       # Stop NATS
./start_nats.sh status     # Check NATS status
./start_nats.sh logs       # View NATS logs
```

### Service Management
```bash
./start_services.sh        # Start all services in terminals
./manage_services.sh status --mode=local    # Check service status
./manage_services.sh health --mode=local    # Health check all services
./manage_services.sh logs --service=user-service --mode=local  # View logs
```

## 🛠 Configuration

### Environment Variables (per service)
- `PORT=8081` - Service port
- `NATS_URL=nats://localhost:4222` - Local NATS connection
- `DATABASE_URL=mysql+pymysql://...` - Your database
- `DEBUG=True` - Development mode

### Service Ports
- User Service: **8081**
- Notification Service: **8084**
- NATS Client: **4222**
- NATS Monitoring: **8222**

## 🔄 Development Workflow

1. **Start**: `./dev.sh start` *(once per session)*
2. **Code**: Edit services in their own terminal windows
3. **Test**: Services auto-reload with Flask debug mode
4. **Debug**: Each service has its own logs in separate terminals
5. **Stop**: `./dev.sh stop` *(end of session)*

## 🎯 Benefits

- ✅ **Fast startup**: No Kubernetes overhead
- ✅ **Easy debugging**: Each service in own terminal
- ✅ **Consistent messaging**: Docker NATS always available
- ✅ **Isolated environments**: Each service has own virtualenv
- ✅ **Auto-reload**: Flask debug mode for quick iteration
- ✅ **Production parity**: Same NATS setup as K8s deployment

## 🚦 Status Indicators

| Component | Status Check | URL |
|-----------|-------------|-----|
| NATS | `./start_nats.sh status` | http://localhost:8222 |
| User Service | `curl http://localhost:8081/api/v1/health` | http://localhost:8081/api/v1/ |
| Notification Service | `curl http://localhost:8084/api/v1/health` | http://localhost:8084/api/v1/ |

This is your perfect development setup! 🎉
