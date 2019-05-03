# #############################################################################
# CLOUDMAKE ###################################################################
# #############################################################################

all: build 
	@#

SELF := $(abspath $(firstword $(MAKEFILE_LIST)))
SELFDIR := $(dir $(SELF))
CWD := $(shell pwd)

pwd:
	@echo $(CWD)

self:
	@echo $(SELFDIR)

# DEPENDENCIES
SHYAML ?= $(shell which shyaml)
DOCKER ?= $(shell which docker)
DOCKER_COMPOSE ?= $(shell which docker-compose)
CTOP ?= $(shell which ctop)
KOMPOSE ?= $(shell which kompose)
KUBECTL ?= $(shell which kubectl)

CLOUDMAKE_DEPS ?= $(SELFDIR).cloudmake
SCRIPTS ?= $(CLOUDMAKE_DEPS)

# UTILS
space :=
space +=
upper-case = $(shell echo $(1) | tr a-z A-Z)

# CONFIGURATION 
CONFIGFILE ?= $(if $(shell ls -a $(CWD) | grep ".cloudmake.config"),$(CWD)/.cloudmake.config,)
read-config = $(if $(CONFIGFILE),$(shell cat $(CONFIGFILE) | grep "^$(1) " | awk '{ print $$2 }'),)
config = $(if $(call read-config,$(1)),$(call read-config,$(1)),$(2))

# CLOUDMAKE SERVICES
CLOUDMAKE_COMPOSE := $(SELFDIR)$(CLOUDMAKE_DEPS)/compose
CLOUDMAKE := -f $(CLOUDMAKE_COMPOSE)/base.yml -f $(CLOUDMAKE_COMPOSE)/prod.yml

# DOCKER REGISTRIES
CLOUDMAKE_REGISTRY_PORT ?= 5000
CLOUDMAKE_REGISTRY ?= localhost:$(CLOUDMAKE_REGISTRY_PORT)
DEV_REGISTRY ?= $(CLOUDMAKE_REGISTRY)
PROD_REGISTRY ?= $(CLOUDMAKE_REGISTRY)
RELEASE_REGISTRY ?= docker.io

# GIT REPO STATE
BRANCH := $(shell git branch | grep '\*' | sed  's/\* //g')
VERSION_TAG := $(shell git describe --tags --always --dirty)
TAG ?= $(call config,TAG,$(BRANCH)-$(VERSION_TAG))

# PROJECT
PROJECT_NAME ?= $(lastword $(subst /, ,$(CWD)))
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

compose-path:
	@echo $(COMPOSE_PATH)

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
IMAGES_ARGS ?=

# OUTPUT
OPS ?= $(SELFDIR)ops

K8S ?= $(OPS)/k8s
K8S_DEV_PATH ?= $(K8S)/dev
K8S_PROD_PATH ?= $(K8S)/prod

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
# STACK CONFIGURATION #########################################################
###############################################################################

# Display configuration as defined in the aggregated compose files
_display-stack = $(COMPOSE_$(call upper-case,$(2))_ENV) \
		$(DOCKER_COMPOSE) $(1) config

display-stack = $(call _display-stack,$(call $(2)-composition,$(1)),$(2))

path-to-target = $(subst /,-,$(1))
get-compose-targets = $(foreach path,$(COMPOSE_PATH),$(1)-stack-display@$(call path-to-target,$(path)))
write-path-file = make --no-print-directory -f $(SELF) $(1) > .$(1).yml
target-compose = $(foreach target,$(call get-compose-targets,$(1)),-f .$(target).yml)
compose-merge = $(call _display-stack,$(call target-compose,$(1)),$(1))

_stack-display = \
	$(foreach target,$(call get-compose-targets,$(1)),$(call write-path-file,$(target));) \
	$(call compose-merge,$(1)) > .cloudmake.$(1).stack.yml; \
	$(foreach target,$(call get-compose-targets,$(1)),rm .$(target).yml;)
    

stack-display: dev-stack-display 
	@#

dev-stack-display: .cloudmake.dev.stack.yml
	@cat .cloudmake.dev.stack.yml
	@rm .cloudmake.dev.stack.yml

prod-stack-display: .cloudmake.prod.stack.yml
	@cat .cloudmake.prod.stack.yml
	@rm .cloudmake.prod.stack.yml

.cloudmake.dev.stack.yml:
	@$(call _stack-display,dev)

.cloudmake.prod.stack.yml:
	@$(call _stack-display,prod)

