#	Utility commands

COMPOSE_SERVICE_NAME = terraform-container



# clear temp files
clear:
	find . -type d -name .terraform -prune -exec rm -rf {} \;

# setup docker environment
up:
	docker-compose up -d
clean-up:
	docker-compose up --detach --build --force-recreate --always-recreate-deps
down:
	docker-compose down
clean-down:
	docker-compose down --rmi all --volumes --remove-orphans
sh:
	docker-compose exec --privileged $(COMPOSE_SERVICE_NAME) bash
bash:
	docker-compose exec --privileged $(COMPOSE_SERVICE_NAME) bash