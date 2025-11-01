#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_usage() {
    echo "Commands:"
    echo "  $0                    - Backup all .env files to a timestamped zip"
    echo "  $0 <zip_file>         - Restore .env files from zip to services"
    echo ""
}

discover_services() {
    SERVICES=()
    SERVICE_DIRS=()
    
    for service_dir in services/*/; do
        if [ -d "$service_dir" ] && [ -f "$service_dir/.env" ]; then
            service_name=$(basename "$service_dir")
            SERVICES+=("$service_name")
            SERVICE_DIRS+=("$service_dir")
        fi
    done
    
    if [ ${#SERVICES[@]} -eq 0 ]; then
        print_warning "No services with .env files found in services/ directory"
        return 1
    fi
    
    print_info "Found ${#SERVICES[@]} services with .env files: ${SERVICES[*]}"
    return 0
}

backup_env_files() {
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_file="env-backup-${timestamp}.zip"
    
    print_info "Creating backup of all .env files..."
    
    if ! discover_services; then
        exit 1
    fi
    
    local temp_dir=$(mktemp -d)
    local backup_dir="$temp_dir/env-backup"
    mkdir -p "$backup_dir"
    
    for i in "${!SERVICES[@]}"; do
        local service="${SERVICES[$i]}"
        local service_dir="${SERVICE_DIRS[$i]}"
        local target_dir="$backup_dir/$service"
        
        print_info "Backing up $service..."
        mkdir -p "$target_dir"
        cp "$service_dir/.env" "$target_dir/.env"
        
        for config_file in "$service_dir"/.env.* "$service_dir"/config.* "$service_dir"/*.conf; do
            if [ -f "$config_file" ]; then
                cp "$config_file" "$target_dir/"
            fi
        done
    done
    
    cat > "$backup_dir/backup-info.txt" << EOF
Backup created: $(date)
Services included: ${SERVICES[*]}
Total services: ${#SERVICES[@]}
Created by: $(whoami)
Host: $(hostname)
Directory: $(pwd)
EOF
    
    cd "$temp_dir"
    if zip -r "$backup_file" env-backup/ > /dev/null 2>&1; then
        local current_dir="$(pwd)"
        cd - > /dev/null
        mv "$temp_dir/$backup_file" "./$backup_file"
        print_success "Backup created: $backup_file"
        
        print_info "Backup contents:"
        unzip -l "$backup_file" | grep "\.env" | sed 's/^/  /'
        
        echo ""
        print_info "Backup file: $(pwd)/$backup_file"
        print_info "Size: $(du -h "$backup_file" | cut -f1)"
    else
        print_error "Failed to create backup zip file"
        cleanup_temp "$temp_dir"
        exit 1
    fi
    
    cleanup_temp "$temp_dir"
}

restore_env_files() {
    local zip_file="$1"
    
    if [[ "$zip_file" != /* ]]; then
        zip_file="$(pwd)/$zip_file"
    fi
    
    if [ ! -f "$zip_file" ]; then
        print_error "Zip file not found: $zip_file"
        exit 1
    fi
    
    if ! unzip -t "$zip_file" > /dev/null 2>&1; then
        print_error "Invalid or corrupted zip file: $zip_file"
        exit 1
    fi
    local temp_dir=$(mktemp -d)
    
    cd "$temp_dir"
    if ! unzip -q "$zip_file"; then
        print_error "Failed to extract zip file"
        cleanup_temp "$temp_dir"
        exit 1
    fi
    
    # Find the backup directory (could be named differently)
    local backup_dir=""
    for dir in env-backup*/ */; do
        if [ -d "$dir" ]; then
            backup_dir="$dir"
            break
        fi
    done
    
    if [ -z "$backup_dir" ]; then
        print_error "No backup directory found in zip file"
        cleanup_temp "$temp_dir"
        exit 1
    fi
    
    print_info "Found backup directory: $backup_dir"
    
    # Show backup info if available
    if [ -f "$backup_dir/backup-info.txt" ]; then
        print_info "Backup information:"
        cat "$backup_dir/backup-info.txt" | sed 's/^/  /'
        echo ""
    fi
    
    # Discover current services
    cd - > /dev/null
    discover_services > /dev/null 2>&1 || true
    
    # Process each service in the backup
    local restored_count=0
    local skipped_count=0
    
    for service_backup_dir in "$temp_dir/$backup_dir"*/; do
        if [ ! -d "$service_backup_dir" ]; then
            continue
        fi
        
        local service_name=$(basename "$service_backup_dir")
        local target_service_dir="services/$service_name"
        
        # Check if .env file exists in backup
        if [ ! -f "$service_backup_dir/.env" ]; then
            print_warning "No .env file found for service: $service_name"
            continue
        fi
        
        # Create service directory if it doesn't exist
        if [ ! -d "$target_service_dir" ]; then
            print_warning "Service directory doesn't exist: $target_service_dir"
            print_info "Creating directory: $target_service_dir"
            mkdir -p "$target_service_dir"
        fi
        
        # Backup existing .env if it exists
        if [ -f "$target_service_dir/.env" ]; then
            local backup_suffix=$(date +"%Y%m%d_%H%M%S")
            cp "$target_service_dir/.env" "$target_service_dir/.env.backup.$backup_suffix"
            print_info "Backed up existing .env for $service_name to .env.backup.$backup_suffix"
        fi
        
        # Copy .env file
        cp "$service_backup_dir/.env" "$target_service_dir/.env"
        print_success "Restored .env for service: $service_name"
        
        # Copy any additional config files
        for config_file in "$service_backup_dir"/*; do
            local filename=$(basename "$config_file")
            if [ "$filename" != ".env" ] && [ -f "$config_file" ]; then
                cp "$config_file" "$target_service_dir/"
                print_info "  Also restored: $filename"
            fi
        done
        
        ((restored_count++))
    done
    
    # Cleanup
    cleanup_temp "$temp_dir"
    
    # Summary
    echo ""
    print_success "Restoration completed!"
    print_info "Services restored: $restored_count"
    
    if [ $restored_count -gt 0 ]; then
        echo ""
        print_info "You may want to restart services to pick up the new configuration:"
        print_info "  ./dev.sh stop && ./dev.sh start"
    fi
}

cleanup_temp() {
    local temp_dir="$1"
    if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

validate_environment() {
    # Check if we're in the right directory
    if [ ! -d "services" ]; then
        print_error "This script must be run from the Backend directory"
        print_error "Expected to find 'services/' directory"
        exit 1
    fi
    
    # Check for required tools
    if ! command -v zip > /dev/null 2>&1; then
        print_error "zip command not found. Please install zip utility."
        exit 1
    fi
    
    if ! command -v unzip > /dev/null 2>&1; then
        print_error "unzip command not found. Please install unzip utility."
        exit 1
    fi
}

# Main function
main() {
    # Parse arguments
    case "${1:-}" in
        -h|--help)
            print_usage
            exit 0
            ;;
        "")
            # No arguments - create backup
            validate_environment
            backup_env_files
            ;;
        *)
            # Zip file provided - restore
            validate_environment
            restore_env_files "$1"
            ;;
    esac
}

main "$@"
