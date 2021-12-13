Use TestDB

SET NOCOUNT ON;

PRINT '************************************************************************************'
PRINT 'Executes a BCP out on all tables having cdc enabled.'
PRINT '************************************************************************************'

DECLARE 
	 @PrintMessage 			varchar(1000)
	,@PreviousTimestamp 	datetime
	
SELECT 	
	 @PrintMessage 				= ''
	,@PreviousTimestamp 		= getdate()
	
DECLARE @bcpOutFolder varchar(100)

DECLARE 
	@schema_name VARCHAR(100)
	, @table_name VARCHAR(100)
	, @selectQuery NVARCHAR(4000)
	, @bcp nvarchar(4000)
	, @bcpTableName varchar(100)
	, @dropTableQuery varchar(100)
	, @ErrorMessage varchar(8000)
	, @dir	varchar(100)
	, @needAccessTo varchar(1000)
    , @LastLsnDate AS varchar(40)
	, @NextLsnDate as varchar(40)

DECLARE  @tbl Table([Values] varchar(1000))
	
SELECT 
	@bcpOutFolder = '\\FileServer\ReplicationToAWS\BCP\Batch 7\'
	, @bcpTableName =''
	, @dropTableQuery =''
	, @dir = 'dir "' + @bcpOutFolder + '"'
	
SELECT @LastLsnDate = CONVERT(varchar(40), CONVERT(datetime, SystemValueValue), 126) FROM SystemValue WHERE SystemValueName = 'LastLsnDate'
SELECT @NextLsnDate= CONVERT(varchar(40), sys.fn_cdc_map_lsn_to_time (sys.fn_cdc_get_max_lsn()), 126)

SELECT @LastLsnDate AS LastLsnDate, @NextLsnDate AS NextLsnDate
    
INSERT INTO @tbl([Values])
exec master..xp_cmdshell @dir

SELECT * FROM @tbl

IF EXISTS(select * from @tbl WHERE [Values] = 'Access is denied.')
BEGIN

	declare @user table(id int identity(1,1), col varchar(8000))
	insert into @user(col)
	EXEC xp_cmdshell 'sqlcmd -Q "select suser_sname()" -S localhost -E'
	select @needAccessTo = col from @user where id = 3

	SELECT @ErrorMessage = 'Please assign access R/W to folder '+@bcpOutFolder +' on a service account ('+@needAccessTo+')';
	SELECT @PrintMessage = @ErrorMessage + '. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS 		VARCHAR(100)), @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 16, 1) WITH NOWAIT	
