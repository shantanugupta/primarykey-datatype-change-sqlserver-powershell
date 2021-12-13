DECLARE 
	@publisher 						nvarchar(1000)
	,@publisher_db 					nvarchar(1000)
	,@publication					nvarchar(1000)
	,@subscriber 					nvarchar(1000)
	,@destination_db 				nvarchar(1000)
	,@distributor					nvarchar(1000)
	,@distributor_db				nvarchar(1000)
	,@distributor_password 			nvarchar(1000)
	,@distributor_data_file 		nvarchar(1000)
	,@distributor_log_file 			nvarchar(1000)
	,@SnapshotFolder				nvarchar(1000)
	,@job_server_publisher			nvarchar(1000)
	,@job_server_subscriber			nvarchar(1000)
	
	,@publisher_db_backup_path_1	nvarchar(1000)
	,@publisher_db_backup_path_2	nvarchar(1000)
	,@db_restore_db_path_1 			nvarchar(1000)
	,@db_restore_db_path_2 			nvarchar(1000)
	,@db_restore_db_path_3 			nvarchar(1000)
	,@db_restore_db_path_4			nvarchar(1000)
	,@db_restore_db_path_5			nvarchar(1000)
	,@db_restore_db_path_6			nvarchar(1000)	
	
SELECT 
	@publisher 						= N'$(publisher)'
	,@publisher_db 					= N'$(publisher_db)'
	,@publication 					= N'$(publication)'
	,@subscriber 					= N'$(subscriber)'
	,@destination_db 				= N'$(destination_db)'
	,@distributor					= N'$(distributor)'
	,@distributor_db				= N'$(distributor_db)'
	,@distributor_password			= N'$(distributor_password)'
	,@distributor_data_file 		= N'$(distributor_data_file)'
	,@distributor_log_file			= N'$(distributor_log_file)'
	,@SnapshotFolder				= N'$(SnapshotFolder)'
	,@job_server_publisher			= N'$(job_server_publisher)'
	,@job_server_subscriber			= N'$(job_server_subscriber)'
	
	,@publisher_db_backup_path_1	= N'$(publisher_db_backup_path_1)'
    ,@publisher_db_backup_path_2	= N'$(publisher_db_backup_path_2)'
    ,@db_restore_db_path_1 	    	= N'$(db_restore_db_path_1)'
    ,@db_restore_db_path_2     		= N'$(db_restore_db_path_2)'
    ,@db_restore_db_path_3 	    	= N'$(db_restore_db_path_3)'
    ,@db_restore_db_path_4		    = N'$(db_restore_db_path_4)'
    ,@db_restore_db_path_5	    	= N'$(db_restore_db_path_5)'
    ,@db_restore_db_path_6	    	= N'$(db_restore_db_path_6)'

DECLARE 
	 @PrintMessage 			varchar(1000)
	,@PreviousTimestamp 	datetime
	
SELECT 	
	 @PrintMessage 				= ''
	,@PreviousTimestamp 		= getdate()
    
DECLARE @jobId BINARY(16)
        ,@schedule_id int
        ,@login_name nvarchar(100)
        ,@sql_command nvarchar(4000)
		,@job_name nvarchar(100)

SET NOCOUNT ON
        
SELECT 
	@login_name =   SYSTEM_USER
	, @job_name  = N'Collect replication stats for data type change',
@sql_command = N'USE '+@destination_db+'
IF NOT EXISTS(SELECT * FROM '+@destination_db+'.sys.tables where name = ''SS_20161228_Db_Disk_Space_Stats_subscriber'')
BEGIN
CREATE TABLE '+@destination_db+'.dbo.SS_20161228_Db_Disk_Space_Stats_subscriber
(
	dbname varchar(20), 
	[FileName] varchar(30), 
	CurrentSize decimal(12,6),
	CreateDate smalldatetime
)
END

INSERT INTO '+@destination_db+'.dbo.SS_20161228_Db_Disk_Space_Stats_subscriber
(
dbname,
[FileName],
CurrentSize,
CreateDate
)
SELECT 
	'''+@destination_db+''' AS DbName, 
	name AS FileName, 
	size/128.0 AS CurrentSizeMB,
	GETDATE()
FROM '+@destination_db+'.sys.database_files

INSERT INTO '+@destination_db+'.dbo.SS_20161228_Db_Disk_Space_Stats_subscriber
(
dbname,
[FileName],
CurrentSize,
CreateDate
)
SELECT 
	''tempdb'' AS DbName, 
	name AS FileName, 
	size/128.0 AS CurrentSizeMB, 
	GETDATE()
FROM tempdb.sys.database_files; 
';

SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name = @job_name)
IF (@jobId IS NOT NULL)
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_id=@jobId, @delete_unused_schedule=1;
	SELECT @PrintMessage = 'Dropped SQL job [Collect replication stats for data type change]. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
END

SELECT @jobId = NULL
EXEC  msdb.dbo.sp_add_job @job_name=@job_name, 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@login_name, @job_id = @jobId OUTPUT
SELECT @jobId

SELECT @PrintMessage = 'Created SQL job to collect space usage stats. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT	

EXEC msdb.dbo.sp_add_jobserver @job_name=@job_name, @server_name = @job_server_subscriber

SELECT @PrintMessage = 'Added SQL job to job server. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT

EXEC msdb.dbo.sp_add_jobstep @job_name=@job_name, @step_name=N'Collect db disk space stats', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=@sql_command, 
		@database_name=@destination_db, 
		@flags=0

SELECT @PrintMessage = 'Added SQL job steps. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT        
        
EXEC msdb.dbo.sp_update_job @job_name=@job_name, 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@login_name, 
		@notify_email_operator_name=N'', 
		@notify_netsend_operator_name=N'', 
		@notify_page_operator_name=N''

EXEC msdb.dbo.sp_add_jobschedule @job_name=@job_name, @name=N'Run every 1 minute', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20161227, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id

