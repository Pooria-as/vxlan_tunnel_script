#!/bin/bash

# ============================================
# COLOR DEFINITIONS
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# ============================================
# BANNER
# ============================================
show_banner() {
    echo -e "${RED}
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║  ██╗   ██╗██╗  ██╗██╗      █████╗ ███╗   ██╗    ████████╗██╗   ██╗███╗   ██╗███╗   ██╗███████╗██╗
║  ██║   ██║╚██╗██╔╝██║     ██╔══██╗████╗  ██║    ╚══██╔══╝██║   ██║████╗  ██║████╗  ██║██╔════╝██║
║  ██║   ██║ ╚███╔╝ ██║     ███████║██╔██╗ ██║       ██║   ██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██║
║  ╚██╗ ██╔╝ ██╔██╗ ██║     ██╔══██║██║╚██╗██║       ██║   ██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║
║   ╚████╔╝ ██╔╝ ██╗███████╗██║  ██║██║ ╚████║       ██║   ╚██████╔╝██║ ╚████║██║ ╚████║███████╗███████╗
║    ╚═══╝  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝       ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝
║                                                                      ║
║                    VXLAN TUNNEL MANAGEMENT SUITE                      ║
║                           Version 3.0                                ║
║                                                                      ║
║                  Developed by: ${GREEN}Pooria_A${RED}                         ║
║                  GitHub: ${GREEN}https://github.com/Pooria-as${RED}            ║
║                  ★ Don't forget to star the repo! ★                   ║
╚══════════════════════════════════════════════════════════════════════╝
${NC}"
}

show_footer() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}💡 Developed by Pooria_A${NC}"
    echo -e "${GREEN}🔗 GitHub: https://github.com/Pooria-as${NC}"
    echo -e "${YELLOW}⭐ If you find this useful, please star the repo!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
}

# ============================================
# FORMAT BYTES TO HUMAN READABLE
# ============================================
format_bytes() {
    local bytes=$1
    local decimals=${2:-2}
    
    # Remove any non-numeric characters
    bytes=$(echo "$bytes" | sed 's/[^0-9]//g')
    
    # If empty or zero
    if [[ -z "$bytes" || "$bytes" == "0" ]]; then
        echo "0 B"
        return
    fi
    
    # Convert to number
    bytes=$(echo "$bytes" | sed 's/^0*//')
    if [[ -z "$bytes" ]]; then
        echo "0 B"
        return
    fi
    
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$(echo "scale=$decimals; $bytes/1073741824" | bc 2>/dev/null || echo "0") GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(echo "scale=$decimals; $bytes/1048576" | bc 2>/dev/null || echo "0") MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(echo "scale=$decimals; $bytes/1024" | bc 2>/dev/null || echo "0") KB"
    else
        echo "${bytes} B"
    fi
}

