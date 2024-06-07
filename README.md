# Introduction

This repository is an experimental notebook for integrating [Ansible](https://www.ansible.com/), [Docker](https://hub.docker.com/_/docker) (Docker-in-Docker), and [Sysbox](https://github.com/nestybox/sysbox).

## Use-Cases

- Custom CI/CD Runners and Pipelines
- Sandboxed Environment for testing infrastructures
- Sandboxed Environment for learning and experimentations

## Development Environment Setup

This process is tested on my Linux Mint Debian Edition 6 with the following details:
- **Linux Kernel:** 6.1.0-21-amd64
- **Sysbox Version:** 0.6.3
- **Docker Version:** 26.1.4
- **Ansible Core Version:** 2.17.0

Ansible is installed in a venv virtual environment with Python 3.11.7.

---

## Usage

### Building the Image
```bash
docker build -t <image-name> --build-arg THE_USER=<username> 
--build-arg THE_PASSWD=<password> .
```

Replace `<image-name>`, `<username>`, and `<password>` with your prefered image name, user name, and password, respectively.


### Running a System Container

Use the following command for testing:

```bash
docker run --runtime=sysbox-runc -it --rm -P --hostname=<container-hostname> --name=<container-name> <image-name>
```
Replace `<container-hostname>` and `<container-name>` with your prefered custom container hostname and docker container name, respectively.

### Manual SSH

As a tip before connecting to system container via SSH, use the following command to get the IP address of a specific container with given container name or id:

```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container-name>
```

To SSH to system container:

```bash
ssh <username>@$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container-name>) -p 22
```

Remind that `<username>` here is the user name you set when you build the image.

### Copy Controller Public SSH Key to System Container

We assume that the controller (e.g. localhost) already generated their SSH _Private and Public keys_ using `ssh-keygen` command.

To copy/transfer the controller's Public Key to System Container, use the following command:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub -p 22 <username>@$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container-name>)
```

### Ansible _inventory.yml_ file

```yaml
# inventory.yml
ungrouped:
  hosts:
  ansible_container:
    ansible_port: <container-port>
    ansible_host: <container-ip>
    ansible_connection: ssh
    ansible_user: <username>
```

### Test by Pinging with Ansible

```bash
ansible -i inventory.yml all -m ping
```

### Running Ansible Playbooks

Suppose we have the following playbook _multi_line_commands.yaml_ for running multi-line commands:

```yaml
- name: Run multi-line bash commands
  hosts: ansible_container
  become: 'yes'
  tasks:
    - name: Execute multi-line bash commands
      shell: |
        echo "Hello, this is a multi-line"
        echo "bash script executed by Ansible."
        echo "This script is running on {{ ansible_hostname }}."

        echo "Test: Creating busybox container ..."
        docker run -t -d busybox
      register: command_output
    - name: Display command output
      debug:
        msg: '{{ command_output.stdout_lines }}'
```

We can use the following command to execute the Ansible Playbook:

```bash
ansible-playbook -i inventory.yml multi_line_commands.yaml
```
