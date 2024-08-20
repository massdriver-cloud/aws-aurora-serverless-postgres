### AWS RDS for PostgreSQL (Aurora Serverless)

Amazon Aurora Serverless is an on-demand, auto-scaling configuration for Amazon Aurora. This service allows PostgreSQL databases to start up, shut down, and scale automatically based on application needs. It offers cost-efficiency by charging only for consumed database capacity.

#### Design Decisions

1. **Engine Mode**: The module uses the `serverless` engine mode, optimizing for auto-scaling capabilities.
2. **Security**: The RDS cluster encrypts storage and copies tags to snapshots for easier management.
3. **Password Management**: Utilizes `random_password` to generate a secure master password.
4. **Networking**: Automatically configures VPC security group and subnet group based on provided VPC structure.
5. **Monitoring and Alerts**: Supports automated and custom CloudWatch alarms for database capacity.
6. **Snapshot Management**: Optionally skips final snapshot creation to speed up deletion when appropriate.

### Runbook

#### Cluster Not Available

If the Aurora cluster is not reachable or available, you can verify its status using AWS CLI commands.

To check the status of an RDS cluster:
```sh
aws rds describe-db-clusters --db-cluster-identifier <your-cluster-identifier>
```
Expected output will include a status like `available`, `backing-up`, etc. Ensure the status is `available`.

#### Connection Issues to PostgreSQL

If there are connection issues, ensure the RDS instance is accepting connections.

From a client machine where psql is installed:
```sh
psql -h <cluster-endpoint> -U <master-username> -p 5432 -d <your-database-name>
```
If the connection is successful, you will be prompted to enter the password, and then you should be logged into the PostgreSQL database.

#### Query Performance Issues

If you are experiencing slow queries, check the performance insights for the database.

To enable performance insights:
```sh
aws rds modify-db-cluster --db-cluster-identifier <your-cluster-identifier> --enable-performance-insights
```
Then, use the AWS Management Console to visualize and diagnose any query performance problems.

In PostgreSQL, to analyze slow queries:
```sql
EXPLAIN ANALYZE <your-slow-sql-query>;
```
This will output detailed execution plan along with the time taken for each part of the query.

#### High CPU Utilization

If you notice high CPU utilization, you might need to analyze which queries are causing the load.

Check CPU utilization using CloudWatch:
```sh
aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization --start-time <start-time> --end-time <end-time> --period 60 --statistics Average --dimensions Name=DBInstanceIdentifier,Value=<your-instance-id>
```
Expected output will show average CPU utilization in percentage.

To identify problematic queries in PostgreSQL:
```sql
SELECT pid, usename, pg_blocking_pids(pid), query, state, age(clock_timestamp(), query_start) AS query_time 
FROM pg_stat_activity 
WHERE state != 'idle' AND now() - query_start > interval '5 minutes';
```
This SQL statement lists all active queries that have been running for more than 5 minutes.

#### Backup Issues

To verify if backups are properly configured and running:

List available backups:
```sh
aws rds describe-db-cluster-snapshots --db-cluster-identifier <your-cluster-identifier>
```
Expected output should list available snapshots with details like `SnapshotCreateTime` and `Status`.

In PostgreSQL, to perform a manual backup:
```sql
psql -h <cluster-endpoint> -U <master-username> -p 5432
\copy (SELECT * FROM your_table) TO '/path/to/backup/file.csv' CSV HEADER;
```
Replace `your_table` with the desired table name and `/path/to/backup/file.csv` with an appropriate file path.

