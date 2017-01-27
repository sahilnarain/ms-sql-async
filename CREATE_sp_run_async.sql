CREATE PROCEDURE sp_run_async
@sqlServerName VARCHAR(MAX),
@dbName VARCHAR(MAX),
@queryStatement VARCHAR(MAX)
AS
BEGIN
	DECLARE @query AS VARCHAR(MAX);
	SET @query = 'use ' + @dbName + ';' + @queryStatement;
	
	DECLARE @jobName AS UNIQUEIDENTIFIER;
	SET @jobName = newid();

	EXEC msdb..sp_add_job @job_name=@jobName, @enabled=1, @start_step_id=1, @delete_level=1;
	EXEC msdb..sp_add_jobstep @job_name=@jobName, @step_id=1, @step_name='run_query', @command=@query;
	EXEC msdb..sp_add_jobserver @job_name=@jobName, @server_name=@sqlServerName;
	PRINT 'Accepted async query request for sqlServer=' + @sqlServerName + ', db=' + @dbName + ', query=' + @queryStatement + ', jobName=' + CAST(@jobName AS VARCHAR(64));
	EXEC msdb..sp_start_job @job_name=@jobName;
	PRINT 'Started job ' + CAST(@jobName AS VARCHAR(64));
END