# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh

# targets
HELP = help
SETUP = setup
INSTALL = install
COLLECTION = collection
GALAXY_YML = galaxy.yml
PUBLISH = publish
LINT = lint
CLEAN = clean

# to be passed in at make runtime
ANSIBLE_GALAXY_TOKEN =

# executables
GIT = git
ENVSUBST = envsubst
ANSIBLE_GALAXY = ansible-galaxy
ANSIBLE_LINT = ansible-lint
PYTHON = python
PIP = pip
executables = \
	${PYTHON}\
	${ANSIBLE_GALAXY}\
	${ANSIBLE_LINT}

# simply expanded variables
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))
ansible_src_paths := $(shell find . \( -type f \) \
	-and \( -name '*.yml' \) \
	-and ! \( -name 'galaxy.yml' \) \
	-and ! \( -name 'galaxy.yml.shtpl' \) \
)

export COLLECTION_VERSION := $(shell ${GIT} describe --tags --abbrev=0 | sed 's/v//')

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${SETUP}               - installs the distro-independent dependencies for this'
>	@echo '                        collection'
>	@echo '  ${INSTALL}             - installs the collection on the system'
>	@echo '  ${COLLECTION}          - build the collection'
>	@echo '  ${GALAXY_YML}          - generate the collection metadata'
>	@echo '  ${PUBLISH}             - publish a collection build'
>	@echo '  ${LINT}                - lints the Ansible configuration code (yml)'
>	@echo '  ${CLEAN}               - removes files generated from other targets'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  ANSIBLE_GALAXY_TOKEN       - represents the Ansible Galaxy API key'

.PHONY: ${SETUP}
${SETUP}:
>	${PYTHON} -m ${PIP} install --upgrade "${PIP}"
>	${PYTHON} -m ${PIP} install \
		--requirement "./requirements.txt" \
		--requirement "./dev-requirements.txt"

.PHONY: ${INSTALL}
${INSTALL}: ${COLLECTION}
>	${ANSIBLE_GALAXY} collection install --force ./cavcrosby-general-*.tar.gz

.PHONY: ${COLLECTION}
${COLLECTION}: ${GALAXY_YML}
>	${ANSIBLE_GALAXY} collection build --force

${GALAXY_YML}: ${GALAXY_YML}.shtpl
>	${ENVSUBST} '$${COLLECTION_VERSION}' < "$<" > "$@"

.PHONY: ${PUBLISH}
${PUBLISH}:
>	@[ -n "${ANSIBLE_GALAXY_TOKEN}" ] || \
		{ echo "make: ANSIBLE_GALAXY_TOKEN was not passed into make"; exit 1; }

>	${ANSIBLE_GALAXY} collection publish \
		--token "${ANSIBLE_GALAXY_TOKEN}" \
		./cavcrosby-general-*.tar.gz

.PHONY: ${LINT}
${LINT}:
>	@for ansible_src_path in ${ansible_src_paths}; do \
		if echo "$${ansible_src_path}" | grep --quiet "-"; then \
			echo "make: $${ansible_src_path} should not contain a dash in the filename"; \
		fi \
	done
>	${ANSIBLE_LINT}

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force ./cavcrosby-general-*.tar.gz
>	rm --force "./${GALAXY_YML}"
