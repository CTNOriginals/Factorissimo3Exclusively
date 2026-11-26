-include .env
include ./.make/main.mk

SCENARIO_NAME?=$(PROJECT_NAME)
SCENARIO_SRC:=src

FACTORIO_ARGS:=--load-scenario $(PROJECT_NAME)/$(SCENARIO_NAME)
PROJECT_DEST:=$(FACTORIO_MOD_DIR)/$(PROJECT_NAME)
FACTORIO_LOG?=$(FACTORIO_DIR)/factorio-current.log

MOD_FILES:=mod/** LICENSE.md README.md

# Copies the mod files and the scenario into $(1) and fills in the version
define copy-mod
	rm -rf "$(1)"
	mkdir -p "$(1)"
	cp -r $(MOD_FILES) "$(1)"
	mkdir -p "$(1)/scenarios/$(SCENARIO_NAME)"
	cp -r $(SCENARIO_SRC)/. "$(1)/scenarios/$(SCENARIO_NAME)"
	sed -i 's/\$$(VERSION)/$(VERSION)/' "$(1)/info.json"
endef

run: ##@run Run factorio and start a new game from the deployed scenario
	$(FACTORIO_EXE) $(FACTORIO_ARGS)

deploy: ##@run Deploy the mod to the factorio mods folder
	@echo Deploying $(PROJECT_NAME) \($(VERSION)\) to $(PROJECT_DEST)
	$(call copy-mod,$(PROJECT_DEST))

log: ##@run Follow the factorio log and print only the lines logged by this mod
	@tail -n +1 -F "$(FACTORIO_LOG)" 2>/dev/null | \
		awk -v info="$(PROJECT_DEST)/info.json" -f scripts/mod-log.awk

# The map editor only opens scenarios from the user scenarios folder and saves
# its loaded copy of every file back there, so the map is edited in that copy
# and only the map files are pulled back into src.
SCENARIO_EDIT_DIR:=$(FACTORIO_DIR)/scenarios/$(SCENARIO_NAME)
MAP_FILES:=blueprint.zip script.dat

edit: ##@map Copy the scenario to the user scenarios folder to open it in the map editor
	@echo Copying $(SCENARIO_NAME) to $(SCENARIO_EDIT_DIR)
	rm -rf "$(SCENARIO_EDIT_DIR)"
	mkdir -p "$(SCENARIO_EDIT_DIR)"
	cp -r $(SCENARIO_SRC)/. "$(SCENARIO_EDIT_DIR)"

pull: ##@map Copy the map saved by the map editor back into src, leaving the scripts alone
	@echo Pulling the map from $(SCENARIO_EDIT_DIR)
	$(foreach file,$(MAP_FILES),cp "$(SCENARIO_EDIT_DIR)/$(file)" "$(SCENARIO_SRC)/$(file)";)

PACKAGE_DIR:=build
PACKAGE_NAME:=$(PROJECT_NAME)_$(VERSION)

package: ##@release Build the mod zip for the mod portal into build/
	@echo Packaging $(PACKAGE_NAME)
	$(call copy-mod,$(PACKAGE_DIR)/$(PACKAGE_NAME))
	rm -f "$(PACKAGE_DIR)/$(PACKAGE_NAME).zip"
	cd "$(PACKAGE_DIR)" && zip -qr "$(PACKAGE_NAME).zip" "$(PACKAGE_NAME)"
	rm -rf "$(PACKAGE_DIR)/$(PACKAGE_NAME)"
