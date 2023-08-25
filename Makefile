IMAGE = ops/638750236702-dn-ops/us-east-1/ipe-hello
IMAGE_VERSION ?= $(shell cat src/app/package.json | jq -r .version)
AWS_PROFILE = registry
AWS_REGION = us-east-1
AWS_ACCOUNT_ID = 638750236702
AWS_SERVER = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
TAG_LATEST = $(AWS_SERVER)/$(IMAGE):latest

create-amd64-builder:
	docker buildx create --name linux-amd64-builder --driver docker-container --bootstrap

use-amd64-builder:
	docker buildx use linux-amd64-builder

build: use-amd64-builder
	docker buildx build --platform linux/amd64 -t $(TAG_LATEST) --ssh default --load \
		--build-arg IMAGE_VERSION="$(IMAGE_VERSION)" \
		--build-arg IMAGE_CREATE_DATE="`date -u +"%Y-%m-%dT%H:%M:%SZ"`" \
		--build-arg IMAGE_SOURCE_REVISION="`git rev-parse HEAD`" \
		-f src/app/Dockerfile -t "$(IMAGE):$(IMAGE_VERSION)" src/app;

login:
	aws --region $(AWS_REGION) ecr get-login-password | docker login --username AWS --password-stdin $(AWS_SERVER)

push: build login
	docker push $(TAG_LATEST)


