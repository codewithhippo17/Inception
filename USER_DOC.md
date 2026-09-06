# User Documentation

This guide explains how an end user or administrator can interact with the services provided by this infrastructure.

## Services Provided
The stack provides a fully functional LEMP-like environment (Linux, NGINX, MariaDB, PHP) entirely containerized:
- **NGINX**: Acts as the web server and reverse proxy, strictly listening on port 443 with TLSv1.2/TLSv1.3 encryption.
- **WordPress**: The content management system (PHP-FPM) serving the website.
- **MariaDB**: The relational database storing WordPress data.

## How to Start and Stop the Project
The project is controlled via the `Makefile` located at the root of the repository.
- **To Start**: Run `make all` (or simply `make`) in your terminal. This will build the images and start the services in detached mode.
- **To Stop**: Run `make down` to gracefully stop the containers without deleting the persistent data.

## Accessing the Website and Administration Panel
Once the project is running:
1. Ensure `ehamza.42.fr` is mapped to `127.0.0.1` in your `/etc/hosts` file.
2. **Main Website**: Open a web browser and navigate to `https://ehamza.42.fr`. Accept the self-signed SSL certificate warning if prompted.
3. **Admin Panel**: Navigate to `https://ehamza.42.fr/wp-admin` to access the WordPress dashboard. 

## Locating and Managing Credentials
Credentials (such as database passwords, WordPress admin/user credentials) are managed securely. 
- For initial setup, credentials may be provided via local `.env` files located in the `srcs/` folder (or via the `/secrets` directory).
- Once initialized, to change passwords, you must use the respective administration interfaces (WordPress Admin Panel for users, or executing SQL queries inside the MariaDB container for database users).

## Checking that Services are Running Correctly
You can verify the status of the infrastructure by running:
```bash
docker ps
```
This command will list all active containers. You should see three containers running (nginx, wordpress, and mariadb). 
To check the logs of a specific service if something isn't working:
```bash
docker logs <container_name>
```
