# ABFSS Spark Data Product

A layered Vulcan data product on **Spark + Iceberg** (`abfsslhdepotrr`, an ABFSS
lakehouse depot): mock **customer / product / order** data seeded from CSV
files, materialized through a **staging → intermediate → mart** pipeline,
with data-quality checks, custom audits, unit tests, macros, a semantic
layer, and business metrics on top.

Modeled after `trino-usecase/starburst` (the repo's most fully-productised
reference project), adapted for Spark: that project reads a live external
catalog (`tpch.tiny`) for its staging layer; this depot has no external
catalog to federate from, so every staging model is a `kind SEED` loading a
mock CSV instead of a `kind VIEW` over a source table. Everything downstream
(intermediate joins, mart tables, dq, audits, tests, macros, semantics,
metrics, linter) follows the same shape as the reference project.

## Layout

```
quick-sanity/
├── config.yaml                 # Vulcan project config (Spark gateway -> abfsslhdepotrr depot)
├── domain-resource.yaml         # DataOS vulcan-rr resource manifest
├── seeds/                       # Mock/sample CSV data (no external source system)
│   ├── raw_customers.csv
│   ├── raw_products.csv
│   ├── raw_orders.csv
│   ├── raw_order_items.csv
│   └── region_tier.csv          # hand-curated region -> tier/priority lookup
├── models/
│   ├── staging/                 # kind SEED, one per CSV (typed, asserted)
│   ├── intermediate/            # kind FULL, joined/enriched
│   ├── mart/                    # kind FULL, consumption-ready (dims/fact/summary/window fn)
│   ├── dq/                      # kind: dq — Soda-style rules + column profiles
│   ├── semantics/                # kind: semantic — dimensions/measures/joins
│   └── metrics/                  # kind: metric — business metrics over semantics
├── audits/                      # custom AUDIT(...) SQL, referenced by bare name in assertions (...)
├── tests/                       # unit-style model tests (DuckDB-backed)
├── macros/                      # Python @macro(...) functions, called as @macro_name(...)
├── linter/                      # custom Python lint rules (Rule subclasses), registered as warn_rules
└── .artifacts/                  # DataOS secret/depot resources (gitignored where sensitive)
```

## Model layers

**Seeds** (`seeds/*.csv`) — mock/sample data standing in for a real source
system: 10 customers, 8 products, 20 orders, 23 order line items, plus
`region_tier.csv` — a hand-curated lookup (region → `region_tier` /
`priority_rank`) that is **not** derived from the other seeds, mirroring
`starburst`'s `market_segment_tier.csv` pattern of joining a seed-backed
reference table into the pipeline like any other source.

**Staging** (`abfsslhdepotrr.staging_v5_vnew`, `kind SEED`) — one seed model per CSV,
typed and asserted: `stg_customers`, `stg_products`, `stg_orders`,
`stg_order_items`, `stg_region_tier`.

**Macros** (`macros/order_macros.py`) — `@net_amount(quantity, unit_price,
discount_pct)` (line revenue after a percentage discount) and
`@order_value_tier(amount_col)` (classifies a line's `net_amount` into
premium/standard/basic/micro), both used in `int_order_lines_enriched`.

**Intermediate** (`abfsslhdepotrr.intermediate_v5_vnew`, `kind FULL`):
- `int_customers_enriched` — customers + the `stg_region_tier` seed lookup
- `int_order_lines_enriched` — order items + orders + customers + products,
  computing `net_amount`/`order_value_tier` via the macros above

**Mart** (`abfsslhdepotrr.mart_v5_vnew`, `kind FULL`) — consumption-ready:
- `dim_customers`, `dim_products` (the latter adds a computed `margin_pct`)
- `fct_order_lines` — order-line grain fact, excludes cancelled orders, adds
  an `order_timestamp` (`TIMESTAMP`) alongside `order_date` (`DATE`) —
  metrics' `ts:` field requires `TIMESTAMP`, but DQ/mart grouping elsewhere
  still wants `DATE`, so both are kept rather than changing one consumer
- `mart_sales_summary` — daily revenue rollup by region × category
  (`GROUP BY`, `SUM`, `COUNT(DISTINCT ...)`)
- `customer_region_rank` — `RANK() OVER (PARTITION BY region ORDER BY
  total_spent DESC)` + a windowed `AVG(...) OVER (...)`, exercising window
  functions the same way `starburst`'s `customer_balance_rank` does

