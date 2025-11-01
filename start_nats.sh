#!/bin/bash
set -e

print_info() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_usage() {
    echo "Usage: $0 [start|stop|status|logs]"
    echo ""
    echo "Commands:"
    echo "  start   - Start NATS server in Docker"
    echo "  stop    - Stop NATS server"
    echo "  status  - Check NATS status"
    echo "  logs    - Show NATS logs"
    echo ""
    echo "  - Client: nats://localhost:4222"
    echo "  - HTTP Monitoring: http://localhost:8222"
}

start_nats() {
    print_info "Starting NATS server in Docker..."
    if docker ps | grep -q "nats-local"; then
        print_info "NATS container is already running"
        return 0
    fi
    docker stop nats-local 2>/dev/null || true
    docker rm nats-local 2>/dev/null || true
    docker run -d \
        --name nats-local \
        -p 4222:4222 \
        -p 8222:8222 \
        -p 6222:6222 \
        nats:2.10-alpine \
        --http_port 8222 \
        --cluster_name local_cluster \
        --cluster nats://0.0.0.0:6222
    
    print_info "Waiting for NATS to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:8222/varz > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    if curl -s http://localhost:8222/varz > /dev/null 2>&1; then
        print_success "NATS server is running!"
        echo ""
        echo "NATS Endpoints:"
        echo "   Client: nats://localhost:4222"
        echo "   Monitoring: http://localhost:8222"
        echo ""
        echo "Your local services can now connect to NATS using:"
        echo "   NATS_URL=nats://localhost:4222"
    else
        echo "[ERROR] NATS failed to start properly"
        return 1
    fi
}

stop_nats() {
    print_info "Stopping NATS server..."
    docker stop nats-local 2>/dev/null || true
    docker rm nats-local 2>/dev/null || true
    print_success "NATS server stopped"
}

status_nats() {
    echo "=== NATS Status ==="
    if docker ps | grep -q "nats-local"; then
        echo " NATS container: Running"
        
        if curl -s http://localhost:8222/varz > /dev/null 2>&1; then
            echo "NATS server: Healthy"
            echo ""
            echo "Quick Stats:"
            curl -s http://localhost:8222/varz | jq -r '"   Connections: " + (.connections | tostring), "   Messages In: " + (.in_msgs | tostring), "   Messages Out: " + (.out_msgs | tostring), "   Uptime: " + .uptime' 2>/dev/null || echo "   (stats unavailable)"
        else
            echo "NATS server: Not responding"
        fi
    else
        echo "NATS container: Not running"
    fi
    
    echo "   Client: nats://localhost:4222"
    echo "   Monitoring: http://localhost:8222"
}

show_logs() {
    if docker ps | grep -q "nats-local"; then
        print_info "NATS logs (last 50 lines):"
        docker logs --tail=50 nats-local
    else
        echo "[ERROR] NATS container is not running"
    fi
}

case "${1:-}" in
    start)
        start_nats
        ;;
    stop)
        stop_nats
        ;;
    status)
        status_nats
        ;;
    logs)
        show_logs
        ;;
    -h|--help|"")
        print_usage
        ;;
    *)
        echo "[ERROR] Unknown command: $1"
        print_usage
        exit 1
        ;;
esac
