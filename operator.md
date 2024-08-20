## AWS RDS PostgreSQL

Amazon Aurora Serverless for PostgreSQL is an on-demand, auto-scaling configuration for Amazon Aurora. It automatically starts up, shuts down, and scales capacity up or down based on your application's needs, ensuring that you only pay for the database resources you consume.

### Design Decisions

- **Serverless Mode**: The module configures Amazon Aurora in serverless mode, which is ideal for variable workloads.
- **Automatic Scaling**: It uses **scaling_configuration** to set parameters for auto-pausing and capacity.
- **Security**: The module ensures encryption at rest and in transit and includes VPC security group configurations.
- **Monitoring**: The module integrates with AWS CloudWatch for monitoring and sets up alarms for database capacity issues.
- **Backup and Restore**: Configurable backup retention period and options to skip final snapshot on cluster deletion.
- **High Availability**: Uses AWS RDS subnet groups to ensure database instances are spread over multiple availability zones.

### Runbook

#### Unable to Connect to PostgreSQL Database

If you are having trouble connecting to your PostgreSQL database, you can use the following commands to diagnose the issue.

Check if the database cluster is available:
```sh
aws rds describe-db-clusters --db-cluster-identifier <cluster-identifier>
```
You should see the status as `available`.

Check the VPC Security Groups attached to the RDS cluster:
```sh
aws ec2 describe-security-groups --group-ids <security-group-id>
```
Ensure the security group has the correct inbound rules.

#### Slow Query Performance

If your PostgreSQL queries are running slow, you can use these queries to diagnose the performance issues.

Check the running queries:
```sql
SELECT pid, age(clock_timestamp(), query_start), usename, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;
```
This will provide you with the list of long-running queries.

Check for table indexes:
```sql
SELECT 
    t.relname AS table_name,
    i.relname AS index_name,
    a.attname AS column_name,
    ix.indisunique AS is_unique
FROM 
    pg_class t, 
    pg_class i, 
    pg_index ix, 
    pg_attribute a 
WHERE 
    t.oid = ix.indrelid 
    AND i.oid = ix.indexrelid 
    AND a.attnum = ANY(ix.indkey) 
    AND t.relkind = 'r' 
    AND t.relname LIKE '%%';
```
This will list all indexes on your tables. Ensure that your queries utilize indexes effectively.

#### Backup Issues

If backups are failing, you can inspect the current backup configuration and logs.

Check backup retention settings:
```sh
aws rds describe-db-instances --db-instance-identifier <instance-identifier>
```
Ensure the `BackupRetentionPeriod` is set correctly.

Review backup logs:
```sh
aws rds describe-events --source-identifier <db-instance-identifier> --source-type db-instance
```
Look for any errors or warnings related to backup tasks.

#### Database Capacity Alarms

If you receive a high database capacity alarm, you can check the current capacity metrics.

Inspect current database capacity:
```sh
aws cloudwatch get-metric-statistics --metric-name ServerlessDatabaseCapacity --namespace AWS/RDS --dimensions Name=DBClusterIdentifier,Value=<cluster-identifier> --statistics Maximum --period 300 --start-time <start-time> --end-time <end-time>
```
This will provide the capacity metrics for the specified time period.

Check if there are performance bottlenecks:
```sql
SELECT datname, numbackends, xact_commit, xact_rollback, blks_read, blks_hit, tup_returned, tup_fetched, tup_inserted, tup_updated, tup_deleted 
FROM pg_stat_database;
```
Analyze the database for frequent read/write operations that may be causing capacity issues.

#### Auto-Scaling Issues

If auto-scaling is not behaving as expected, verify the scaling configuration settings.

Describe the current scaling configuration:
```sh
aws rds describe-db-clusters --db-cluster-identifier <cluster-identifier>
```
Ensure the `ScalingConfiguration` parameters are set correctly.

Check for recent scaling activities:
```sh
aws rds describe-db-cluster-snapshots --db-cluster-identifier <cluster-identifier>
```
Review logs for any auto-scaling events or issues.

