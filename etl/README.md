## Task: ETL

Create SQL ETL scripts to achieve needed transformations from source into target data.

### Database Setup

Use such command to spin up a PostgreSQL database in Docker:
```shell
$ docker run --name ucu-dw-etl -e POSTGRES_PASSWORD=pass123 -p 5432:5432 -d postgres:latest
```
