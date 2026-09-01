.PHONY: all native full test verify clean bump-major bump-minor bump-patch health monitor diagnostics

all: native full test verify

bump-major:
	@./bump_version.sh major

bump-minor:
	@./bump_version.sh minor

bump-patch:
	@./bump_version.sh patch

native:
	@./build_native_app.sh

full:
	@./build_full_pkg.sh

test:
	@./tests/run_tests.sh

health:
	@./scripts/health_check.sh

monitor:
	@./scripts/monitor_telemetry.sh stream

diagnostics:
	@./scripts/monitor_telemetry.sh summary 1h

verify:
	@echo "=================================================="
	@echo " Verifying All Distributables                     "
	@echo "=================================================="
	@./verify_pkg.sh dist/MacProductivitySuite-Full.pkg
	@./verify_pkg.sh dist/MacProductivitySuite-Native.pkg
	@ls -lh dist/*.pkg

clean:
	@rm -rf dist
