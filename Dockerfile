FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# Install base system + XFCE desktop + VNC + libs for Chrome
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    wget curl gnupg2 software-properties-common \
    xfce4 xfce4-goodies \
    dbus-x11 x11-xserver-utils \
    tigervnc-standalone-server tigervnc-common \
    novnc websockify \
    python3 python3-pip unzip \
    fonts-liberation libasound2 libatk1.0-0 libatk-bridge2.0-0 \
    libcairo2 libcups2 libdbus-1-3 libgbm1 libglib2.0-0 libgtk-3-0 \
    libnspr4 libnss3 libpango-1.0-0 libvulkan1 libxcomposite1 \
    libxdamage1 libxkbcommon0 libxrandr2 xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Install Google Chrome
# ------------------------------------------------------------------------------
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

# ------------------------------------------------------------------------------
# Install matching ChromeDriver (by major version)
# ------------------------------------------------------------------------------
# Get Chrome version
RUN CHROME_VERSION=$(google-chrome --version | awk '{print $3}') && \
    echo $CHROME_VERSION > /tmp/CHROME_VERSION

# Get Chrome-for-Testing driver version based on Chrome version
RUN CHROME_VERSION=$(cat /tmp/CHROME_VERSION) && \
    wget -q "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_VERSION%.*}" -O /tmp/DRIVER_VERSION

# Download the correct ChromeDriver ZIP (Chrome for Testing)
RUN DRIVER_VERSION=$(cat /tmp/DRIVER_VERSION) && \
    wget -q "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${DRIVER_VERSION}/linux64/chromedriver-linux64.zip" \
        -O /tmp/chromedriver.zip

# Unzip ChromeDriver
RUN unzip /tmp/chromedriver.zip -d /tmp

# Move chromedriver into PATH
RUN mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver

# Fix permissions
RUN chmod +x /usr/local/bin/chromedriver

# Clean temp files
RUN rm -rf /tmp/chromedriver* /tmp/CHROME_VERSION /tmp/DRIVER_VERSION


# ------------------------------------------------------------------------------
# Install Selenium
# ------------------------------------------------------------------------------
RUN pip3 install selenium

# ------------------------------------------------------------------------------
# Expose VNC + noVNC ports
# ------------------------------------------------------------------------------
EXPOSE 5901
EXPOSE 6080

# ------------------------------------------------------------------------------
# Startup command: XFCE desktop + VNC + noVNC
# ------------------------------------------------------------------------------
CMD ["bash", "-c", "mkdir -p ~/.vnc && \
echo '123456' | vncpasswd -f > ~/.vnc/passwd && \
chmod 600 ~/.vnc/passwd && \
vncserver :1 -geometry 1920x1080 -depth 24 && \
websockify --web=/usr/share/novnc/ 6080 localhost:5901 & \
tail -f /dev/null"]

# To connect: VNC viewer to localhost:5901 or web browser to http://localhost:6080/vnc.html
