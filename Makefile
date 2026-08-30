.PHONY: all native full clean verify

all: native full

native:
	@./build_native_app.sh

full:
	@./build_full_pkg.sh

verify:
	@echo "=================================================="
	@echo " Verifying All Distributables                     "
	@echo "=================================================="
	@ls -lh dist/*.pkg
	@test -f "dist/MacProductivitySuite-Native.pkg" && echo "✅ Native Package: OK ($(shell ls -lh dist/MacProductivitySuite-Native.pkg | awk '{print $$5}'))"
	@test -f "dist/MacProductivitySuite-Full.pkg" && echo "✅ Full Package (with Karabiner & Hammerspoon): OK ($(shell ls -lh dist/MacProductivitySuite-Full.pkg | awk '{print $$5}'))"

clean:
	@rm -rf dist
