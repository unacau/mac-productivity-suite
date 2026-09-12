.PHONY: all build native test health monitor diagnostics clean bump-major bump-minor bump-patch install

all: native test health

build: native

native:
	@./build_native_app.sh

test:
	@./tests/run_tests.sh

health:
	@./scripts/health_check.sh

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

install:
	@./install.sh

clean:
	@rm -rf dist .build
