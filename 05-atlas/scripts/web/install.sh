#!/bin/bash
set -e

echo "Installing Apache..."
sudo apt-get update -y &>/dev/null
sudo apt-get install -y apache2 &>/dev/null

echo "Registering service with Consul..."
sudo tee /etc/consul.d/web.json > /dev/null <<"EOF"
{
  "service": {
    "name": "web",
    "port": 80,
    "check": {
      "http": "http://localhost",
      "interval": "5s",
      "timeout": "1s"
    }
  }
}
EOF

echo "Restarting Consul to register service..."
sudo service consul restart

echo "Installing Consul Template configuration..."
sudo tee /etc/consul-template.d/web.hcl > /dev/null <<"EOF"
template {
  source      = "/tmp/index.html.ctmpl"
  destination = "/var/www/html/index.html"
}
EOF

echo "Restarting Consul Template..."
sudo service consul-template restart
