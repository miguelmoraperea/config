# CONFIG

[![Build Status](https://app.travis-ci.com/miguelmoraperea/config.svg?branch=master)](https://app.travis-ci.com/miguelmoraperea/config)

## Install

Create a new python3 virtual environment:
```
python3 -m venv venv
python3 -m pip install --upgrade pip
sourve venv/bin/activate
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
ansible-playbook playbook.yml playbook.yml --tags yabai --ask-become-pass
```

# Dotfiles

To symlink all the dotfiles simply run:

```
./install
```
