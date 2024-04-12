# CONFIG

[![Build Status](https://app.travis-ci.com/miguelmoraperea/config.svg?branch=master)](https://app.travis-ci.com/miguelmoraperea/config)

## Install

For new installations, you might need to install venv:
```
sudo apt install python3-venv
```

Create a new python3 virtual environment:
```
python3 -m venv venv
source venv/bin/activate
python3 -m pip install --upgrade pip
```

Install 'ansible' and 'ansible-lint'
```
pip3 install ansible
pip3 install ansible-lint
```

## Usage

```
sourve venv/bin/activate
ansible-playbook playbook.yml --tags mac
```

In some cases sudo password is required:

```
ansible-playbook playbook.yml --tags yabai --ask-become-pass
```

# Dotfiles

To symlink all the dotfiles simply run:

```
./install
```