**Semantics** (`models/semantics/`, `kind: semantic`): `customers` and
`order_lines` (joins `many_to_one` to `customers`) — every entity here is
reachable from `order_lines` through that join, deliberately no standalone,
unjoined entities. `customer_region_rank` (the window-function mart above)
is **not** wrapped in a semantic entity: it's a single-table window-function
result with no natural multi-entity relationship of its own, so rather than
manufacture a join just to satisfy "every entity joined," it's simplest not
to expose it as a `kind: semantic` entity at all — see the matching decision
in `trino-usecase/starburst`'s Changelog (2026-07-20). **Rule that isn't
obvious from the DSL**: every column a
measure's `expression` or a join's `expression` references must also be
listed under that model's `dimensions:` — `vulcan plan` rejects "unknown
dimension" otherwise, even for purely numeric columns.

**Metrics** (`models/metrics/`, `kind: metric`): `daily_revenue` (day
granularity, net revenue by region × category) and `orders_by_region`
(month granularity, distinct order count by region). Both use
`ts: order_lines.order_timestamp` — a `DATE` dimension is rejected here.

**DQ** (`models/dq/`, `kind: dq`) — one suite per mart model plus
`stg_customers` (closing the gap `RequireDqForMartModels` would otherwise
flag): row-count/missing/duplicate checks plus `failed rows` checks for
negative margins, negative net amounts, out-of-range discounts, and
duplicate summary grain. Every suite also carries a `profiles:` list (the
column-profiling mechanism — a top-level key in the `dq/*.yml` file, not a
`MODEL(...)` clause).

**Audits** (`audits/*.sql`) — custom checks referenced by **bare name only**
inside each model's `assertions (...)` clause (there is no separate
`audits (...)` model clause — `assertions (...)` takes built-in checks and
custom audit names together in one list):
`no_null_region_tier` / `region_tier_lookup_consistency` → `dim_customers`
(the second re-derives the lookup join *inside* the audit, catching drift
even if the upstream join were ever miswired); `no_negative_quantity` /
`no_negative_net_amount` / `net_amount_consistency` → `fct_order_lines`
(the last recomputes `net_amount` from its inputs and flags drift beyond
rounding tolerance); `no_negative_total_net_amount` → `mart_sales_summary`.

**Tests** (`tests/*.yaml`) — DuckDB-backed unit tests: `test_int_customers_enriched`
(lookup-join correctness), `test_int_order_lines_enriched` (verifies the
`net_amount`/`order_value_tier` macro formulas), `test_mart_sales_summary`
(aggregation correctness).

**Linter** (`linter/linters.py`, warning-only via `config.yaml`'s
`linter.warn_rules`): `RequireGrainForAllModels`, `RequireOwnerForAllModels`,
`RequireAssertionsForAllModels`, `RequireDqForMartModels` — skips
non-materializing kinds (seed/dq/audit/metric/semantic/external) so the
rules don't misfire on files that can't carry a grain or a dq suite.

## A note on the SEED/Hive-catalog gotcha

`vulcan-spark` defaults to a Hive session catalog for SEED loads but the
image ships no Derby driver, which can break `vulcan plan`/`run` once a
project has multiple SEED models (all five staging models here are seeds).
`domain-resource.yaml`'s `sparkConf` sets
`spark.sql.catalogImplementation: "in-memory"` on both the workflow and API
sections to sidestep this — every table in this project lives in the
Iceberg REST depot, not the Hive metastore, so an in-memory catalog is
sufficient and avoids needing to vendor a Derby jar at all.

## Plan & run

```bash
vulcan migrate   # initializes local Vulcan state
vulcan plan      # stages all 13 models (5 seeds, 2 intermediate, 5 mart, dq/semantics/metrics are metadata-only)
vulcan run       # materializes staging seeds + intermediate/mart tables
```

Ad-hoc sanity check after `run`:

```bash
vulcan fetchdf "select * from abfsslhdepotrr.mart_v5_vnew.mart_sales_summary order by total_net_amount_usd desc limit 10"
```

## Deploy

Apply the object-store secret before (or alongside) the domain resource —
`domain-resource.yaml`'s `spec.objectStoreConnection` resolves it as
`<entityTenant>:vulcan-object-store-sec`:

```bash
dataos apply -f .artifacts/vulcan-object-store-sec.yaml
dataos apply -f domain-resource.yaml
```
