# BigQuery Quick-Sanity Data Product

A layered Vulcan data product on **Trino + BigQuery** (`bigquery` catalog):
mock **customer / product / order** data seeded from CSV files, materialized
through a **staging → intermediate → mart** pipeline, with data-quality
checks, custom audits, unit tests, macros, a semantic layer, and business
metrics on top.

Modeled after `spark-usecase/lakehouse/s3/quick-sanity`, adapted for Trino:
that project uses `spark2` dialect against an S3/Iceberg depot with no
external catalog to federate from; this project is the same shape but
targets the Trino `bigquery` catalog set up in [`cluster/`](cluster) instead
(see [`cluster/README.md`](cluster/README.md) for cluster setup and
credentials). Every staging model is still a `kind SEED` loading a mock CSV
— there is no live external BigQuery source table used here.

## Layout

```
bigquery/
├── config.yaml                  # Vulcan project config (Trino gateway -> bigquery catalog)
├── cluster/                      # Local Trino + BigQuery docker-compose cluster (see its own README)
├── seeds/                        # Mock/sample CSV data (no external source system)
│   ├── raw_customers.csv
│   ├── raw_products.csv
│   ├── raw_orders.csv
│   ├── raw_order_items.csv
│   └── region_tier.csv           # hand-curated region -> tier/priority lookup
├── models/
│   ├── staging/                  # kind SEED, one per CSV (typed, asserted)
│   ├── intermediate/             # kind FULL, joined/enriched
│   ├── mart/                     # kind FULL tables on bigqueryrr
│   ├── mart_views/               # kind VIEW on abfsslhdepotrr (BigQuery marts + Spark Iceberg)
│   ├── dq/                       # kind: dq — Soda-style rules + column profiles
│   ├── semantics/                # kind: semantic — dimensions/measures/joins
│   └── metrics/                  # kind: metric — business metrics over semantics
├── audits/                       # custom AUDIT(...) SQL, referenced by bare name in assertions (...)
├── tests/                        # unit-style model tests (DuckDB-backed)
├── macros/                       # Python @macro(...) functions, called as @macro_name(...)
└── linter/                       # custom Python lint rules (Rule subclasses), registered as warn_rules
```

## Model layers

**Seeds** (`seeds/*.csv`) — mock/sample data: 10 customers, 8 products, 20
orders, 23 order line items, plus `region_tier.csv` — a hand-curated lookup
(region → `region_tier` / `priority_rank`) that is **not** derived from the
other seeds.

**Staging** (`bigqueryrr.staging_v4_vnew`, `kind SEED`) — one seed model
per CSV, typed and asserted: `stg_customers`, `stg_products`, `stg_orders`,
`stg_order_items`, `stg_region_tier`.

**Macros** (`macros/order_macros.py`) — `@net_amount(quantity, unit_price,
discount_pct)` (line revenue after a percentage discount) and
`@order_value_tier(amount_col)` (classifies a line's `net_amount` into
premium/standard/basic/micro), both used in `int_order_lines_enriched`.

**Intermediate** (`bigqueryrr.intermediate_v4_vnew`, `kind FULL`):
- `int_customers_enriched` — customers + the `stg_region_tier` seed lookup
- `int_order_lines_enriched` — order items + orders + customers + products,
  computing `net_amount`/`order_value_tier` via the macros above

**Mart** (`bigqueryrr.mart_v4_vnew`, `kind FULL`) — all physical mart tables:
- `dim_customers`, `dim_products` (the latter adds a computed `margin_pct`)
- `fct_order_lines` — order-line grain fact, excludes cancelled orders, adds
  an `order_timestamp` (`TIMESTAMP(6)`) alongside `order_date` (`DATE`) —
  metrics' `ts:` field requires a timestamp, but DQ/mart grouping elsewhere
  still wants `DATE`, so both are kept. **BigQuery-specific gotcha**: Trino's
  BigQuery connector only supports `TIMESTAMP(6)` (microsecond precision) —
  bare `TIMESTAMP` defaults to `TIMESTAMP(3)` and fails with `Unsupported
  column type: timestamp(3)`.
- `mart_sales_summary` — daily revenue rollup by region × category
- `region_order_summary` — regional order/revenue totals
- `customer_region_rank` — `RANK() OVER (PARTITION BY region ORDER BY
  total_spent DESC)` + a windowed `AVG(...) OVER (...)`

