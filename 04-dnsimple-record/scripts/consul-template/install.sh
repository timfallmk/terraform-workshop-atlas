#!/bin/bash
set -e

echo "Installing dependencies..."
sudo apt-get update -y &>/dev/null
sudo apt-get install -y unzip &>/dev/null

echo "Fetching Consul Template..."
cd /tmp
curl -s -L -o consul-template.zip https://releases.hashicorp.com/consul-template/0.14.0/consul-template_0.14.0_linux_amd64.zip

echo "Installing Consul Template..."
unzip /tmp/consul-template.zip
sudo chmod +x consul-template
sudo mv consul-template /usr/local/bin/consul-template

echo "Setting up configurations directory..."
sudo mkdir -p /etc/consul-template.d

echo "Installing Consul Template upstart service..."
sudo tee /etc/init/consul-template.conf > /dev/null <<"EOF"
description "Run Consul Template"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

script
  /usr/local/bin/consul-template \
    -log-level=debug \
    -config="/etc/consul-template.d/" \
    >>/var/log/consul-template.log 2>&1

  logger -t "consul-template" "Running!"
end script
EOF

echo "Starting Consul Template..."
sudo service consul-template start
