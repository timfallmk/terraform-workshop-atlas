#!/bin/bash
set -e

# Literally throw away everything cloud-init has done
echo "Installing haproxy..."
sudo add-apt-repository ppa:vbernat/haproxy-1.5 --yes &>/dev/null
sudo apt-get --yes update &>/dev/null
sudo apt-get install haproxy &>/dev/null

echo "Registering service with Consul..."
sudo tee /etc/consul.d/lb.json > /dev/null <<"EOF"
{
  "service": {
    "name": "lb",
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
sudo tee /etc/consul-template.d/lb.hcl > /dev/null <<"EOF"
template {
  source      = "/tmp/haproxy.cfg.ctmpl"
  destination = "/etc/haproxy/haproxy.cfg"
  command     = "sudo service haproxy reload"
}
EOF

echo "Restarting Consul Template..."
sudo service consul-template restart
