define check_arg
	@[ ${1} ] || ( echo ">> ${2} is not set"; exit 1 )
endef

test:
	$(call check_arg, ${domain}, domain)
	@echo 'test ${domain}'

# Build image
build:
	@docker build -t thenginx .

# Run container
run:
	@docker run --name thenginx -d \
		-p 80:80 -p 443:443 \
		-v ${PWD}/var.www:/var/www \
		-v ${PWD}/etc.nginx/nginx.conf:/etc/nginx/nginx.conf \
		-v ${PWD}/etc.nginx/nginxconfig:/etc/nginx/nginxconfig \
		-v ${PWD}/etc.nginx/sites-available:/etc/nginx/sites-available \
		-v ${PWD}/etc.nginx/sites-enabled:/etc/nginx/sites-enabled \
		thenginx

# Greate new config
create:
	$(call check_arg, ${domain}, domain)
	@cp ./etc.nginx/sites-available/example.com.conf ./etc.nginx/sites-available/${domain}.conf
	@sed -i -E 's/example.com/${domain}/g' ./etc.nginx/sites-available/${domain}.conf
	@docker exec -it thenginx ln -s /etc/nginx/sites-available/${domain}.conf /etc/nginx/sites-enabled/
	# @make reload.nginx

# Delete a config
delete:
	$(call check_arg, ${domain}, domain)
	@rm ./etc.nginx/sites-available/${domain}.conf
	@rm ./etc.nginx/sites-enabled/${domain}.conf
	# @make reload.nginx

# Reload NGINX:
reload.nginx:
	@docker exec -it thenginx nginx -t
	@docker exec -it thenginx nginx -s reload

# Obtain certificate:
obtain.certificate:
	$(call check_arg, ${domain}, domain)
	$(call check_arg, ${email}, email)
	@docker exec -it thenginx certbot certonly --webroot -d ${domain} -d www.${domain} --email ${email} -w /var/www/_letsencrypt -n --agree-tos --force-renewal
