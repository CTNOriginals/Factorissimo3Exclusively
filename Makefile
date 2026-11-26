-include .env
include ./.make/main.mk

SCENARIO_NAME?=$(PROJECT_NAME)

FACTORIO_ARGS:=--load-scenario $(PROJECT_NAME)/$(SCENARIO_NAME)

run: ##@run Run factorio and start a new game from the deployed scenario
	$(FACTORIO_EXE) $(FACTORIO_ARGS)

