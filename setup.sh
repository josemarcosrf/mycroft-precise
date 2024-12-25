#!/usr/bin/env bash
# Copyright 2019 Mycroft AI Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "👋 Hello!"

guess_package_manager() {
    # Source the os-release file to access OS identification variables
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    else
        echo "Cannot determine the operating system. /etc/os-release not found."
        exit 1
    fi

    # Check the ID and ID_LIKE fields to determine the package manager
    case "$ID" in
        debian|ubuntu|linuxmint)
            echo "💻️ Detected Debian-based system. Using apt for package management."
            PACKAGE_MANAGER="apt"
            ;;
        fedora)
            echo "💻️ Detected Fedora system. Using dnf for package management."
            PACKAGE_MANAGER="dnf"
            ;;
        centos|rhel)
            echo "💻️ Detected Red Hat-based system. Using yum for package management."
            PACKAGE_MANAGER="yum"
            ;;
        *)
            # Check ID_LIKE for derivatives
            case "$ID_LIKE" in
                debian)
                    echo "💻️ Detected Debian-based system via ID_LIKE. Using apt for package management."
                    PACKAGE_MANAGER="apt"
                    ;;
                rhel|fedora)
                    # Distinguish between dnf and yum
                    if command -v dnf &> /dev/null; then
                        echo "💻️ Detected Red Hat-based system via ID_LIKE. Using dnf for package management."
                        PACKAGE_MANAGER="dnf"
                    else
                        echo "💻️ Detected Red Hat-based system via ID_LIKE. Using yum for package management."
                        PACKAGE_MANAGER="yum"
                    fi
                    ;;
                *)
                    echo "Unsupported or unrecognized Linux distribution."
                    exit 1
                    ;;
            esac
            ;;
    esac
}

is_command() { 
    hash "$1" 2>/dev/null; 
}

apt_is_locked() { 
    fuser /var/lib/dpkg/lock >/dev/null 2>&1; 
}

wait_for_apt() {
	if apt_is_locked; then
		echo "Waiting to obtain dpkg lock file..."
		while apt_is_locked; do echo .; sleep 0.5; done
	fi
}

has_piwheels() { 
    cat /etc/pip.conf 2>/dev/null | grep -qF 'piwheels'; 
}

install_piwheels() {
    echo "Installing piwheels..."
    echo "
[global]
extra-index-url=https://www.piwheels.org/simple
" | sudo tee -a /etc/pip.conf
}

#############################################
set -e; cd "$(dirname "$0")" # Script Start #
#############################################

VENV=${VENV-$(pwd)/.venv}

# ========= System-wide dependencies =========
os=$(uname -s)
if [ "$os" = "Linux" ]; then
    echo "🐧 Running on Linux OS"
    guess_package_manager
    echo "📦 Detected '$PACKAGE_MANAGER' as package manager..."
    if is_command $PACKAGE_MANAGER; then
        if [ $PACKAGE_MANAGER = "apt" ]; then
            # Ubuntu / Debian and family packages
            wait_for_apt
            sudo apt install -y python3-pip curl libopenblas-dev python3-scipy cython libhdf5-dev python3-h5py portaudio19-dev swig libpulse-dev libatlas-base-dev
        else
            # Fedora and family packages (dnf or yum)
            sudo $PACKAGE_MANAGER install -y python3-pip curl openblas-devel python3-scipy cython hdf5-devel python3-h5py portaudio-devel
        fi
    fi
elif [ "$os" = "Darwin" ]; then
    echo "🍏 Running on MacOS"
    if is_command brew; then
        brew install portaudio
    fi
fi

# ========= Python Environment and Dependencies =========
echo "🐍 Setting python environment"
if [ ! -x "$VENV/bin/python" ]; then 
    python3 -m venv "$VENV" #--without-pip; 
fi
source "$VENV/bin/activate"
# if [ ! -x "$VENV/bin/pip" ]; then curl https://bootstrap.pypa.io/get-pip.py | python; fi

arch="$(python -c 'import platform; print(platform.machine())')"
if [ "$arch" = "armv7l" ] && ! has_piwheels; then
    echo "📥️ Detcted 'armv7l' architecture. Installing wheels..."
    install_piwheels
fi

pip install -e runner/
pip install -e .
# pip install pocketsphinx  # Optional, for comparison
