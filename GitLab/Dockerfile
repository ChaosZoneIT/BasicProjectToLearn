FROM ubuntu:24.04

# Configure file for gitlab
ENV CONFIG_FILE=/etc/gitlab/gitlab.rb
# Domain can use only: RUN, CMD, ENTRYPOINT, ENV
ENV DOMAIN=gitlab.company.local
ENV CONTAINER_ID=172.0.10.3


RUN apt-get update
RUN apt-get install -y nano
# we not use ex
# RUN apt-get -y --no-install-recommends install vim-tiny
RUN apt-get install -y curl openssh-server ca-certificates tzdata perl
RUN curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
RUN apt install sysvinit-utils
RUN apt-get install gitlab-ce
#Need to start gitlab
RUN apt install -y logrotate

# Used sed because can't change separator in command ex with / to | (in my example)to not escape characters in https address
# RUN LOCAL_DOMAIN=$CONTAINER_ID && sed -i "s|^external_url.*|external_url 'http://"$LOCAL_DOMAIN"'|" $CONFIG_FILE

# ADDED ssl_certificate for local domain: gitlab.company.local
RUN apt install openssl -y
RUN mkdir -p /etc/gitlab/ssl
RUN chmod 700 /etc/gitlab/ssl

RUN openssl req -newkey rsa:2048 -nodes -keyout /etc/gitlab/ssl/gitlab.company.local.key \
-x509 -days 3650 -out /etc/gitlab/ssl/gitlab.company.local.crt \
-subj "/C=PL/ST=Test/L=Test/O=Local/CN=gitlab.company.local"

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
    


# END ADDED ssl_certificate


#beckup when mount this directory
RUN cp $CONFIG_FILE /tmp/gitlab.rb

COPY startGitLab.sh /startGitLab.sh
RUN chmod +x /startGitLab.sh

# TODO:
    # 1. add ssh certificate
    # 2. add login to ssh to container
    # 3. add email configuration

EXPOSE 80 22 443
CMD ["/startGitLab.sh", "-D"]