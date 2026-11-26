-include .env
include ./.make/main.mk

SCENARIO_NAME?=$(PROJECT_NAME)

FACTORIO_ARGS:=--load-scenario $(PROJECT_NAME)/$(SCENARIO_NAME)
PROJECT_DEST:=$(FACTORIO_MOD_DIR)/$(PROJECT_NAME)

DEPLOY_FILES:=src/** LICENSE.md README.md

# Copies the deploy files into $(1) and fills in the version
define copy-mod
	rm -rf "$(1)"
	mkdir -p "$(1)"
	cp -r $(DEPLOY_FILES) "$(1)"
	sed -i 's/\$$(VERSION)/$(VERSION)/' "$(1)/info.json"
endef

run: ##@run Run factorio and start a new game from the deployed scenario
	$(FACTORIO_EXE) $(FACTORIO_ARGS)

deploy: ##@run Deploy the src files to the factorio mods folder
	@echo Deploying $(PROJECT_NAME) \($(VERSION)\) to $(PROJECT_DEST)
	$(call copy-mod,$(PROJECT_DEST))

