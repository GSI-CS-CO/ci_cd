# -------------------------------------------------------------------------------------------------
# Optional Arguments (Example: "make remote_run REMOTE_LOGIN=user@hostname")
# -------------------------------------------------------------------------------------------------
REMOTE_LOGIN ?= root@localhost
REMOTE_WORKSPACE ?= /home/group/user/lnx/workspace
TEST_CASE ?= default_test

# -------------------------------------------------------------------------------------------------
# Fixed Variables
# -------------------------------------------------------------------------------------------------
PARSER = generator.py
TESTER = tester.sh
TEST_CONF = test_configuration.sh
FILES = *.sh
LOG_FOLDER = icmp_test_log
LOG_EXTENSION = log

# -------------------------------------------------------------------------------------------------
# Make Targets
# -------------------------------------------------------------------------------------------------
all: conf run

conf:
ifeq ($(TEST_CASE),default_test)
	@./$(PARSER)
endif
ifeq ($(TEST_CASE),fast_test)
	@./$(PARSER) -c 10 -i 0.2
endif
ifeq ($(TEST_CASE),long_test)
	@./$(PARSER) -c 10000 -i 1.0
endif
ifeq ($(TEST_CASE),overkill_test)
	@./$(PARSER) -c 10000 -i 0.2 -p 5 -x
endif

show_config:
	@cat $(TEST_CONF)

run: conf
	@./$(TESTER)

remote_run: conf
	scp $(FILES) $(REMOTE_LOGIN):$(REMOTE_WORKSPACE)
	ssh $(REMOTE_LOGIN) "mkdir $(REMOTE_WORKSPACE)/$(LOG_FOLDER)" || true
	ssh $(REMOTE_LOGIN) "cd $(REMOTE_WORKSPACE)/ && $(REMOTE_WORKSPACE)/$(TESTER)"

remote_clean:
	ssh $(REMOTE_LOGIN) "rm -r $(REMOTE_WORKSPACE)/$(LOG_FOLDER)" || true

clean:
	rm -rf $(LOG_FOLDER) || true

.PHONY: all conf run show_config remote_run remote_clean clean