stack-display@%: dev-stack-display@%
	@#

dev-stack-display@%:
	@$(call display-stack,$(subst -,/,$*),dev)

prod-stack-display@%:
	@$(call display-stack,$(subst -,/,$*),prod)

stack-display@bypath: dev-stack-display@bypath
	@#

dev-stack-display@bypath:
	@$(foreach path,$(COMPOSE_PATH),echo $(path); echo ""; $(call display-stack,$(path),dev);)

prod-stack-display@bypath:
	@$(foreach path,$(COMPOSE_PATH),echo $(path); echo ""; $(call display-stack,$(path),prod);)

###############################################################################
# IMAGE CONTEXT ###############################################################
###############################################################################

_image-context = $(SCRIPTS)/image_context.py $(1) \
	&& rm .cloudmake.$(firstword $(1)).stack.yml

image-context-list@%: dev-image-context-list@%
	@#

dev-image-context-list@%: .cloudmake.dev.stack.yml
	@$(call _image-context,dev all $*)

image-context-list: dev-image-context-list 
	@#

dev-image-context-list: .cloudmake.dev.stack.yml
	@$(call _image-context,dev all)

prod-image-context-list@%: .cloudmake.prod.stack.yml
	@$(call _image-context,prod all $*)

prod-image-context-list: .cloudmake.prod.stack.yml
	@$(call _image-context,prod all)

image-context-list@build: dev-image-context-list@build 
	@#

dev-image-context-list@build: .cloudmake.dev.stack.yml
	@$(call _image-context,dev build)

prod-image-context-list@build: .cloudmake.prod.stack.yml
	@$(call _image-context,prod build)

###############################################################################
# LIST BUILT IMAGES ###########################################################
###############################################################################

built-images-list@all: built-dev-images-list@all

built-dev-images-list@all:
	echo $@

built-prod-images-list@all:
	echo $@

built-images-list: built-dev-images-list 

built-dev-images-list:
	echo $@

built-prod-images-list:
	echo $@

###############################################################################
# BUILD IMAGES ################################################################
###############################################################################

_build = $(COMPOSE_$(call upper-case,$(1))_ENV) \
		 $(DOCKER_COMPOSE) $(2) build $(BUILD_ARGS) $(3)

build: dev-build 
	@#

dev-build:
	@$(foreach path,$(COMPOSE_PATH),$(call _build,dev,$(call dev-composition,$(path)),);)

build@%: dev-build@%
	@#

dev-build@%: .cloudmake.dev.stack.yml
	@$(call _build,dev,-f $<,$*)
	@rm $<

prod-build:
	@$(foreach path,$(COMPOSE_PATH),$(call _build,prod,$(call prod-composition,$(path)),);)

prod-build@%: .cloudmake.prod.stack.yml
	@$(call _build,prod,-f $<,$*)
	@rm $<

###############################################################################
# PUSH IMAGES #################################################################
###############################################################################

_push = IMAGE=$(1) REGISTRY=$(2) $(DOCKER_COMPOSE) $(CLOUDMAKE) up push-image 
_get_image = $(shell make --no-print-directory -f $(SELF) $(2)-image-context-list@$(1))

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

_up = $(COMPOSE_$(call upper-case,$(1))_ENV) \
		$(DOCKER_COMPOSE) -f .cloudmake.$(1).stack.yml up $(UP_ARGS) $(2)

up@%: dev-up@%
	@#

dev-up@%: dev-down@% 
	@$(MAKE) --no-print-directory -f $(SELF) .cloudmake.dev.stack.yml
	@trap "trap - INT; exit 0" INT; $(call _up,dev,$*) 2> /dev/null

prod-up@%: prod-down@% 
	@$(MAKE) --no-print-directory -f $(SELF) .cloudmake.prod.stack.yml
	@trap "trap - INT; exit 0" INT; $(call _up,prod,$*) 2> /dev/null

up: dev-up
	@#

dev-up: dev-down 
	@$(MAKE) --no-print-directory -f $(SELF) .cloudmake.dev.stack.yml
	@trap "trap - INT; exit 0" INT; $(call _up,dev,) 2> /dev/null

prod-up: prod-down
	@$(MAKE) --no-print-directory -f $(SELF) .cloudmake.prod.stack.yml
	@trap "trap - INT; exit 0" INT; $(call _up,prod,) 2> /dev/null

###############################################################################
# MONITORING ##################################################################
###############################################################################
#
#
# Processes (docker-compose top)

