#!/bin/sh
# We use /bin/sh because Alpine utilizes BusyBox, which uses ash/sh by default, not bash.

# 1. VALIDATION
# Check if a login name was provided as the first argument ($1).
# If it is empty (-z), print an error and exit the script.
if [ -z "$1" ]; then
    echo "Error: Please provide your Hive login."
    echo "Usage: ./setup.sh <login>"
    exit 1
fi

LOGIN=$1

# 2. PACKAGE INSTALLATION
# Update the package index and install required software.
echo "--> Installing base packages..."
apk update
apk add sudo openssh docker docker-cli-compose make git

# 3. USER PROVISIONING
# Create the user without prompting for a password interactively (-D).
echo "--> Creating user: $LOGIN"
adduser -D $LOGIN

# Set a temporary default password for the new user (e.g., '1234').
# The syntax 'username:password' is piped into chpasswd.
echo "$LOGIN:1234" | chpasswd

# Add the user to the 'wheel' group (for sudo) and 'docker' group.
adduser $LOGIN wheel
adduser $LOGIN docker

# Modify the sudoers file to allow the 'wheel' group to execute commands.
# sed -i edits the file in place.
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# 4. SSH CONFIGURATION
echo "--> Configuring SSH..."
# Change default port 22 to 4241.
sed -i 's/#Port 22/Port 4241/' /etc/ssh/sshd_config
# Explicitly disable root login over SSH for security.
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# 5. SERVICE INITIALIZATION
echo "--> Enabling and starting services..."
# Add Docker and SSH to the default boot runlevel so they start on reboot.
rc-update add docker boot
rc-update add sshd default

# Start the services immediately so we don't have to reboot right now.
rc-service sshd restart
service docker start

echo "--> Setup complete! You can now SSH into port 4241 with user $LOGIN."
