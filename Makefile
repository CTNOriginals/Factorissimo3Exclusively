-include .env
include ./.make/main.mk

SCENARIO_NAME?=$(PROJECT_NAME)
SCENARIO_SRC:=src

# Only the paths set in .env are passed to factorio, so it (or a launcher) uses its own defaults for the rest.
# This is evaluated before the defaults below are filled in.
FACTORIO_ARGS:=$(strip \
	$(if $(FACTORIO_CONFIG),--config "$(FACTORIO_CONFIG)") \
	$(if $(FACTORIO_MOD_DIR),--mod-directory "$(FACTORIO_MOD_DIR)"))

# Paths that are not set in .env resolve from FACTORIO_DIR, like a standalone factorio install
FACTORIO_EXE?=$(FACTORIO_DIR)/bin/x64/factorio.exe
FACTORIO_MOD_DIR?=$(FACTORIO_DIR)/mods
FACTORIO_LOG?=$(FACTORIO_DIR)/factorio-current.log

PROJECT_DEST:=$(FACTORIO_MOD_DIR)/$(PROJECT_NAME)

# Fails the targets that need a factorio install when FACTORIO_DIR is not set
.PHONY: require-factorio-dir
require-factorio-dir:
	@test -n "$(FACTORIO_DIR)" || { echo "FACTORIO_DIR is not set, copy .env.example to .env and fill it in"; exit 1; }

run play deploy log edit pull: require-factorio-dir

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

# Runs factorio with the arguments in $(1), followed by FACTORIO_RUN_ARGS for anything extra,
# e.g. make run FACTORIO_RUN_ARGS="--load-game path/to/save.zip"
define run-factorio
	"$(FACTORIO_EXE)" $(strip $(FACTORIO_ARGS) $(1) $(FACTORIO_RUN_ARGS))
endef

run: ##@run Run factorio
	$(call run-factorio)

play: deploy ##@run Deploy the mod and start a new game from its scenario
	$(call run-factorio,--load-scenario "$(PROJECT_NAME)/$(SCENARIO_NAME)")

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

# zip is not part of Git for Windows, so the tar.exe that ships with Windows is used when zip is missing.
# It writes a zip from the .zip extension, with the forward slashes in paths that factorio needs.
WINDOWS_TAR?=/c/Windows/System32/tar.exe

package: ##@release Build the mod zip for the mod portal into build/
	@echo Packaging $(PACKAGE_NAME)
	$(call copy-mod,$(PACKAGE_DIR)/$(PACKAGE_NAME))
	rm -f "$(PACKAGE_DIR)/$(PACKAGE_NAME).zip"
	cd "$(PACKAGE_DIR)" && if command -v zip >/dev/null; then \
		zip -qr "$(PACKAGE_NAME).zip" "$(PACKAGE_NAME)"; \
	else \
		"$(WINDOWS_TAR)" -a -cf "$(PACKAGE_NAME).zip" "$(PACKAGE_NAME)"; \
	fi
	rm -rf "$(PACKAGE_DIR)/$(PACKAGE_NAME)"
