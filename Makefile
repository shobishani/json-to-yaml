#############################################
#                                           #
#          Makefile Configuration           #
#                                           #
#############################################

ifndef PROJECT_VERSION
PROJECT_VERSION:=$(shell cat src/__version__.py | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p' )
endif

ifndef IMAGE_REPO
IMAGE_REPO:=json-to-yaml
endif

ifndef IMAGE_TAG
IMAGE_TAG:=$(PROJECT_VERSION)-$(shell git rev-parse --short HEAD)
endif

start-minikube:
	minikube start

package: env-IMAGE_REPO env-IMAGE_TAG
	docker build -t $(IMAGE_REPO):$(IMAGE_TAG) .
	gcloud docker -- push $(IMAGE_REPO):$(IMAGE_TAG)

helm-dry:
	helm install json-to-yaml -n json-to-yaml etc/kubernetes/helm/json-to-yaml \
		--set image.repository=$(IMAGE_REPO) \
		--set image.tag=$(IMAGE_TAG) \
		--dry-run

helm-install:
	helm upgrade --install json-to-yaml -n json-to-yaml etc/kubernetes/helm/json-to-yaml \
		--set image.repository=$(IMAGE_REPO) \
		--set image.tag=$(IMAGE_TAG) \

helm-uninstall:
	helm uninstall json-to-yaml

package-helm:
	helm package etc/kubernetes/helm/json-to-yaml

dependencies:
	pip install -r requirements.txt

version:
	@echo $(PROJECT_VERSION)
	@echo $(IMAGE_TAG)


#############################################
#                                           #
#             Helper Utilities              #
#                                           #
#############################################

env-%:
	@if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi