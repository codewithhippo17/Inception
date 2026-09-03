FROM alpine:3.19

RUN apk update && apk add --no-cache nginx openssl

# Generate self-signed certificate
RUN mkdir -p /etc/ssl/private /etc/ssl/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=MO/ST=BeniMellal/L=Khouribga/O=1337/OU=Student/CN=inception.42.fr"

# Copy configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Create necessary directories and set permissions
RUN mkdir -p /var/www/html /run/nginx && \
    chown -R nginx:nginx /var/www/html /run/nginx

EXPOSE 443

# Run NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]