ALL_SOURCES:=$(shell git ls-tree --full-tree -r --name-only HEAD)
MAKE_DIR:=.make

$(MAKE_DIR):
	mkdir -p $@

requirements: $(MAKE_DIR)/requirements

$(MAKE_DIR)/requirements: $(MAKE_DIR) requirements/ci.txt
	python -m pip install -r requirements/ci.txt
	touch $@

pre-commit: $(MAKE_DIR)/pre-commit

$(MAKE_DIR)/pre-commit: $(MAKE_DIR) $(ALL_SOURCES) .pre-commit-config.yaml
	pre-commit run
	touch $@
