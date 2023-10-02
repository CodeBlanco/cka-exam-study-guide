resource "aws_instance" "example" {
  count = var.instance_count  # Define 'instance_count' variable to specify the number of instances

  ami           = "ami-03a6eaae9938c858c"  
  instance_type = "t2.medium"
  key_name      = "cka"

  user_data = <<-EOF
#!/bin/bash

# Logging function for debugging
log() {
    echo "$(date) - $1" >> /tmp/userdata.log
}

# Start of the user-data script
log "Starting user-data script."

# Ensure SSH directory and private key setup for EC2 user
log "Ensuring .ssh directory exists for EC2 user."
mkdir -p /home/ec2-user/.ssh/
if [ ! -f /home/ec2-user/.ssh/id_ed25519 ]; then
    log "Creating the private key."
    cat << EOF > /home/ec2-user/.ssh/id_ed25519
# ... [Your private key here]
EOF
else
    log "Private key already exists, skipping creation."
fi
log "Setting ownership and permissions for private key."
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_ed25519
chmod 600 /home/ec2-user/.ssh/id_ed25519

# Generating the public key from the private key
log "Generating the public key from the private key."
ssh-keygen -y -f /home/ec2-user/.ssh/id_ed25519 > /home/ec2-user/.ssh/id_ed25519.pub

# Installing containerd
log "Installing containerd."
wget $CONTAINERD
tar -C /usr/local -xzvf `basename $CONTAINERD`

# Setting up containerd for systemctl
log "Setting up containerd for systemctl."
mkdir -p /usr/local/lib/systemd/system
sudo wget -O /usr/local/lib/systemd/system/containerd.service $SYSTEMCTL_CONTAINERD 
systemctl daemon-reload
systemctl enable --now containerd

# Installing runc
log "Installing runc."
wget $RUNC
install -m 755 `basename $RUNC` /usr/local/sbin/runc

# Installing and setting up the network plugin
log "Installing and configuring network plugin."
mkdir -p /opt/cni/bin
wget $NETWORK_PLUGIN 
tar -C /opt/cni/bin/ -xzvf `basename $NETWORK_PLUGIN`

# Pre-flight checks
log "Starting pre-flight checks."

# Install tc if not present
if ! command -v tc &> /dev/null; then
    log "Installing tc..."
    sudo yum install -y iproute-tc
fi

# Loading the br_netfilter module and related settings
log "Loading br_netfilter module."
sudo modprobe br_netfilter
if [ ! -f /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
    log "Setting bridge-nf-call-iptables to 1..."
    echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables
fi

# Ensure IP forwarding is enabled
log "Ensuring IP forwarding is enabled."
if [[ $(cat /proc/sys/net/ipv4/ip_forward) != "1" ]]; then
    log "Enabling IP forwarding..."
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
    sudo sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

log "Pre-flight checks addressed."

# Disabling SELinux
log "Disabling SELinux."
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Setting up the Kubernetes repository and installing Kubernetes binaries
log "Setting up Kubernetes repo and installing binaries."
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# End of the user-data script
log "Finished user-data script."
              EOF

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = {
    Name = "example-instance-${count.index}"
  }
}
