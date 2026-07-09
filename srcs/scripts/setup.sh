#!/bin/sh
# We use /bin/sh because Alpine utilizes BusyBox, which uses ash/sh by default.

# 1. VALIDATION
# Check if a login name was provided as the first argument ($1).
# If it is empty (-z), print an error and exit the script.
if [ -z "$1" ]; then
    echo "Error: Please provide your Hive login."
    echo "Usage: ./setup.sh <login>"
    exit 1
fi

LOGIN=$1

echo "--> Enabling community repository..."
# This command searches for the 'community' repository line in the config file
# and removes the comment character (#) at the start of the line to enable it.#!/bin/sh
# We use /bin/sh because Alpine utilizes BusyBox, which uses ash/sh by default.

# 1. VALIDATION
# Check if a login name was provided as the first argument ($1).
# If it is empty (-z), print an error and exit the script.
if [ -z "$1" ]; then
    echo "Error: Please provide your Hive login."
    echo "Usage: ./setup.sh <login>"
    exit 1
fi

LOGIN=$1

echo "--> Enabling community repository..."
# This command searches for the 'community' repository line in the config file
# and removes the comment character (#) at the start of the line to enable it.
sed -i '/community/s/^#//' /etc/apk/repositories

echo "--> Installing base packages..."
# Update the package index now that the community repo is active, then install.
apk update
apk add sudo openssh docker docker-cli-compose make git

echo "--> Setting up user: $LOGIN"
# Check if the user already exists in the system.
# Redirecting output to /dev/null keeps the terminal clean.
if id "$LOGIN" >/dev/null 2>&1; then
    echo "User $LOGIN already exists, skipping creation."
else
    # Create the user without prompting for a password interactively (-D).
    adduser -D $LOGIN
    # Set a temporary default password (e.g., '1234') for the new user.
    echo "$LOGIN:1234" | chpasswd
fi

# Ensure the user is in the correct administrative groups.
# Running these commands again if the user is already in the group is safe.
adduser $LOGIN wheel
adduser $LOGIN docker

# Grant sudo privileges to the 'wheel' group by uncommenting the relevant line.
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "--> Configuring SSH..."
# Change default SSH port from 22 to 4241 as required by the subject.
sed -i 's/#Port 22/Port 4241/' /etc/ssh/sshd_config
# Explicitly disable root login over SSH to enforce system security.
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

echo "--> Enabling and starting services..."
# Add Docker and SSH to the boot sequence so they start automatically on restart.
rc-update add docker boot
rc-update add sshd default

# Start/restart the services immediately to apply changes without rebooting.
rc-service sshd restart
service docker start

echo "--> Setup complete! You can now SSH into port 4241 with user $LOGIN."
sed -i '/community/s/^#//' /etc/apk/repositories

echo "--> Installing base packages..."
# Update the package index now that the community repo is active, then install.
apk update
apk add sudo openssh docker docker-cli-compose make git

echo "--> Setting up user: $LOGIN"
# Check if the user already exists in the system.
# Redirecting output to /dev/null keeps the terminal clean.
if id "$LOGIN" >/dev/null 2>&1; then
    echo "User $LOGIN already exists, skipping creation."
else
    # Create the user without prompting for a password interactively (-D).
    adduser -D $LOGIN
    # Set a temporary default password (e.g., '1234') for the new user.
    echo "$LOGIN:1234" | chpasswd
fi

# Ensure the user is in the correct administrative groups.
# Running these commands again if the user is already in the group is safe.
adduser $LOGIN wheel
adduser $LOGIN docker

# Grant sudo privileges to the 'wheel' group by uncommenting the relevant line.
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/'
