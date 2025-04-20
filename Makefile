.PHONY: \
 help \
 cleanAll \
 startConfigurationAll \
 gitLab \
 gitLab-clean-storage \
 gitLab-clean-configuration-before-start \
 gitLab-clean-configuration-after-start \
 gitLab-copy-configuration-before-start \
 gitLab-copy-configuration-after-start \
 nginx-copy-config \
 nginx-clean

help:
	echo "todo"

# Clean all related directories and files: GitLab storage, configuration folders, nginx storage, and SSL certificates
cleanAll:
	$(MAKE) gitLab-clean-storage
	$(MAKE) gitLab-clean-configuration-before-start
	$(MAKE) gitLab-clean-configuration-after-start
	$(MAKE) nginx-clean
	$(MAKE) remove-ssl-cert

# Copy all required configuration files for services startup (GitLab before/after and Nginx)
startConfigurationAll:
	$(MAKE) gitLab-copy-configuration-before-start
	$(MAKE) gitLab-copy-configuration-after-start
	$(MAKE) nginx-copy-config

# Remove the entire storage/ssl directory and its contents
remove-ssl-cert:
	bash tools/remove-cert-ssl.sh

gitLab:
	bash tools/gitlab/clean-storage.sh && \
	bash tools/gitlab/clean-before-config.sh && \
	bash tools/gitlab/clean-after-config.sh && \
	bash tools/gitlab/copy-config-before.sh && \
	bash tools/gitlab/copy-config-after.sh

# Clean all files and directories inside storage/gitlab, except .gitkeep and configuration files (before/after)
gitLab-clean-storage:
	bash tools/gitlab/clean-storage.sh

# Clean storage/gitlab/config-before-start folder, remove all files except .gitkeep
gitLab-clean-configuration-before-start:
	bash tools/gitlab/clean-config-before.sh

# Clean storage/gitlab/config-after-start folder, remove all files except .gitkeep
gitLab-clean-configuration-after-start:
	bash tools/gitlab/clean-config-after.sh

# Copy configuration files from GitLab/config/before-start to storage/gitlab/config-before-start
gitLab-copy-configuration-before-start:
	bash tools/gitlab/copy-config-before.sh

# Copy configuration files from GitLab/config/after-start to storage/gitlab/config-after-start
gitLab-copy-configuration-after-start:
	bash tools/gitlab/copy-config-after.sh


# Copy nginx.conf file from nginxReverseProxy/config to storage/nginxReverseProxy/config (create directories if needed)
nginx-copy-config:
	bash tools/nginxReverseProxy/copy-configuration.sh

# Remove the entire storage/nginxReverseProxy directory and its contents
nginx-clean:
	bash tools/nginxReverseProxy/clean-nginx-storage.sh