# ============================================
# DETECT NETWORK INFO
# ============================================
detect_network() {
    MAIN_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    MAIN_IP=$(ip -4 addr show dev "$MAIN_IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
    MAIN_GW=$(ip route | grep default | awk '{print $3}' | head -n1)
    
    echo -e "${GREEN}✓ Detected Interface:${NC} $MAIN_IFACE"
    echo -e "${GREEN}✓ Detected IP:${NC}       $MAIN_IP"
    echo -e "${GREEN}✓ Detected Gateway:${NC}  $MAIN_GW"
}

# ============================================
# CHECK VXLAN STATUS
# ============================================
check_vxlan_status() {
    local dev=$1
    local status="DOWN"
    local port="N/A"
    local tx=0
    local rx=0
    local bytes_tx=0
    local bytes_rx=0
    local vxlan_id=""
    local ip_addr=""
    local peer_ip=""
    
    if ip link show "$dev" &>/dev/null; then
        # Check if interface is UP using multiple methods
        local link_state=$(ip link show "$dev" 2>/dev/null)
        
        # Method 1: Check for "state UP"
        if echo "$link_state" | grep -q "state UP"; then
            status="${GREEN}UP${NC}"
        # Method 2: Check for "UP" flag
        elif echo "$link_state" | grep -q "UP" && echo "$link_state" | grep -q "LOWER_UP"; then
            status="${GREEN}UP${NC}"
        # Method 3: Check /sys
        elif [[ -f "/sys/class/net/$dev/operstate" ]]; then
            local operstate=$(cat "/sys/class/net/$dev/operstate" 2>/dev/null)
            if [[ "$operstate" == "up" ]]; then
                status="${GREEN}UP${NC}"
            else
                status="${RED}DOWN${NC}"
            fi
        else
            status="${RED}DOWN${NC}"
        fi
        
        # Get port from VXLAN configuration
        if ip -d link show "$dev" 2>/dev/null | grep -q "dstport"; then
            port=$(ip -d link show "$dev" | grep -oP 'dstport \K\d+' | head -n1)
        fi
        
        # Get VXLAN ID
        if ip -d link show "$dev" 2>/dev/null | grep -q "id"; then
            vxlan_id=$(ip -d link show "$dev" | grep -oP 'id \K\d+' | head -n1)
        fi
        
        # Get TX/RX stats from ip command
        local stats=$(ip -s link show "$dev" 2>/dev/null)
        if echo "$stats" | grep -A1 "RX:" | tail -n1 | grep -q "[0-9]"; then
            bytes_rx=$(echo "$stats" | grep -A1 "RX:" | tail -n1 | awk '{print $1}' 2>/dev/null | sed 's/,//g')
            bytes_tx=$(echo "$stats" | grep -A1 "TX:" | tail -n1 | awk '{print $1}' 2>/dev/null | sed 's/,//g')
            rx=$(echo "$stats" | grep -A1 "RX:" | tail -n1 | awk '{print $2}' 2>/dev/null | sed 's/,//g')
            tx=$(echo "$stats" | grep -A1 "TX:" | tail -n1 | awk '{print $2}' 2>/dev/null | sed 's/,//g')
        fi
        
        # If stats are empty, try /sys
        if [[ -z "${bytes_rx//[0-9]/}" || "$bytes_rx" == "0" ]] && [[ -f "/sys/class/net/$dev/statistics/rx_bytes" ]]; then
            bytes_rx=$(cat "/sys/class/net/$dev/statistics/rx_bytes" 2>/dev/null | sed 's/[^0-9]//g')
            bytes_tx=$(cat "/sys/class/net/$dev/statistics/tx_bytes" 2>/dev/null | sed 's/[^0-9]//g')
            rx=$(cat "/sys/class/net/$dev/statistics/rx_packets" 2>/dev/null | sed 's/[^0-9]//g')
            tx=$(cat "/sys/class/net/$dev/statistics/tx_packets" 2>/dev/null | sed 's/[^0-9]//g')
        fi
        
        # Get IP address
        ip_addr=$(ip -4 addr show "$dev" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -n1)
        if [[ -z "$ip_addr" ]]; then
            ip_addr=$(ip addr show "$dev" 2>/dev/null | grep -E "inet " | awk '{print $2}' | head -n1)
        fi
        
        # Get peer IP
        peer_ip=$(ip -d link show "$dev" 2>/dev/null | grep -oP 'remote \K\d+(\.\d+){3}' | head -n1)
        
    else
        status="${RED}NOT FOUND${NC}"
    fi
    
    # Set global variables
    VXLAN_STATUS="${status}"
    VXLAN_PORT="${port:-N/A}"
    VXLAN_TX="${tx:-0}"
    VXLAN_RX="${rx:-0}"
    VXLAN_BYTES_TX="${bytes_tx:-0}"
    VXLAN_BYTES_RX="${bytes_rx:-0}"
    VXLAN_IP_ADDR="${ip_addr:-N/A}"
    VXLAN_PEER_IP="${peer_ip:-N/A}"
    VXLAN_ID_DETECTED="${vxlan_id:-N/A}"
}

# ============================================
# ADD IPTABLES RULES - DYNAMIC
# ============================================
add_iptables_rules() {
    local vxlan_dev=$1
    local main_iface=$2
    local main_ip=$3
    local main_gw=$4
    
    echo -e "\n${YELLOW}Adding iptables rules...${NC}"
    
    # Enable IP forwarding
    sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
    sudo sysctl -p > /dev/null 2>&1
    
    # Check if tun0 exists (OpenVPN)
    if ip link show tun0 &>/dev/null; then
        echo "  Adding rules for tun0..."
        sudo iptables -A FORWARD -i tun0 -o "$vxlan_dev" -j ACCEPT 2>/dev/null || true
        sudo iptables -A FORWARD -i "$vxlan_dev" -o tun0 -j ACCEPT 2>/dev/null || true
    fi
    
    # Check if wg0 exists (WireGuard)
    if ip link show wg0 &>/dev/null; then
        echo "  Adding rules for wg0..."
        sudo iptables -A FORWARD -i wg0 -o "$vxlan_dev" -j ACCEPT 2>/dev/null || true
        sudo iptables -A FORWARD -i "$vxlan_dev" -o wg0 -j ACCEPT 2>/dev/null || true
    fi
    
    # Add rules for main interface
    echo "  Adding rules for $main_iface..."
    sudo iptables -A FORWARD -i "$main_iface" -o "$vxlan_dev" -j ACCEPT 2>/dev/null || true
    sudo iptables -A FORWARD -i "$vxlan_dev" -o "$main_iface" -j ACCEPT 2>/dev/null || true
    
    # Add NAT masquerade for VXLAN
    echo "  Adding NAT masquerade..."
    sudo iptables -t nat -A POSTROUTING -o "$vxlan_dev" -j MASQUERADE 2>/dev/null || true
    
    echo -e "${GREEN}✓ iptables rules applied!${NC}"
}

# ============================================
# QUICK STATUS - WITH HUMAN READABLE TRAFFIC
# ============================================
quick_status() {
    clear
    show_banner
    
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}                  📊 QUICK VXLAN STATUS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}\n"
    
    # Get all VXLAN interfaces
    local vxlan_ifaces=$(ip -d link show type vxlan 2>/dev/null | grep -oP '^[0-9]+: \K[^:]+')
    
    if [[ -z "$vxlan_ifaces" ]]; then
        echo -e "${YELLOW}⚠ No VXLAN interfaces found.${NC}"
        echo -e "${YELLOW}   Use option 4 or 5 to start a tunnel.${NC}\n"
        show_footer
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BOLD}${WHITE}Active VXLAN Interfaces:${NC}\n"
    
    local count=0
    for iface in $vxlan_ifaces; do
        count=$((count + 1))
        check_vxlan_status "$iface"
        
        echo -e "${BOLD}${GREEN}[$count]${NC} ${BOLD}Interface:${NC} $iface"
        echo -e "    ${WHITE}Status:${NC}      $VXLAN_STATUS"
        echo -e "    ${WHITE}VXLAN ID:${NC}    ${VXLAN_ID_DETECTED:-N/A}"
        echo -e "    ${WHITE}Port:${NC}        ${VXLAN_PORT:-N/A}"
        echo -e "    ${WHITE}IP:${NC}          ${VXLAN_IP_ADDR:-N/A}"
        echo -e "    ${WHITE}Peer:${NC}        ${VXLAN_PEER_IP:-N/A}"
        echo -e "    ${WHITE}TX:${NC}          ${VXLAN_TX:-0} packets ($(format_bytes ${VXLAN_BYTES_TX:-0}))"
        echo -e "    ${WHITE}RX:${NC}          ${VXLAN_RX:-0} packets ($(format_bytes ${VXLAN_BYTES_RX:-0}))"
        echo -e "    ${CYAN}───────────────────────────────────────────────────────${NC}"
    done
    
    show_footer
    read -p "Press Enter to continue..."
}

