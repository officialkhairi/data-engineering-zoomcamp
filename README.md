# data-engineering-zoomcamp

NY Taxi data ingestion pipeline: loads NYC Yellow Taxi trip data (CSV, downloaded
from the [DataTalksClub nyc-tlc-data](https://github.com/DataTalksClub/nyc-tlc-data)
releases) into a Postgres database.

## Prerequisites

- Docker
- [uv](https://docs.astral.sh/uv/) (for local/non-Docker runs)

## Setup

Install dependencies:

```bash
uv sync
```

## Running Postgres + pgAdmin

Start the database and pgAdmin via Docker Compose:

```bash
docker compose up -d
```

This brings up two services on the `data-engineering-zoomcamp_default` network:

| Service     | Image            | Port | Credentials                                  |
|-------------|------------------|------|-----------------------------------------------|
| `pgdatabase`| `postgres:18`    | 5432 | user: `root`, password: `root`, db: `ny_taxi` |
| `pgadmin`   | `dpage/pgadmin4` | 8085 | `admin@admin.com` / `root`                    |

Open pgAdmin at [http://localhost:8085](http://localhost:8085) and register a new
server pointing at host `pgdatabase`, port `5432`.

## Ingesting data

`ingest_data.py` downloads a month of Yellow Taxi trip data and loads it into
Postgres in chunks, via a Click CLI.

### Build the ingestion image

```bash
docker build -t taxi_ingest:v001 .
```

### Run ingestion

```bash
docker run -it \
  --network=data-engineering-zoomcamp_default \
  taxi_ingest:v001 \
    --pg-user=root \
    --pg-pass=root \
    --pg-host=pgdatabase \
    --pg-port=5432 \
    --pg-db=ny_taxi \
    --target-table=yellow_taxi_data \
    --year=2021 \
    --month=1 \
    --chunksize=100000
```

`--pg-host` must be `pgdatabase` (the Compose service name) when running on the
`data-engineering-zoomcamp_default` network.

### CLI options

| Option            | Default              | Description                  |
|--------------------|-----------------------|-------------------------------|
| `--pg-user`        | `root`                | Postgres user                |
| `--pg-pass`        | `root`                | Postgres password             |
| `--pg-host`        | `localhost`           | Postgres host                 |
| `--pg-port`        | `5432`                | Postgres port                 |
| `--pg-db`          | `ny_taxi`              | Postgres database name        |
| `--year`           | `2021`                 | Year of the trip data         |
| `--month`          | `1`                    | Month of the trip data        |
| `--chunksize`      | `100000`               | Rows per chunk written to SQL |
| `--target-table`   | `yellow_taxi_data`     | Destination table name        |

Run `python ingest_data.py --help` for the same reference locally.

### Running locally (without Docker)

```bash
uv run ingest_data.py --pg-host=localhost --year=2021 --month=1
```
