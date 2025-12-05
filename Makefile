# run: make run <path_to_project>
run:
	@RUN_PATH=$(word 2,$(MAKECMDGOALS)); \
	if [ -z "$$RUN_PATH" ]; then \
		echo "Error: No path specified. Usage: make run <path_to_project>"; \
		exit 1; \
	elif [ ! -d "$$RUN_PATH" ]; then \
		echo "Error: $$RUN_PATH is not a valid directory"; \
		exit 1; \
	fi; \
	docker compose run --rm -v "$$RUN_PATH":/project -w /project dev

