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
-----------------BEGIN: Script to be run at Subscriber 'subscriber-host'----------------

EXEC sp_addpullsubscription @publisher = @publisher
	,@publication = @publication
	,@publisher_db = @publisher_db
	,@independent_agent = N'True'
	,@subscription_type = N'pull'
	,@description = N''
	,@update_mode = N'read only'
	,@immediate_sync = 0
	
	SELECT @PrintMessage = 'Added subscription on subscriber. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT

EXEC sp_addpullsubscription_agent @publisher = @publisher
	,@publisher_db = @publisher_db
	,@publication = @publication
	,@distributor = @distributor
	,@distributor_security_mode = 1
	,@distributor_login = N''
	,@distributor_password = NULL
	,@enabled_for_syncmgr = N'False'
	,@frequency_type = 64
	,@frequency_interval = 0
	,@frequency_relative_interval = 0
	,@frequency_recurrence_factor = 0
	,@frequency_subday = 0
	,@frequency_subday_interval = 0
	,@active_start_time_of_day = 0
	,@active_end_time_of_day = 235959
	,@active_start_date = 20160928
	,@active_end_date = 99991231
	,@alt_snapshot_folder = N''
	,@working_directory = N''
	,@use_ftp = N'False'
	,@job_login = NULL
	,@job_password = NULL
	,@publication_type = 0

	SELECT @PrintMessage = 'Added subscriber job. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT

-----------------END: Script to be run at Subscriber 'subscriber-host'-----------------




