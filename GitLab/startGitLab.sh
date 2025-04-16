#!/bin/bash

/opt/gitlab/embedded/bin/runsvdir-start &

cp /tmp/gitlab.rb /etc/gitlab/gitlab.rb
gitlab-ctl reconfigure


tail -f /dev/null  # or another way to keep the container alive