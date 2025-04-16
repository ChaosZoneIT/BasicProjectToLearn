FROM ubuntu:24.04

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
RUN sed -i "s|^external_url.*|external_url 'http://172.0.10.3'|" /etc/gitlab/gitlab.rb

#beckup when mount this directory
RUN cp /etc/gitlab/gitlab.rb /tmp/gitlab.rb

COPY startGitLab.sh /startGitLab.sh
RUN chmod +x /startGitLab.sh

# TODO:
    # 1. add ssh certificate
    # 2. add login to ssh to container
    # 3. add email configuration

EXPOSE 80 22 443
CMD ["/startGitLab.sh", "-D"]