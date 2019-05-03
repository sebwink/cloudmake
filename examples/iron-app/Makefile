# #############################################################################
# CLOUDMAKE ###################################################################
# #############################################################################

SELF := $(abspath $(firstword $(MAKEFILE_LIST)))
SELFDIR := $(dir $(SELF))

# DEPENDENCIES
SHYAML ?= $(shell which shyaml)
DOCKER ?= $(shell which docker)
DOCKER_COMPOSE ?= $(shell which docker-compose)
CTOP ?= $(shell which ctop)
KOMPOSE ?= $(shell which kompose)
KUBECTL ?= $(shell which kubectl)

SCRIPTS ?= $(SELFDIR).cloudmake

# UTILS
space :=
space +=
upper-case = $(shell echo $(1) | tr a-z A-Z)

# CONFIGURATION 
CONFIGFILE = $(if $(shell ls -a $(SELFDIR) | grep ".cloudmake.config"),$(SELFDIR).cloudmake.config,)
read-config = $(if $(CONFIGFILE),$(shell cat $(CONFIGFILE) | grep "^$(1) " | awk '{ print $$2 }'),)
config = $(if $(call read-config,$(1)),$(call read-config,$(1)),$(2))

SCRATCH := $(SELFDIR).cloudmake/scratch

scratch:
	@mkdir -p $(SCRATCH)

# CLOUDMAKE SERVICES
CLOUDMAKE_COMPOSE := $(SELFDIR).cloudmake/compose
CLOUDMAKE := -f $(CLOUDMAKE_COMPOSE)/base.yml -f $(CLOUDMAKE_COMPOSE)/prod.yml

# DOCKER REGISTRIES
CLOUDMAKE_REGISTRY_PORT ?= 5000
CLOUDMAKE_REGISTRY ?= localhost:$(CLOUDMAKE_REGISTRY_PORT)
DEV_REGISTRY ?= $(CLOUDMAKE_REGISTRY)
PROD_REGISTRY ?= $(CLOUDMAKE_REGISTRY)
RELEASE_REGISTRY ?= docker.io

# GIT REPO STATE
BRANCH := $(shell cd $(SELFDIR) && git branch | grep '\*' | sed  's/\* //g')
VERSION_TAG := $(shell cd $(SELFDIR) && git describe --tags --always --dirty)
TAG ?= $(call config,TAG,$(BRANCH)-$(VERSION_TAG))

# PROJECT
PROJECT_NAME ?= $(lastword $(subst /, ,$(SELFDIR)))
COMPOSE_PROJECT_NAME ?= $(PROJECT_NAME)
DOCKER_USER ?= $(PROJECT_NAME)

# INPUT 
#
# COMPOSE FILES AND WHERE TO FIND THEM
COMPOSE_PATH ?= $(subst :, ,$(call config,COMPOSE_PATH,docker/compose))

original-compose-path = $(subst $(space),:,$(COMPOSE_PATH))

compose-path-display:
	@echo $(call original-compose-path)

