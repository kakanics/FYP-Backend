#!/bin/bash

# Kubernetes Cluster Setup Script
# Works with Docker Desktop or Colima

set -e

# Function to print output
print_info() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

print_error() {
    echo "[ERROR] $1"
}

print_usage() {
    echo "Usage: $0 [setup|start|stop|status|cleanup] [--colima|--docker-desktop]"
    echo ""
    echo "Commands:"
    echo "  setup         - Setup Kubernetes cluster and deploy all services"
    echo "  start         - Start the Kubernetes cluster"
    echo "  stop          - Stop the Kubernetes cluster"
    echo "  status        - Check cluster and services status"
    echo "  cleanup       - Remove all deployments and services"
    echo ""
    echo "Options:"
    echo "  --colima         - Use Colima (default if detected)"
    echo "  --docker-desktop - Use Docker Desktop"
    echo ""
    echo "Examples:"
    echo "  $0 setup --colima"
    echo "  $0 start"
    echo "  $0 status"
}

# Detect container runtime
detect_runtime() {
    if command -v colima &> /dev/null && colima status &> /dev/null; then
        echo "colima"
    elif docker context ls | grep -q "desktop-linux\|docker-desktop" 2>/dev/null; then
        echo "docker-desktop"
    else
        echo "unknown"
    fi
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first:"
        echo "  brew install kubectl"
        echo "  or visit: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Setup Colima with Kubernetes
setup_colima() {
    print_info "Setting up Colima with Kubernetes..."
    
    # Check if colima is installed
    if ! command -v colima &> /dev/null; then
        print_error "Colima is not installed. Installing via Homebrew..."
        brew install colima
    fi
    
    # Stop colima if running
    if colima status &> /dev/null; then
        print_info "Stopping existing Colima instance..."
        colima stop
    fi
    
    # Start colima with Kubernetes
    print_info "Starting Colima with Kubernetes support..."
    colima start --kubernetes --cpu 4 --memory 8 --disk 50
    
    # Wait for Kubernetes to be ready
    print_info "Waiting for Kubernetes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    print_success "Colima with Kubernetes is ready"
}

# Setup Docker Desktop Kubernetes
setup_docker_desktop() {
    print_info "Setting up Docker Desktop Kubernetes..."
    
    # Check if Docker Desktop is running
    if ! docker context ls | grep -q "desktop-linux\|docker-desktop" 2>/dev/null; then
        print_error "Docker Desktop is not running. Please start Docker Desktop and enable Kubernetes."
        print_info "To enable Kubernetes in Docker Desktop:"
        print_info "1. Open Docker Desktop"
        print_info "2. Go to Settings > Kubernetes"
        print_info "3. Check 'Enable Kubernetes'"
        print_info "4. Click 'Apply & Restart'"
        exit 1
    fi
    
    # Switch to docker-desktop context
    kubectl config use-context docker-desktop
    
    # Wait for Kubernetes to be ready
    print_info "Waiting for Kubernetes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    print_success "Docker Desktop Kubernetes is ready"
}

# Create Kubernetes manifests
create_k8s_manifests() {
    print_info "Creating Kubernetes manifests..."
    
    mkdir -p k8s
    
    # NATS for service communication
    cat > k8s/nats.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nats-config
data:
  nats.conf: |
    # NATS Server Configuration
    port: 4222
    http_port: 8222
    
    # Clustering (if needed later)
    cluster {
      name: nats_cluster
      port: 6222
    }
    
    # Monitoring
    monitor_port: 8222
    
    # Logging
    log_file: "/tmp/nats.log"
    logtime: true
    debug: false
    trace: false
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nats
  labels:
    app: nats
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nats
  template:
    metadata:
      labels:
        app: nats
    spec:
      containers:
      - name: nats
        image: nats:2.10-alpine
        ports:
        - containerPort: 4222
          name: client
        - containerPort: 8222
          name: monitor
        - containerPort: 6222
          name: cluster
        volumeMounts:
        - name: config-volume
          mountPath: /etc/nats
        args:
        - "--config"
        - "/etc/nats/nats.conf"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 8222
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8222
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: config-volume
        configMap:
          name: nats-config
---
apiVersion: v1
kind: Service
metadata:
  name: nats-service
  labels:
    app: nats
spec:
  selector:
    app: nats
  ports:
  - port: 4222
    targetPort: 4222
    name: client
  - port: 8222
    targetPort: 8222
    name: monitor
    nodePort: 30822
  - port: 6222
    targetPort: 6222
    name: cluster
  type: NodePort
EOF

    # Create service manifests for each service
    for service_dir in services/*/; do
        if [ -d "$service_dir" ]; then
            service_name=$(basename "$service_dir")
            # Convert underscores to hyphens for Kubernetes-valid names
            k8s_service_name=$(echo "$service_name" | tr '_' '-')
            
            # Skip if not a valid service directory
            if [ ! -f "$service_dir/app.py" ]; then
                continue
            fi
            
            # Get port from .env file
            port=$(grep "^PORT=" "$service_dir/.env" | cut -d'=' -f2)
            if [ -z "$port" ]; then
                port="8080"
            fi
            
            # Map service port to NodePort range (30000-32767)
            case "$k8s_service_name" in
                "user-service")
                    nodeport="30002"
                    ;;
                "notification-service")
                    nodeport="30084"
                    ;;
                *)
                    nodeport="30080"
                    ;;
            esac
            
            # Create Dockerfile if it doesn't exist or update it
            cat > "$service_dir/Dockerfile" << EOF
FROM python:3.11-slim

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy shared components
COPY ../../shared/ ./shared/
COPY ../../db_manager/ ./db_manager/

# Copy service code
COPY . .

EXPOSE $port

CMD ["python", "app.py"]
EOF

            # Create Kubernetes manifest
            cat > "k8s/${k8s_service_name}.yaml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${k8s_service_name}-config
data:
  DEBUG: "True"
  DATABASE_URL: "mysql+pymysql://root:password@YOUR_EXTERNAL_DB_HOST:3306/flask_services"
  SERVICE_NAME: "${k8s_service_name}"
  PORT: "${port}"
  NATS_URL: "nats://nats-service:4222"
  NATS_HOST: "nats-service"
  NATS_PORT: "4222"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${k8s_service_name}
  labels:
    app: ${k8s_service_name}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${k8s_service_name}
  template:
    metadata:
      labels:
        app: ${k8s_service_name}
    spec:
      containers:
      - name: ${k8s_service_name}
        image: ${service_name}:latest
        imagePullPolicy: Never
        ports:
        - containerPort: ${port}
        envFrom:
        - configMapRef:
            name: ${k8s_service_name}-config
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: ${port}
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: ${port}
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: ${k8s_service_name}-service
spec:
  selector:
    app: ${k8s_service_name}
  ports:
    - port: 80
      targetPort: ${port}
      nodePort: ${nodeport}
  type: NodePort
EOF
        fi
    done
    
    print_success "Kubernetes manifests created"
}

# Build Docker images
build_images() {
    print_info "Building Docker images..."
    
    for service_dir in services/*/; do
        if [ -d "$service_dir" ] && [ -f "$service_dir/app.py" ]; then
            service_name=$(basename "$service_dir")
            
            print_info "Building image for $service_name..."
            
            # Create build context
            mkdir -p "build/$service_name"
            
            # Copy shared components
            cp -r shared "build/$service_name/"
            cp -r db_manager "build/$service_name/"
            
            # Copy service files
            cp -r "$service_dir"/* "build/$service_name/"
            
            # Build image (keep original service_name for image tag)
            docker build -t "$service_name:latest" "build/$service_name/"
            
            # Clean up build context
            rm -rf "build/$service_name"
        fi
    done
    
    print_success "Docker images built"
}

# Deploy to Kubernetes
deploy_to_k8s() {
    print_info "Deploying to Kubernetes..."
    
    # Deploy NATS first for service communication
    kubectl apply -f k8s/nats.yaml
    
    # Wait for NATS to be ready
    print_info "Waiting for NATS to be ready..."
    kubectl wait --for=condition=Ready pod -l app=nats --timeout=300s
    
    # Deploy services
    for manifest in k8s/*.yaml; do
        if [ "$(basename "$manifest")" != "nats.yaml" ]; then
            kubectl apply -f "$manifest"
        fi
    done
    
    # Wait for deployments to be ready
    print_info "Waiting for services to be ready..."
    kubectl wait --for=condition=Available deployment --all --timeout=300s
    
    print_success "All services deployed to Kubernetes"
    print_info "NATS monitoring available at: http://localhost:30822"
    print_warning "Note: Update DATABASE_URL in service configs to point to your external MySQL server"
}

# Check cluster status
check_status() {
    print_info "Checking Kubernetes cluster status..."
    
    # Check nodes
    echo ""
    echo "Nodes:"
    kubectl get nodes
    
    # Check pods
    echo ""
    echo "Pods:"
    kubectl get pods -o wide
    
    # Check services
    echo ""
    echo "Services:"
    kubectl get services
    
    # Check deployments
    echo ""
    echo "Deployments:"
    kubectl get deployments
    
    # Show service URLs
    echo ""
    echo "Service URLs:"
    echo "  User Service: http://localhost:30002/api/v1/"
    echo "  Notification Service: http://localhost:30084/api/v1/"
    echo "  NATS Monitoring: http://localhost:30822"
    echo ""
    print_warning "Note: Services are configured to use external MySQL database"
    print_info "NATS is available for inter-service communication on localhost:30422"
}

# Cleanup function
cleanup_k8s() {
    print_warning "Cleaning up Kubernetes resources..."
    
    # Delete all deployments and services
    kubectl delete -f k8s/ --ignore-not-found=true
    
    # Delete persistent volume claims
    kubectl delete pvc --all --ignore-not-found=true
    
    print_success "Cleanup completed"
}

# Start cluster
start_cluster() {
    local runtime="$1"
    
    case $runtime in
        colima)
            if ! colima status &> /dev/null; then
                colima start --kubernetes --cpu 4 --memory 8 --disk 50
            else
                print_info "Colima is already running"
            fi
            ;;
        docker-desktop)
            kubectl config use-context docker-desktop
            print_info "Using Docker Desktop Kubernetes"
            ;;
        *)
            print_error "Unknown runtime: $runtime"
            exit 1
            ;;
    esac
    
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    print_success "Kubernetes cluster is ready"
}

# Stop cluster
stop_cluster() {
    local runtime="$1"
    
    case $runtime in
        colima)
            if colima status &> /dev/null; then
                colima stop
                print_success "Colima stopped"
            else
                print_info "Colima is not running"
            fi
            ;;
        docker-desktop)
            print_info "Please stop Docker Desktop manually if needed"
            ;;
        *)
            print_error "Unknown runtime: $runtime"
            exit 1
            ;;
    esac
}

# Main script logic
main() {
    # Parse arguments
    COMMAND=""
    RUNTIME=""
    
    for arg in "$@"; do
        case $arg in
            setup|start|stop|status|cleanup)
                COMMAND="$arg"
                ;;
            --colima)
                RUNTIME="colima"
                ;;
            --docker-desktop)
                RUNTIME="docker-desktop"
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
        esac
    done
    
    if [ -z "$COMMAND" ]; then
        print_usage
        exit 1
    fi
    
    # Auto-detect runtime if not specified
    if [ -z "$RUNTIME" ]; then
        RUNTIME=$(detect_runtime)
        if [ "$RUNTIME" = "unknown" ]; then
            print_error "Could not detect container runtime. Please specify --colima or --docker-desktop"
            exit 1
        fi
        print_info "Auto-detected runtime: $RUNTIME"
    fi
    
    case $COMMAND in
        setup)
            check_prerequisites
            if [ "$RUNTIME" = "colima" ]; then
                setup_colima
            else
                setup_docker_desktop
            fi
            create_k8s_manifests
            build_images
            deploy_to_k8s
            check_status
            ;;
        start)
            check_prerequisites
            start_cluster "$RUNTIME"
            ;;
        stop)
            stop_cluster "$RUNTIME"
            ;;
        status)
            check_status
            ;;
        cleanup)
            cleanup_k8s
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            print_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
