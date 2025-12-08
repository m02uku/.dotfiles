run:
	@RUN_PATH=$(word 2,$(MAKECMDGOALS)); \
	if [ -z "$$RUN_PATH" ]; then \
		echo "No path specified."; \
		docker compose run --rm -it dev; \
		exit 1; \
	elif [ ! -d "$$RUN_PATH" ]; then \
		echo "Error: $$RUN_PATH is not a valid directory"; \
		exit 1; \
	fi; \
	echo "$$RUN_PATH specified."; \
	docker compose run --rm -it -v "$$RUN_PATH":/project dev; \
	if [ $$? -eq 130 ] || [ $$? -eq 0 ]; then exit 0; fi

%:
	@:

