# -------------------------------------------------------------------------------------------------
# Optional Arguments (Example: "make all REMOTE_LOGIN=user@hostname")
# -------------------------------------------------------------------------------------------------
INSTALL_PATH ?= /etc/icinga2/conf.d
REMOTE_LOGIN ?= root@localhost
RESTART_CMD ?= sudo systemctl reload icinga2

# -------------------------------------------------------------------------------------------------
# Fixed Variables
# -------------------------------------------------------------------------------------------------
PARSER = icinga-parser.py
GROUPS = groups.conf
HOSTS = hosts.conf
FILES = *.conf *.sh *.txt
CHECK = ls -las

# -------------------------------------------------------------------------------------------------
# Make Targets
# -------------------------------------------------------------------------------------------------
all: conf

conf:
	@./$(PARSER)
	@$(CHECK) $(GROUPS)
	@$(CHECK) $(HOSTS)

install:
	cp $(FILES) $(INSTALL_PATH)

restart:
	$(RESTART_CMD)

remote_install:
	scp $(FILES) $(REMOTE_LOGIN):$(INSTALL_PATH)

remote_restart:
	ssh $(REMOTE_LOGIN) $(RESTART_CMD)

clean:
	rm $(GROUPS) || true
	rm $(HOSTS) || true

.PHONY: all confs install remote_install restart remote_restart clean
