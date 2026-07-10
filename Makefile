.PHONY: setup doctor validate image-scan up up-proxy down logs backup smoke

setup:
	./bin/setup

doctor:
	./bin/doctor

validate:
	./tests/validate.sh

image-scan:
	AI_GATEWAY_IMAGE_SCAN=1 ./tests/scan-images.sh

up:
	docker compose --env-file .env -f compose.yaml up -d

up-proxy:
	docker compose --env-file .env -f compose.yaml -f compose.proxy.yaml up -d

down:
	docker compose --env-file .env -f compose.yaml -f compose.proxy.yaml down

logs:
	docker compose --env-file .env -f compose.yaml logs -f --tail=200

backup:
	./bin/backup

smoke:
	AI_GATEWAY_SMOKE=1 ./tests/smoke.sh