compose-files = -f $(shell ls -m $(1)/*$(2).yml | sed 's/,/ -f /g')

base-compose-files = $(call compose-files,$(1),base)
dev-compose-files = $(call compose-files,$(1),dev)
prod-compose-files = $(call compose-files,$(1),prod)

dev-composition = $(call base-compose-files,$(1)) $(call dev-compose-files,$(1))
prod-composition = $(call base-compose-files,$(1)) $(call prod-compose-files,$(1))

COMPOSE := $(call config,COMPOSE,docker/compose)
BASE := -f $(shell ls -m $(COMPOSE)/*base.yml | sed 's/,/ -f /g')
DEV := $(BASE) -f $(shell ls -m $(COMPOSE)/*dev.yml | sed 's/,/ -f /g')
PROD := $(BASE) -f $(shell ls -m $(COMPOSE)/*prod.yml | sed 's/,/ -f /g')

# DOCKER COMPOSE
COMPOSE_BASE_ENV := DOCKER_USER=$(DOCKER_USER) COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME)
COMPOSE_DEV_ENV := $(COMPOSE_BASE_ENV) DOCKER_TAG=dev-$(TAG)
COMPOSE_PROD_ENV := $(COMPOSE_BASE_ENV) DOCKER_TAG=$(TAG)
UP_ARGS ?= -d 
DOWN_ARGS ?= -v
BUILD_ARGS ?=
RMI_ARGS ?= --force 
LOGS_ARGS ?= --follow
CTOP_ARGS ?= 
CTOP_FILTER ?= $(COMPOSE_PROJECT_NAME)_

# OUTPUT
OPS ?= $(SELFDIR)ops

K8S ?= $(OPS)/k8s
K8S_DEV_ROOT ?= $(OPS)/k8s/dev
K8S_PROD_ROOT ?= $(OPS)/k8s/prod
K8S_DEV_PATH ?= $(K8S_DEV_ROOT)/$(TAG)
K8S_PROD_PATH ?= $(K8S_PROD_ROOT)/$(TAG)

SWARM ?= $(OPS)/swarm

###############################################################################
# CLOUDMAKE SYSTEM ############################################################
###############################################################################

system-report:
	@#

registry:
	@#

k8s-cluster:
	@#

swarm-cluster:
	@#

###############################################################################
### VALIDATE COMPOSITION ######################################################
###############################################################################

# Validation of current compose file aggregation
validate = $(COMPOSE_$(call upper-case,$(2))_ENV) \
		$(DOCKER_COMPOSE) $(call $(2)-composition,$(1)) config --quiet

validation: dev-validation 
	@#

# Validate the current development compose file aggregate
dev-validation:
	@$(foreach path,$(COMPOSE_PATH),$(call validate,$(path),dev);)

# Validate the current production compose file aggregate
prod-validation:
	@$(foreach path,$(COMPOSE_PATH),$(call validate,$(path),prod);)

###############################################################################
### LIST SERVICES #############################################################
###############################################################################

# List services defined in the aggregated compose files
list-services = $(COMPOSE_$(call upper-case,$(2))_ENV) \
		$(DOCKER_COMPOSE) $(call $(2)-composition,$(1)) config --services

get-services-list = $(foreach path,$(COMPOSE_PATH),$(shell $(call list-services,$(path),$(1))))

services-list: dev-services-list
	@#

# List services defined in the aggregated development compose files
dev-services-list:
	@$(foreach path,$(COMPOSE_PATH),$(call list-services,$(path),dev);)

# List services defined in the aggregated production compose files
prod-services-list:
	@$(foreach path,$(COMPOSE_PATH),$(call list-services,$(path),prod);)

###############################################################################
# LIST VOLUMES ################################################################
###############################################################################

# List volumes defined in the aggregated compose files
list-volumes = $(COMPOSE_$(call upper-case,$(2))_ENV) \
		$(DOCKER_COMPOSE) $(call $(2)-composition,$(1)) config --volumes

get-volumes-list = $(foreach path,$(COMPOSE_PATH),$(shell $(call list-volumes,$(path),$(1))))

volumes-list: dev-volumes-list
	@#

# List volumes defined in the aggregated development compose files
dev-volumes-list:
	@$(foreach path,$(COMPOSE_PATH),$(call list-volumes,$(path),dev);)

# List volumes defined in the aggregated production compose files
prod-volumes-list:
	@$(foreach path,$(COMPOSE_PATH),$(call list-volumes,$(path),prod);)

###############################################################################
# SHOW CONFIGURATION ##########################################################
###############################################################################

# Display configuration as defined in the aggregated compose files
_display-config = $(COMPOSE_$(call upper-case,$(2))_ENV) \
		$(DOCKER_COMPOSE) $(1) config

display-config = $(call _display-config,$(call $(2)-composition,$(1)),$(2))

path-to-target = $(subst /,-,$(1))
get-compose-targets = $(foreach path,$(COMPOSE_PATH),$(1)-config-display@$(call path-to-target,$(path)))
write-path-file = $(MAKE) --no-print-directory $(1) > .$(1).yml
target-compose = $(foreach target,$(call get-compose-targets,$(1)),-f .$(target).yml)
compose-merge = $(call _display-config,$(call target-compose,$(1)),$(1))

_config-display = \
	$(foreach target,$(call get-compose-targets,$(1)),$(call write-path-file,$(target));) \
	$(call compose-merge,$(1)); \
	$(foreach target,$(call get-compose-targets,$(1)),rm .$(target).yml;)
    

config-display: dev-config-display 
	@#

dev-config-display:
	@$(call _config-display,dev)

prod-config-display:
	@$(call _config-display,prod)

config-display@%: dev-config-display@%
	@#

dev-config-display@%:
	@$(call display-config,$(subst -,/,$*),dev)

prod-config-display@%:
	@$(call display-config,$(subst -,/,$*),prod)

config-display@bypath: dev-config-display@bypath
	@#

dev-config-display@bypath:
	@$(foreach path,$(COMPOSE_PATH),echo $(path); echo ""; $(call display-config,$(path),dev);)

prod-config-display@bypath:
	@$(foreach path,$(COMPOSE_PATH),echo $(path); echo ""; $(call display-config,$(path),prod);)

###############################################################################
# IMAGE CONTEXT ###############################################################
###############################################################################

_image-context = \
    $(MAKE) --no-print-directory config-display > $(SCRATCH)/stack.yml; \
    $(SCRIPTS)/image_context.py $(1); \
	rm $(SCRATCH)/stack.yml

image-context-list@%: dev-image-context-list@%
	@#

dev-image-context-list@%: scratch
	@$(call _image-context,dev all $*)

image-context-list: dev-image-context-list 
	@#

dev-image-context-list: scratch
	@$(call _image-context,dev all)

prod-image-context-list@%: scratch
	@$(call _image-context,prod all $*)

prod-image-context-list: scratch
	@$(call _image-context,prod all)

image-context-list@build: dev-image-context-list@build 
	@#

dev-image-context-list@build: scratch
	@$(call _image-context,dev build)

prod-image-context-list@build: scratch
	@$(call _image-context,prod build)

###############################################################################
# LIST BUILT IMAGES ###########################################################
###############################################################################

built-images-list@context: built-dev-images-list@context

built-dev-images-list@context:
	echo $@

built-prod-images-list@context:
	echo $@

built-images-list: built-dev-images-list 

built-dev-images-list:
	echo $@

built-prod-images-list:
	echo $@

###############################################################################
# BUILD IMAGES ################################################################
###############################################################################

_build = $(COMPOSE_$(1)_ENV) $(DOCKER_COMPOSE) $($(1)) build $(BUILD_ARGS) $(2)

build: dev-build 
	@#

dev-build:
	@$(call _build,DEV,)

build@%: dev-build@%
	@#

dev-build@%:
	@$(call _build,DEV,$*)

prod-build:
	@$(call _build,PROD,)

prod-build@%:
	@$(call _build,PROD,$*)

###############################################################################
# PUSH IMAGES #################################################################
###############################################################################

_push = IMAGE=$(1) REGISTRY=$(2) $(DOCKER_COMPOSE) $(CLOUDMAKE) up push-image 
_get_image = $(shell make --no-print-directory -f $(SELF) show-$(2)-image-context@$(1))

#PUSH_DEV_SERVICES := $(patsubst %,push@%,$(DEV_SERVICES))
#PUSH_PROD_SERVICES := $(patsubst %,push@%,$(PROD_SERVICES))

push: dev-push 
	@#

dev-push: $(PUSH_DEV_SERVICES) 
	@#

push@%: dev-push@%
	@#

dev-push@%: dev-build@%
	@$(call _push,$(call _get_image,$*,dev),$(DEV_REGISTRY))

prod-push: $(PUSH_PROD_SERVICES)
	@#

prod-push@%: prod-build@%
	@$(call _push,$(call _get_image,$*,prod),$(PROD_REGISTRY))

###############################################################################
# START SERVICES ##############################################################
###############################################################################

_up = $(COMPOSE_$(1)_ENV) $(DOCKER_COMPOSE) $($(1)) up $(UP_ARGS) $(2)

up@%: dev-up@%
	@#

dev-up@%: dev-down@%
	@trap 'trap - INT; exit 0' INT; $(call _up,DEV,$*) 2> /dev/null

prod-up@%: prod-down@%
	@trap 'trap - INT; exit 0' INT; $(call _up,PROD,$*) 2> /dev/null

up: dev-up
	@#

dev-up: dev-down 
	@trap 'trap - INT; exit 0' INT; $(call _up,DEV,) 2> /dev/null

prod-up: prod-down 
	@trap 'trap - INT; exit 0' INT; $(call _up,PROD,) 2> /dev/null

###############################################################################
# MONITORING ##################################################################
###############################################################################

_top = $(COMPOSE_$(1)_ENV) $(DOCKER_COMPOSE) $($(1)) top $(2)

top@%:
	@$(call _top,DEV,$*)

top:
	@$(call _top,DEV,)

_logs = $(COMPOSE_$(1)_ENV) $(DOCKER_COMPOSE) $($(1)) logs $(LOGS_ARGS) $(2)

logs@%:
	@trap 'trap - INT; exit 0' INT; $(call _logs,DEV,$*) 2> /dev/null

logs:
	@trap 'trap - INT; exit 0' INT; $(call _logs,DEV,) 2> /dev/null

# ctop:

#    - https://ctop.sh/
#    - https://github.com/bcicen/ctop

ctop@%:
	@#

ctop:
	@$(CTOP) $(CTOP_ARGS) -f $(CTOP_FILTER)

###############################################################################
# STOP SERVICES ###############################################################
###############################################################################

_down = $(COMPOSE_$(1)_ENV) $(DOCKER_COMPOSE) $($(1)) rm --force --stop $(DOWN_ARGS) $($(2))

down@%: dev-down@%
	@echo $@

dev-down@%:
	@$(call _down,DEV,$*)

prod-down@%:
	@$(call _down,PROD,$*)

down: dev-down

dev-down:
	@$(call _down,DEV,)

prod-down:
	@$(call _down,PROD,)

###############################################################################
# IMAGES ######################################################################
###############################################################################

_images = $(COMPOSE_$(1)_ENV) $(DOCKER_COMPOSE) $($(1)) images $(IMAGES_ARGS) $*

images:
	@$(call _images,DEV,)

images@%:
	@$(call _images,DEV,$*)

# REMOVE IMAGES ###############################################################

rmi: rmi-dev rmi-prod

rmi-dev:
	echo $@

rmi-prod:
	echo $@

rmi@%: rmi-dev@% rmi-prod@%

rmi-dev@%:
	$(DOCKER) rmi $(RMI_ARGS) $(shell $(DOCKER) images $(DOCKER_USER)/$* | grep dev-$(TAG) | awk ' { print $$3 } ')

rmi-prod@%:
	$(DOCKER) rmi $(RMI_ARGS) $(shell $(DOCKER) images $(DOCKER_USER)/$* | grep $(TAG) | awk ' { print $$3 } ')

rmi@built: rmi-dev@built rmi-dev@built

rmi-dev@built:
	$(DOCKER) rmi $(RMI_ARGS) $(shell $(DOCKER) images | grep $(call get_images,dev) | tail -n +2 | awk ' { print $$3 }' | uniq)

rmi-prod@built:
	$(DOCKER) rmi $(RMI_ARGS) $(shell $(DOCKER) images | grep $(call get_images,prod) | tail -n +2 | awk ' { print $$3 }' | uniq)

###############################################################################
###############################################################################
# # # KUBERNETES # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ##
###############################################################################
###############################################################################

# Stack Conversion powered by Kompose:

#   - https://github.com/kubernetes/kompose
#   - http://kompose.io/

k8s@%:
	echo $@

rm-k8s: rm-k8s-dev rm-k8s-prod 
	@echo "Removed all Kubernetes configuration for current tag."

rm-k8s@all: rm-k8s-dev@all rm-k8s-prod@all
	@echo "Removed all Kubernetes configuration globally."

rm-k8s@%: rm-k8s-dev@% rm-k8s-prod@%
	@echo "Removed all Kubernetes configuration for tag $*"

k8s-dev: validate-dev
	@rm -rf $(K8S_DEV_PATH)
	@mkdir -p $(K8S_DEV_PATH)
	@make --no-print-directory -f $(SELF) show-dev-config > $(K8S_DEV_PATH)/.stack.yml
	@$(KOMPOSE) -f $(K8S_DEV_PATH)/.stack.yml -o $(K8S_DEV_PATH) convert

rm-k8s-dev:
	@rm -rf $(K8S_DEV_PATH)

rm-k8s-dev@all:
	@rm -rf $(K8S_DEV_ROOT)

rm-k8s-dev@%:
	@rm -rf $(K8S_DEV_ROOT)/$*

k8s-prod: validate-prod
	@rm -rf $(K8S_PROD_PATH)
	@mkdir -p $(K8S_PROD_PATH)
	@make --no-print-directory -f $(SELF) show-prod-config > $(K8S_PROD_PATH)/.stack.yml
	@$(KOMPOSE) -f $(K8S_PROD_PATH)/.stack.yml -o $(K8S_PROD_PATH) convert

rm-k8s-prod:
	@rm -rf $(K8S_PROD_PATH)

rm-k8s-prod@all:
	@rm -rf $(K8S_PROD_ROOT)

rm-k8s-prod@%:
	@rm -rf $(K8S_PROD_ROOT)/$*

k8s-deploy:
	@#

###############################################################################
# DOCKER SWARM ################################################################
###############################################################################

swarm:
	echo $@

###############################################################################
# _DEBUG_ #####################################################################
###############################################################################

show-env:
	@# https://www.cmcrossroads.com/article/dumping-every-makefile-variable
	@$(foreach V,                                                \
		$(sort $(.VARIABLES)),                                   \
		    $(if                                                 \
                 $(filter-out environment% default automatic,    \
                     $(origin $V)                                \
				 ),                                              \
				 $(info $V=$($V) ($(value $V))                   \
		    )                                                    \
		)                                                        \
    )
