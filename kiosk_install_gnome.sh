#!/bin/bash

# Ubuntu image
# https://cdimage.ubuntu.com/ubuntu/releases/20.04/release/inteliot/ubuntu-20.04-live-server-amd64+intel-iot.iso

# Update and Upgrade the System
apt update && apt upgrade -y

# Install the required libraries, X server, GNOME Shell, gnome-session, dconf-cli, and dbus-x11
apt install --no-install-recommends xorg libwebkit2gtk-4.0-37 libgl1 libc6 gnome-shell gnome-session dconf-cli dbus-x11 gdm3 -y

# Install the Tauri App
# Make sure to replace 'your-tauri-app.deb' with the actual path to your Tauri app's .deb package
dpkg -i tauriapp.deb

# Create the 'kiosk' user if it doesn't exist and set its home directory
if id "kiosk" &>/dev/null; then
    echo "User 'kiosk' already exists."
else
    useradd -m -s /bin/bash kiosk
    echo "User 'kiosk' created."
fi

# Set up auto-login for the 'kiosk' user
mkdir -p /etc/gdm3
cat >> /etc/gdm3/custom.conf <<EOL
[daemon]
AutomaticLogin = kiosk
AutomaticLoginEnable= true
EOL

# Disable screen locking
sudo -u kiosk dbus-launch --exit-with-session gsettings set org.gnome.desktop.screensaver lock-enabled false

# Disable Win+L to lock the screen at all
sudo -u kiosk dbus-launch --exit-with-session gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "[]"


# Enable on-screen keyboard
sudo -u kiosk dbus-launch --exit-with-session gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true

# Prevent the "overview" screen in GNOME (also known as "Activities" view)
# sudo -u kiosk dbus-launch --exit-with-session gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false
sudo -u kiosk dbus-launch --exit-with-session gsettings set org.gnome.mutter overlay-key ''

# Create an autostart entry for your app
mkdir -p /home/kiosk/.config/autostart
cat > /home/kiosk/.config/autostart/tauriapp.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=/usr/bin/tauriapp
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Tauri App
Comment=Start Tauri App on login
EOL
chown -R kiosk:kiosk /home/kiosk/.config

# Start GNOME session on login
echo "dbus-launch --exit-with-session gnome-session" > /home/kiosk/.xsession
chown kiosk:kiosk /home/kiosk/.xsession

# Reboot the System for changes to take effect
reboot

# Use this to prevent gdm3 to login to the default admin user and ask for login.
# sudo usermod -u 9999 admin  # replace 'admin' with the usernames as necessary