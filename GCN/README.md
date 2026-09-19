# GCN Kafka → ELK

Streams NASA [GCN](https://gcn.nasa.gov) alerts from Kafka into a local Elastic stack and
gives you a Kibana dashboard over them.

```text
kafka.gcn.nasa.gov  ──▶  Spark Structured Streaming  ──▶  Elasticsearch  ──▶  Kibana
   (SASL_SSL /             read + decode + bulk index      gcn-<topic>       "GCN master sink"
    OAUTHBEARER)           (this is the "L" in ELK)        indices           data view + dashboard
```

Logstash is deliberately absent: Spark already holds the GCN OAuth credentials and the
exactly-once checkpointing, so it writes straight to the Elasticsearch `_bulk` API.

Everything lives in one notebook, [`gcn-elk-pipeline.ipynb`](gcn-elk-pipeline.ipynb), run
top to bottom.

## Prerequisites

- **Docker Desktop** with the `es01` / `kib01` containers running (Elasticsearch + Kibana
  9.x, security enabled). Alternatively set `MANAGE_STACK = True` in section 1 to use the
  bundled [`docker-compose.elk.yml`](docker-compose.elk.yml), which binds `9201` / `5602` so it
  can coexist with `es01`.
- **Java 17 or 21.** Spark 4.x supports nothing newer; the notebook locates one via
  `/usr/libexec/java_home` if `JAVA_HOME` points elsewhere.
- **Python kernel `gcn`** with `pyspark` and `python-dotenv`. Everything else is stdlib.
- **GCN client credentials** — create them at <https://gcn.nasa.gov/quickstart>.

## Configuration

`.env` (git-ignored):

```ini
GCN_CLIENT_ID=...
GCN_CLIENT_SECRET=...
ES_URL=https://localhost:9200
KIBANA_URL=http://localhost:5601
ES_USER=elastic
ES_PASSWORD=...
ES_CA_CERT=certs/es01_ca.crt
```

Start from the template: `cp .env.example .env`.

`es01` serves HTTPS with a self-signed CA. Copy it out once so TLS is verified rather than
skipped:

```sh
docker exec es01 cat /usr/share/elasticsearch/config/certs/http_ca.crt > certs/es01_ca.crt
```

The knobs that matter are all in **section 1** of the notebook:

| constant | default | meaning |
| --- | --- | --- |
| `TOPIC_LIST` | 8 science topics | Kafka topics indexed into Elasticsearch |
| `FAIL_ON_DATA_LOSS` | `True` | abort if Kafka has aged out offsets we still owe, rather than silently skipping |
| `MAX_OFFSETS_PER_TRIGGER` | `500` | records per 10 s micro-batch, across all topics |
| `STREAM_SECONDS` | `120` | how long a run streams before stopping cleanly |
| `RETENTION_DAYS` | `60` | documents older than this are pruned from Elasticsearch |
| `HEARTBEAT_MAX_AGE` | `30` | seconds without a heartbeat before the endpoint is reported lost |

## What the notebook does

| § | step |
| --- | --- |
| 1 | Resolve `docker` / Java, check the stack is up, wait for ES and Kibana |
| 2 | Install index templates: one `gcn-<topic>` index per topic, plus a `dynamic: false` dead-letter index |
| 3 | Build two Kafka readers: science topics from `earliest` under a durable checkpoint; heartbeat from `latest` |
| 4 | `foreachBatch` sinks: bulk-index science records; track heartbeat liveness |
| 5 | Run for `STREAM_SECONDS`, printing consumer lag and heartbeat age per batch |
| 6 | Verify: doc counts, **offset-gap audit**, dead-letter inspection, prune stale docs |
| 7 | Create the **GCN master sink** data view and the **GCN alerts** dashboard |
| 8 | Optional teardown of the compose stack |

### Delivery guarantees

The pipeline is stateless — no watermark, so nothing is dropped for arriving late.
Completeness rests on three things:

- Spark's offset checkpoint at `.checkpoints/gcn-elk` (at-least-once).
- Document IDs of `topic-partition-offset`, so a replay overwrites instead of duplicating
  (effectively exactly-once in Elasticsearch).
- A dead-letter index: a record Elasticsearch rejects is parked with its raw payload, and if
  *that* write fails the batch refuses to commit. Nothing is acknowledged that isn't stored.

Section 6b checks the result arithmetically: for every partition,
`max(offset) − min(offset) + 1` must equal the document count.

### Heartbeat as a liveness probe

`gcn.heartbeat` ticks once a second. It is consumed but **never indexed** — 86k docs/day of
noise. Instead the run loop compares the newest tick's timestamp against the wall clock:

- silence beyond `HEARTBEAT_MAX_AGE` writes one `lost` document to `gcn-heartbeat-events`;
- the next tick after that writes a matching `restored` document with the measured gap.

A healthy run writes nothing. The heartbeat reader always starts at `latest` on a throwaway
checkpoint, because a backlog of old ticks says nothing about whether the endpoint is up *now*.

### Kibana

Section 7 creates exactly one data view, **GCN master sink** (`gcn-*`), covering every topic
index, the dead-letter index and the heartbeat-incident index. Narrow by `topic` or `_index`
rather than switching views; any per-topic views from earlier revisions are removed.

The **GCN alerts** dashboard (records per topic, latest circulars, dead-letter count) stores a
time window wide enough to cover what's indexed. Discover does *not* inherit that — if it opens
empty on "Last 15 minutes", widen the picker.

`@timestamp` is the Kafka broker append time (converted to UTC). The astrophysical event time
lives under `alert.*` and differs per topic schema.

## How often to run

GCN's Kafka retention is **~28 days** (measured 2026-09-11; segments roll weekly, so records may
survive up to ~35 days but only 28 are guaranteed). Elasticsearch keeps 60, so the notebook
is the long-term store.

