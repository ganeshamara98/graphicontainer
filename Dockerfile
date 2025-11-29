# Using Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set non-interactive frontend to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# Update package list and install required packages
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    # Basic utilities for downloading files and managing repos
    wget curl gnupg2 software-properties-common \
    # XFCE desktop environment and additional tools
    xfce4 xfce4-goodies \
    # X11 support for GUI applications
    dbus-x11 x11-xserver-utils \
    # VNC server for remote desktop access
    tigervnc-standalone-server tigervnc-common \
    # noVNC provides browser-based VNC access, websockify is its websocket proxy
    novnc websockify \
    # Python3 for scripting, pip for Python package installation, unzip for ChromeDriver
    python3 python3-pip unzip \
    # Fonts required for rendering web pages in Chrome
    fonts-liberation \
    # Libraries required for running Google Chrome
    libasound2 libatk1.0-0 libatk-bridge2.0-0 \
    libcairo2 libcups2 libdbus-1-3 libgbm1 libglib2.0-0 libgtk-3-0 \
    libnspr4 libnss3 libpango-1.0-0 libvulkan1 libxcomposite1 \
    libxdamage1 libxkbcommon0 libxrandr2 xdg-utils \
    # Clean up cached package lists to reduce image size
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Install Google Chrome
# ------------------------------------------------------------------------------
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    # Install the downloaded Chrome .deb package
    apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    # Remove the .deb file to reduce image size
    rm google-chrome-stable_current_amd64.deb

# ------------------------------------------------------------------------------
# Get installed Google Chrome version
# ------------------------------------------------------------------------------
RUN CHROME_VERSION=$(google-chrome --version | awk '{print $3}') && \
    # Save Chrome version to a temporary file for ChromeDriver version matching
    echo $CHROME_VERSION > /tmp/CHROME_VERSION

# ------------------------------------------------------------------------------
# Get matching ChromeDriver version based on installed Chrome
# ------------------------------------------------------------------------------
RUN CHROME_VERSION=$(cat /tmp/CHROME_VERSION) && \
    # Fetch the latest ChromeDriver version compatible with Chrome major version
    wget -q "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_VERSION%.*}" -O /tmp/DRIVER_VERSION

# ------------------------------------------------------------------------------
# Download ChromeDriver ZIP for Linux
# ------------------------------------------------------------------------------
RUN DRIVER_VERSION=$(cat /tmp/DRIVER_VERSION) && \
    wget -q "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${DRIVER_VERSION}/linux64/chromedriver-linux64.zip" \
        -O /tmp/chromedriver.zip

# ------------------------------------------------------------------------------
# Unzip ChromeDriver binary
# ------------------------------------------------------------------------------
RUN unzip /tmp/chromedriver.zip -d /tmp

# ------------------------------------------------------------------------------
# Move ChromeDriver into system PATH for global access
# ------------------------------------------------------------------------------
RUN mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver

# ------------------------------------------------------------------------------
# Make ChromeDriver executable
# ------------------------------------------------------------------------------
RUN chmod +x /usr/local/bin/chromedriver

# ------------------------------------------------------------------------------
# Clean up temporary files used during ChromeDriver installation
# ------------------------------------------------------------------------------
RUN rm -rf /tmp/chromedriver* /tmp/CHROME_VERSION /tmp/DRIVER_VERSION

# ------------------------------------------------------------------------------
# Install Selenium Python package
# ------------------------------------------------------------------------------
RUN pip3 install selenium

# ------------------------------------------------------------------------------
# Expose ports for VNC and noVNC access
# ------------------------------------------------------------------------------
EXPOSE 5901  # VNC server port
EXPOSE 6080  # noVNC web interface port

# ------------------------------------------------------------------------------
# Start XFCE desktop with VNC and noVNC
# ------------------------------------------------------------------------------
    # 1 Create VNC config directory \
    # 2 Set VNC password to '123456' and save it \
    # 3 Secure VNC password file \
    # 4 Start VNC server with display :1, 1920x1080 resolution, 24-bit color \
    # 5 Start noVNC to proxy VNC to web browser on port 6080 \
    # 6 Keep the container running indefinitely \
CMD ["bash", "-c", "\
    mkdir -p ~/.vnc && \
    echo '123456' | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd && \
    vncserver :1 -geometry 1920x1080 -depth 24 && \
    websockify --web=/usr/share/novnc/ 6080 localhost:5901 & \
    tail -f /dev/null"]

# ------------------------------------------------------------------------------
# Usage: Connect via VNC client to <ip_address>:5901 or web browser to http://<ip_address>:6080/vnc.html
# ------------------------------------------------------------------------------
