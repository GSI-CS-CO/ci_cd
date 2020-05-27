# -------------------------------------------------------------------------------------------------
# Optional Arguments (Example: "make all REMOTE_LOGIN=user@hostname")
# -------------------------------------------------------------------------------------------------
REMOTE_LOGIN ?= root@localhost
REMOTE_WORKSPACE ?= /home/group/user/lnx/workspace

# -------------------------------------------------------------------------------------------------
# Fixed Variables
# -------------------------------------------------------------------------------------------------
PARSER = generator.py
TESTER = tester.sh
FILES = *.sh
LOG_FOLDER = log
LOG_EXTENSION = log

# -------------------------------------------------------------------------------------------------
# Make Targets
# -------------------------------------------------------------------------------------------------
all: conf run

conf:
	@./$(PARSER)

run: conf
	@./$(TESTER)

remote_run: conf
	scp $(FILES) $(REMOTE_LOGIN):$(REMOTE_WORKSPACE)
	ssh $(REMOTE_LOGIN) "mkdir $(REMOTE_WORKSPACE)/$(LOG_FOLDER)" || true
	ssh $(REMOTE_LOGIN) "$(REMOTE_WORKSPACE)/$(TESTER)"

remote_clean:
	ssh $(REMOTE_LOGIN) "rm $(REMOTE_WORKSPACE)/*.$(LOG_EXTENSION)" || true
	ssh $(REMOTE_LOGIN) "rm -r $(REMOTE_WORKSPACE)/$(LOG_FOLDER)" || true

clean:
	rm *.$(LOG_EXTENSION) || true
	rm -r $(LOG_FOLDER)/*/ || true

.PHONY: all conf run remote_run remote_clean clean
