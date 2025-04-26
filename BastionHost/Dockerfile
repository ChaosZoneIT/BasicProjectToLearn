FROM quay.io/centos/centos:stream9 AS centos-9-basic

ARG USERNAME=devops

# User setup
RUN useradd -m -G wheel "$USERNAME" && \
    echo "$USERNAME:$USERNAME" | chpasswd && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} && \
    echo "root:secret" | chpasswd

# Install required tools.
RUN dnf -y update && \
    dnf -y install vim openssh-server openssh-clients sudo nano &&\
    # netstat
    dnf install -y net-tools && \ 
    dnf clean all && rm -rf /var/cache/dnf

# Add prompt configuration with Docker icon (🐳) fallback to [doc]
RUN printf '%s\n' \
'if [ "$(echo -e "\U1F433")" == "🐳" ]; then' \
'  export PS1="\[\033[0;34m\]🐳\[\033[00m\] \[\033[1;31m\]\u@\H:\w\[\033[00m\] \$ "' \
'else' \
'  export PS1="\[\033[0;34m\][doc]\[\033[00m\] \[\033[1;31m\]\u@\H:\w\[\033[00m\] \$ "' \
'fi' \
>> /etc/bashrc

# Configure SSHD.
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    bash -c 'install -m755 <(printf "#!/bin/sh\nexit 0") /usr/sbin/policy-rc.d' && \
    ex +'%s/^#\zeListenAddress/\1/g' -scwq /etc/ssh/sshd_config && \
    ex +'%s/^#\zeHostKey .*ssh_host_.*_key/\1/g' -scwq /etc/ssh/sshd_config && \
    # Disable SSH login as root user
    sed -i 's@^#\?PermitRootLogin.*@PermitRootLogin no@' /etc/ssh/sshd_config && \
    sed -i 's@^#\?Port.*@Port 2221@' /etc/ssh/sshd_config

# User configure
RUN echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USERNAME" && \
    chmod 0440 "/etc/sudoers.d/$USERNAME"

# Ensure only the specified user(s) can connect via SSH.
# If AllowUsers exists, append the user if not already present.
# If not, create a new AllowUsers line with the user.
RUN set -eux; \
    if grep -q '^AllowUsers' /etc/ssh/sshd_config; then \
        grep -q "\<$USERNAME\>" /etc/ssh/sshd_config || \
        sed -i "/^AllowUsers/ s/$/ $USERNAME/" /etc/ssh/sshd_config; \
    else \
        echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config; \
    fi

# Generate all missing SSH host keys
RUN ssh-keygen -A

EXPOSE 2221

CMD [ "/usr/bin/sudo", "/usr/sbin/sshd", "-D", "-o", "ListenAddress=0.0.0.0"]


FROM centos-9-basic

RUN dnf update -y && \
    dnf install -y python3.11 python3.11-pip && \
    # Install virtualenv using pip
    python3.11 -m ensurepip --upgrade && \
    python3.11 -m pip install --upgrade pip && \
    python3.11 -m pip install virtualenv && \
    # Install other required things
    dnf install -y git wget gcc make tar && \
    dnf install -y openssl-devel zlib-devel bzip2-devel xz-devel readline-devel libffi-devel && \
    dnf clean all && rm -rf /var/cache/dnf

# Install python 3.8 to use ansible 2.9
# WORKDIR /usr/src
# RUN wget https://www.python.org/ftp/python/3.8.10/Python-3.8.10.tgz && \
#       tar xzf Python-3.8.10.tgz
# WORKDIR /usr/src/Python-3.8.10
# RUN ./configure --enable-optimizations && \
#       make altinstall
# WORKDIR /
# RUN rm /usr/src/Python-3.8.10.tgz && rm -R /usr/src/Python-3.8.10


RUN mkdir -p /opt/ansible

# RUN /usr/local/bin/python3.8 -m venv /opt/ansible/ansible-2.9 && \
#     /opt/ansible/ansible-2.9/bin/pip install --upgrade pip && \
#     /opt/ansible/ansible-2.9/bin/pip install ansible==2.9.27

# python 3.11 require to use in ansible 2.18.5
RUN python3.11 -m venv /opt/ansible/ansible-2.18.5 && \
    /opt/ansible/ansible-2.18.5/bin/pip install --upgrade pip && \
    # /opt/ansible/ansible-2.18.5/bin/pip install ansible==2.18.5
    /opt/ansible/ansible-2.18.5/bin/pip install git+https://github.com/ansible/ansible.git@v2.18.5#egg=ansible-core

#     # For normal shell, when dont useing Dockerfile
#     # 2.18.5 required python min 3.11
#     # python3 -m venv /opt/ansible/ansible-2.18.5 && \
#     # source /opt/ansible/ansible-2.18.5/bin/activate && \
#     # pip install --upgrade pip && \
#     # pip install ansible==2.18.5 && \
#     # deactivate #use only set source (virtual environment)

COPY ansible_aliases.sh /etc/profile.d/ansible_aliases.sh
RUN chmod +x /etc/profile.d/ansible_aliases.sh