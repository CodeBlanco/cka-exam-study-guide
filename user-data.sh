#!/bin/bash

# The private key used below should be the same key that you setup your ec2 instance. 

# Logging function for debugging
log() {
    echo "$(date) - $1" >> /tmp/userdata.log
}

log "Starting user-data script."

log "Ensuring .ssh directory exists."
mkdir -p /home/ec2-user/.ssh/

if [ ! -f /home/ec2-user/.ssh/id_ed25519 ]; then
    log "Creating the private key."
    # Creating the private key
    cat << EOF > /home/ec2-user/.ssh/id_ed25519
-----BEGIN OPENSSH PRIVATE KEY-----
UPDATE WITH YOUR REAL KEY
asdfAAAAAAABAAAAMwAAAAtz
asdfasdfasdfasdfasddfasdfsadgsakloghsadkfhkasdhflkasdhkfjlasdhkjlfaskldj
AIgiDATNIgwEGhRAjKgklNcEig1zWAAAAAAECAwQF
-----END OPENSSH PRIVATE KEY-----
EOF
else
    log "Private key already exists, skipping creation."
fi

# Setting ownership and permissions
log "Setting ownership and permissions for private key."
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_ed25519
chmod 600 /home/ec2-user/.ssh/id_ed25519

log "Generating the public key from the private one."
# Generating the public key from the private one
ssh-keygen -y -f /home/ec2-user/.ssh/id_ed25519 > /home/ec2-user/.ssh/id_ed25519.pub

log "Finished user-data script."
