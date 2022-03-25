.DEFAULT_GOAL := help
PROJECTNAME=$(shell basename "$(PWD)")

define check_arg
	@[ ${1} ] || ( echo ">> ${2} is not set, use: ${2}=value"; exit 1 )
endef

test:
	$(call check_arg, ${domain}, domain)
	@echo '${PROJECTNAME} test ${domain}'

help: Makefile
	@echo "Available commands: "${PROJECTNAME}""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build docker image
	@docker build -t ${PROJECTNAME} .

run: ## Run docker container
	@docker run --name ${PROJECTNAME} -d \
		--network host \
		--restart always \
		-p 80:80 -p 443:443 \
		-v ${PWD}/var.www:/var/www \
		-v ${PWD}/etc.nginx/nginx.conf:/etc/nginx/nginx.conf \
		-v ${PWD}/etc.nginx/nginxconfig:/etc/nginx/nginxconfig \
		-v ${PWD}/etc.nginx/sites-available:/etc/nginx/sites-available \
		-v ${PWD}/etc.nginx/sites-enabled:/etc/nginx/sites-enabled \
		${PROJECTNAME}

generate: ## Generate domain configuration and obtain certificate
	$(call check_arg, ${domain}, domain)
	$(call check_arg, ${email}, email)
	@echo '...generate: ${domain}, email: ${email}'
	@make create
	@make ls
	@make certificate
	@sed -i.bak -r -E 's/#?#;//g' ./etc.nginx/sites-available/${domain}.conf
	@make reload
	@sleep 5 && curl -I https://${domain}

create: ## Create new nginx config file for domain
	$(call check_arg, ${domain}, domain)
	@cp ./etc.nginx/sites-available/example.com.conf ./etc.nginx/sites-available/${domain}.conf
	@sed -i -E 's/example.com/${domain}/g' ./etc.nginx/sites-available/${domain}.conf
	@docker exec -it ${PROJECTNAME} ln -s /etc/nginx/sites-available/${domain}.conf /etc/nginx/sites-enabled/
	@make reload

delete: ## Delete a nginx config with letsencrypt certificate
	$(call check_arg, ${domain}, domain)
	@rm ./etc.nginx/sites-available/${domain}.conf
	@rm ./etc.nginx/sites-enabled/${domain}.conf
	@docker exec -it ${PROJECTNAME} certbot delete --cert-name ${domain}
	@make reload

configs: ## List available configs
	@ls -all etc.nginx/sites-available

logs: ## Nginx container logs
	@docker logs --tail=100 -f ${PROJECTNAME}

reload: ## Reload nginx in container
	@docker exec -it ${PROJECTNAME} nginx -t
	@docker exec -it ${PROJECTNAME} nginx -s reload

certificate: ## Obtain certificate for domain
	$(call check_arg, ${domain}, domain)
	$(call check_arg, ${email}, email)
	@docker exec -it ${PROJECTNAME} certbot certonly --webroot -d ${domain} -d www.${domain} --email ${email} -w /var/www/_letsencrypt -n --agree-tos --force-renewal

certs: ## List available certificates
	@docker exec -it ${PROJECTNAME} certbot certificates

renew: ## Renew all previously obtained certificates that are near expiry
	@docker exec -it ${PROJECTNAME} certbot renew
