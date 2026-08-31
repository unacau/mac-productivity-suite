.PHONY: all native full test verify clean bump-major bump-minor bump-patch

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

verify:
	@echo "=================================================="
	@echo " Verifying All Distributables                     "
	@echo "=================================================="
	@./verify_pkg.sh dist/MacProductivitySuite-Full.pkg
	@./verify_pkg.sh dist/MacProductivitySuite-Native.pkg
	@ls -lh dist/*.pkg

clean:
	@rm -rf dist
