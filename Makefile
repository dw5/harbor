.PHONY: build-ci-image push-ci-image

build-ci-image:
	docker build \
		-t gitlab.futo.org:5050/polycentric/harbor:ci \
		-f Dockerfile.ci \
		.

push-ci-image:
	docker push gitlab.futo.org:5050/polycentric/harbor:ci