**Mart views** (`abfsslhdepotrr.mart_v4_vnew`, `kind VIEW`) — read-only
depot-facing views over the BigQuery marts above (`SELECT * FROM
bigqueryrr.mart_v4_vnew.<model>`). Semantics and Explore consumers query
these views; DQ/tests target the underlying `bigqueryrr` tables.

One extra view federates a table that Spark already materialized on the
same depot in `abfss-quick-sanity` (schema `mart_v6_vnew`), so this DP
does not recreate it:

- `abfss_mart_sales_summary` → `abfsslhdepotrr.mart_v6_vnew.mart_sales_summary`

**Semantics** (`models/semantics/`, `kind: semantic`): `customers` and
`order_lines` (joins `many_to_one` to `customers`) — every entity here is
reachable from `order_lines` through that join. `customer_region_rank` (the
window-function mart above) is **not** wrapped in a semantic entity: it's a
single-table window-function result with no natural multi-entity
relationship of its own. **Rule that isn't obvious from the DSL**: every
column a measure's `expression` or a join's `expression` references must
also be listed under that model's `dimensions:` — `vulcan plan` rejects
"unknown dimension" otherwise, even for purely numeric columns.

**Metrics** (`models/metrics/`, `kind: metric`): `daily_revenue` (day
granularity, net revenue by region × category) and `orders_by_region`
(month granularity, distinct order count by region). Both use
`ts: order_lines.order_timestamp` — a `DATE` dimension is rejected here.

**DQ** (`models/dq/`, `kind: dq`) — one suite per mart model plus
`stg_customers`: row-count/missing/duplicate checks plus `failed rows`
checks for negative margins, negative net amounts, out-of-range discounts,
and duplicate summary grain. Every suite also carries a `profiles:` list.

**Audits** (`audits/*.sql`) — custom checks referenced by **bare name only**
inside each model's `assertions (...)` clause:
`no_null_region_tier` / `region_tier_lookup_consistency` → `dim_customers`;
`no_negative_quantity` / `no_negative_net_amount` / `net_amount_consistency`
→ `fct_order_lines`; `no_negative_total_net_amount` → `mart_sales_summary`.

**Tests** (`tests/*.yaml`) — DuckDB-backed unit tests: `test_int_customers_enriched`
(lookup-join correctness), `test_int_order_lines_enriched` (verifies the
`net_amount`/`order_value_tier` macro formulas), `test_mart_sales_summary`
(aggregation correctness).

**Linter** (`linter/linters.py`, warning-only via `config.yaml`'s
`linter.warn_rules`): `RequireGrainForAllModels`, `RequireOwnerForAllModels`,
`RequireAssertionsForAllModels`, `RequireDqForMartModels`.

## BigQuery/Trino gotchas hit while building this

1. **Timestamp precision** — use `TIMESTAMP(6)`, never bare `TIMESTAMP`
   (see `fct_order_lines` above).
2. **No `partitioned_by` table property support** — `INCREMENTAL_BY_TIME_RANGE`
   models default to auto-partitioning by the time column
   (`partition_by_time_column: true`), which Trino tries to express as a
   `partitioned_by` table property. The BigQuery connector doesn't support
   that property at all, so any such model needs
   `partition_by_time_column false` explicitly in its `kind` block. This
   project sidesteps the issue entirely by using `kind FULL` everywhere
   downstream of staging (same as `quick-sanity`).
3. **Service account key field names** — the JSON key file must use
   `project_id` (snake_case), not `projectId`; the BigQuery client library
   silently fails to resolve the project otherwise.

## Plan & run

```bash
# 1. Start the local Trino + BigQuery cluster (see cluster/README.md)
cd cluster && docker compose up -d && cd ..

# 2. Point Vulcan at it
export TRINO_HOST=localhost
export TRINO_PORT=18080

vulcan plan      # stages all models (5 seeds, 2 intermediate, 5 mart, dq/semantics/metrics are metadata-only)
vulcan run       # materializes staging seeds + intermediate/mart tables
```

Ad-hoc sanity check after `run`:

```bash
vulcan fetchdf "select * from abfsslhdepotrr.mart_v4_vnew.mart_sales_summary order by total_net_amount_usd desc limit 10"
vulcan fetchdf "select * from abfsslhdepotrr.mart_v4_vnew.abfss_mart_sales_summary order by total_net_amount_usd desc limit 10"
```
