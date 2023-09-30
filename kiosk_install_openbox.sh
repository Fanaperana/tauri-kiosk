#!/bin/bash

# This script sets up a kiosk mode with a Tauri app on Ubuntu Server 20.04
# The Tauri app will be located at /usr/bin/tauriapp and the user will be 'kiosk'

# Update and Upgrade the System
apt update && apt upgrade -y

# Install the required libraries, X server, and openbox window manager
apt install --no-install-recommends xorg libwebkit2gtk-4.0-37 libgl1 libc6 openbox dconf-cli -y

# Install the Tauri App
# Make sure to replace 'your-tauri-app.deb' with the actual path to your Tauri app's .deb package
dpkg -i tauriapp.deb

# Create the 'kiosk' user if it doesn't exist and set its home directory
if id "kiosk" &>/dev/null; then
    echo "User 'kiosk' already exists."
else
    useradd -m kiosk
    echo "User 'kiosk' created."
fi

# Set up auto-login for the 'kiosk' user
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin kiosk --noclear %I $TERM
EOL

# Reload systemd to pick up the changes
systemctl daemon-reload

# Openbox Configuration to ensure the Tauri app starts in fullscreen
mkdir -p /home/kiosk/.config/openbox
cat > /home/kiosk/.config/openbox/rc.xml <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
    <applications>
        <!-- Change 'tauriapp' to the actual window class or title of your Tauri app if different -->
        <application class="tauriapp">
            <fullscreen>yes</fullscreen>
        </application>
    </applications>
</openbox_config>
EOL
chown -R kiosk:kiosk /home/kiosk/.config

# Create .xinitrc to run the Tauri app within Openbox
cat > /home/kiosk/.xinitrc <<EOL
exec openbox-session &
/usr/bin/tauriapp
EOL
chown kiosk:kiosk /home/kiosk/.xinitrc
chmod +x /home/kiosk/.xinitrc

# Ensure kiosk user's shell is /bin/bash
chsh -s /bin/bash kiosk

# Make X server start upon login using .bash_login
echo -e "if [[ -z \$DISPLAY ]] && [[ \$(tty) = /dev/tty1 ]]; then\n  startx\nfi" > /home/kiosk/.bash_login
chown kiosk:kiosk /home/kiosk/.bash_login

# Enable on-screen keyboard
# sudo -u kiosk gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true
# sudo -u kiosk dconf write /org/gnome/desktop/a11y/applications/screen-keyboard-enabled true

# Reboot the System for changes to take effect
reboot
