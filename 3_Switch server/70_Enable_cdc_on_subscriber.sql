USE TestDB
DECLARE 
	 @PrintMessage 			varchar(1000)
	,@PreviousTimestamp 	datetime
	
SELECT 	
	 @PrintMessage 				= ''
	,@PreviousTimestamp 		= getdate()
		
DECLARE
	@source_database sysname,
	@source_schema sysname, 
	@source_name sysname
SELECT 
	@source_database = N'TestDB',
	@source_schema = N'dbo'

--Enable CDC on database
IF (SELECT is_cdc_enabled FROM sys.databases WHERE [name] = @source_database) =0
BEGIN
	SELECT @PrintMessage = 'Enabled CDC on database. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS 		VARCHAR(100)), @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT	
	EXEC sys.sp_cdc_enable_db
END

--Enable CDC on database
IF (SELECT is_cdc_enabled FROM sys.databases WHERE [name] = @source_database) =0
BEGIN
	SELECT @PrintMessage = 'Increased CDC data retention to 10 days. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS 		VARCHAR(100)), @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT	
	EXEC sp_cdc_change_job @job_type='cleanup', @retention=14400; --10 days retention
END

--Enable CDC on all tables under source schema
DECLARE #hinstance CURSOR LOCAL fast_forward
FOR
	SELECT name  
	FROM [sys].[tables]
	WHERE SCHEMA_NAME(schema_id) = @source_schema
	AND is_ms_shipped = 0
	AND is_tracked_by_cdc = 0
    
OPEN #hinstance
FETCH #hinstance INTO @source_name
	
WHILE (@@fetch_status <> -1)
BEGIN
	EXEC [sys].[sp_cdc_enable_table]
		@source_schema
		,@source_name
		,@role_name = NULL
		,@supports_net_changes = 1
		
	SELECT @PrintMessage = 'Enabled CDC on table ['+@source_name+']. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS 		VARCHAR(100)), @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
	
	FETCH #hinstance INTO @source_name
END
	
CLOSE #hinstance
DEALLOCATE #hinstance
--Enable CDC on tables complete