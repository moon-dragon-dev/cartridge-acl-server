.PHONY: test

local_build:
	cartridge build

local_start:
	cartridge start -d

local_stop:
	cartridge stop

local_clean: local_stop
	rm -rf .rocks
	cartridge clean

local_bootstrap: local_clean local_build local_start
	cartridge replicasets setup --file local/replicasets.yml
	cartridge failover setup --file local/failover.yml

deps_for_test:
	tarantoolctl rocks install luacheck
	tarantoolctl rocks install luatest
	tarantoolctl rocks install luacov

test_only:
	rm -rf tmp/luacov.*
	rm -rf tmp/db_test
	.rocks/bin/luacheck .
	.rocks/bin/luatest test/ --coverage -v
	.rocks/bin/luacov . && grep -A999 '^Summary' tmp/luacov.report.out

test: local_clean local_build deps_for_test test_only
