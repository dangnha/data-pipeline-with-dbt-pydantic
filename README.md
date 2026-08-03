# Data Pipeline — E-Commerce Retail ETL

**Pydantic → PostgreSQL → dbt** — end-to-end ETL pipeline that validates raw CSV data, loads it into PostgreSQL, and transforms it into feature-ready mart tables.
[
> **Dataset acknowledgment**: This project uses retail e-commerce data from [**Vindatathon 2026, Round 1**](https://www.kaggle.com/competitions/datathon-2026-round-1).

## Architecture

```
┌──────────┐     ┌──────────────────┐     ┌──────────────┐     ┌────────────────┐
│ 13 CSVs  │ ──▶ │  Pydantic Models  │ ──▶ │  PostgreSQL   │ ──▶ │  dbt Transform │
│ (dataset) │     │  (validate/type)  │     │  (raw tables) │     │  (stg/int/mart)│
└──────────┘     └──────────────────┘     └──────────────┘     └────────────────┘
```

| Layer | Description | Count |
|-------|-------------|-------|
| **Pydantic models** | Type-safe row validation with enums, Decimal precision, and semantic checks | 13 |
| **Ingestion** | Chunked CSV reads → validate → bulk insert into PostgreSQL | 1 script |
| **dbt Staging** | Lightly cleaned views over raw tables | 13 models |
| **dbt Intermediate** | Joined entities (orders + payments + shipments, etc.) | 6 models |
| **dbt Marts** | Feature tables ready for downstream modeling | 4 models |

### Mart Tables

| Mart | Granularity | Key Features |
|------|-------------|-------------|
| `mart_daily_sales_features` | Daily | Revenue, COGS, orders, traffic, 7d/30d rolling windows |
| `mart_order_features` | Order × Item | Price, discount, delivery, returns, ratings, region |
| `mart_customer_features` | Customer | Demographics, lifetime spend, return rate, avg rating |
| `mart_product_features` | Product | Sales, stock health, return rate, avg rating |

## Project Structure

```
data-pipeline/
├── dataset/                          # CSV files (downloaded, gitignored)
├── src/data_pipeline/
│   ├── config.py                     # DB connection, paths, env loading
│   ├── ingest.py                     # CSV → Pydantic → PostgreSQL
│   └── models/                       # 13 Pydantic row validators
├── dbt_project/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── packages.yml
│   └── models/
│       ├── staging/_sources.yml      # Source definitions + tests
│       ├── staging/schema.yml        # Staging model tests
│       ├── intermediate/             # 6 intermediate models
│       ├── intermediate/schema.yml
│       ├── marts/                    # 4 mart models
│       └── marts/schema.yml
├── .env.example                      # Credentials template
├── pyproject.toml
├── Makefile
└── .gitignore
```

## Setup Guide

### Prerequisites

- **Python 3.11+**
- **PostgreSQL 14+** — running and accessible
- **dbt Core** with PostgreSQL adapter (`dbt-postgres`)

### 1. Clone and navigate

```bash
git clone <repo-url>
cd data-pipeline
```

### 2. Download dataset

```bash
pip install gdown
gdown --folder "https://drive.google.com/drive/folders/17craI5-exAYN7S5GlnTG9F5gRu0_v7BK?usp=sharing" \
  -O dataset/
```

This downloads 13 CSV files plus a baseline notebook into `dataset/`.

### 3. Install Python dependencies

```bash
make install
```

This installs the package, plus `gdown`, `dbt-postgres`, and dev tooling.

### 4. Configure environment

Copy and edit the environment file:

```bash
cp .env.example .env
```

Edit `.env` with your PostgreSQL credentials:

```env
DATA_DB_HOST=localhost
DATA_DB_PORT=5432
DATA_DB_NAME=data_pipeline
DATA_DB_USER=postgres
DATA_DB_PASSWORD=postgres
DATA_DB_SCHEMA=raw
```

### 5. Create the database

```bash
createdb -U postgres -h localhost data_pipeline
```

### 6. Run ingestion (validate + load CSVs → PostgreSQL)

```bash
python -m data_pipeline.ingest
```

This reads all 13 CSVs from `dataset/`, validates each row against Pydantic models, creates `raw.*` tables, and bulk-inserts clean data. Any rejected rows are logged to `dataset/ingest_errors.csv`.

### 7. Install dbt packages

```bash
dbt deps --project-dir dbt_project
```

### 8. Run dbt models

```bash
dbt run --project-dir dbt_project
```

Builds staging → intermediate → marts.

### 9. Run dbt tests

```bash
dbt test --project-dir dbt_project
```

Verifies uniqueness constraints, not-nulls, and referential integrity.

### All-in-one

```bash
make pipeline
```

Runs ingestion → dbt run → dbt test sequentially.

## Quick Commands

```bash
make install       # Install Python package + dbt + gdown
make download-data # Download dataset from Google Drive
make ingest        # Validate and load CSVs into PostgreSQL
make dbt-run       # Execute all dbt models
make dbt-test      # Run dbt data quality tests
make pipeline      # Full pipeline: ingest + dbt-run + dbt-test
make clean         # Remove error logs
```

## Data Validation Rules

Pydantic models enforce:

- **Type safety** — int, Decimal, date, Enum for categoricals
- **Ranges** — `quantity > 0`, `rating` 1–5, `bounce_rate` 0–1, `fill_rate` 0–1
- **Monetary precision** — all financial columns use `Decimal(15,2)` to avoid float drift
- **Date integrity** — `ship_date ≤ delivery_date`, `start_date < end_date` on promotions
- **Enums** — `order_status`, `payment_method`, `gender`, `age_group`, `acquisition_channel`, etc.
- **Null handling** — optional fields (`promo_id`, `promo_id_2`, `applicable_category`) accept `None`; required fields reject it

## dbt Data Quality Tests

| Test Type | Applied To |
|-----------|-----------|
| `unique` | All primary keys (`customer_id`, `order_id`, `product_id`, `return_id`, `review_id`, `promo_id`, `zip`, `date`) |
| `not_null` | All primary keys and critical columns |
| `accepted_values` | Enum columns (via source/staging definitions) |

## Troubleshooting

**Connection refused (port 5432)**
```bash
pg_isready  # check if PostgreSQL is running
pg_lsclusters  # list clusters (Ubuntu/Debian)
```

**Role does not exist**
```bash
createdb -U $(whoami) data_pipeline  # use your local user
```

**dbt profile not found** — Ensure `profiles.yml` is in the `dbt_project/` directory and environment variables are set. On first run, dbt looks for profiles in `~/.dbt/`. Symlink it:
```bash
ln -sf $(pwd)/dbt_project/profiles.yml ~/.dbt/profiles.yml
```

**Missing dbt adapter** — Install the PostgreSQL adapter:
```bash
pip install dbt-postgres
```