# ============================================
# REAL-TIME MONITOR - WITH HUMAN READABLE TRAFFIC
# ============================================
monitor_vxlan() {
    clear
    show_banner
    
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}                    📡 REAL-TIME VXLAN MONITOR${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}\n"
    
    local vxlan_ifaces=$(ip -d link show type vxlan 2>/dev/null | grep -oP '^[0-9]+: \K[^:]+')
    
    if [[ -z "$vxlan_ifaces" ]]; then
        echo -e "${YELLOW}⚠ No VXLAN interfaces found.${NC}"
        show_footer
        read -p "Press Enter to continue..."
        return
    fi
    
    local monitor_iface=$(echo "$vxlan_ifaces" | head -n1)
    
    # Store previous stats for rate calculation
    local prev_rx=0
    local prev_tx=0
    local prev_time=$(date +%s)
    
    while true; do
        clear
        show_banner
        echo -e "${BOLD}${WHITE}📊 VXLAN Monitor - $monitor_iface${NC}"
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────${NC}"
        
        check_vxlan_status "$monitor_iface"
        
        # Calculate rate
        local current_time=$(date +%s)
        local time_diff=$((current_time - prev_time))
        local rx_rate=0
        local tx_rate=0
        
        if [[ $time_diff -gt 0 ]]; then
            rx_rate=$(( (${VXLAN_BYTES_RX:-0} - prev_rx) / time_diff ))
            tx_rate=$(( (${VXLAN_BYTES_TX:-0} - prev_tx) / time_diff ))
        fi
        
        echo -e "${WHITE}Status:${NC}         $VXLAN_STATUS"
        echo -e "${WHITE}Port:${NC}           ${VXLAN_PORT:-N/A}"
        echo -e "${WHITE}VXLAN ID:${NC}       ${VXLAN_ID_DETECTED:-N/A}"
        echo -e "${WHITE}IP Address:${NC}     ${VXLAN_IP_ADDR:-N/A}"
        echo -e "${WHITE}Peer IP:${NC}        ${VXLAN_PEER_IP:-N/A}"
        
        echo -e "\n${WHITE}📈 Traffic Statistics:${NC}"
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────${NC}"
        echo -e "${GREEN}⬇ RX:${NC} $(format_bytes ${VXLAN_BYTES_RX:-0}) (${VXLAN_RX:-0} packets)"
        echo -e "${BLUE}⬆ TX:${NC} $(format_bytes ${VXLAN_BYTES_TX:-0}) (${VXLAN_TX:-0} packets)"
        
        echo -e "\n${WHITE}📊 Transfer Rate:${NC}"
        echo -e "${GREEN}⬇ RX Rate:${NC} $(format_bytes $rx_rate)/s"
        echo -e "${BLUE}⬆ TX Rate:${NC} $(format_bytes $tx_rate)/s"
        
        if [[ ${VXLAN_RX:-0} -gt 0 || ${VXLAN_TX:-0} -gt 0 ]]; then
            echo -e "${WHITE}📊 Status:${NC} ${GREEN}Active Traffic${NC}"
        else
            echo -e "${WHITE}📊 Status:${NC} ${YELLOW}Idle${NC}"
        fi
        
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────${NC}"
        echo -e "${YELLOW}Last updated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
        show_footer
        
        # Update previous values
        prev_rx=${VXLAN_BYTES_RX:-0}
        prev_tx=${VXLAN_BYTES_TX:-0}
        prev_time=$current_time
        
        sleep 2
    done
}

