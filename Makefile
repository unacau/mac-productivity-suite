.PHONY: all package clean

APP_NAME = MacProductivitySuite
VERSION = 1.0.0
PACKAGE_NAME = $(APP_NAME)-$(VERSION).zip

all: package

package:
	@echo "Packaging $(PACKAGE_NAME)..."
	@mkdir -p dist/$(APP_NAME)
	@cp -R hammerspoon dist/$(APP_NAME)/
	@cp -R karabiner dist/$(APP_NAME)/
	@cp install.sh dist/$(APP_NAME)/
	@cd dist && zip -r $(PACKAGE_NAME) $(APP_NAME)
	@echo "Package created at dist/$(PACKAGE_NAME)"

clean:
	@rm -rf dist
