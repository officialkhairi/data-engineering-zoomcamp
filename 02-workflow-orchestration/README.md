# 02 - Workflow Orchestration (Kestra)

Workflow orchestration module using [Kestra](https://kestra.io/) to build data pipelines that load NYC taxi trip data into Postgres and GCP (GCS + BigQuery), plus a couple of flows demonstrating LLM chat with and without RAG.

## Stack

`docker-compose.yml` spins up:

- **kestra** — orchestration engine (UI on `http://localhost:8080`)
- **kestra_postgres** — backing store for Kestra itself
- **pgdatabase** — target Postgres database for the taxi data (`localhost:5433`)
- **pgadmin** — Postgres UI (`http://localhost:8086`)

Kestra basic auth: `admin@kestra.io` / `Admin1234!`

## Setup

### 1. Secrets and env vars

Two files are required in this directory and are **gitignored** — never commit them:

- `service-account.json` — a GCP service account key with permissions for GCS/BigQuery.
- `.env_encoded` — loaded into the `kestra` container via `env_file`. Generate it with:

  ```bash
  echo "SECRET_GCP_CREDS=$(base64 < service-account.json | tr -d '\n')" > .env_encoded
  ```

  This maps to `{{ secret('GCP_CREDS') }}` inside flows (07, 08, 09).

- `GEMINI_API_KEY` — export this in your shell before starting Docker Compose; it's interpolated into Kestra's server-level AI config (used only if you wire flows to `kv('GEMINI_API_KEY')` or similar, see flows 10/11 which read it from the Kestra KV store instead — set it there via the UI: **Namespaces → zoomcamp → KV Store**).

### 2. Start the stack

```bash
docker compose up -d
```

### 3. Configure GCP KV values

Run `flows/06_gcp_kv.yaml` first and edit the values for your own project (project id, bucket name, location, dataset) before running it.

## Flows

| Flow | Purpose |
|---|---|
| [01_hello_world.yaml](flows/01_hello_world.yaml) | Minimal flow: inputs, variables, logging, sleep, disabled daily schedule trigger. |
| [02_python.yaml](flows/02_python.yaml) | Runs a Python script in Docker to fetch Kestra's Docker Hub pull count and return it as an output. |
| [03_getting_started_data_pipeline.yaml](flows/03_getting_started_data_pipeline.yaml) | Extract/transform/query pipeline: downloads JSON, filters columns with Python, aggregates with DuckDB. |
| [04_postgres_taxi.yaml](flows/04_postgres_taxi.yaml) | Downloads a selected taxi CSV (taxi type/year/month inputs) and loads it into `pgdatabase`. |
| [05_postgres_taxi_scheduled.yaml](flows/05_postgres_taxi_scheduled.yaml) | Same as 04, driven by a schedule trigger using `trigger.date` instead of manual year/month inputs. |
| [06_gcp_kv.yaml](flows/06_gcp_kv.yaml) | Sets GCP-related KV Store values (`GCP_PROJECT_ID`, `GCP_LOCATION`, `GCP_BUCKET_NAME`, `GCP_DATASET`). **Edit the placeholder values before running.** |
| [07_gcp_setup.yaml](flows/07_gcp_setup.yaml) | Creates the GCS bucket and BigQuery dataset using the values from flow 06 and the `GCP_CREDS` secret. |
| [08_gcp_taxi.yaml](flows/08_gcp_taxi.yaml) | Downloads a selected taxi CSV, uploads it to GCS, and loads it into BigQuery. |
| [09_gcp_taxi_scheduled.yaml](flows/09_gcp_taxi_scheduled.yaml) | Same as 08, driven by a schedule trigger. |
| [10_chat_without_rag.yaml](flows/10_chat_without_rag.yaml) | Asks Gemini about Kestra 1.1 features with no retrieved context — shows outdated/generic answers. |
| [11_chat_with_rag.yaml](flows/11_chat_with_rag.yaml) | Ingests the Kestra 1.1 release notes into embeddings and answers the same question using RAG — compare against flow 10. |

## Suggested run order

1. `01_hello_world` / `02_python` / `03_getting_started_data_pipeline` — get familiar with the UI.
2. `04_postgres_taxi` then `05_postgres_taxi_scheduled` — local Postgres pipeline.
3. `06_gcp_kv` (edit values first) → `07_gcp_setup` → `08_gcp_taxi` → `09_gcp_taxi_scheduled` — GCP pipeline.
4. `10_chat_without_rag` → `11_chat_with_rag` — RAG demo.