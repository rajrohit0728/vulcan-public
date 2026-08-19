# Trino Cluster (Coordinator + Workers) via Docker Compose — BigQuery

Local Trino cluster with a single `bigqueryrr` catalog, for use with the
`connectors/bigquery` Vulcan project.

- 1 coordinator (`trino-coordinator`)
- 2 workers (`trino-worker-1`, `trino-worker-2`)

## Prereqs

- Docker Desktop (or Docker Engine) with `docker compose`
- A GCP service account with BigQuery access (`roles/bigquery.dataViewer` +
  `roles/bigquery.jobUser` at minimum), with a JSON key downloaded

## Setup

Place the service account key at `./bigquery_key.json` (gitignored):

```bash
cp /path/to/your-service-account-key.json bigquery_key.json
```

Configure the project id:

```bash
cd trino-usecase/trino/connectors/bigquery/cluster
cp catalogs.env.example .env
# edit .env — set BIGQUERY_PROJECT_ID
set -a && source .env && set +a
docker compose up -d
```

Coordinator UI / endpoint: **http://localhost:18080**

## Verify workers registered

```bash
curl -s http://localhost:18080/v1/info | jq .
curl -s http://localhost:18080/v1/node | jq '[.nodes[] | {nodeId, coordinator, state, uri}]'
```

## Try a query

```bash
docker exec -it trino-coordinator trino --server http://localhost:8080 --execute "SHOW CATALOGS"
docker exec -it trino-coordinator trino --server http://localhost:8080 --execute "SHOW SCHEMAS FROM bigqueryrr"
```

## Run Vulcan against this cluster

```bash
export TRINO_HOST=localhost
export TRINO_PORT=18080
export TRINO_CATALOG=bigqueryrr

cd ../
vulcan plan
vulcan run
```

## Notes (Apple Silicon)

Compose pins Trino services to `linux/amd64` because the image tag used here
may not publish an arm64 variant.

## Stop / clean up

```bash
docker compose down -v
```
