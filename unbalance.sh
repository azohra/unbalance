#!/bin/bash

# Set strict mode
set -euo pipefail

# Configurable Parameters
disks=("/mnt/disk1" "/mnt/disk2" "/mnt/disk3" "/mnt/disk4")        # Array of disk mounts
log_file="$PWD/unbalance.log"                                      # Where to log the output     
run_id=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6)         # Generate a random job ID


# Create the log file
touch "$log_file"

# Function to print usage
print_usage() {
    echo "Usage: $0 <path>"
    echo "Example: $0 'movies/Inception'"
}

# Function for logging
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [$run_id] $1"
    echo -e "$message" | tee -a "$log_file"
    update_display
}

# Function to update display
update_display() {
    clear
    echo "Path: $target_path"
    echo "-------------------"
    echo "Logs: $log_file (ID: $run_id)"
    echo "-------------------"
    echo "Path Usage:"
    for i in "${!disks[@]}"; do
        local size=${disk_sizes[$i]:-0}
        if [ "$size" -eq 0 ]; then
            echo "${disks[$i]}: Not present"
        elif [ "${disks[$i]}" == "$largest_disk" ]; then
            echo "${disks[$i]}: $(numfmt --to=iec-i --suffix=B $size) (Largest)"
        else
            echo "${disks[$i]}: $(numfmt --to=iec-i --suffix=B $size)"
        fi
    done
    echo "-------------------"
    echo "Total data to move: $(numfmt --to=iec-i --suffix=B ${data_to_move:-0})"
    echo "-------------------"
    echo "Current operation: ${current_operation:-N/A}"
    echo "-------------------"
    echo "Recent Logs:"
    grep "$run_id" "$log_file" | tail -n 15 | sed 's/^/  /'
    echo "-------------------"
}

# Function to check disk space
check_disk_space() {
    local required_space=$1
    local dest_disk=$2
    local available_space
    available_space=$(df -B1 --output=avail "$dest_disk" | tail -n 1)

    if [ "$available_space" -lt "$required_space" ]; then
        log "❌ Not enough space on $dest_disk. Required: $(numfmt --to=iec-i --suffix=B $required_space), Available: $(numfmt --to=iec-i --suffix=B $available_space)"
        exit 1
    fi
}

# Function to check and install packages
check_and_install() {
    local packages=("rsync")

    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            echo "❌ $pkg is not installed. Please install $pkg and run the script again."
            exit 1
        fi
    done
}

# Function to prompt for confirmation
confirm_action() {
    local prompt="$1"
    read -p "$prompt (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Function to scan disks for the target path
scan_disks() {
    largest_size=0
    largest_disk=""
    total_size=0
    current_operation="Scanning disks"

    log "Starting disk scan for path"
    for i in "${!disks[@]}"; do
        disk="${disks[$i]}"
        if [ -d "$disk/$target_path" ]; then
            size=$(du -sb "$disk/$target_path" 2>/dev/null | cut -f1)
            size=${size:-0}
            disk_sizes[$i]=$size
            total_size=$((total_size + size))
            log "Path present on $disk: $(numfmt --to=iec-i --suffix=B $size)"
            if [ "$size" -gt "$largest_size" ]; then
                largest_size=$size
                largest_disk=$disk
            fi
        else
            log "Path not present on $disk"
            disk_sizes[$i]=0
        fi
    done

    current_operation="Checking data balance"
    data_to_move=$((total_size - largest_size))
    if [ "$data_to_move" -eq 0 ]; then
        log "✔️ Path is already unbalanced (or does not exist on any disk)"
        exit 0
    fi

    if [ -n "$largest_disk" ]; then
        log "Path is largest on $largest_disk with $(numfmt --to=iec-i --suffix=B $largest_size)"
        log "$(numfmt --to=iec-i --suffix=B $data_to_move) of data should move to $largest_disk"
    fi
}

# Function to move files from source disks to the largest disk
move_files() {
    for i in "${!disks[@]}"; do
        disk="${disks[$i]}"
        if [ "$disk" != "$largest_disk" ] && [ -d "$disk/$target_path" ]; then
            current_operation="Moving files from $disk to $largest_disk"
            
            log "Starting file transfer from $disk to $largest_disk"
            if ! rsync -avhXWE --numeric-ids --remove-source-files --progress --log-file="$log_file" "$disk/$target_path/" "$largest_disk/$target_path/"; then
                log "❌ rsync failed for $disk/$target_path"
                exit 1
                continue
            fi
            log "Completed file transfer from $disk to $largest_disk"
            
            current_operation="Removing empty directories from $disk"
            output=$(find "$disk/$target_path" -type d -empty -delete -print)

            # Check if the output is empty or not
            if [ -n "$output" ]; then
                log "Removed empty directories from $disk:\n$output"
            else
                log "No empty directories found in $disk/$target_path"
            fi
        fi
    done

    current_operation="Operation complete"
    log "All files for '$target_path' have been moved to $largest_disk"
}

# Main script logic
main() {
    check_and_install 

    if [ $# -eq 0 ]; then
        print_usage
        exit 1
    fi

    target_path="$1"
    declare -a disk_sizes
    current_operation=""

    log "🟢 Unbalance started for '$target_path'"
    scan_disks

    # Proceed with file moving if the largest disk is identified
    if [ -n "$largest_disk" ]; then
        check_disk_space "$data_to_move" "$largest_disk"
        
        if confirm_action "Proceed with moving files?"; then
            move_files
        else
            log "Operation cancelled by user"
        fi
    fi

    log "✔️ Path unbalanced successfully"
    exit 0
}

main "$@"
