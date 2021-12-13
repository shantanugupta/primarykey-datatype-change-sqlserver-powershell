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
	

SELECT @PrintMessage = 'Check if UIProperties table exists. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
	, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
	
IF (
		NOT EXISTS (
			SELECT *
			FROM sysobjects
			WHERE NAME = 'UIProperties'
				AND type = 'U '
			)
		)
	CREATE TABLE UIProperties (id INT)


SELECT @PrintMessage = 'Added UIProperties table. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
	, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT

IF (
		EXISTS (
			SELECT *
			FROM::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', NULL, NULL)
			)
		)
	EXEC sp_updateextendedproperty N'SnapshotFolder', @SnapshotFolder, 'user', dbo, 'table', 'UIProperties'
ELSE
	EXEC sp_addextendedproperty N'SnapshotFolder', @SnapshotFolder, 'user', dbo, 'table', 'UIProperties'

SELECT @PrintMessage = 'Added snapshot folder. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
	, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT


IF NOT EXISTS (
		SELECT 1
		FROM msdb.dbo.MSdistpublishers
		WHERE NAME = @publisher
		)
BEGIN
	EXEC sp_adddistpublisher @publisher = @publisher, @distribution_db = @distributor_db
	, @security_mode = 1, @working_directory = @SnapshotFolder
	, @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'


SELECT @PrintMessage = 'Added publisher to distributor. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100))
	, @PreviousTimestamp = GETDATE()	
RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT	
END