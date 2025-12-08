run:
	@RUN_PATH=$(word 2,$(MAKECMDGOALS)); \
	if [ -z "$$RUN_PATH" ]; then \
		echo "No path specified."; \
		docker compose run --rm -it dev; \
		exit 1; \
	fi; \
	ABS_PATH=$$(eval echo "$$RUN_PATH"); \
	ABS_PATH=$$(cd "$$ABS_PATH" && pwd); \
	if [ ! -d "$$ABS_PATH" ]; then \
		echo "Error: $$RUN_PATH is not a valid directory"; \
		exit 1; \
	fi; \
	echo "Mounting: $$ABS_PATH"; \
	docker compose run --rm -it -v "$$ABS_PATH":/project dev; \
	if [ $$? -eq 130 ] || [ $$? -eq 0 ]; then exit 0; fi

%:
	@:
