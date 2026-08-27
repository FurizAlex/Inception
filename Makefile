# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: alechin <alechin@student.42kl.edu.my>      +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/08/11 14:39:33 by alechin           #+#    #+#              #
#    Updated: 2026/08/11 14:39:33 by alechin          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME                = Inception
DOCKER_COMPOSE_FILE = docker-compose.yml
ENV_FILE            = ./src/.env
ENV_EXAMPLE         = ./src/.env.example
DOMAIN_NAME         = $(shell awk -F= '/^DOMAIN_NAME=/ {print $$2}' $(ENV_FILE))
USER_HOME           = $(shell awk -F= '/^USER_HOME=/ {print $$2}' $(ENV_FILE))

GREEN   = \033[1;32m
YELLOW  = \033[1;33m
BLUE    = \033[1;34m
CYAN    = \033[1;36m
RED     = \033[1;31m
RESET   = \033[0m

.PHONY: all generate_certs prep re clean fclean help logs status certs-only env down

all: $(NAME)

generate_certs:
	@echo "$(CYAN)[CERTS]$(RESET) Checking and generating SSL certificates..."
	@mkdir -p ./secrets
	@bash -c "\
    if [[ ! -f ./secrets/dhparam.pem || ! -f ./secrets/cert.pem || ! -f ./secrets/cert.key ]]; then \
        echo 'Generating SSL certs for $(DOMAIN_NAME)...'; \
        rm -f ./secrets/*; \
        openssl dhparam -out ./secrets/dhparam.pem 2048; \
        openssl req -new -newkey rsa:2048 -nodes -keyout secrets/cert.key -out secrets/cert.csr \
            -subj '/C=MY/ST=Selangor/L=Subang/O=My Company/OU=IT/CN=$(DOMAIN_NAME)'; \
        openssl x509 -req -days 3650 -in secrets/cert.csr -signkey secrets/cert.key -out secrets/cert.pem; \
        rm -f secrets/cert.csr; \
    fi"

prep: generate_certs env
	@echo "$(CYAN)[PREP]$(RESET) Setting up directories..."
	@mkdir -p $(USER_HOME)/data/mariadb
	@mkdir -p $(USER_HOME)/data/wordpress
	@echo "$(CYAN)[PREP]$(RESET) Mapping domain $(DOMAIN_NAME) to localhost..."
	@sudo bash -c "\
	if ! grep -q '$(DOMAIN_NAME)' /etc/hosts; then \
		cp /etc/hosts $(USER_HOME)/data/hosts.backup; \
		echo '127.0.0.1 $(DOMAIN_NAME)' >> /etc/hosts; \
	fi"

$(NAME): prep
	@echo "$(GREEN)[START]$(RESET) bilding and starting Docker containers..."
	@sudo docker compose -f src/$(DOCKER_COMPOSE_FILE) up --build -d
	@echo "$(GREEN)[DONE]$(RESET) services are up"
	@echo "open $(GREEN)https://$(DOMAIN_NAME)/$(RESET) manually in your browser."

re: fclean all

clean:
	@echo "$(YELLOW)[CLEAN]$(RESET) removing containers..."
	@sudo docker compose -f src/$(DOCKER_COMPOSE_FILE) down

fclean: clean
	@echo "$(YELLOW)[FCLEAN]$(RESET) full cleanup in progress..."

	# Restore /etc/hosts if backup exists
	@bash -c "\
	if [[ -f $(USER_HOME)/data/hosts.backup ]]; then \
		sudo cp $(USER_HOME)/data/hosts.backup /etc/hosts; \
		sudo rm -f $(USER_HOME)/data/hosts.backup; \
	fi"

	# Remove bind-mounted data (host folders)
	@sudo rm -rf $(USER_HOME)/data/mariadb
	@sudo rm -rf $(USER_HOME)/data/wordpress

	# Remove /data directory if empty
	@bash -c "\
	if [[ -d $(USER_HOME)/data && $$(ls -A $(USER_HOME)/data | wc -l) -eq 0 ]]; then \
	    sudo rm -rf $(USER_HOME)/data; \
	fi"

	# Remove project named volumes (Docker-managed)
	@echo "$(YELLOW)[FCLEAN]$(RESET) removing project named volumes..."
	@docker volume ls --format '{{.Name}}' | grep -E '^src_mariadb$$|^src_wordpress$$' | xargs -r docker volume rm -f

	# Remove project images
	@echo "$(YELLOW)[FCLEAN]$(RESET) removing project images..."
	@docker images --format '{{.Repository}}:{{.Tag}}' | grep -E 'mariadb:42|wordpress:42|nginx:42' | xargs -r docker rmi -f

	# Remove project network
	@echo "$(YELLOW)[FCLEAN]$(RESET) removing project network..."
	@docker network ls --format '{{.Name}}' | grep -E '^src_inception-network$$' | xargs -r docker network rm

	@echo "$(GREEN)[FCLEAN]$(RESET) project fully cleaned!"

down:
	@echo "$(YELLOW)[CLEAN]$(RESET) shutting Down containers..."
	@sudo docker compose -f src/$(DOCKER_COMPOSE_FILE) down

logs:
	@echo "$(BLUE)[LOGS]$(RESET) showing logs..."
	@docker compose -f src/$(DOCKER_COMPOSE_FILE) logs -f || true

status:
	@echo "$(BLUE)[STATUS]$(RESET) containers:"
	@docker ps -a
	@echo "\n volumes:"
	@docker volume ls
	@echo "\n networks:"
	@docker network ls

certs-only:
	@$(MAKE) generate_certs

env:
	@if [ ! -f $(ENV_FILE) ]; then \
		if [ -f $(ENV_EXAMPLE) ]; then \
			cp $(ENV_EXAMPLE) $(ENV_FILE); \
			echo "$(YELLOW)[ENV]$(RESET) copied .env.example to .env"; \
		else \
			echo "$(RED)[ENV]$(RESET) missing .env and .env.example!"; \
			false; \
		fi \
	fi

help:
	@echo "$(CYAN) -- Makefile Commands --$(RESET)"
	@echo "  make            Build/start all containers"
	@echo "  make re         Rebuild everything"
	@echo "  make clean      Remove containers"
	@echo "  make fclean     Full reset including host/data"
	@echo "  make logs       Show Docker logs"
	@echo "  make status     Show container/volume/network info"
	@echo "  make certs-only Regenerate SSL certs"
	@echo "  make env        Create .env from .env.example"
	@echo "  make help       Show this help message"