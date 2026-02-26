#!/bin/bash
# Install or upgrade Variable Weather plasmoid

PACKAGE_DIR="$(dirname "$0")/package"

if kpackagetool6 -t Plasma/Applet -s com.github.JoshuaKimsey.variableweather &>/dev/null; then
    echo "Upgrading Variable Weather..."
    kpackagetool6 -t Plasma/Applet -u "$PACKAGE_DIR"
else
    echo "Installing Variable Weather..."
    kpackagetool6 -t Plasma/Applet -i "$PACKAGE_DIR"
fi

if [ $? -eq 0 ]; then
    echo "Done! You may need to restart Plasma or log out/in to see changes."
    echo "  Quick restart: plasmashell --replace &"
else
    echo "Installation failed. Check the output above for errors."
    exit 1
fi
