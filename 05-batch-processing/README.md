# Module 5: Batch Processing (Spark)

NYC taxi/FHVHV trip data explored and converted to Parquet with PySpark,
running locally (`local[*]`) via a `uv`-managed virtualenv.

## Project layout

```
05-batch-processing/
├── .venv/                              # project virtualenv (pyspark), gitignored
├── pyproject.toml                      # deps: pyspark (Spark 4.2.0)
├── 00_test.ipynb                       # sanity check: SparkSession boots, Spark UI reachable
├── 01_simple_csv_to_parquet.ipynb      # taxi zone lookup: CSV -> DataFrame -> Parquet
├── 02_pyspark.ipynb                    # FHVHV Jan 2021: schema inference, explicit schema,
│                                        # partitioning, UDFs, column ops
├── taxi_zone_lookup.csv                # downloaded source (NYC TLC)
├── fhvhv_tripdata_2021-01.csv(.gz)     # downloaded source (DataTalksClub release mirror)
├── head.csv                            # first 1000 rows of the FHVHV file, for quick iteration
├── zones/                              # Parquet output from notebook 01
├── fhvhv/2021/01/                      # Parquet output from notebook 02 (24 partitions)
├── main.py                             # empty scaffold, not yet used
└── test_spark.py                       # standalone script version of the 00_test sanity check
```

## Setup

```bash
uv sync            # installs pyspark into .venv (Python 3.13)
source .venv/bin/activate
```

Requires a local Java runtime for Spark to run (`local[*]` master).

## Progress so far

1. **00_test.ipynb / test_spark.py** — confirm PySpark (4.2.0) starts locally and the Spark UI
   comes up (`http://localhost:4040`).
2. **01_simple_csv_to_parquet.ipynb** — download `taxi_zone_lookup.csv`, read it with
   `spark.read.csv(header=True)`, write it out as Parquet (`zones/`).
3. **02_pyspark.ipynb** — download the January 2021 FHVHV trip data (~124MB gzipped):
   - Read with header-only inference, inspect the resulting (all-string) schema.
   - Sample the file to `head.csv` and use pandas to figure out real column types, then
     define an explicit `pyspark.sql.types.StructType` schema (proper timestamps/ints)
     and re-read the CSV with it.
   - `repartition(24)` and write to `fhvhv/2021/01/` as partitioned Parquet.
   - Re-read the Parquet output, derive `pickup_date`/`dropoff_date` columns with
     `F.to_date`, and register a Python UDF (`crazy_stuff`) to derive a `base_id` from
     `dispatching_base_num`.

## Notes

- `main.py` and the `.ipynb_checkpoints/` copies are unused leftovers from `uv init` /
  Jupyter autosave — safe to ignore.
- The root `.gitignore` excludes `.venv/` and `*.parquet`, but the raw CSV/GZ downloads
  (`taxi_zone_lookup.csv`, `fhvhv_tripdata_2021-01.csv`, `.csv.gz`, `head.csv`) and the
  `zones/`/`fhvhv/` Parquet directory contents are **not** currently ignored — worth adding
  before committing, since the gzipped trip file alone is ~124MB.
