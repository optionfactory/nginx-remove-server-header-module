VERSION=1.24.0-1
NGINX_VERSION=1.24.0
DOCKER_IMAGE=optionfactory/debian12-nginx120:53
REPO_OWNER=optionfactory
REPO_NAME=nginx-remove-server-header-module
ARTIFACT_NAME=opfa_http_remove_server_header_module-$(VERSION).so


build: nginx-$(NGINX_VERSION)
	$(eval moduledir=${PWD})
	$(eval nginx_flags=$(shell docker run -ti --rm --entrypoint nginx $(DOCKER_IMAGE) -V | grep configure | sed 's/configure arguments://'))
	cd nginx-$(NGINX_VERSION) && ./configure --add-dynamic-module=$(moduledir) $(nginx_flags) && make modules
	mv $(PWD)/nginx-$(NGINX_VERSION)/objs/opfa_http_remove_server_header_module.so dist/$(ARTIFACT_NAME)

nginx-${NGINX_VERSION}:
	curl -# -j -k -L https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xz

clean:
	rm -rf dist/*.so
	rm -rf nginx-*/Makefile nginx-*/objs

clean-deps:
	rm -rf nginx-*

release:
	$(eval github_token=$(shell echo url=https://github.com/$(REPO_OWNER)/$(REPO_NAME) | git credential fill | grep '^password=' | sed 's/password=//'))
	$(eval release_id=$(shell curl -X POST \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer $(github_token)" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		https://api.github.com/repos/$(REPO_OWNER)/$(REPO_NAME)/releases \
	  	-d '{"tag_name":"v$(VERSION)","target_commitish":"master","name":"v$(VERSION)"}' | jq .id))
	@curl -X POST \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer $(github_token)" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		-H "Content-Type: application/octet-stream" \
		https://uploads.github.com/repos/$(REPO_OWNER)/$(REPO_NAME)/releases/$(release_id)/assets?name=$(ARTIFACT_NAME) \
  		--data-binary "@dist/$(ARTIFACT_NAME)"
run:
	docker run -ti --rm --name nginx-with-remove-header-module \
		-p 0.0.0.0:12000:80 \
        -v ${PWD}/nginx.conf:/etc/nginx/nginx.conf:ro \
		-v ${PWD}/dist/$(ARTIFACT_NAME):/etc/nginx/modules/$(ARTIFACT_NAME) \
        $(DOCKER_IMAGE)
