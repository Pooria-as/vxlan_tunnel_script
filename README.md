# 🚀 VXLAN Tunnel Management Suite

<div align="center">

![Version](https://img.shields.io/badge/version-3.0-blue)
![Bash](https://img.shields.io/badge/bash-5.0+-green)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![License](https://img.shields.io/badge/license-MIT-orange)

**A powerful, all-in-one VXLAN tunnel management script with real-time monitoring, traffic statistics, and iptables integration**

</div>

---

## 📦 Quick Start

### One Line Install
```bash
bash <(curl -Ls https://raw.githubusercontent.com/Pooria-as/vxlan_tunnel_script/main/vxlan.sh)
```

### Alternative Methods
```bash
# Using wget
bash <(wget -qO- https://raw.githubusercontent.com/Pooria-as/vxlan_tunnel_script/main/vxlan.sh)

# Download and execute
curl -sSL https://raw.githubusercontent.com/Pooria-as/vxlan_tunnel_script/main/vxlan.sh | sudo bash

# Manual install
git clone https://github.com/Pooria-as/vxlan_tunnel_script.git
cd vxlan_tunnel_script
sudo chmod +x vxlan.sh
sudo ./vxlan.sh
```

---

## ✨ Features

| Category | Features |
|----------|----------|
| **📊 Status & Monitoring** | Real-time traffic stats, KB/MB/GB formatting, transfer rate, Active/Idle status |
| **🔧 Tunnel Management** | One-command setup, Client/Server modes, Auto-detection, Config persistence |
| **🌐 Testing & Debugging** | Ping test with response time, YouTube download test, Speed calculation |
| **🛡️ Security & Firewall** | Auto IP forwarding, iptables integration, NAT masquerade |

---

## 📋 Menu Options

| Option | Description |
|--------|-------------|
| `[1]` | **Quick Status** - Show all VXLAN interfaces with traffic stats |
| `[2]` | **Real-time Monitor** - Live traffic monitoring with transfer rates |
| `[3]` | **Test Tunnel** - Test connectivity with speed & time metrics |
| `[4]` | **Start Client** - Start VXLAN client with iptables rules |
| `[5]` | **Start Server** - Start VXLAN server with iptables rules |
| `[6]` | **Stop Tunnel** - Stop VXLAN tunnel |
| `[0]` | **Exit** - Exit the program |

---

## 📋 How to Use

### Step-by-Step Guide

#### 1. On the Server (Remote)
```bash
# Run the script
sudo ./vxlan.sh

# Select option [5] Start VXLAN Server
# Enter remote IP (Client's public IP)
```

#### 2. On the Client (Local)
```bash
# Run the script
sudo ./vxlan.sh

# Select option [4] Start VXLAN Client
# Enter remote IP (Server's public IP)
```

#### 3. Verify Connection
```bash
# Check status - Option [1]
# Test connectivity - Option [3]
```

---

## 📁 Configuration

### Configuration File: `/etc/vxlan_config.conf`
```bash
VXLAN_REMOTE_IP="5.6.7.8"          # Remote server IP
VXLAN_ID="1200"                     # VXLAN Network Identifier
VXLAN_DEV="vxlan02"                 # Interface name
VXLAN_DSTPORT="9080"                # Destination port
VXLAN_MTU="1420"                    # MTU size
VXLAN_ADDR="2.2.2.9/30"            # VXLAN IP address
VXLAN_PEER="2.2.2.10"              # Peer IP address
TABLE_DIRECT="DIRECT"               # Routing table name
```

---

## 🛠️ Requirements

### System Requirements
- **OS**: Linux (Ubuntu 18.04+, Debian 10+, CentOS 7+, RHEL 8+)
- **RAM**: 256MB minimum
- **Disk**: 50MB free space
- **Root Access**: Required

### Install Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install -y iproute2 iptables bridge-utils wget curl bc

# CentOS/RHEL
sudo yum install -y iproute iptables bridge-utils wget curl bc
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| **404: command not found** | Use correct URL: `bash <(curl -Ls https://raw.githubusercontent.com/Pooria-as/vxlan_tunnel_script/main/vxlan.sh)` |
| **Permission denied** | Run with sudo: `sudo ./vxlan.sh` |
| **VXLAN interface not created** | Load module: `sudo modprobe vxlan` |
| **No traffic through tunnel** | Check interface: `ip link show vxlan02` |
| **Can't ping peer** | Check firewall: `sudo iptables -L -n -v` |

---

## 📚 Understanding VXLAN

**VXLAN (Virtual Extensible LAN)** creates Layer 2 overlay networks over Layer 3 infrastructure.

### How It Works:
```
┌────────────┐         ┌────────────┐
│   Client   │◄───────►│   Server   │
│ 2.2.2.9/30 │  VXLAN  │ 2.2.2.10/30│
└────────────┘  Tunnel └────────────┘
      │                    │
      └─────────┬──────────┘
                │
         ┌──────▼──────┐
         │   Internet  │
         └─────────────┘
```

### Key Concepts:
- **VNI (VXLAN Network Identifier)**: Like VLAN ID, allows up to 16 million networks
- **VTEP (VXLAN Tunnel Endpoint)**: Device that encapsulates/decapsulates packets
- **Encapsulation**: Original packet wrapped with outer MAC/IP/UDP headers

---

## 🔒 iptables Rules Applied

```bash
# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# FORWARD rules
iptables -A FORWARD -i tun0 -o vxlan02 -j ACCEPT
iptables -A FORWARD -i wg0 -o vxlan02 -j ACCEPT
iptables -A FORWARD -i eth0 -o vxlan02 -j ACCEPT

# NAT masquerade
iptables -t nat -A POSTROUTING -o vxlan02 -j MASQUERADE
```

---

## 📊 Performance Tips

1. **MTU**: Use 1420 for better performance
2. **Port**: Use ports > 1024 for non-root users
3. **Monitoring**: Use real-time monitor for troubleshooting

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request

---

## 👤 Author

**Pooria_A**

- GitHub: [@Pooria-as](https://github.com/Pooria-as)
- Repository: [vxlan_tunnel_script](https://github.com/Pooria-as/vxlan_tunnel_script)

---

## ⭐ Support

If you find this project useful:
- ⭐ Star the repository
- 🐛 Report issues
- 🔧 Contribute code
- 📢 Share with others

---

**Made with ❤️ by Pooria_A**

[![GitHub stars](https://img.shields.io/github/stars/Pooria-as/vxlan_tunnel_script)](https://github.com/Pooria-as/vxlan_tunnel_script/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Pooria-as/vxlan_tunnel_script)](https://github.com/Pooria-as/vxlan_tunnel_script/network)
[![GitHub issues](https://img.shields.io/github/issues/Pooria-as/vxlan_tunnel_script)](https://github.com/Pooria-as/vxlan_tunnel_script/issues)
