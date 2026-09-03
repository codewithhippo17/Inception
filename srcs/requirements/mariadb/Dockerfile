# Use the penultimate stable version of Alpine
FROM alpine:3.19

# Install MariaDB server and client
RUN apk update && apk add --no-cache mariadb mariadb-client

# Create the socket directory and set ownership
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# Copy custom configuration
COPY conf/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf

# Copy initialization script
COPY tools/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["mariadbd", "--user=mysql"]