# Module 4: Analytics Engineering

NYC taxi trip data modeled with dbt on top of DuckDB. Raw yellow/green taxi
trip parquet files are ingested into a local DuckDB file, then transformed
through staging → intermediate → marts layers.

## Project layout

```
04-analytics-engineering/
├── .venv/                      # project virtualenv (dbt-core + dbt-duckdb)
└── taxi_rides_ny/               # dbt project
    ├── ingest.py                 # downloads raw data & loads it into DuckDB
    ├── taxi_rides_ny.duckdb       # DuckDB database file (generated)
    ├── data/                     # downloaded parquet files (generated, gitignored)
    ├── models/
    │   ├── staging/                 # 1:1 with raw sources, light cleanup/casting
    │   │   ├── stg_yellow_tripdata.sql
    │   │   ├── stg_green_tripdata.sql
    │   │   └── sources.yml
    │   ├── intermediate/            # unions/joins across staging models
    │   │   └── int_trips_unioned.sql
    │   └── marts/                   # final, query-ready dimensional models
    │       ├── dim_locations.sql
    │       ├── dim_vendors.sql
    │       └── fct_trips.sql
    └── macros/
        └── get_payment_type_description.sql
```

## Prerequisites

- Python 3.12 (the project venv already has it pinned)
- The project venv at `.venv/` with `dbt-core` and `dbt-duckdb` installed

> ⚠️ If your system also has another `dbt` on `PATH` (e.g. an old
> `~/Library/Python/3.9/bin/dbt`), make sure the project venv comes first,
> otherwise `dbt run` will fail with `Could not find adapter type duckdb!`.
> Activating the venv (below) takes care of this.

## Setup

From `04-analytics-engineering/`:

```bash
# activate the project virtualenv
source .venv/bin/activate

# (only if the venv doesn't exist yet or is missing packages)
uv venv .venv
uv pip install --python .venv/bin/python dbt-core dbt-duckdb
```

## 1. Ingest raw data

From `taxi_rides_ny/`, download the NYC taxi parquet files (2019–2020,
yellow + green) and load them into DuckDB under the `prod` schema:

```bash
cd taxi_rides_ny
python ingest.py
```

This populates `taxi_rides_ny.duckdb` with `prod.yellow_tripdata` and
`prod.green_tripdata`. It's safe to re-run — already-downloaded files are
skipped.

## 2. Run dbt

Still inside `taxi_rides_ny/`:

```bash
dbt debug     # sanity-check the connection/profile
dbt run       # build all models into the `dev` schema
dbt test      # run schema/data tests
dbt build     # run + test in DAG order
```

Useful selectors:

```bash
dbt run --select staging          # just the staging layer
dbt run --select stg_yellow_tripdata+   # a model and everything downstream
```

Docs:

```bash
dbt docs generate
dbt docs serve
```

## Profile

dbt connects using the `taxi_rides_ny` profile in `~/.dbt/profiles.yml`,
targeting the local `taxi_rides_ny.duckdb` file with two targets:

- `dev` — writes to the `dev` schema (default target)
- `prod` — writes to the `prod` schema

## Notes

- `trip_type` and `ehail_fee` only exist in the green taxi source data; they
  are `NULL`-cast in `stg_yellow_tripdata` so the two staging models line up
  for the union in `int_trips_unioned`.
- The `models/example/` models are the default dbt scaffold models and can
  be deleted once you no longer need them for reference.