**Run at least weekly.** That leaves three weeks of slack against the cliff. Volume without
heartbeat is small (~17 circulars + ~70 gwalerts a day), so a week's backlog clears in two
micro-batches and the default `STREAM_SECONDS = 120` is ample.

Watch the lag line printed per batch: lag trending *upward* means you are consuming slower
than GCN produces, and sustained lag turns into permanent loss once it crosses retention.

## Operational notes

- **Changing `TOPIC_LIST` invalidates the checkpoint.** With `FAIL_ON_DATA_LOSS = True`,
  Spark aborts with `<partition> are gone` if a checkpointed topic is no longer subscribed.
  Delete `.checkpoints/gcn-elk` and let it replay; idempotent IDs make that safe.
- **`igwn.gwalert` documents are ~1.7 MB each** (embedded skymaps). A full replay of a month
  is several GB. Most are MDC test events (`superevent_id` starting with `M`); filter them in
  `to_document` if that's more than you want.
- **Pruning is `_delete_by_query`, not ILM.** There is one long-lived index per topic, and
  ILM acts on index age, which would drop a whole topic at once.
- `gcn-elk-pipeline.executed.ipynb` is the output of the last `nbconvert --execute` run;
  `.bak` is a pre-refactor copy. Neither is needed to run the pipeline.

## Files

```text
gcn-elk-pipeline.ipynb   the pipeline
docker-compose.elk.yml   self-contained ES + Kibana (optional; ports 9201 / 5602)
sample-pyspark.ipynb     GCN's own PySpark connection example, kept for reference
README.md                this file
.env.example             template for .env -- copy it and fill in the values
.env                     credentials and endpoints (git-ignored, never commit)
.gitignore               excludes .env, certs/, .checkpoints/ and notebook run artifacts
certs/es01_ca.crt        CA extracted from es01 (git-ignored)
.checkpoints/gcn-elk/    Spark offset checkpoint (git-ignored)
```

Local development only: the compose stack runs Elasticsearch without security. Do not expose
its ports beyond localhost.
