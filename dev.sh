#!/bin/bash

set -e

print_info() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_usage() {
    echo "Usage: $0 [start|stop|status]"
    echo "Commands:"
    echo "  start   - Start NATS (Docker) + Services (Local)"
    echo "  stop    - Stop everything"
    echo "  status  - Check status of everything"
    echo ""
}

start_dev_environment() {
    print_info "Step 1: Starting NATS server..."
    ./start_nats.sh start
    print_info "Step 2: Starting microservices locally..."
    ./start_services.sh
    
    echo "   • Use './dev.sh status' to check everything"
    echo "   • Use './dev.sh stop' to stop everything"
}

stop_dev_environment() {
    print_info "Stopping development environment..."
    pkill -f 'python3 app.py' 2>/dev/null || true
    pkill -f 'python app.py' 2>/dev/null || true
    ./start_nats.sh stop
}

show_status() {
    echo "=== Development Environment Status ==="
    echo ""
    
    ./start_nats.sh status
    ./manage_services.sh status --mode=local
}

# Parse command
case "${1:-}" in
    start)
        start_dev_environment
        ;;
    stop)
        stop_dev_environment
        ;;
    status)
        show_status
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
