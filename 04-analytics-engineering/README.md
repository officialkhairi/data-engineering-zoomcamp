# Module 4: Analytics Engineering

NYC taxi trip data modeled with dbt on top of DuckDB. Raw yellow/green taxi
trip parquet files are ingested into a local DuckDB file, then transformed
through staging → intermediate → marts layers into a star schema
(`fct_trips` + `dim_zones` / `dim_vendors`) with a reporting mart on top.

## Project layout

```
04-analytics-engineering/
├── .venv/                          # project virtualenv (dbt-core + dbt-duckdb)
└── taxi_rides_ny/                   # dbt project
    ├── ingest.py                      # downloads raw data & loads it into DuckDB
    ├── taxi_rides_ny.duckdb            # DuckDB database file (generated, gitignored)
    ├── data/                           # downloaded parquet files (generated, gitignored)
    ├── seeds/
    │   ├── payment_type_lookup.csv        # payment_type code -> description
    │   └── taxi_zone_lookup.csv           # NYC taxi zone/borough lookup
    ├── models/
    │   ├── staging/                       # 1:1 with raw sources, light cleanup/casting
    │   │   ├── stg_yellow_tripdata.sql
    │   │   ├── stg_green_tripdata.sql
    │   │   └── sources.yml
    │   ├── intermediate/                  # unions, enrichment, dedup
    │   │   ├── int_trips_unioned.sql         # union of yellow + green staging
    │   │   └── int_trips.sql                 # + payment lookup, surrogate key, dedup
    │   └── marts/                         # final, query-ready dimensional models
    │       ├── dim_zones.sql                 # from taxi_zone_lookup seed
    │       ├── dim_vendors.sql               # distinct vendors from fct_trips
    │       ├── fct_trips.sql                 # incremental fact table (star schema)
    │       └── reportings/
    │           └── fct_monthly_zone_revenue.sql  # monthly revenue by zone/service_type
    └── macros/
        ├── get_payment_type_description.sql
        ├── get_trip_duration_minutes.sql   # duckdb/bigquery-aware timestamp diff
        └── get_vendor_names.sql
```

## Prerequisites

- Python 3.12 (the project venv already has it pinned)
- The project venv at `.venv/` with `dbt-core` and `dbt-duckdb` installed

> ⚠️ If your system also has another `dbt` on `PATH` (e.g. an old
> `~/Library/Python/3.9/bin/dbt`), make sure the project venv comes first,
> otherwise `dbt run` will fail with `Could not find adapter type duckdb!`.
> Activating the venv (below) takes care of this.

> ⚠️ DuckDB only allows a single writer connection to the `.duckdb` file. If
> `dbt run`/`build` fails with `Could not set lock on file ...`, another
> process (commonly the VS Code dbt Power User extension's query panel) still
> has it open — close that panel / reload the window and try again.

## Setup

From `04-analytics-engineering/`:

```bash
# activate the project virtualenv
source .venv/bin/activate

# (only if the venv doesn't exist yet or is missing packages)
uv venv .venv
uv pip install --python .venv/bin/python dbt-core dbt-duckdb
```

From `taxi_rides_ny/`, install the dbt package dependencies (this project uses
`dbt_utils` for surrogate key generation in `int_trips`):

```bash
cd taxi_rides_ny
dbt deps
```

## 1. Ingest raw data

Still inside `taxi_rides_ny/`, download the NYC taxi parquet files
(2019–2020, yellow + green) and load them into DuckDB under the `prod`
schema:

```bash
python ingest.py
```

This populates `taxi_rides_ny.duckdb` with `prod.yellow_tripdata` and
`prod.green_tripdata`. It's safe to re-run — already-downloaded files are
skipped.

## 2. Run dbt

```bash
dbt debug     # sanity-check the connection/profile
dbt seed      # load payment_type_lookup.csv and taxi_zone_lookup.csv
dbt run       # build all models into the `dev` schema
dbt test      # run schema/data tests
dbt build     # seed + run + test, in DAG order (recommended)
```

Useful selectors:

```bash
dbt build --select staging          # just the staging layer
dbt build --select stg_yellow_tripdata+   # a model and everything downstream
dbt build --select fct_trips+             # rebuild the fact table and its consumers
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

Both targets are configured with `memory_limit: '16GB'`. If `fct_trips`
(materialized incrementally, generating surrogate keys over the full
2019–2020 union of yellow + green trips) fails with a DuckDB `Out of Memory
Error` on your machine, lower this to fit your available RAM, or raise it if
you have more headroom.

## Notes

- `trip_type` and `ehail_fee` only exist in the green taxi source data;
  they're synthesized (`1`/`0`, since yellow is street-hail only) in
  `stg_yellow_tripdata` so both staging models line up for the union in
  `int_trips_unioned`.
- Column naming convention across staging/intermediate/marts is full
  snake_case (`vendor_id`, `rate_code_id`, `pickup_location_id`,
  `dropoff_location_id`) — keep new models consistent with this.
- `fct_trips` is materialized as `incremental` (`merge` on `trip_id`), so
  reruns only reprocess new trips based on `pickup_datetime`. Use
  `dbt run --full-refresh --select fct_trips` to force a full rebuild.
- Known issue: `dim_vendors.sql` calls `{{ get_vendor_data(...) }}`, but the
  macro defined in `macros/get_vendor_names.sql` is named `get_vendor_name`
  — this mismatch will fail at compile time until one of the two is renamed
  to match.