END
ELSE
BEGIN
	PRINT 'Executing else'
	if OBJECT_ID('tempdb..#get_net_changes') IS NOT NULL
		DROP TABLE #get_net_changes
		
	;with cte
	as
	(
		SELECT 
			o.name
			, SUBSTRING(o.name, charindex('fn_cdc_get_net_changes_', o.name) + len('fn_cdc_get_net_changes_'), len(o.name) - len('fn_cdc_get_net_changes')) AS tbl
		FROM sys.objects o
		--inner join sys.tables t on o.object_id = t.object_id
		WHERE o.type IN ('FN', 'IF', 'TF')
		and o.schema_id = schema_id('cdc')
		and o.[name] like 'fn_cdc_get_net_changes%'
		and o.is_ms_shipped = 0
	), y 
		as(
			select [name], tbl
				, SUBSTRING(tbl, 0,  charindex('_', tbl)) as [schema_name]
				, SUBSTRING(tbl, 2+ len(SUBSTRING(tbl, 0,  charindex('_', tbl))) , LEN(tbl) - len(SUBSTRING(tbl, 0,  charindex('_', tbl)))) AS [table_name]
				, query = ' INTO [SS_BCP_'+tbl+'] FROM '+DB_NAME()+'.cdc.['+[name]+'](sys.fn_cdc_get_min_lsn(N'''+tbl+'''), sys.fn_cdc_get_max_lsn(), ''all'') ' 
				+ ' WHERE __$start_lsn >= (sys.fn_cdc_map_time_to_lsn(''smallest greater than or equal'', CONVERT(datetime, '''+ISNULL(@LastLsnDate, '1900/01/01')+''') ))'
			 from cte
		 ) , z 
			as (
				 select  [name], tbl, [schema_name], table_name, query 
				 , stuff(
					(select ', [' + column_name +']' from INFORMATION_SCHEMA.COLUMNS c where c.TABLE_NAME = y.table_name and c.TABLE_SCHEMA = y.schema_name for xml path(''))
					, 1, 2, '') AS column_list
				 from y
				)
	 SELECT 
		[schema_name]
		,table_name 
		, 'SELECT CASE __$operation WHEN 1 THEN ''D'' WHEN 2 THEN ''I'' ELSE ''U'' END AS Operation, ' + column_list+ query AS getNetChangesQuery 
		INTO #get_net_changes 
	 FROM z
	
	SELECT * FROM #get_net_changes 
	
	PRINT '************************************************************************************'
	PRINT '--Pull delta from each cdc table into csv file using cursor'
	PRINT '************************************************************************************'

	BEGIN TRY

			DECLARE cur  CURSOR
			FOR SELECT * FROM #get_net_changes ORDER BY 1, 2
			OPEN cur
			FETCH NEXT FROM cur INTO @schema_name, @table_name, @selectQuery

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @bcpTableName = 'SS_BCP_' + @schema_name +'_'+ @table_name

				IF EXISTS(SELECT * FROM sys.tables where name = @bcpTableName)
				BEGIN
					SELECT @dropTableQuery = 'DROP TABLE [' + @bcpTableName + ']'
					PRINT 'Dropping table before bcp: ' + @dropTableQuery
					EXEC (@dropTableQuery)
				END
	
				EXEC (@selectQuery)
				PRINT @selectQuery;
	
				SELECT @bcp = 'bcp "'+@bcpTableName+'" out "'+@bcpOutFolder+@table_name+'.csv" -c -C 1252, -E -T -S "' + @@SERVERNAME + '" -d "' + DB_NAME()+'"';

				print @bcp
	
				exec master..xp_cmdshell @bcp
	
				IF EXISTS(SELECT * FROM sys.tables where name = @bcpTableName)
				BEGIN
					SELECT @dropTableQuery = 'DROP TABLE [' + @bcpTableName + ']'
					PRINT 'Dropping table after bcp: ' + @dropTableQuery
					EXEC (@dropTableQuery)
				END
	
				PRINT '************************************************************************************'
			 FETCH NEXT FROM cur INTO @schema_name, @table_name, @selectQuery
			END

			CLOSE cur
			DEALLOCATE cur

			PRINT '************************************************************************************'
			PRINT '--Update new LSN value to pull delta only'
			PRINT '************************************************************************************'
			IF NOT EXISTS(SELECT * FROM SystemValue where SystemValueName = 'LastLsnDate')
			BEGIN
				INSERT INTO systemValue (SystemValueName, SystemValueValue) VALUES('LastLsnDate', @NextLsnDate)
			END
			ELSE
			BEGIN
				UPDATE s
					SET SystemValueValue = @NextLsnDate 
				FROM SystemValue s 
				WHERE SystemValueName = 'LastLsnDate'
			END
	END TRY
	BEGIN CATCH
		SELECT  
        ERROR_NUMBER() AS ErrorNumber  
        ,ERROR_SEVERITY() AS ErrorSeverity  
        ,ERROR_STATE() AS ErrorState  
        ,ERROR_PROCEDURE() AS ErrorProcedure  
        ,ERROR_LINE() AS ErrorLine  
        ,ERROR_MESSAGE() AS ErrorMessage; 

		IF CURSOR_STATUS('global','CUR')>=-1
		BEGIN
			CLOSE CUR
			DEALLOCATE CUR
		END
	END CATCH
END --End else access check for bcp folder