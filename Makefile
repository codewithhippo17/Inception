NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_PATH = /home/_hippo/data

all: setup up

setup:
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress

up: setup
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

fclean: clean
	@sudo rm -rf $(DATA_PATH)/mariadb || true
	@sudo rm -rf $(DATA_PATH)/wordpress || true
	@docker system prune -af

re: fclean all

.PHONY: all setup up down clean fclean re
