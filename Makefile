.PHONY: \
 gitLab \
 gitLab-clean-storage \
 gitLab-clean-configuration-before-start \
 gitLab-clean-configuration-after-start \
 gitLab-copy-configuration-before-start \
 gitLab-copy-configuration-after-start


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
	bash tools/gitlab/clean-before-config.sh

# Clean storage/gitlab/config-after-start folder, remove all files except .gitkeep
gitLab-clean-configuration-after-start:
	bash tools/gitlab/clean-after-config.sh

# Copy configuration files from GitLab/config/before-start to storage/gitlab/config-before-start
gitLab-copy-configuration-before-start:
	bash tools/gitlab/copy-config-before.sh

# Copy configuration files from GitLab/config/after-start to storage/gitlab/config-after-start
gitLab-copy-configuration-after-start:
	bash tools/gitlab/copy-config-after.sh

