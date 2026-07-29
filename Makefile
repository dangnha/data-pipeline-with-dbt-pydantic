.PHONY: install download-data ingest dbt-run dbt-test pipeline clean

install:
	pip install -e ".[dev]"

download-data:
	gdown --folder "https://drive.google.com/drive/folders/17craI5-exAYN7S5GlnTG9F5gRu0_v7BK?usp=sharing" -O dataset/datathon-2026-round-1/

ingest:
	python -m vindatathon.ingest

dbt-run:
	dbt run --project-dir dbt_project

dbt-test:
	dbt test --project-dir dbt_project

pipeline: ingest dbt-run dbt-test

clean:
	rm -f dataset/ingest_errors.csv
