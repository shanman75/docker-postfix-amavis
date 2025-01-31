# Makefile
#
# build
#

-include    *.mk

BLD_ARG  ?= --build-arg DIST=alpine --build-arg REL=3.13 --progress=plain
BLD_REPO ?= shanman75/postfix-amavis
BLD_VER  ?= latest
BLD_TGT  ?= full

TST_REPO ?= $(BLD_REPO)
TST_VER  ?= $(BLD_VER)
TST_ENV  ?= -C test
TST_TGTE ?= $(addprefix test-,all diff down env htop imap logs mail mail-send pop3 sh sv up)
TST_INDX ?= 1 2 3 4 5 6 7 8 9
TST_TGTI ?= $(addprefix test_,$(TST_INDX)) $(addprefix test-up_,0 $(TST_INDX))

export TST_REPO TST_VER

_version  = $(if $(findstring $(BLD_TGT),$(1)),\
$(if $(findstring latest,$(2)),latest $(1),$(2) $(1)-$(2)),\
$(if $(findstring latest,$(2)),$(1),$(1)-$(2)))

build-all: build_mini build_base build_full

build: build_$(BLD_TGT)

build_%: Dockerfile
	docker build $(BLD_ARG) --target $* \
	$(addprefix --tag $(BLD_REPO):,$(call _version,$*,$(BLD_VER))) .

variables:
	make -pn | grep -A1 "^# makefile"| grep -v "^#\|^--" | sort | uniq

pushgcp:
	gcloud auth configure-docker us-central1-docker.pkg.dev
	gcloud auth login
	gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev
	docker tag shanman75/postfix-amavis us-central1-docker.pkg.dev/sonic-falcon-368322/spinksdkr/postfix-amavis
	docker tag shanman75/postfix-amavis us-central1-docker.pkg.dev/helical-kayak-235319/shanrepo/postfix-amavis		
	docker push us-central1-docker.pkg.dev/sonic-falcon-368322/spinksdkr/postfix-amavis
	docker push us-central1-docker.pkg.dev/helical-kayak-235319/shanrepo/postfix-amavis

ps:
	docker ps -a

prune:
	docker image prune -f

clean:
	docker images | grep $(BLD_REPO) | awk '{print $$1 ":" $$2}' | uniq | xargs docker rmi

$(TST_TGTE):
	${MAKE} $(TST_ENV) $@

$(TST_TGTI):
	${MAKE} $(TST_ENV) $@
