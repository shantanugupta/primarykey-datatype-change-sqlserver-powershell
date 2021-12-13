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


SELECT @PrintMessage = 'Adding distributor in sysservers. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
IF NOT EXISTS (
		SELECT 1
		FROM sys.sysservers
		WHERE srvname = 'repl_distributor'
			AND datasource = @distributor
			AND dist = 1
		)
BEGIN
	EXEC sp_adddistributor @distributor = @distributor, @password = @distributor_password;

	SELECT @PrintMessage = 'Added distributor in sysservers. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT		
END


SELECT @PrintMessage = 'Adding distributor database. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
IF NOT EXISTS (
		SELECT NAME
		FROM sys.databases
		WHERE is_distributor = 1
			AND NAME = @distributor_db
		)
BEGIN
	EXEC sp_adddistributiondb @database = @distributor_db, @data_folder = @distributor_data_file
	, @log_folder = @distributor_log_file, @log_file_size = 2, @min_distretention = 0
	, @max_distretention = 240, @history_retention = 48, @security_mode = 1

	SELECT @PrintMessage = 'Added distributor database. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT	
	
	exec sp_adddistpublisher @publisher = @publisher, @distribution_db = @distributor_db, @security_mode = 1
		, @working_directory = @SnapshotFolder, @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'
	
	SELECT @PrintMessage = 'Added publisher to distributor database. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
	, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
END