# ============================================
# TEST TUNNEL - WITH SPEED AND TIME
# ============================================
test_tunnel() {
    clear
    show_banner
    
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}                  🌐 TEST TUNNEL CONNECTION${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}\n"
    
    local vxlan_ifaces=$(ip -d link show type vxlan 2>/dev/null | grep -oP '^[0-9]+: \K[^:]+')
    
    if [[ -z "$vxlan_ifaces" ]]; then
        echo -e "${YELLOW}⚠ No VXLAN interfaces found.${NC}"
        show_footer
        read -p "Press Enter to continue..."
        return
    fi
    
    local test_iface=$(echo "$vxlan_ifaces" | head -n1)
    
    # Check if interface exists and is UP
    local is_up=false
    if ip link show "$test_iface" | grep -q "state UP"; then
        is_up=true
    elif ip link show "$test_iface" | grep -q "UP" && ip link show "$test_iface" | grep -q "LOWER_UP"; then
        is_up=true
    elif [[ -f "/sys/class/net/$test_iface/operstate" ]] && [[ "$(cat /sys/class/net/$test_iface/operstate 2>/dev/null)" == "up" ]]; then
        is_up=true
    fi
    
    if ! $is_up; then
        echo -e "${RED}✗ VXLAN interface $test_iface is DOWN!${NC}"
        echo -e "${YELLOW}   But you can still test connectivity...${NC}"
    else
        echo -e "${GREEN}✓ VXLAN interface $test_iface is UP${NC}"
    fi
    
    local peer_ip=$(ip -d link show "$test_iface" 2>/dev/null | grep -oP 'remote \K\d+(\.\d+){3}' | head -n1)
    
    if [[ -n "$peer_ip" ]]; then
        echo -e "\n${WHITE}Testing ping to peer:${NC} $peer_ip"
        local ping_start=$(date +%s%N)
        if ping -c 3 -W 2 "$peer_ip" &>/dev/null; then
            local ping_end=$(date +%s%N)
            local ping_time=$((($ping_end - $ping_start) / 1000000))
            echo -e "${GREEN}✓ Peer is reachable!${NC} ${YELLOW}(${ping_time}ms)${NC}"
        else
            echo -e "${RED}✗ Peer is NOT reachable!${NC}"
        fi
    fi
    
    echo -e "\n${WHITE}Testing internet connectivity...${NC}"
    echo -e "${YELLOW}Downloading youtube.com homepage...${NC}\n"
    
    local temp_file="/tmp/youtube_test.html"
    local start_time=$(date +%s%N)
    
    # Download with wget and capture output
    if wget -q --timeout=15 --tries=2 -O "$temp_file" "https://www.youtube.com" 2>/dev/null; then
        local end_time=$(date +%s%N)
        
        # Calculate time taken
        local time_taken=$((($end_time - $start_time) / 1000000)) # milliseconds
        local time_sec=$(echo "scale=2; $time_taken / 1000" | bc 2>/dev/null || echo "0")
        
        # Get file size
        local file_size=$(stat -c%s "$temp_file" 2>/dev/null || echo "0")
        local file_size_human=$(format_bytes "$file_size")
        
        # Calculate speed in bytes per second
        local speed=0
        if [[ $time_taken -gt 0 ]]; then
            speed=$(echo "scale=2; ($file_size * 1000) / $time_taken" | bc 2>/dev/null || echo "0")
        fi
        
        echo -e "${GREEN}✅ SUCCESS! Tunnel is working!${NC}"
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────${NC}"
        echo -e "  ${WHITE}File downloaded:${NC} $temp_file"
        echo -e "  ${WHITE}File size:${NC}       $file_size_human"
        echo -e "  ${WHITE}Time taken:${NC}      ${time_sec}s (${time_taken}ms)"
        
        # Show speed in human readable
        local speed_float=$(echo "$speed" | cut -d'.' -f1)
        if [[ -z "$speed_float" ]]; then
            speed_float=0
        fi
        
        if [[ $speed_float -gt 1048576 ]]; then
            local speed_mb=$(echo "scale=2; $speed / 1048576" | bc 2>/dev/null || echo "0")
            echo -e "  ${WHITE}Download speed:${NC} ${speed_mb} MB/s"
        elif [[ $speed_float -gt 1024 ]]; then
            local speed_kb=$(echo "scale=2; $speed / 1024" | bc 2>/dev/null || echo "0")
            echo -e "  ${WHITE}Download speed:${NC} ${speed_kb} KB/s"
        else
            echo -e "  ${WHITE}Download speed:${NC} ${speed} B/s"
        fi
        
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────${NC}"
        
        # Show preview
        echo -e "\n${WHITE}📄 Content preview (first 3 lines):${NC}"
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────${NC}"
        head -3 "$temp_file" 2>/dev/null | head -c 200
        echo -e "\n${CYAN}───────────────────────────────────────────────────────────────────────${NC}"
        
        rm -f "$temp_file"
    else
        local end_time=$(date +%s%N)
        local time_taken=$((($end_time - $start_time) / 1000000))
        local time_sec=$(echo "scale=2; $time_taken / 1000" | bc 2>/dev/null || echo "0")
        
        echo -e "${RED}❌ FAILED! Tunnel is NOT working properly.${NC}"
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────${NC}"
        echo -e "  ${WHITE}Time taken:${NC} ${time_sec}s (${time_taken}ms)"
        echo -e "  ${YELLOW}Status:${NC} Connection timeout or failed"
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────${NC}"
        
        echo -e "\n${YELLOW}Possible issues:${NC}"
        echo -e "  🔴 Routing not configured correctly"
        echo -e "  🔴 Peer is not reachable"
        echo -e "  🔴 Firewall blocking traffic"
        echo -e "  🔴 DNS resolution issues"
        echo -e "  🔴 No internet connectivity through tunnel"
    fi
    
    show_footer
    read -p "Press Enter to continue..."
}

