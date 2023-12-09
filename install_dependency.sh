#!/bin/bash

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package using the package manager
install_package() {
    local package=$1
    echo "Installing $package..."
    sudo apt-get install -y "$package" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Successfully installed $package."
    else
        echo "Error installing $package."
        exit 1
    fi
}

# Function to install Bazelisk on Linux
install_bazelisk_linux() {
    local bazelisk_url="https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64"
    local bazelisk_path="/usr/local/bin/bazelisk"

    # Check if Bazelisk is already installed
    if ! command_exists "bazelisk"; then
        # Download Bazelisk binary and add it to the PATH manually
        echo "Installing Bazelisk on Linux..."
        sudo wget -O "$bazelisk_path" "$bazelisk_url"
        sudo chmod +x "$bazelisk_path"
        sudo sudo mv "$bazelisk_path" /usr/bin/bazel
        /usr/bin/bazel
        if [ $? -eq 0 ]; then
            echo "Successfully installed Bazelisk."
            # Add Bazelisk to the PATH
            echo "export PATH=$PATH:/usr/bin/bazel" >> ~/.bashrc
            source ~/.bashrc
            echo "Added Bazelisk to the PATH."
        else
            echo "Error installing Bazelisk."
            exit 1
        fi
    else
        echo "Bazelisk is already installed."
    fi
}
sudo apt-get update
sudo apt-get -y upgrade

# Check and install C++ compiler with C++11 support
install_package "g++"

# Check and install standard C/C++ development headers
install_package "build-essential"

# Check and install terminfo development libraries
install_package "libncurses5-dev" # Adjust for your distribution

# Check and install libresolv-wrapper package on Ubuntu < 22.04
if [ "$(lsb_release -rs)" \< "22.04" ]; then
    install_package "libresolv-wrapper"
fi

# Check and install Git
install_package "git"

# Check and install Bash 4+
if [ "${BASH_VERSION%%.*}" -lt 4 ]; then
    echo "Bash version 4 or later is required."
    exit 1
fi

# Check and install GNU Make 4.2+
install_package "make"

# Check and install CMake 3.20.*
install_package "cmake"

# Check and install Autoconf 2.68+
install_package "autoconf"

# Check and install Yacc or Bison
install_package "bison"

# Check and install GNU Patch 2.7+
install_package "patch"

# Install Bazelisk on Linux
install_bazelisk_linux

# Install Build dependency
sudo apt-get install -y libresolv-wrapper

# Check and install Go
if ! command_exists "go"; then
    echo "Installing Go..."
    sudo apt-get install -y golang-go >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Successfully installed Go."
    else
        echo "Error installing Go."
        exit 1
    fi
else
    echo "Go is already installed."
fi

# Check and install NodeJS 12.x and Yarn 1.7+
if ! command_exists "node" || ! command_exists "yarn"; then
    echo "Installing NodeJS and Yarn..."
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
    sudo apt-get install -y nodejs yarn >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Successfully installed NodeJS and Yarn."
    else
        echo "Error installing NodeJS and Yarn."
        exit 1
    fi
else
    echo "NodeJS and Yarn are already installed."
fi

echo "All dependencies including Bazelisk, Go, NodeJS, and Yarn have been installed successfully."

# Summary of installed packages
echo -e "\nSummary of installed packages:"
echo "--------------------------------"
echo "C++ Compiler: $(g++ --version | head -n1)"
echo "Git: $(git --version)"
echo "Bash: $BASH_VERSION"
echo "Make: $(make --version | head -n1)"
echo "CMake: $(cmake --version | head -n1)"
echo "Autoconf: $(autoconf --version | head -n1)"
echo "Bison: $(bison --version | head -n1)"
echo "Patch: $(patch --version | head -n1)"
echo "Bazelisk: $(bazelisk --version | head -n1)"
echo "Go: $(go version)"
echo "NodeJS: $(node --version)"
echo "Yarn: $(yarn --version)"
# Optionally, add Bazelisk version if installed

git config --global --add safe.directory "*"
git clone https://github.com/cockroachdb/cockroach
cd cockroach

exit 0
