FROM ubuntu:24.04 AS ubuntu-with-ssh

ARG USER_NAME=admin

# Comment out PS1 assignments in /etc/skel/.bashrc
# This ensures that new users will inherit the global prompt defined in /etc/bash.bashrc,
# instead of using the default user-specific prompt.
# This helps keep a consistent shell appearance across all users (e.g., for SSH logins).
RUN sed -i 's/^\s*\(PS1=.*\)$/# \1/' /etc/skel/.bashrc && \
    sed -i 's/^\s*\(PS1\s*=\)/# \1/' /etc/skel/.bashrc && \
    sed -i 's/^\s*\(case.*PS1=.*\)$/# \1/' /etc/skel/.bashrc

# User setup
RUN useradd -m -G sudo -s /bin/bash "$USER_NAME" &&\
    echo "$USER_NAME:$USER_NAME" | chpasswd &&\
    chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

RUN apt-get update && \
    # we use ex
    apt-get -y --no-install-recommends install vim-tiny && \
    apt-get install -y sudo nano openssh-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure SSHD.
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    bash -c 'install -m755 <(printf "#!/bin/sh\nexit 0") /usr/sbin/policy-rc.d' && \
    ex +'%s/^#\zeListenAddress/\1/g' -scwq /etc/ssh/sshd_config && \
    ex +'%s/^#\zeHostKey .*ssh_host_.*_key/\1/g' -scwq /etc/ssh/sshd_config && \
    # Disable SSH login as root user
    sed -i 's@^#\?PermitRootLogin.*@PermitRootLogin no@' /etc/ssh/sshd_config

# User configure
RUN mkdir -p /etc/sudoers.d
RUN echo "$USER_NAME ALL=(ALL:ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME" && \
    chmod 0440 "/etc/sudoers.d/$USER_NAME"

# Ensure only the specified user(s) can connect via SSH.
# If AllowUsers exists, append the user if not already present.
# If not, create a new AllowUsers line with the user.
RUN set -eux; \
    if grep -q '^AllowUsers' /etc/ssh/sshd_config; then \
        grep -q "\<$USER_NAME\>" /etc/ssh/sshd_config || \
        sed -i "/^AllowUsers/ s/$/ $USER_NAME/" /etc/ssh/sshd_config; \
    else \
        echo "AllowUsers $USER_NAME" >> /etc/ssh/sshd_config; \
    fi

RUN ssh-keygen -A
RUN mkdir -p /run/sshd

CMD ["/usr/sbin/sshd", "-D"]

FROM ubuntu-with-ssh

# Base directory for startup and configuration scripts
ARG BASE_SCRIPTS_DIR=/startScript

ARG CONFIGURATION_DIR=/gitlab-config
ENV CONFIGURE_BEFORE_START=${CONFIGURATION_DIR}/before
ENV CONFIGURE_BEFORE_START_DONE=${CONFIGURATION_DIR}/before-done
# Directory with configuration scripts to be executed.
# This is mounted in docker-compose, which allows dynamically adding new scripts
# without rebuilding the image. Scripts are moved here from init folder at runtime.
ENV CONFIGURE_AFTER_START=${CONFIGURATION_DIR}/after
# Directory to store already executed configuration scripts.
ENV CONFIGURE_AFTER_START_DONE=${CONFIGURATION_DIR}/after-done

# Path to GitLab's main configuration file
ENV CONFIG_FILE=/etc/gitlab/gitlab.rb
ENV CONFIG_FILE_TMP=/tmp/gitlab.rb
# Path to ssh main configuration file
ENV SSH_CONFIG_DIR=/etc/ssh
ENV SSH_CONFIG_DIR_TMP=/tmp/ssh

ENV PROFILE_D_DIR=/etc/profile.d
ENV PROFILE_D_DIR_TMP=/tmp/profile.d

ENV SUDOERS_D_DIR=/etc/sudoers.d
ENV SUDOERS_D_DIR_TMP=/tmp/sudoers.d

ENV HOME_DIR=/home
ENV HOME_DIR_TMP=/tmp/home

# Domain for GitLab instance (used in SSL certificate and configuration)
ENV DOMAIN=gitlab.company.local

# IP address to identify container (optional use case)
ENV CONTAINER_ID=172.0.10.3

# Destination directory for GitLab certificates
ENV SSL_CERTIFICATE_DIR=/etc/gitlab/ssl
# Temporary directory where certificates are stored
ENV SSL_CERTIFICATE_DIR_TMP=/ssl


# Install basic tools
RUN apt-get update
RUN apt-get install -y curl ca-certificates tzdata perl

# Add GitLab repository and install GitLab CE
RUN curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
RUN apt install sysvinit-utils
RUN apt-get install gitlab-ce
# Need to start gitlab
RUN apt install -y logrotate

# Install minimal netcat version for simple port checks
RUN apt-get install -y netcat-traditional

# [Alternative] Uncomment below if you need more advanced netcat version (e.g., for CI/CD)
# (e.g., with better timeout support or in CI/CD environments)
# RUN apt-get install -y netcat-openbsd

# Firest wersion without ssl
# Used sed because can't change separator in command ex with / to | (in my example)to not escape characters in https address
# RUN LOCAL_DOMAIN=$CONTAINER_ID && sed -i "s|^external_url.*|external_url 'http://"$LOCAL_DOMAIN"'|" $CONFIG_FILE

