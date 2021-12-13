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

DECLARE 
	@description nvarchar(500)

SELECT 
	@description = ''
			
-- Enabling the replication database
USE TestDB

EXEC sp_replicationdboption @dbname = @publisher_db
	,@optname = N'publish'
	,@value = N'true'

SELECT @PrintMessage = 'Enabled replication on '+@publisher_db+'. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
	, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT

SELECT @description = N'Transactional publication of database '+@publisher_db+' from Publisher '+@publisher+' .'

-- Adding the transactional publication
EXEC sp_addpublication @publication = @publication
	,@description = @description
	,@sync_method = N'concurrent'
	,@retention = 0
	,@allow_push = N'true'
	,@allow_pull = N'true'
	,@allow_anonymous = N'false'
	,@enabled_for_internet = N'false'
	,@snapshot_in_defaultfolder = N'true'
	,@compress_snapshot = N'false'
	,@ftp_port = 21
	,@allow_subscription_copy = N'false'
	,@add_to_active_directory = N'false'
	,@repl_freq = N'continuous'
	,@status = N'active'
	,@independent_agent = N'true'
	,@immediate_sync = N'false'
	,@allow_sync_tran = N'false'
	,@allow_queued_tran = N'false'
	,@allow_dts = N'false'
	,@replicate_ddl = 1
	,@allow_initialize_from_backup = N'true'
	,@enabled_for_p2p = N'false'
	,@enabled_for_het_sub = N'false'

SELECT @PrintMessage = 'Added transactional publication on '+@publisher_db+'. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT

EXEC sp_addpublication_snapshot @publication = @publication
	,@frequency_type = 1
	,@frequency_interval = 1
	,@frequency_relative_interval = 1
	,@frequency_recurrence_factor = 0
	,@frequency_subday = 8
	,@frequency_subday_interval = 1
	,@active_start_time_of_day = 0
	,@active_end_time_of_day = 235959
	,@active_start_date = 0
	,@active_end_date = 0
	,@job_login = NULL
	,@job_password = NULL
	,@publisher_security_mode = 1

SELECT @PrintMessage = 'Added publication snapshot job. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT