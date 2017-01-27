# ms-sql-async
A hacky way of running SQL queries in a non-blocking manner.

#Scenario
Consider a scenario where a series of time-consuming DML queries are to be run.
```
  --1 - Takes 25 seconds
  INSERT INTO TABLE1 (<fields>) VALUES(<values>);
  --2 - Takes 20 seconds
  INSERT INTO TABLE2 (<fields>) VALUES(<values>);
  --3 - Takes 45 seconds
  UPDATE TABLE3 SET(<fieldList>=<valueList>) WHERE (<conditions>);
  --4 - Takes 30 seconds
  SELECT (<fields>) FROM TABLE4 WHERE (<conditions>);

  -- 1,2,3,4 together take 25+20+45+30 = 120 seconds, which is bad enough to make any respectable production code to time out and give up by then.
```

# Usage
After creating the SP called `sp_run_async`, the piece of code calling DML queries would become non-blocking.
Of course, this should not be used in case you need the queries to be run synchronously (which would be the case if result-dependent values need to be passed on to the next query, or if the queries are logically transactional in nature).

```
  exec sp_run_async SQL_SERVER_NAME, DB_NAME, QUERY 
```

So, for the above example would be run this way -
```
  DECLARE @sqlServerName AS VARCHAR(MAX);
  DELCARE @dbName AS VARCHAR(MAX);
  DECLARE @sqlQuery AS VARCHAR(MAX);

  SET @sqlServerName = 'MSSQL_Server1'; --Replace this with the actual server name
  SET @dbName = 'TestDatabase'; --Replace this with the actual database name
  
  SET @query1 = 'INSERT INTO TABLE1 (<fields>) VALUES(<values>);';
  SET @query2 = 'INSERT INTO TABLE2 (<fields>) VALUES(<values>);';
  SET @query3 = 'UPDATE TABLE3 SET(<fieldList>=<valueList>) WHERE (<conditions>);';
  SET @query4 = 'SELECT (<fields>) FROM TABLE4 WHERE (<conditions>);';

  -- Now to run them in a non-blocking manner
  EXEC sp_run_async @sqlServerName, @dbName, @query1;
  EXEC sp_run_async @sqlServerName, @dbName, @query2;
  EXEC sp_run_async @sqlServerName, @dbName, @query3;
  EXEC sp_run_async @sqlServerName, @dbName, @query4;
  
  -- These would probably run in less than a second. Much wow.
```

# Explanation and internals
The parameters to the `sp_run_async` stored procedure are used for creating a SQL job, which is triggered immediately after creationg and deleted on successful creation.
For unsuccessful runs, the SQL job would not be deleted, so you can always have a look at the jobs in the SQL Server specified as @sqlServerName and re-run them (we've already assumed that these are non-critical to transactional logic but important nonetheless!)

Of course, this assumes that the user running the `sp_run_async` stored procedure has sufficient privileges to run SQL jobs.
If not, permissions need to be given to the user running `sp_run_async` by running
```
  GRANT EXECUTE ON OBJECT::dbo.sp_add_job TO <user>;
  GO
  GRANT EXECUTE ON OBJECT::dbo.sp_add_jobstep TO <user>;
  GO
  GRANT EXECUTE ON OBJECT::dbo.sp_add_jobserver TO <user>;
  GO
  GRANT EXECUTE ON OBJECT::dbo.sp_start_job TO <user>;
  GO
```
