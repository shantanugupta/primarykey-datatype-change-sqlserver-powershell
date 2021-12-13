USE TestDB

SET NOCOUNT ON;

PRINT '************************************************************************************'
PRINT 'Executes a BCP IN for all tables having replication enabled. Data from csv is moved to permanent tables starting with SS_BCP_'
PRINT '************************************************************************************'

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

DECLARE  @tbl Table([Values] varchar(1000))
	
SELECT 
	@bcpOutFolder = '\\FileServer\ReplicationToAWS\BCP\Batch 3\'
	, @bcpTableName =''
	, @dropTableQuery =''
	, @dir = 'dir /b "' + @bcpOutFolder + '"'

INSERT INTO @tbl([Values])
exec master..xp_cmdshell @dir --no output to be checked
SELECT * FROM  @tbl

PRINT '****************DROP ALL TABLES HAVING PREFIX "SS_BCP_" ****************************************'
DECLARE cur  CURSOR
FOR 
	select 
	SCHEMA_NAME(t.[schema_id]) AS Table_Schema, t.[name] AS table_name,
	Query = 
	'IF EXISTS(SELECT * FROM sys.tables where name = ''SS_BCP_' + SCHEMA_NAME(schema_id) +'_'+ t.name + ''') '
	+ ' BEGIN'
	+ 	' DROP TABLE SS_BCP_' + SCHEMA_NAME(schema_id) +'_'+ t.name
	+ ' END ' 
	FROM  sys.tables t 
	where  is_ms_shipped = 0  and schema_id = schema_id('dbo')	
OPEN cur
FETCH NEXT FROM cur INTO @schema_name, @table_name, @selectQuery

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--SELECT @schema_name AS [schema_name], @table_name as table_name, @selectQuery as Query
	
		SELECT @bcpTableName = 'SS_BCP_' + @schema_name +'_'+ @table_name

		PRINT 'Dropping and creating table before bcp: ' + @selectQuery
		EXEC (@selectQuery)
	
		PRINT '************************************************************************************'
	 FETCH NEXT FROM cur INTO @schema_name, @table_name, @selectQuery
	END
	
	CLOSE cur
	DEALLOCATE cur


PRINT '************DROP & RECREATE TABLES WITH SS_BCP_ prefix and populate data**********************'
DECLARE cur  CURSOR
FOR 
	select 
	SCHEMA_NAME(t.[schema_id]) AS Table_Schema, t.[name] AS table_name,
	Query = 
	'IF EXISTS(SELECT * FROM sys.tables where name = ''SS_BCP_' + SCHEMA_NAME(schema_id) +'_'+ t.name + ''') '
	+ ' BEGIN'
	+ 	' DROP TABLE SS_BCP_' + SCHEMA_NAME(schema_id) +'_'+ t.name
	+ ' END ' 
	+ ' SELECT CAST(NULL AS char(1)) AS Operation, * INTO SS_BCP_' + SCHEMA_NAME(schema_id) +'_'+ t.name + ' FROM [' + t.name +'] t WHERE 1=2'
	FROM  sys.tables t 
	where  is_ms_shipped = 0  and schema_id = schema_id('dbo') 
		--and is_published = 1
	AND EXISTS(SELECT * FROM @tbl WHERE [Values] = t.name+'.csv')
OPEN cur
FETCH NEXT FROM cur INTO @schema_name, @table_name, @selectQuery

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--SELECT @schema_name AS [schema_name], @table_name as table_name, @selectQuery as Query
	
		SELECT @bcpTableName = 'SS_BCP_' + @schema_name +'_'+ @table_name

		PRINT 'Dropping and creating table before bcp: ' + @selectQuery
		EXEC (@selectQuery)
	
		SELECT @bcp = 'bcp "'+@bcpTableName+'" in "'+@bcpOutFolder+@table_name+'.csv" -c -C 1252, -E -T -S "' + @@SERVERNAME + '" -d "' + DB_NAME()+'"';

		print @bcp
	
		exec master..xp_cmdshell @bcp
	
		PRINT '************************************************************************************'
	 FETCH NEXT FROM cur INTO @schema_name, @table_name, @selectQuery
	END

	CLOSE cur
	DEALLOCATE cur