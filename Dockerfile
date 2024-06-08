# Disclaimer: The following content is not my original work. 
# I have modified it for specific purpose. All credit goes to https://github.com/nestybox

# References:
#   - https://github.com/nestybox
#   - https://github.com/nestybox/sysbox/blob/master/docs/quickstart/dind.md#deploy-a-system-container-with-systemd-sshd-and-docker-inside
#   - https://github.com/nestybox/dockerfiles/blob/master/ubuntu-bionic-systemd-docker/Dockerfile

# Ubuntu Bionic + Systemd + sshd + Docker

FROM ghcr.io/nestybox/ubuntu-bionic-systemd:latest

ARG THE_USER
ARG THE_PASSWD

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set up new user and password
RUN adduser --disabled-password --gecos "" $THE_USER \
    && echo "$THE_USER:$THE_PASSWD" | chpasswd \
    && usermod -aG sudo $THE_USER \
    && echo "$THE_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$THE_USER-nopasswd \
    && chmod 0440 /etc/sudoers.d/$THE_USER-nopasswd

RUN echo "admin:$THE_PASSWD" | chpasswd

# Install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh \
    && usermod -aG docker $THE_USER
ADD https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker /etc/bash_completion.d/docker.sh

# Configure SSH
RUN mkdir /home/$THE_USER/.ssh \
    && chown $THE_USER:$THE_USER /home/$THE_USER/.ssh \
    && chmod 700 /home/$THE_USER/.ssh \
    && echo "AllowUsers $THE_USER" >> /etc/ssh/sshd_config

# Install Python3.11
# Reference: https://stackoverflow.com/questions/75159821/installing-python-3-11-1-on-a-docker-container
RUN apt-get -y install build-essential \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \ 
        libnss3-dev \
        libssl-dev \
        libreadline-dev \
        libffi-dev \
        libsqlite3-dev \
        libbz2-dev \
        wget \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get purge -y imagemagick imagemagick-6-common 

RUN cd /usr/src \
    && wget https://www.python.org/ftp/python/3.11.7/Python-3.11.7.tgz \
    && tar -xzf Python-3.11.7.tgz \
    && cd Python-3.11.7 \
    && ./configure --enable-optimizations \
    && make altinstall

# Set default python3 to python3.11
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.11 1

RUN cd /home/$THE_USER

# Clean
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 22

# Set systemd as entrypoint.
ENTRYPOINT [ "/sbin/init", "--log-level=err" ]
