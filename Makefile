prefix ?= /usr/local
destdir ?= ${prefix}
config ?= release
arch ?=

BUILD_DIR ?= build/$(config)
SRC_DIR ?= stable
binary := $(BUILD_DIR)/stable
tests_binary := $(BUILD_DIR)/test

ifdef config
  ifeq (,$(filter $(config),debug release))
    $(error Unknown configuration "$(config)")
  endif
endif

ifeq ($(config),release)
	PONYC = ponyc
else
	PONYC = ponyc --debug
endif

ifneq ($(arch),)
  arch_arg := --cpu $(arch)
endif

ifneq ($(wildcard .git),)
  tag := $(shell cat VERSION)-$(shell git rev-parse --short HEAD)
else
  tag := $(shell cat VERSION)
endif

SOURCE_FILES := $(shell find $(SRC_DIR) -path $(SRC_DIR)/test -prune -o -name \*.pony)
TEST_FILES := $(shell find $(SRC_DIR)/test -name \*.pony)
VERSION := "$(tag) [$(config)]"
GEN_FILES_IN := $(shell find $(SRC_DIR) -name \*.pony.in)
GEN_FILES = $(patsubst %.pony.in, %.pony, $(GEN_FILES_IN))

%.pony: %.pony.in
	sed s/%%VERSION%%/$(VERSION)/ $< > $@

$(binary): $(GEN_FILES) $(SOURCE_FILES) | $(BUILD_DIR)
	${PONYC} $(arch_arg) $(SRC_DIR) -o ${BUILD_DIR}

install: $(binary)
	mkdir -p $(DESTDIR)$(prefix)/bin
	cp $^ $(DESTDIR)$(prefix)/bin

$(tests_binary): $(GEN_FILES) $(SOURCE_FILES) $(TEST_FILES) | $(BUILD_DIR)
	${PONYC} $(arch_arg) --debug -o ${BUILD_DIR} $(SRC_DIR)/test

integration: $(binary) $(tests_binary)
	$(tests_binary) --only=integration

test: $(tests_binary)
	$^ --exclude=integration

clean:
	rm -rf $(BUILD_DIR)

all: $(binary)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# package_name, _version, and _iteration can be overridden by Travis or AppVeyor
package_base_version ?= $(tag)
package_iteration ?= "1"
package_name ?= "pony-stable"
package_version = $(package_base_version)-$(package_iteration)
archive = $(package_name)-$(package_version).tar
package = build/$(package_name)-$(package_version)

# Note: linux only
define EXPAND_DEPLOY
deploy: test
	$(SILENT)bash .bintray.bash debian "$(package_base_version)" "$(package_name)"
	$(SILENT)bash .bintray.bash rpm    "$(package_base_version)" "$(package_name)"
	$(SILENT)bash .bintray.bash source "$(package_base_version)" "$(package_name)"
	$(SILENT)rm -rf build/bin
	@mkdir -p build/bin
	@mkdir -p $(package)/usr/bin
	@mkdir -p $(package)/usr/lib/pony-stable/$(package_version)/bin

	$(SILENT)cp $(BUILD_DIR)/stable $(package)/usr/lib/pony-stable/$(package_version)/bin

	$(SILENT)ln -f -s /usr/lib/pony-stable/$(package_version)/bin/stable $(package)/usr/bin/stable
	$(SILENT)fpm -s dir -t deb -C $(package) -p build/bin --name $(package_name) --version $(package_base_version) --iteration "$(package_iteration)" --description "Pony dependency manager" --provides "pony-stable"
	$(SILENT)fpm -s dir -t rpm -C $(package) -p build/bin --name $(package_name) --version $(package_base_version) --iteration "$(package_iteration)" --description "Pony dependency manager" --provides "pony-stable"
	$(SILENT)git archive HEAD > build/bin/$(archive)
	$(SILENT)bzip2 build/bin/$(archive)
	$(SILENT)rm -rf $(package) build/bin/$(archive)
endef

$(eval $(call EXPAND_DEPLOY))

.PHONY: all clean deploy install test integration
