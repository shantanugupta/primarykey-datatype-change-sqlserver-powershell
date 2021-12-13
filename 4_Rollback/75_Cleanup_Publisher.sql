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
	,@found 				int
	
SELECT 	
	 @PrintMessage 				= ''
	,@PreviousTimestamp 		= getdate()
	,@Found 					= -1
	
	
-- Drop subscription
EXEC sp_helpsubscription @publication = @publication, @article = 'all', @subscriber = @subscriber, @destination_db = @destination_db, @found = @Found OUTPUT
SELECT @PrintMessage = 'Subscription found? :'+ CONVERT(varchar(10), @Found) +', Dropping subscription if found. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
	, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT

IF @Found = 1
BEGIN	
	EXEC sp_dropsubscription @publication = @publication, @subscriber = @subscriber, 
	@destination_db = @destination_db, @article = N'all'
	
	SELECT @PrintMessage = 'Dropped subscription if found. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
	, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
END
	
-- Connect Publisher Server
IF EXISTS(select name, is_published, is_subscribed, is_merge_published, is_distributor
  from sys.databases
  where is_published = 1 or is_distributor = 1
  and name = @publisher_db)
BEGIN	
	-- Drop publication
	SELECT @PrintMessage = 'Dropping publication. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
	
	exec sp_droppublication @publication = @publication

	
	-- Disable replication db option
	SELECT @PrintMessage = 'Disable replication. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
		
	exec sp_replicationdboption @dbname = @publisher_db, @optname = N'publish', @value = N'false'
END

IF EXISTS(select name from sys.databases where is_distributor = 1 AND name = @distributor_db)
BEGIN
	-- Connect Distributor
	SELECT @PrintMessage = 'Remove published jobs. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
	
	exec Distribution.dbo.sp_MSremove_published_jobs @server = @distributor, @database = @publisher_db

	SELECT @PrintMessage = 'Drop distributor. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
		, @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
	
	exec sp_dropdistributor @no_checks = 1
END