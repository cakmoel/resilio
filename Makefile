.PHONY: test test-unit test-system lint

test: test-unit

test-unit:
	bats tests/unit

test-system:
	@echo "⚠️  System tests are slow and destructive"
	@echo "Run manually: bats tests/system"

lint:
	shellcheck -x -e SC2006 bin/dlt.sh lib/*.sh config/dlt.conf
