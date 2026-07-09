# Variables
LOGIN = mhirvasm
DATA_PATH = /home/$(LOGIN)/data

# Docker Compose command referencing the specific compose file
COMPOSE = docker compose -f srcs/docker-compose.yml

# Phony targets to ensure make doesn't confuse them with actual files
.PHONY: all up down clean fclean re data-dirs

all: data-dirs up

# 1. Creates the required data directories inside the VM
data-dirs:
	@echo "--> Ensuring data directories exist in $(DATA_PATH)"
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress

# 2. Builds and starts the containers in the background
up: data-dirs
	@echo "--> Starting up Inception infrastructure..."
	@$(COMPOSE) up -d --build

# 3. Stops the containers without destroying data
down:
	@echo "--> Stopping containers..."
	@$(COMPOSE) down

# 4. Cleans up containers, networks, and images (leaves volumes intact)
clean: down
	@echo "--> Cleaning up Docker environment..."
	@docker system prune -af

# 5. The Nuclear Option: Destroys everything, including the persistent data on the VM
fclean: clean
	@echo "--> WARNING: Destroying all persistent data volumes..."
	@sudo rm -rf $(DATA_PATH)/*
	@docker volume prune -f

# 6. Restarts the entire build from scratch
re: fclean all
