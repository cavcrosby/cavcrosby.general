include base.mk

# recursively expanded variables
POETRY_PYTHON_CONSTRAINT = ~3.10

# targets
COLLECTION = collection
GALAXY_YML = galaxy.yml
COLLECTION_META = collection-meta
PUBLISH = publish

# to be passed in at make runtime
ANSIBLE_GALAXY_TOKEN =

# include other generic makefiles
include python.mk
include ansible.mk
# overrides defaults set by included makefiles
ANSIBLE_SRC = $(shell find . \
	\( \
		\( -type f \) \
		-or \( -name '*.yml' \) \
	\) \
	-and ! \( -name 'galaxy.yml' \) \
	-and ! \( -name '.python-version' \) \
	-and ! \( -path '*.git*' \) \
)

# executables
executables = \
	${base_executables}\
	${ansible_executables}

# simply expanded variables
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))
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
>	@echo '  ${ANSIBLE_LINT}        - lints the Ansible configuration code (yml)'
>	@echo '  ${CLEAN}               - removes files generated from other targets'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  ANSIBLE_GALAXY_TOKEN       - represents the Ansible Galaxy API key'

.PHONY: ${SETUP}
${SETUP}: ${PYENV_REQUIREMENTS_SETUP}

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
>	@[ -n "${ANSIBLE_GALAXY_TOKEN}" ] || { echo "make: ANSIBLE_GALAXY_TOKEN was not passed into make"; exit 1; }
>	${ANSIBLE_GALAXY} collection publish ./cavcrosby-general-*.tar.gz --token "${ANSIBLE_GALAXY_TOKEN}"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force ./cavcrosby-general-*.tar.gz
>	rm --force "./${GALAXY_YML}"