_top = $(COMPOSE_$(call upper-case,$(1))_ENV) \
		$(DOCKER_COMPOSE) -f .cloudmake.$(1).stack.yml top $(2)

top@%: dev-top@%
	@#

dev-top@%: .cloudmake.dev.stack.yml
	@$(call _top,dev,$*)

top: dev-top
	@#

dev-top: .cloudmake.dev.stack.yml
	@$(call _top,dev,)

prod-top@%: .cloudmake.prod.stack.yml
	@$(call _top,prod,$*)

prod-top: .cloudmake.prod.stack.yml
	@$(call _top,prod,)

#
# Logs (docker-compose logs)

_logs = $(COMPOSE_$(call upper-case,$(1))_ENV) \
		$(DOCKER_COMPOSE) -f .cloudmake.$(1).stack.yml logs $(LOGS_ARGS) $(2)

logs@%: dev-logs@%
	@#

dev-logs@%: .cloudmake.dev.stack.yml
	@trap 'trap - INT; exit 0' INT; $(call _logs,dev,$*) 2> /dev/null

logs: dev-logs
	@#

dev-logs: .cloudmake.dev.stack.yml
	@trap 'trap - INT; exit 0' INT; $(call _logs,dev,) 2> /dev/null

prod-logs@%: .cloudmake.prod.stack.yml
	@trap 'trap - INT; exit 0' INT; $(call _logs,prod,$*) 2> /dev/null

prod-logs: .cloudmake.prod.stack.yml
	@trap 'trap - INT; exit 0' INT; $(call _logs,prod,) 2> /dev/null

#
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

_down = $(COMPOSE_$(call upper-case,$(1))_ENV) \
		$(DOCKER_COMPOSE) -f .cloudmake.$(1).stack.yml rm --force --stop $(DOWN_ARGS) $(2)

down@%: dev-down@%
	@echo $@

dev-down@%: .cloudmake.dev.stack.yml
	@$(call _down,dev,$*)
	@rm -f $<

prod-down@%: .cloudmake.prod.stack.yml 
	@$(call _down,prod,$*)
	@rm -f $<

down: dev-down

dev-down: .cloudmake.dev.stack.yml
	@$(call _down,dev,$*)
	@$(COMPOSE_DEV_ENV) $(DOCKER_COMPOSE) -f $< down $(DOWN_ARGS)
	@rm -f $<

prod-down: .cloudmake.prod.stack.yml
	@$(call _down,prod,)
	@$(COMPOSE_PROD_ENV) $(DOCKER_COMPOSE) -f $< down $(DOWN_ARGS)
	@rm -f $<

###############################################################################
# IMAGES ######################################################################
###############################################################################

_images = $(COMPOSE_$(call upper-case,$(1))_ENV) \
		$(DOCKER_COMPOSE) -f .cloudmake.$(1).stack.yml images $(IMAGES_ARGS) $(2)

images: dev-images
	@#

dev-images: .cloudmake.dev.stack.yml
	@$(call _images,dev,)

images@%: dev-images@%
	@#

dev-images@%: .cloudmake.dev.stack.yml
	@$(call _images,dev,$*)

prod-images: .cloudmake.prod.stack.yml
	@$(call _images,prod,)

prod-images@%: .cloudmake.prod.stack.yml
	@$(call _images,prod,$*)

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

k8s: k8s-dev 
	@#

k8s-dev: dev-validation
	@rm -rf $(K8S_DEV_PATH)
	@mkdir -p $(K8S_DEV_PATH)
	@make --no-print-directory -f $(SELF) dev-config-display > $(K8S_DEV_PATH)/.stack.yml
	@$(KOMPOSE) -f $(K8S_DEV_PATH)/.stack.yml -o $(K8S_DEV_PATH) convert

rm-k8s-dev:
	@rm -rf $(K8S_DEV_PATH)

k8s-prod: prod-validation
	@rm -rf $(K8S_PROD_PATH)
	@mkdir -p $(K8S_PROD_PATH)
	@make --no-print-directory -f $(SELF) prod-config-display > $(K8S_PROD_PATH)/.stack.yml
	@$(KOMPOSE) -f $(K8S_PROD_PATH)/.stack.yml -o $(K8S_PROD_PATH) convert

rm-k8s-prod:
	@rm -rf $(K8S_PROD_PATH)

k8s-deploy:
	@#

k8s-prod-deploy:
	$(KUBECTL) apply -f $(K8S_PROD_PATH)

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
