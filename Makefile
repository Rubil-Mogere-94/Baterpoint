.PHONY: run

run:
	@echo "Starting backend services..."
	docker compose up --build -d
	@echo "Running Flutter frontend..."
	cd frontend && flutter run