# ============================================
# STOP VXLAN
# ============================================
stop_vxlan() {
    clear
    show_banner
    
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}                    🛑 STOPPING VXLAN TUNNEL${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}\n"
    
    local vxlan_ifaces=$(ip -d link show type vxlan 2>/dev/null | grep -oP '^[0-9]+: \K[^:]+')
    
    if [[ -z "$vxlan_ifaces" ]]; then
        echo -e "${YELLOW}⚠ No VXLAN interfaces found.${NC}"
        show_footer
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${WHITE}Found VXLAN interfaces:${NC}"
    local count=0
    for iface in $vxlan_ifaces; do
        count=$((count + 1))
        echo -e "  ${GREEN}$count)${NC} $iface"
    done
    echo -e "  ${GREEN}0)${NC} Cancel"
    echo
    
    read -p "Select interface to stop [0-$count]: " choice
    
    if [[ "$choice" == "0" ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        show_footer
        read -p "Press Enter to continue..."
        return
    fi
    
    local selected_iface=$(echo "$vxlan_ifaces" | sed -n "${choice}p")
    
    if [[ -n "$selected_iface" ]]; then
        echo "Stopping $selected_iface..."
        sudo ip link set down dev "$selected_iface"
        sleep 1
        sudo ip link del "$selected_iface"
        echo -e "${GREEN}✓ VXLAN tunnel $selected_iface stopped successfully!${NC}"
    else
        echo -e "${RED}Invalid selection!${NC}"
    fi
    
    show_footer
    read -p "Press Enter to continue..."
}

# ============================================
# YOUR EXACT CLIENT SCRIPT + IPTABLES
# ============================================
run_client() {
    clear
    show_banner
    
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}                    🚀 STARTING VXLAN CLIENT${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}\n"
    
    set -e
    
    prompt_default() {
        local prompt_msg=$1
        local default_val=$2
        local input
        
        read -p "$prompt_msg [$default_val]: " input
        if [ -z "$input" ]; then
            echo "$default_val"
        else
            echo "$input"
        fi
    }
    
    main_iface=$(ip route | grep default | awk '{print $5}' | head -n1)
    main_ip=$(ip -4 addr show dev "$main_iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
    main_gw=$(ip route | grep default | awk '{print $3}' | head -n1)
    
    echo "Detected main interface: $main_iface"
    echo "Detected IP address:    $main_ip"
    echo "Detected Gateway:       $main_gw"
    echo
    
    VXLAN_REMOTE_IP=$(prompt_default "Enter VXLAN remote IP" "202.133.88.9")
    VXLAN_ID=$(prompt_default "Enter VXLAN ID" "1200")
    VXLAN_DEV=$(prompt_default "Enter VXLAN device name" "vxlan02")
    VXLAN_DSTPORT=$(prompt_default "Enter VXLAN destination port" "9080")
    VXLAN_MTU=$(prompt_default "Enter VXLAN MTU" "1420")
    VXLAN_ADDR=$(prompt_default "Enter VXLAN IP address with mask" "2.2.2.9/30")
    VXLAN_PEER=$(prompt_default "Enter VXLAN peer IP" "2.2.2.10")
    TABLE_DIRECT=$(prompt_default "Enter routing table name" "DIRECT")
    
    echo
    echo "Summary of parameters:"
    echo "Main interface: $main_iface"
    echo "Main IP:        $main_ip"
    echo "Gateway:        $main_gw"
    echo "VXLAN Remote IP:$VXLAN_REMOTE_IP"
    echo "VXLAN ID:       $VXLAN_ID"
    echo "VXLAN Device:   $VXLAN_DEV"
    echo "VXLAN DstPort:  $VXLAN_DSTPORT"
    echo "VXLAN MTU:      $VXLAN_MTU"
    echo "VXLAN Address:  $VXLAN_ADDR"
    echo "VXLAN Peer IP:  $VXLAN_PEER"
    echo "Routing Table:  $TABLE_DIRECT"
    echo
    
    if [ ! -f /etc/rules.v4 ]; then
        echo "/etc/rules.v4 does not exist."
        read -p "Do you want to create an empty /etc/rules.v4 file? (y/n): " create_rules
        if [[ "$create_rules" =~ ^[Yy]$ ]]; then
            sudo touch /etc/rules.v4
            echo "Created /etc/rules.v4"
        else
            echo "Please create /etc/rules.v4 and re-run the script."
            exit 1
        fi
    fi
    
    echo "Applying network configuration..."
    
    if ! grep -q "^200[[:space:]]\+$TABLE_DIRECT" /etc/iproute2/rt_tables 2>/dev/null; then
        echo "200 $TABLE_DIRECT" >> /etc/iproute2/rt_tables
    fi
    
    sudo ip route add default via "$main_gw" dev "$main_iface" src "$main_ip" table "$TABLE_DIRECT" 2>/dev/null || true
    sudo ip rule add from "$main_ip" table "$TABLE_DIRECT" prio 1 2>/dev/null || true
    
    if ip link show "$VXLAN_DEV" &>/dev/null; then
        echo "VXLAN device $VXLAN_DEV exists, deleting it first..."
        sudo ip link del "$VXLAN_DEV"
    fi
    
    sudo ip link add "$VXLAN_DEV" type vxlan id "$VXLAN_ID" local "$main_ip" remote "$VXLAN_REMOTE_IP" dstport "$VXLAN_DSTPORT"
    sudo ip link set mtu "$VXLAN_MTU" dev "$VXLAN_DEV"
    sudo ip addr add "$VXLAN_ADDR" dev "$VXLAN_DEV"
    sudo ip link set up dev "$VXLAN_DEV"
    sudo ip route add 0.0.0.0/1 via "$VXLAN_PEER" 2>/dev/null || true
    sudo ip route add 128.0.0.0/1 via "$VXLAN_PEER" 2>/dev/null || true
    sudo iptables-restore < /etc/rules.v4 2>/dev/null || true
    
    add_iptables_rules "$VXLAN_DEV" "$main_iface" "$main_ip" "$main_gw"
    
    echo "Network configuration applied successfully."
    
    echo -e "\n${GREEN}✓ VXLAN Client started!${NC}"
    check_vxlan_status "$VXLAN_DEV"
    echo -e "${GREEN}✓ Status: $VXLAN_STATUS${NC}"
    echo -e "${GREEN}✓ Port: ${VXLAN_PORT:-$VXLAN_DSTPORT}${NC}"
    
    show_footer
    read -p "Press Enter to continue..."
}

# ============================================
# YOUR EXACT SERVER SCRIPT + IPTABLES
# ============================================
run_server() {
    clear
    show_banner
    
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}                    🚀 STARTING VXLAN SERVER${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}\n"
    
    set -euo pipefail
    
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Use sudo." >&2
        exit 1
    fi
    
    get_default_network_info() {
        local iface ip gw
        iface=$(ip route | awk '/default/ {print $5; exit}')
        if [[ -z "$iface" ]]; then
            echo "Error: Could not detect default network interface." >&2
            exit 1
        fi
        ip=$(ip -4 addr show "$iface" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
        if [[ -z "$ip" ]]; then
            echo "Error: Could not detect IP address for interface $iface." >&2
            exit 1
        fi
        gw=$(ip route | awk '/default/ {print $3; exit}')
        if [[ -z "$gw" ]]; then
            echo "Error: Could not detect default gateway." >&2
            exit 1
        fi
        echo "$iface" "$ip" "$gw"
    }
    
    prompt_remote_ip() {
        local ip
        while true; do
            read -rp "Enter remote IP address for VXLAN (e.g. 87.107.162.13): " ip
            if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                IFS='.' read -r -a octets <<< "$ip"
                valid=true
                for octet in "${octets[@]}"; do
                    if ((octet < 0 || octet > 255)); then
                        valid=false
                        break
                    fi
                done
                if $valid; then
                    echo "$ip"
                    return
                fi
            fi
            echo "Invalid IP format. Please try again."
        done
    }
    
    enable_ip_forwarding() {
        if [[ $(sysctl -n net.ipv4.ip_forward) -ne 1 ]]; then
            echo "Enabling IP forwarding..."
            sysctl -w net.ipv4.ip_forward=1
        else
            echo "IP forwarding already enabled."
        fi
    }
    
    add_routing_table_entry() {
        local entry="200 DIRECT"
        if ! grep -q "^$entry" /etc/iproute2/rt_tables; then
            echo "$entry" >> /etc/iproute2/rt_tables
            echo "Added routing table entry: $entry"
        else
            echo "Routing table entry '$entry' already exists."
        fi
    }
    
    echo "Detecting default network interface, IP, and gateway..."
    read -r DEFAULT_IFACE DEFAULT_IP DEFAULT_GW < <(get_default_network_info)
    
    echo "Detected interface: $DEFAULT_IFACE"
    echo "Detected local IP: $DEFAULT_IP"
    echo "Detected gateway: $DEFAULT_GW"
    
    REMOTE_IP=$(prompt_remote_ip)
    
    LOCAL_IP="$DEFAULT_IP"
    GATEWAY_IP="$DEFAULT_GW"
    INTERFACE="$DEFAULT_IFACE"
    VXLAN_ID=1200
    VXLAN_IP="2.2.2.10/30"
    VXLAN_MTU=1420
    VXLAN_DSTPORT=5890
    NAT_INTERFACE="$INTERFACE"
    NAT_SUBNET="2.2.2.8/30"
    TABLE_NAME="DIRECT"
    VXLAN_DEV="vxlan${VXLAN_ID}"
    
    echo
    echo "Using parameters:"
    echo "  Local IP: $LOCAL_IP"
    echo "  Gateway IP: $GATEWAY_IP"
    echo "  Interface: $INTERFACE"
    echo "  Remote IP: $REMOTE_IP"
    echo "  VXLAN ID: $VXLAN_ID"
    echo "  VXLAN IP: $VXLAN_IP"
    echo "  VXLAN MTU: $VXLAN_MTU"
    echo "  VXLAN DSTPORT: $VXLAN_DSTPORT"
    echo "  NAT Interface: $NAT_INTERFACE"
    echo "  NAT Subnet: $NAT_SUBNET"
    echo
    
    add_routing_table_entry
    enable_ip_forwarding
    
    if ! ip route show table "$TABLE_NAME" | grep -q "^default via $GATEWAY_IP dev $INTERFACE src $LOCAL_IP"; then
        echo "Adding IP route to table $TABLE_NAME..."
        ip route add default via "$GATEWAY_IP" dev "$INTERFACE" src "$LOCAL_IP" table "$TABLE_NAME"
    else
        echo "IP route for table $TABLE_NAME already exists, skipping."
    fi
    
    if ! ip rule show | grep -q "from $LOCAL_IP lookup $TABLE_NAME"; then
        echo "Adding IP rule from $LOCAL_IP to table $TABLE_NAME..."
        ip rule add from "$LOCAL_IP" table "$TABLE_NAME" prio 1
    else
        echo "IP rule from $LOCAL_IP to table $TABLE_NAME already exists, skipping."
    fi
    
    if ! ip link show "$VXLAN_DEV" &>/dev/null; then
        echo "Creating VXLAN interface $VXLAN_DEV..."
        ip link add "$VXLAN_DEV" type vxlan id "$VXLAN_ID" local "$LOCAL_IP" remote "$REMOTE_IP" dstport "$VXLAN_DSTPORT"
    else
        echo "VXLAN interface $VXLAN_DEV already exists, skipping creation."
    fi
    
    echo "Setting VXLAN MTU to $VXLAN_MTU..."
    ip link set mtu "$VXLAN_MTU" dev "$VXLAN_DEV"
    
    if ! ip addr show dev "$VXLAN_DEV" | grep -qw "${VXLAN_IP%/*}"; then
        echo "Assigning IP $VXLAN_IP to $VXLAN_DEV..."
        ip addr add "$VXLAN_IP" dev "$VXLAN_DEV"
    else
        echo "$VXLAN_DEV already has IP $VXLAN_IP assigned, skipping."
    fi
    
    echo "Bringing up VXLAN interface $VXLAN_DEV..."
    ip link set up dev "$VXLAN_DEV"
    
    if [ ! -f /etc/rules.v4 ]; then
        echo "/etc/rules.v4 not found, creating empty file."
        touch /etc/rules.v4
    fi
    
    echo "Restoring iptables rules from /etc/rules.v4..."
    iptables-restore < /etc/rules.v4 2>/dev/null || true
    
    if ! iptables -t nat -C POSTROUTING -s "$NAT_SUBNET" -o "$NAT_INTERFACE" -j MASQUERADE &>/dev/null; then
        echo "Adding NAT masquerade rule for $NAT_SUBNET on $NAT_INTERFACE..."
        iptables -t nat -A POSTROUTING -s "$NAT_SUBNET" -o "$NAT_INTERFACE" -j MASQUERADE
    else
        echo "NAT masquerade rule already exists, skipping."
    fi
    
    add_iptables_rules "$VXLAN_DEV" "$INTERFACE" "$LOCAL_IP" "$GATEWAY_IP"
    
    echo
    echo "VXLAN tunnel setup completed successfully!"
    
    check_vxlan_status "$VXLAN_DEV"
    echo -e "\n${GREEN}✓ Status: $VXLAN_STATUS${NC}"
    echo -e "${GREEN}✓ Port: ${VXLAN_PORT:-$VXLAN_DSTPORT}${NC}"
    
    show_footer
    read -p "Press Enter to continue..."
}

# ============================================
# MAIN MENU
# ============================================
main_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}${WHITE}                        📋 MAIN MENU${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
        
        echo -e "\n${BOLD}${GREEN}📊 STATUS & MONITOR${NC}"
        echo -e "  ${GREEN}[1]${NC} Quick Status - Show all VXLAN interfaces"
        echo -e "  ${GREEN}[2]${NC} Real-time Monitor ${YELLOW}(with transfer rate)${NC}"
        echo -e "  ${GREEN}[3]${NC} Test Tunnel ${YELLOW}(with speed & time)${NC}"
        
        echo -e "\n${BOLD}${PURPLE}🚀 TUNNEL OPERATIONS${NC}"
        echo -e "  ${GREEN}[4]${NC} Start VXLAN Client ${YELLOW}(+ iptables rules)${NC}"
        echo -e "  ${GREEN}[5]${NC} Start VXLAN Server ${YELLOW}(+ iptables rules)${NC}"
        echo -e "  ${GREEN}[6]${NC} Stop VXLAN Tunnel"
        
        echo -e "\n${BOLD}${RED}🔧 SYSTEM${NC}"
        echo -e "  ${GREEN}[0]${NC} Exit"
        
        echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
        show_footer
        echo
        
        read -p "Enter your choice [0-6]: " choice
        
        case $choice in
            1) quick_status ;;
            2) monitor_vxlan ;;
            3) test_tunnel ;;
            4) run_client ;;
            5) run_server ;;
            6) stop_vxlan ;;
            0)
                clear
                show_banner
                echo -e "\n${GREEN}Thank you for using VXLAN Tunnel Management Suite!${NC}"
                echo -e "${GREEN}Developed by Pooria_A${NC}"
                echo -e "${GREEN}🔗 https://github.com/Pooria-as${NC}"
                echo -e "${YELLOW}⭐ Please star the repo if you found this useful!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice!${NC}"
                sleep 1
                ;;
        esac
    done
}

# ============================================
# SCRIPT START
# ============================================

if [[ $EUDI -ne 0 ]]; then
    echo -e "${RED}This script must be run as root. Use sudo.${NC}" >&2
    exit 1
fi

main_menu
