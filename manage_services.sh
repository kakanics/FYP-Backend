#!/bin/bash

set -e

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
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  status        - Show status of all services"
    echo "  health        - Check health of all services"
    echo "  logs          - Show logs for services"
    echo "  stop          - Stop all services"
    echo "  restart       - Restart services"
    echo "  scale         - Scale services (k8s/docker)"
    echo "  debug         - Debug a specific service"
    echo "  test          - Run API tests"
    echo "  monitor       - Real-time monitoring"
    echo ""
    echo "Options:"
    echo "  --service=NAME    - Target specific service"
    echo "  --mode=MODE       - Specify mode (local/docker/k8s)"
    echo "  --follow          - Follow logs in real-time"
    echo "  --replicas=N      - Number of replicas for scaling"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs --service=user-service --follow"
    echo "  $0 scale --service=user-service --replicas=3 --mode=k8s"
    echo "  $0 debug --service=user-service"
}

discover_environment() {
    SERVICES=()
    for service_dir in services/*/; do
        if [ -d "$service_dir" ] && [ -f "$service_dir/app.py" ]; then
            service_name=$(basename "$service_dir")
            SERVICES+=("$service_name")
        fi
    done
    
    # Auto-detect running mode
    if kubectl cluster-info &> /dev/null && kubectl get pods &> /dev/null; then
        AUTO_MODE="k8s"
    elif docker-compose ps &> /dev/null && docker-compose ps | grep -q "Up"; then
        AUTO_MODE="docker"
    else
        AUTO_MODE="local"
    fi
}

# Show comprehensive status
show_status() {
    local mode=${1:-$AUTO_MODE}
    
    echo "=== Microservices Status ==="
    echo "Mode: $mode"
    echo "Services: ${SERVICES[*]}"
    echo ""
    
    case $mode in
        local)
            show_local_status
            ;;
        docker)
            show_docker_status
            ;;
        k8s)
            show_k8s_status
            ;;
    esac
}

show_local_status() {
    echo "Local Services Status:"
    for service in "${SERVICES[@]}"; do
        service_dir="services/$service"
        port=$(grep "^PORT=" "$service_dir/.env" | cut -d'=' -f2 2>/dev/null || echo "unknown")
        
        if [ "$port" != "unknown" ] && curl -s "http://localhost:$port/api/v1/health" > /dev/null 2>&1; then
            echo "  $service (port $port) - Running"
        else
            echo "  $service (port $port) - Not responding"
        fi
    done
    
    echo ""
    echo "Database Status:"
    if docker ps | grep -q mysql; then
        echo "  MySQL - Running"
    else
        echo "  MySQL - Not running"
    fi
}

show_docker_status() {
    echo "Docker Services Status:"
    if [ -f "docker-compose.master.yml" ]; then
        docker-compose -f docker-compose.master.yml ps
    else
        docker-compose ps
    fi
}

show_k8s_status() {
    echo "Kubernetes Status:"
    echo ""
    echo "Nodes:"
    kubectl get nodes
    
    echo ""
    echo "Pods:"
    kubectl get pods -o wide
    
    echo ""
    echo "Services:"
    kubectl get services
    
    echo ""
    echo "Deployments:"
    kubectl get deployments
}

# Health check all services
health_check() {
    local service_name="$1"
    local mode=${2:-$AUTO_MODE}
    
    echo "=== Health Check ==="
    
    if [ -n "$service_name" ]; then
        check_service_health "$service_name" "$mode"
    else
        for service in "${SERVICES[@]}"; do
            check_service_health "$service" "$mode"
        done
    fi
}

check_service_health() {
    local service="$1"
    local mode="$2"
    
    case $mode in
        local)
            local port=$(grep "^PORT=" "services/$service/.env" | cut -d'=' -f2 2>/dev/null)
            if [ -n "$port" ]; then
                local url="http://localhost:$port/api/v1/health"
                if response=$(curl -s "$url" 2>/dev/null); then
                    echo "$service: $(echo "$response" | jq -r '.message' 2>/dev/null || echo 'OK')"
                else
                    echo "$service: Not responding"
                fi
            fi
            ;;
        docker)
            local container_name=$(docker-compose ps -q "$service" 2>/dev/null)
            if [ -n "$container_name" ]; then
                if docker exec "$container_name" curl -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
                    echo "$service: Healthy"
                else
                    echo "$service: Unhealthy"
                fi
            else
                echo "$service: Container not found"
            fi
            ;;
        k8s)
            local pod=$(kubectl get pods -l app="$service" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
            if [ -n "$pod" ]; then
                if kubectl get pod "$pod" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
                    echo "$service: Ready"
                else
                    echo "$service: Not ready"
                fi
            else
                echo "$service: Pod not found"
            fi
            ;;
    esac
}

show_logs() {
    local service_name="$1"
    local mode=${2:-$AUTO_MODE}
    local follow="$3"
    
    if [ -z "$service_name" ]; then
        print_error "Please specify a service name with --service=NAME"
        return 1
    fi
    echo "=== Logs for $service_name ==="
    case $mode in
        local)
            local port=$(grep "^PORT=" "services/$service_name/.env" | cut -d'=' -f2 2>/dev/null)
            echo "Local mode: Check terminal where $service_name is running"
            if [ -n "$port" ]; then
                echo "Service URL: http://localhost:$port/api/v1/"
            fi
            ;;
        docker)
            if [ "$follow" = "true" ]; then
                docker-compose logs -f "$service_name"
            else
                docker-compose logs --tail=50 "$service_name"
            fi
            ;;
        k8s)
            if [ "$follow" = "true" ]; then
                kubectl logs -f -l app="$service_name"
            else
                kubectl logs --tail=50 -l app="$service_name"
            fi
            ;;
    esac
}

stop_services() {
    local service_name="$1"
    local mode=${2:-$AUTO_MODE}
    echo "=== Stopping Services ==="
    case $mode in
        local)
            if [ -n "$service_name" ]; then
                pkill -f "services/$service_name/app.py" 2>/dev/null || true
                echo "Stopped $service_name"
            else
                pkill -f "python.*app.py" 2>/dev/null || true
                echo "Stopped all local services"
            fi
            ;;
        docker)
            if [ -n "$service_name" ]; then
                docker-compose stop "$service_name"
            else
                docker-compose down
            fi
            ;;
        k8s)
            if [ -n "$service_name" ]; then
                kubectl scale deployment "$service_name" --replicas=0
            else
                kubectl delete -f k8s/ --ignore-not-found=true
            fi
            ;;
    esac
}

scale_services() {
    local service_name="$1"
    local replicas="$2"
    local mode=${3:-$AUTO_MODE}
    
    if [ -z "$service_name" ] || [ -z "$replicas" ]; then
        print_error "Please specify --service=NAME and --replicas=N"
        return 1
    fi
    echo "=== Scaling $service_name to $replicas replicas ==="
    case $mode in
        local)
            print_warning "Scaling not supported in local mode"
            ;;
        docker)
            docker-compose up -d --scale "$service_name=$replicas"
            ;;
        k8s)
            kubectl scale deployment "$service_name" --replicas="$replicas"
            kubectl rollout status deployment/"$service_name"
            ;;
    esac
}

debug_service() {
    local service_name="$1"
    local mode=${2:-$AUTO_MODE}
    
    if [ -z "$service_name" ]; then
        print_error "Please specify a service name with --service=NAME"
        return 1
    fi
    echo "=== Debugging $service_name ==="
    check_service_health "$service_name" "$mode"
    echo ""
    echo "Configuration:"
    if [ -f "services/$service_name/.env" ]; then
        cat "services/$service_name/.env"
    fi
    
    echo ""
    echo "Recent logs:"
    show_logs "$service_name" "$mode" "false"
    
    case $mode in
        k8s)
            echo ""
            echo "Pod details:"
            kubectl describe pods -l app="$service_name"
            ;;
        docker)
            echo ""
            echo "Container details:"
            docker-compose ps "$service_name"
            ;;
    esac
}
run_tests() {
    local service_name="$1"
    local mode=${2:-$AUTO_MODE}
    
    echo "=== API Tests ==="
    
    if [ -n "$service_name" ]; then
        test_service_api "$service_name" "$mode"
    else
        for service in "${SERVICES[@]}"; do
            test_service_api "$service" "$mode"
        done
    fi
}

test_service_api() {
    local service="$1"
    local mode="$2"
    
    local base_url=""
    case $mode in
        local)
            local port=$(grep "^PORT=" "services/$service/.env" | cut -d'=' -f2 2>/dev/null)
            base_url="http://localhost:$port/api/v1"
            ;;
        docker|k8s)
            local port=$(grep "^PORT=" "services/$service/.env" | cut -d'=' -f2 2>/dev/null)
            base_url="http://localhost:$port/api/v1"
            ;;
    esac
    if [ -n "$base_url" ]; then
        echo ""
        echo "Testing $service:"
        if response=$(curl -s "$base_url/health" 2>/dev/null); then
            echo "  Health: $(echo "$response" | jq -r '.message' 2>/dev/null || echo 'OK')"
        else
            echo "  Health: Failed"
        fi
        if response=$(curl -s "$base_url/" 2>/dev/null); then
            echo "  Root: $(echo "$response" | jq -r '.message' 2>/dev/null || echo 'OK')"
        else
            echo "  Root: Failed"
        fi
    fi
}
monitor_services() {
    local mode=${1:-$AUTO_MODE}
    echo "=== Real-time Monitoring (Press Ctrl+C to stop) ==="
    while true; do
        clear
        echo "=== Microservices Monitor $(date) ==="
        show_status "$mode"
        echo ""
        health_check "" "$mode"
        sleep 5
    done
}
parse_args() {
    COMMAND=""
    SERVICE_NAME=""
    MODE=""
    FOLLOW="false"
    REPLICAS=""
    for arg in "$@"; do
        case $arg in
            status|health|logs|stop|restart|scale|debug|test|monitor)
                COMMAND="$arg"
                ;;
            --service=*)
                SERVICE_NAME="${arg#*=}"
                ;;
            --mode=*)
                MODE="${arg#*=}"
                ;;
            --follow)
                FOLLOW="true"
                ;;
            --replicas=*)
                REPLICAS="${arg#*=}"
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
}

# Main function
main() {
    parse_args "$@"
    discover_environment
    local current_mode=${MODE:-$AUTO_MODE}
    case $COMMAND in
        status)
            show_status "$current_mode"
            ;;
        health)
            health_check "$SERVICE_NAME" "$current_mode"
            ;;
        logs)
            show_logs "$SERVICE_NAME" "$current_mode" "$FOLLOW"
            ;;
        stop)
            stop_services "$SERVICE_NAME" "$current_mode"
            ;;
        restart)
            stop_services "$SERVICE_NAME" "$current_mode"
            sleep 2
            echo "Use start_services.sh to restart services"
            ;;
        scale)
            scale_services "$SERVICE_NAME" "$REPLICAS" "$current_mode"
            ;;
        debug)
            debug_service "$SERVICE_NAME" "$current_mode"
            ;;
        test)
            run_tests "$SERVICE_NAME" "$current_mode"
            ;;
        monitor)
            monitor_services "$current_mode"
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            print_usage
            exit 1
            ;;
    esac
}
main "$@"
