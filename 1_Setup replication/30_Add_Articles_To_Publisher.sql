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

EXEC sp_addarticle @publication = @publication
                ,@article = N'Table1'
                ,@source_owner = N'dbo'
                ,@source_object = N'Table1'
                ,@type = N'logbased'
                ,@description = NULL
                ,@creation_script = NULL
                ,@pre_creation_cmd = N'drop'
                ,@schema_option = 0x000000000803509F
                ,@identityrangemanagementoption = N'manual'
                ,@destination_table = N'Table1'
                ,@destination_owner = N'dbo'
                ,@vertical_partition = N'false'
                ,@ins_cmd = N'CALL sp_MSins_dboTable1'
                ,@del_cmd = N'CALL sp_MSdel_dboTable1'
                ,@upd_cmd = N'SCALL sp_MSupd_dboTable1';
RAISERROR('Article added for replication: Table1', 0, 1)  WITH NOWAIT

EXEC sp_addarticle @publication = @publication
                ,@article = N'Table2'
                ,@source_owner = N'dbo'
                ,@source_object = N'Table2'
                ,@type = N'logbased'
                ,@description = NULL
                ,@creation_script = NULL
                ,@pre_creation_cmd = N'drop'
                ,@schema_option = 0x000000000803509F
                ,@identityrangemanagementoption = N'manual'
                ,@destination_table = N'Table2'
                ,@destination_owner = N'dbo'
                ,@vertical_partition = N'false'
                ,@ins_cmd = N'CALL sp_MSins_dboTable2'
                ,@del_cmd = N'CALL sp_MSdel_dboTable2'
                ,@upd_cmd = N'SCALL sp_MSupd_dboTable2';
RAISERROR('Article added for replication: Table2', 0, 1)  WITH NOWAIT

EXEC sp_addarticle @publication = @publication
                ,@article = N'Table3'
                ,@source_owner = N'dbo'
                ,@source_object = N'Table3'
                ,@type = N'logbased'
                ,@description = NULL
                ,@creation_script = NULL
                ,@pre_creation_cmd = N'drop'
                ,@schema_option = 0x000000000803509F
                ,@identityrangemanagementoption = N'manual'
                ,@destination_table = N'Table3'
                ,@destination_owner = N'dbo'
                ,@vertical_partition = N'false'
                ,@ins_cmd = N'CALL sp_MSins_dboTable3'
                ,@del_cmd = N'CALL sp_MSdel_dboTable3'
                ,@upd_cmd = N'SCALL sp_MSupd_dboTable3';
RAISERROR('Article added for replication: Table3', 0, 1)  WITH NOWAIT
            