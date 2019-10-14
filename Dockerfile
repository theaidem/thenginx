FROM nginx:1.17

# Some install:
RUN apt-get update && apt-get -y install openssl ca-certificates certbot

# Generate Diffie-Hellman keys:
RUN openssl dhparam -out /etc/nginx/dhparam.pem 2048

# Create a common ACME-challenge directory (for Let's Encrypt):
# Also configure Certbot to reload NGINX after success renew:
RUN mkdir -p /var/www/_letsencrypt && \ 
    chown www-data /var/www/_letsencrypt && \
    echo -e '#\!/bin/bash\nnginx -t && nginx -s reload' | \
    tee /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh && \
    chmod a+x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh

EXPOSE 80 443