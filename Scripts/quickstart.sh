#!/bin/bash

#installing default dependencies
echo "Installing default dependencies..."

apt update
apt upgrade -y
apt install wget curl ncdu tmux ufw make build-essential screen git gcc libpam-google-authenticator lsof fail2ban tree jq pkg-config smartmontools htop net-tools chrony clang -y

# Check if default SSH keys should be added

echo "Do you want to add the default Citizen Cosmos SSH keys? (y/n):"
read answer

if [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then
    echo "Adding default Citizens SSH keys..."
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDATtIkkqM7eYVkTCN2j01zpuq//8wobqq088SobfEfb+tHbPfEbq+0vYHghynkqqWrGKnIj46pCok6WkM6VCuLVtg3pIJyDwJtWnQjtx7ie94bySl7EgfghTt3zElyfvjyN12hggPZRmk+H3Q1CDFkQNxCja8a8hJP0yySbodWNu/ovJdM3MoM3KoF4j63UNSA7i2884Eb+mi6w3bYBI7FV4C4AvmJY2+QdA+/O27Hh366hDTlKFI7n9mGys4tkB9MRKR3F18+SmyHPkSGcDphMz5qHLrRF4io+M65/xjum/UCQQ/ey0wWrZtlzlQ1UK8BKMmnacFS8OeIuvaoXgF2MmumpN88N0pAbD6oZSW9aSqTFPrKFmgUDB9aSd3G2JtuK44bl+vjlJeLOKMfZtq7IEJhNpZTzsqD71LurGdMTCTnHlVvwl6M00/VKEUn1/OYkvEbz7QAuvHkHHPVxBNXepvbYLTL8cyRDplt4j8ecZ6yOFxy5q3huClGZbLbT5c= alex@alex-VirtualBox" >> ~/.ssh/authorized_keys
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8DNFA4MW/KoHRKHl8Jo4s2MCkJZG3u1UcbjkWb+1ykEcUKJQvFjCYJ9nPw3PoxBGI9O9qcGaVVPywCalQ/kx9PT6YaeFGRE4sts8JZM8pOtbx3qaA6WMGUk1ROyBDemJluAzX/RtCKyoCnenVRpR+eUcK9NEKuI427u7MI0CSE1LhSFyV4wWchHp1LYBotBGOglMU2OmNjuhjc/oadfFqTB06HWrAoSRbTkDIrfbC+OIG/D9ca73HpRWdymzb7Fi4FHB3V+PtnkJsybIgXczZMHd9IuvPfIr6d8yq0EfMefbS1s7o46Knv9dEdCh0ZTPCYWAwS8YOiXGdVrlmxDx7bvT3uGqJnVc/uRfg+3ZoN/wK0ygEcGYVPIlNi23u2l5Vl7b8w+K1yTCoN7RaAip/VI8EKQxpNMw73K/Qb7J5mHRQVPwi9YEXWKYE+Fkq4q+ODHVAYMwminrA5CqE1ZlcbZhSRjqtMg3wgp+/c8mt4b7d3YU6RS5D8jx/BPJqv9Xr9LOEFYK9eHE6DESct5BvidDhgU1NT+KL2BisKC4zPDckPE5zRBR29aqT6HQWdD6IJcmQJ7oQ0UlF3Fs0pbMRFCFu9UglyRfBk3Ul4wWA+zZ3L5tP18WwlJWsvEjPCVz2/CVEmE0qgk5sJ72zL7gXzlqY5qEyxd80BJy+9SJoKQ== shafetovarrow@gmail.com" >> ~/.ssh/authorized_keyss
    echo "Citizen Cosmos keys adds successfuly" 
fi

# Prompt user to add SSH keys
while true; do
    read -p "Do you want to add your SSH keys? (y/n): " add_key
    if [[ "$add_key" =~ ^[Yy]$ ]]; then
        read -p "Enter SSH key: " ssh_key
        echo "$ssh_key" >> ~/.ssh/authorized_keys
        ssh-add -K ~/.ssh/id_rsa
    else
        break
    fi
done

echo "Done adding SSH keys."

#Installing monitoring tools

echo "Do you want to set up Prometheus? (y/n):"
read PROMETHEUS

if [ $PROMETHEUS == "y" ]; then
    echo "Installing Prometheus..."
    #Downloadind and extracting latest version
    PROMETHEUS_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep tag_name | cut -d '"' -f 4)
    wget https://github.com/prometheus/prometheus/releases/download/$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
    tar xzf prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
    sudo mv prometheus-$PROMETHEUS_VERSION.linux-amd64/prometheus /usr/local/bin/

    echo "Configuring Prometheus..."
    # Create the Prometheus user and group
    sudo groupadd --system prometheus
    sudo useradd -s /sbin/nologin --system -g prometheus prometheus

    # Create the Prometheus configuration directory and copy the example configuration file
    sudo mkdir /etc/prometheus
    sudo cp prometheus-$PROMETHEUS_VERSION.linux-amd64/prometheus.yml /etc/prometheus/

    # Update the ownership and permissions of the Prometheus files
    sudo chown -R prometheus:prometheus /usr/local/bin/prometheus /etc/prometheus/
    sudo chmod -R 775 /usr/local/bin/prometheus /etc/prometheus/
    sudo chmod 755 /usr/local/bin/prometheus

    # Create the Prometheus systemd service file
    sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus Monitoring System
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/data \
  --web.console.templates=/usr/local/bin/prometheus/consoles \
  --web.console.libraries=/usr/local/bin/prometheus/console_libraries
  --web.listen-address="0.0.0.0:8090"

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl start prometheus
    sudo systemctl enable prometheus

echo "Prometheus has been installed successfully!"
fi

echo "Do you want to set up Node Exporter? (y/n):"
read NODE_EXPORTER

if [ $NODE_EXPORTER == "y" ]; then
    echo "Installing Node Exporter..."
    # Download latest Node Exporter binary
    wget https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-$(uname -s)-$(uname -m).tar.gz

    # Extract the binary and move it to /usr/local/bin
    tar xvfz node_exporter-$(uname -s)-$(uname -m).tar.gz
    sudo mv node_exporter*/node_exporter /usr/local/bin/

    echo "Configuring Node Exporter..."
    # Create the Node Exporter service file
    sudo tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl start node_exporter
    sudo systemctl enable node_exporter

    # Display the Node Exporter version
    echo "Node Exporter version: $(/usr/local/bin/node_exporter --version)"
fi

#installing golang
echo "Do you want to install Go? (y/n):" install_go
read install_go

if [ "$install_go" == "y" ]; then
    read -p "Which version of Go do you want to install? [e.g., 1.16.3] :" version
    echo "Installing Go version $version..."
    sudo wget https://golang.org/dl/go$version.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go$version.linux-amd64.tar.gz
    rm "go$version.linux-amd64.tar.gz"
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
    source ~/.bashrc
fi

echo "Go version installed on this machine: $(go version)"