# --- SSL CONFIGURATION ---

# Install OpenSSL and prepare SSL folder
RUN apt install openssl -y
RUN mkdir -p ${SSL_CERTIFICATE_DIR} && \
    chmod 700 ${SSL_CERTIFICATE_DIR} && \
    mkdir -p ${SSL_CERTIFICATE_DIR_TMP} && \
    chmod 700 ${SSL_CERTIFICATE_DIR_TMP}

# Generate self-signed certificate for local domain
RUN openssl req -newkey rsa:2048 -nodes -keyout /ssl/gitlab.company.local.key \
-x509 -days 3650 -out /ssl/gitlab.company.local.crt \
-subj "/C=PL/ST=Test/L=Test/O=Local/CN=gitlab.company.local"

# Inject SSL configuration and other settings into gitlab.rb
RUN LOCAL_DOMAIN=$DOMAIN && \
        # CONFIG_FILE="/etc/gitlab/gitlab-test.rb" &&  for testing when copy past to comandline ind container and remember to change $Domain to gitlab.company.local
        # Add variable if not exist
        grep -q "^my_gitlab_domain" "$CONFIG_FILE" || sed -i "1imy_gitlab_domain = \"$LOCAL_DOMAIN\"\n" "$CONFIG_FILE" && \
        # external_url
        sed -i "s|^external_url .*|external_url \"https://\#{my_gitlab_domain}\"|" "$CONFIG_FILE" && \
        grep -q "^external_url" "$CONFIG_FILE" || echo "external_url \"https://\#{my_gitlab_domain}\"" >> "$CONFIG_FILE" && \
        # HTTPS redirect
        sed -i "s|^# *nginx\['redirect_http_to_https'\].*|nginx['redirect_http_to_https'] = true|" "$CONFIG_FILE" && \
        grep -q "nginx\['redirect_http_to_https'\]" "$CONFIG_FILE" || echo "nginx['redirect_http_to_https'] = true" >> "$CONFIG_FILE" && \
        # certificate
        sed -i "s|^# *nginx\['ssl_certificate'\].*|nginx['ssl_certificate'] = \"/etc/gitlab/ssl/\#{my_gitlab_domain}.crt\"|" "$CONFIG_FILE" && \
        grep -q "nginx\['ssl_certificate'\]" "$CONFIG_FILE" || echo "nginx['ssl_certificate'] = \"/etc/gitlab/ssl/\#{my_gitlab_domain}.crt\"" >> "$CONFIG_FILE" && \
        # key
        sed -i "s|^# *nginx\['ssl_certificate_key'\].*|nginx['ssl_certificate_key'] = \"/etc/gitlab/ssl/\#{my_gitlab_domain}.key\"|" "$CONFIG_FILE" && \
        grep -q "nginx\['ssl_certificate_key'\]" "$CONFIG_FILE" || echo "nginx['ssl_certificate_key'] = \"/etc/gitlab/ssl/\#{my_gitlab_domain}.key\"" >> "$CONFIG_FILE"

# --- END SSL CONFIGURATION ---

# Save backup of gitlab.rb when mounting config
RUN cp $CONFIG_FILE $CONFIG_FILE_TMP && \
    mkdir -p $SSH_CONFIG_DIR_TMP && \
    mkdir -p $SUDOERS_D_DIR_TMP && \
    mkdir -p $PROFILE_D_DIR_TMP && \
    mkdir -p $HOME_DIR_TMP && \
    cp -r $SSH_CONFIG_DIR/* $SSH_CONFIG_DIR_TMP/ && \
    cp -r $SUDOERS_D_DIR/* $SUDOERS_D_DIR_TMP/ && \
    cp -r $PROFILE_D_DIR/* $PROFILE_D_DIR_TMP/ && \
    cp -r $HOME_DIR/* $HOME_DIR_TMP/ && \
    # Create necessary directories
    mkdir ${BASE_SCRIPTS_DIR} && \
    mkdir ${CONFIGURATION_DIR} && \
    mkdir ${CONFIGURE_BEFORE_START} && \
    mkdir ${CONFIGURE_BEFORE_START_DONE} && \
    mkdir ${CONFIGURE_AFTER_START} && \
    mkdir ${CONFIGURE_AFTER_START_DONE}


# Copy startup script
COPY startGitLab.sh ${BASE_SCRIPTS_DIR}/startGitLab.sh
RUN chmod +x ${BASE_SCRIPTS_DIR}/startGitLab.sh

# Copy configuration execution script
COPY configure-before-start.sh ${BASE_SCRIPTS_DIR}/configure-before-start.sh
RUN chmod +x ${BASE_SCRIPTS_DIR}/configure-before-start.sh

COPY configure-after-start.sh ${BASE_SCRIPTS_DIR}/configure-after-start.sh
RUN chmod +x ${BASE_SCRIPTS_DIR}/configure-after-start.sh

# Add prompt configuration
RUN echo 'export PS1="\[\033[0;34m\][gitLab]\[\033[00m\] \[\033[1;31m\]\u@\H:\w\[\033[00m\] \$ "' >> /etc/bash.bashrc

# Open required ports
EXPOSE 80 22 443

# Default command (runs GitLab and configuration scripts)
CMD ["/bin/bash","/startScript/startGitLab.sh", "-D"]

# Alternative: keep container running without starting GitLab (for debugging)
# CMD ["tail", "-f", "/dev/null"]
