# Armadillo storage / CSV REST API (`admin:admin` basic auth)

Endpoints on a running Armadillo (see `armadillo-local-run.md`):

- Create project: `PUT /access/projects` with `{"name":"<proj>"}`
- Upload CSV (converts to parquet): `POST /storage/projects/{proj}/csv`
  form fields: `file`, `object` (e.g. `core/x.csv`), `numberOfRowsToDetermineTypeBy`
- Upload parquet/binary: `POST /storage/projects/{proj}/objects` (fields `file`, `object`)
- Read back: `GET .../objects/{object}/metadata`, `.../preview`, or download `.../objects/{object}`
  (CSV is stored as `<name>.parquet`).
