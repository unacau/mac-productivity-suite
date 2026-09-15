.PHONY: all build native package test health validate checksums monitor diagnostics clean bump-major bump-minor bump-patch install release

all: validate test native checksums health

build: native

native:
	@./build_native_app.sh

package: native

validate:
	@echo "Checking version synchronization..."
	@V_TXT=$$(cat VERSION.txt | tr -d '[:space:]'); \
	B_TXT=$$(cat BUILD.txt | tr -d '[:space:]'); \
	PLIST="src/ChromeQuickAccess/Info.plist"; \
	V_PLIST=$$(plutil -extract CFBundleShortVersionString raw "$$PLIST" 2>/dev/null || echo "missing"); \
	B_PLIST=$$(plutil -extract CFBundleVersion raw "$$PLIST" 2>/dev/null || echo "missing"); \
	if [ "$$V_TXT" != "$$V_PLIST" ] || [ "$$B_TXT" != "$$B_PLIST" ]; then \
		echo "❌ Version mismatch: VERSION.txt ($$V_TXT/$$B_TXT) vs Info.plist ($$V_PLIST/$$B_PLIST)"; \
		exit 1; \
	fi; \
	echo "✅ Version synchronized ($$V_TXT, Build $$B_TXT)"
	@echo "Checking script syntax..."
	@bash -n release.sh build_native_app.sh bump_version.sh install.sh scripts/*.sh tests/*.sh
	@echo "✅ All shell scripts valid"

test:
	@./tests/run_tests.sh

health:
	@./scripts/health_check.sh

checksums:
	@if [ -f "dist/Khomyak.dmg" ]; then \
		cd dist && shasum -a 256 Khomyak.dmg > checksums.txt && echo "✅ dist/checksums.txt generated: $$(cat checksums.txt)" && cd ..; \
	else \
		echo "ℹ️ dist/Khomyak.dmg not built yet. Run 'make native' first."; \
	fi

monitor:
	@./scripts/monitor_telemetry.sh stream

diagnostics:
	@./scripts/monitor_telemetry.sh summary 1h

bump-major:
	@./bump_version.sh major

bump-minor:
	@./bump_version.sh minor

bump-patch:
	@./bump_version.sh patch

release:
	@./release.sh

install:
	@./install.sh

clean:
	@rm -rf dist .build
