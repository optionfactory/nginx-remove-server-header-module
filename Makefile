VERSION=1.30.8-1
NGINX_VERSION=1.30.8
DOCKER_IMAGE=optionfactory/debian13-nginx130:259
REPO_OWNER=optionfactory
REPO_NAME=nginx-remove-server-header-module
ARTIFACT_NAME=$(REPO_NAME)-linux-amd64.so



build: nginx-$(NGINX_VERSION)
	$(eval moduledir=${PWD})
	$(eval nginx_flags=$(shell docker run -ti --rm --entrypoint nginx $(DOCKER_IMAGE) -V | grep configure | sed 's/configure arguments://' | sed 's/-D_FORTIFY_SOURCE=2/-U_FORTIFY_SOURCE/'))
	echo nginx_flags=${nginx_flags}
	cd nginx-$(NGINX_VERSION) && ./configure --add-dynamic-module=$(moduledir) $(nginx_flags) && make modules
	mv $(PWD)/nginx-$(NGINX_VERSION)/objs/opfa_http_remove_server_header_module.so dist/$(ARTIFACT_NAME)

deps:
	sudo apt install build-essential libpcre3-dev zlib1g-dev libssl-dev

nginx-${NGINX_VERSION}:
	curl -# -j -k -L https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xz

clean:
	rm -rf dist/*.so
	rm -rf nginx-*/Makefile nginx-*/objs

clean-deps:
	rm -rf nginx-*

# the release is tagged on the commit GitHub has: only a clean tree, with master pushed
pushed:
	@git diff --quiet HEAD || { echo "uncommitted changes: commit them first"; exit 1; }
	@git fetch -q origin master
	@[ "$$(git rev-parse HEAD)" = "$$(git rev-parse origin/master)" ] || { echo "master is not pushed: push it first"; exit 1; }

publish-github: pushed build
	@cd dist && sha256sum $(ARTIFACT_NAME) > SHA256SUMS
	@gh release create "v$(VERSION)" \
		"dist/$(ARTIFACT_NAME)" \
		"dist/SHA256SUMS" \
		--repo "$(REPO_OWNER)/$(REPO_NAME)" \
		--title "v$(VERSION)" \
		--target "master" \
		--notes ""
	-@rm dist/SHA256SUMS

run:
	docker run -ti --rm --name nginx-with-remove-header-module \
		-p 0.0.0.0:12000:80 \
        -v ${PWD}/nginx.conf:/etc/nginx/nginx.conf:ro \
		-v ${PWD}/dist/$(ARTIFACT_NAME):/etc/nginx/modules/opfa_http_remove_server_header_module.so \
        $(DOCKER_IMAGE)
