#!/bin/bash
set -e

print_usage() {
    echo "start all services"
}

discover_services() {
    SERVICES=()
    for service_dir in services/*/; do
        if [ -d "$service_dir" ] && [ -f "$service_dir/app.py" ]; then
            service_name=$(basename "$service_dir")
            SERVICES+=("$service_name")
        fi
    done
    
    echo "Found services: ${SERVICES[*]}"
}

start_service_in_terminal() {
    local service_name="$1"
    local service_dir="services/$service_name"
    
    echo "Starting $service_name..."
    
    local startup_cmd="cd '$PWD/$service_dir' && echo 'Starting $service_name...' && "
    
    startup_cmd+="if [ ! -d 'venv' ]; then echo 'Creating virtual environment...'; python3 -m venv venv; fi && "
    startup_cmd+="source venv/bin/activate && "
    startup_cmd+="if [ ! -f '.deps_installed' ]; then echo 'Installing dependencies...'; pip install -r requirements.txt && touch .deps_installed; else echo 'Dependencies already installed'; fi && "
    startup_cmd+="echo 'Starting Flask app...' && python3 app.py"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "
        tell application \"Terminal\"
            do script \"$startup_cmd\"
            activate
        end tell"
    else
        powershell.exe -Command "Start-Process pwsh -ArgumentList '-NoExit', '-Command', '$startup_cmd'"
    fi
}

for arg in "$@"; do
    case $arg in
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            print_usage
            exit 1
            ;;
    esac
done

discover_services
for service in "${SERVICES[@]}"; do
    start_service_in_terminal "$service"
    sleep 1 
done

echo "Service URLs:"
for service in "${SERVICES[@]}"; do
    service_dir="services/$service"
    if [ -f "$service_dir/.env" ]; then
        port=$(grep "^PORT=" "$service_dir/.env" | cut -d'=' -f2 2>/dev/null || echo "unknown")
        echo "  $service: http://localhost:$port/api/v1/"
    fi
done
