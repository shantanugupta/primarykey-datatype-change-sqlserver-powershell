SET NOCOUNT ON
USE TestDB

PRINT '/************************************************************************************/'
PRINT '--Moves the data from SS_BCP tables back to corresponding permanent tables. Data is moved in batches'
PRINT '/************************************************************************************/'

---For debug only purpose, set debug  = 1 to debug script i.e. print insert, delete, update query
DECLARE @debug bit = 0
DECLARE @query varchar(max) =''

DECLARE 
	 @msg 		varchar(999)
	,@PrevTime 	datetime
    ,@batchSize int
    ,@bcpOutFolder varchar(999)

SELECT 	
	 @msg 			= ''''
	,@PrevTime 		= getdate()
    ,@batchSize     = 500
    ,@bcpOutFolder  = '\\FileServer\ReplicationToAWS\BCP\Batch 1\Logs\'
    
IF OBJECT_ID('tempdb..#Merge') IS NOT NULL
BEGIN
	DROP TABLE #Merge
    SELECT @msg = '--Dropped table #Merge. Cur Time '+CONVERT(varchar(30), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
    , @PrevTime = GETDATE()
    RAISERROR(@msg, 0, 0) WITH NOWAIT      
END

;with c
as(
	select  
		y.name as Table_name
		, replace(y.name, 'SS_BCP_'+schema_name(y.schema_id)+'_', '') AS Original_table_name
		, schema_name(y.schema_id) AS SCHEMA_NAME
		, insert_list = stuff(
				(select ', [' + c.name +']' from sys.columns c 
					where c.object_id = object_id(replace(y.name, 'SS_BCP_'+schema_name(y.schema_id)+'_', ''))
					for xml path(''))
				, 1, 2, '')  
		, insert_list_with_alias = stuff(
				(select ', d.[' + c.name +']' from sys.columns c 
					where c.object_id = object_id(replace(y.name, 'SS_BCP_'+schema_name(y.schema_id)+'_', ''))
					for xml path(''))
					, 1, 2, '')  
		, update_list = stuff(
				(select ', [' + c.name +'] = d.[' + c.name +'] ' from sys.columns c
					where c.object_id = object_id(replace(y.name, 'SS_BCP_'+schema_name(y.schema_id)+'_', '')) 
					AND c.is_identity = 0 for xml path(''))
					, 1, 2, '') 
		, pk_list = stuff(
							 (SELECT
								' AND s.[' + c.NAME +'] = d.[' + c.name + ']'
							FROM
								sys.key_constraints kc 
							INNER JOIN 
								sys.index_columns ic ON kc.parent_object_id = ic.object_id  and kc.unique_index_id = ic.index_id
							INNER JOIN 
								sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
							WHERE
								kc.type = 'PK' and kc.parent_object_id = object_id(replace(y.name, 'SS_BCP_'+schema_name(y.schema_id)+'_', '')) for xml path(''))
					, 1, 4, '')
		, pk_list_null = stuff(
					(SELECT
					' AND s.[' + c.NAME +'] IS NULL'
				FROM
					sys.key_constraints kc 
				INNER JOIN 
					sys.index_columns ic ON kc.parent_object_id = ic.object_id  and kc.unique_index_id = ic.index_id
				INNER JOIN 
					sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
				WHERE
					kc.type = 'PK' and kc.parent_object_id = object_id(replace(y.name, 'SS_BCP_'+schema_name(y.schema_id)+'_', '')) for xml path(''))
		, 1, 4, '')
	from sys.tables y
	where y.is_ms_shipped = 0
	and y.name like 'SS_BCP_%'
)
select Table_name, Original_table_name
, add_new_columns_query = 
'SET NOCOUNT ON
USE '+db_name()+'

DECLARE 
	 @msg 		varchar(999)
	,@PrevTime 	datetime

SELECT 	
	 @msg 			= ''''
	,@PrevTime 		= getdate()

IF COL_LENGTH('''+TABLE_NAME+''',''IsProcessingReplication'') IS NULL
BEGIN
	ALTER TABLE '+TABLE_NAME+' ADD IsProcessingReplication bit;
    
    SELECT @msg = ''Added column IsProcessingReplication in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
    , @PrevTime = GETDATE()	
    RAISERROR(@msg, 0, 0) WITH NOWAIT   
END

IF COL_LENGTH('''+TABLE_NAME+''',''IsProcessedReplication'') IS NULL
BEGIN
	ALTER TABLE '+TABLE_NAME+' ADD IsProcessedReplication bit;
    
    SELECT @msg = ''Added column IsProcessedReplication in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
    , @PrevTime = GETDATE()
    RAISERROR(@msg, 0, 0) WITH NOWAIT
END'
    
, insert_batch_query =  
'SET NOCOUNT ON
USE '+db_name()+'

DECLARE 
	 @msg 		varchar(999)
	,@PrevTime 	datetime

SELECT 	
	 @msg 			= ''''
	,@PrevTime 		= getdate()

DECLARE @rowCount int
        , @error int;

IF OBJECT_ID(''tempdb..#clone'') IS NOT NULL
BEGIN
	DROP TABLE #clone
    SELECT @msg = ''Dropped temporary table #clone in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
    , @PrevTime = GETDATE()	
    RAISERROR(@msg, 0, 0) WITH NOWAIT
END

SELECT * INTO #clone
FROM '+TABLE_NAME+' WHERE 1=2;

SELECT @rowCount = 1;

WHILE @rowCount > 0
BEGIN
		TRUNCATE TABLE #Clone;
		
		USE tempdb
		IF (OBJECTPROPERTY(OBJECT_ID(''tempdb..#Clone''), ''TableHasIdentity'') = 1)
		BEGIN
			SET IDENTITY_INSERT #Clone ON;
            SELECT @msg = ''Enable identity insert ON for #Clone table in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
            , @PrevTime = GETDATE()
            RAISERROR(@msg, 0, 0) WITH NOWAIT        
		END

		INSERT INTO #Clone(
			'+insert_list+'
			)
		SELECT TOP ('+CAST(@batchSize AS varchar(10))+')
			'+insert_list_with_alias+'
		FROM '+db_name()+'..'+TABLE_NAME+' AS d
		WHERE d.IsProcessingReplication IS NULL AND d.Operation = ''I''

        SELECT @msg = CAST(@@ROWCOUNT AS varchar(100)) + '' rows inserted into #Clone table in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT
        
		IF (OBJECTPROPERTY(OBJECT_ID(''tempdb..#Clone''), ''TableHasIdentity'') = 1)
		BEGIN
			SET IDENTITY_INSERT #Clone OFF;
            SELECT @msg = ''Enable identity insert OFF for #Clone table in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
            , @PrevTime = GETDATE()
            RAISERROR(@msg, 0, 0) WITH NOWAIT       
		END
			
		USE '+db_name()+'
				
		UPDATE d
		SET d.IsProcessingReplication = 1
		FROM #Clone s
		INNER JOIN '+TABLE_NAME+' d 
			ON '+pk_list+'
		WHERE (d.IsProcessingReplication IS NULL)

        SELECT @rowCount = @@ROWCOUNT, @msg = CAST(@rowCount AS varchar(100)) + '' rows updated in '+TABLE_NAME+' with IsProcessingReplication = 1. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT
		
		IF (OBJECTPROPERTY(OBJECT_ID('''+Original_table_name+'''), ''TableHasIdentity'') = 1)
		BEGIN
			SET IDENTITY_INSERT '+Original_table_name+' ON;
            SELECT @msg = ''Enable identity insert ON for '+TABLE_NAME+' table. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
            , @PrevTime = GETDATE()
            RAISERROR(@msg, 0, 0) WITH NOWAIT            
		END

		INSERT INTO '+Original_table_name+'(
			'+insert_list+'
			)
		SELECT
			'+insert_list_with_alias+'
		FROM #clone d
		LEFT JOIN ['+Original_table_name+'] s ON  '+pk_list+'
		WHERE '+pk_list_null+'	
        
        SELECT @error = @@Error, @msg = CAST(@@ROWCOUNT AS varchar(100)) + '' rows inserted in '+Original_table_name+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT
        
		IF (OBJECTPROPERTY(OBJECT_ID('''+Original_table_name+'''), ''TableHasIdentity'') = 1)
		BEGIN
			SET IDENTITY_INSERT '+Original_table_name+' OFF;
            SELECT @msg = ''Enable identity insert OFF for '+Original_table_name+' table. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
            , @PrevTime = GETDATE()
            RAISERROR(@msg, 0, 0) WITH NOWAIT                 
		END
		
		UPDATE d
		SET d.IsProcessedReplication = CASE WHEN @error > 0 THEN 0 ELSE 1 END
		FROM #Clone s
		INNER JOIN '+TABLE_NAME+' d 
			ON '+pk_list+'
            
        SELECT @msg = CAST(@@ROWCOUNT AS varchar(100)) + '' rows updated in '+TABLE_NAME+' with IsProcessedReplication. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT
        
        SELECT @rowCount = CASE WHEN @error > 0 THEN 1 ELSE @rowCount END          
END'
, delete_batch_query = '
SET NOCOUNT ON
USE '+db_name()+'

DECLARE 
	 @msg 		varchar(999)
	,@PrevTime 	datetime

SELECT 	
	 @msg 			= ''''
	,@PrevTime 		= getdate()

DECLARE @rowCount int
        , @error int;

IF OBJECT_ID(''tempdb..#clone'') IS NOT NULL
BEGIN
	DROP TABLE #clone
    SELECT @msg = ''Dropped temporary table #clone in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
    , @PrevTime = GETDATE()	
    RAISERROR(@msg, 0, 0) WITH NOWAIT
END

SELECT * INTO #clone
FROM '+TABLE_NAME+' WHERE 1=2;

SELECT @rowCount = 1;

WHILE @rowCount > 0
BEGIN
		TRUNCATE TABLE #Clone;
		
		USE tempdb

		IF (OBJECTPROPERTY(OBJECT_ID(''tempdb..#Clone''), ''TableHasIdentity'') = 1)
		BEGIN
			SET IDENTITY_INSERT #Clone ON;
            SELECT @msg = ''Enable identity insert ON for #Clone table in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
            , @PrevTime = GETDATE()
            RAISERROR(@msg, 0, 0) WITH NOWAIT
		END

		INSERT INTO #Clone(
			'+insert_list+'
			)
		SELECT TOP ('+CAST(@batchSize AS varchar(10))+')
			'+insert_list_with_alias+'
		FROM '+db_name()+'..'+TABLE_NAME+' AS d
		WHERE d.IsProcessingReplication IS NULL AND d.Operation = ''D''
        
        SELECT @msg = CAST(@@ROWCOUNT AS varchar(100)) + '' rows inserted into #Clone table in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT        
        
		IF (OBJECTPROPERTY(OBJECT_ID(''tempdb..#Clone''), ''TableHasIdentity'') = 1)
		BEGIN
			SET IDENTITY_INSERT #Clone OFF;
            SELECT @msg = ''Enable identity insert OFF for #Clone table in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
            , @PrevTime = GETDATE()
            RAISERROR(@msg, 0, 0) WITH NOWAIT
		END
			
		USE '+db_name()+'
				
		UPDATE d
		SET d.IsProcessingReplication = 1
		FROM #Clone s
		INNER JOIN '+TABLE_NAME+' d 
			ON '+pk_list+'
		WHERE (d.IsProcessingReplication IS NULL)

        SELECT @rowCount = @@ROWCOUNT, @msg = CAST(@rowCount AS varchar(100)) + '' rows updated in '+TABLE_NAME+' with IsProcessingReplication = 1. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT        
		
		DELETE s
		FROM #clone d
		INNER JOIN ['+Original_table_name+'] s ON  '+pk_list+'
				
        SELECT @error = @@Error, @msg = CAST(@@ROWCOUNT AS varchar(100)) + '' rows deleted from '+Original_table_name+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT

		UPDATE d
			SET 
				d.IsProcessedReplication = CASE WHEN @error > 0 THEN 0 ELSE 1 END
		FROM #Clone s
		INNER JOIN '+TABLE_NAME+' d 
			ON '+pk_list+'

        SELECT @msg = CAST(@@ROWCOUNT AS varchar(100)) + '' rows updated in '+TABLE_NAME+' with IsProcessedReplication. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT 

        SELECT @rowCount = CASE WHEN @error > 0 THEN 1 ELSE @rowCount END          
END'
, update_batch_query = 
'SET NOCOUNT ON
USE '+db_name()+'

DECLARE 
	 @msg 		varchar(999)
	,@PrevTime 	datetime

SELECT 	
	 @msg 			= ''''
	,@PrevTime 		= getdate()

DECLARE @rowCount int
        , @error int;

IF OBJECT_ID(''tempdb..#clone'') IS NOT NULL
BEGIN
	DROP TABLE #clone
    SELECT @msg = ''Dropped temporary table #clone in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
    , @PrevTime = GETDATE()	
    RAISERROR(@msg, 0, 0) WITH NOWAIT
END

SELECT * INTO #clone
FROM '+TABLE_NAME+' WHERE 1=2;

SELECT @rowCount = 1;


WHILE @rowCount > 0
BEGIN
		TRUNCATE TABLE #Clone;
		
		USE tempdb

		IF (OBJECTPROPERTY(OBJECT_ID(''tempdb..#Clone''), ''TableHasIdentity'') = 1)
		BEGIN
			SET IDENTITY_INSERT #Clone ON;
            SELECT @msg = ''Enable identity insert ON for #Clone table in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
            , @PrevTime = GETDATE()
            RAISERROR(@msg, 0, 0) WITH NOWAIT            
		END

		INSERT INTO #Clone(
			'+insert_list+'
			)
		SELECT TOP ('+CAST(@batchSize AS varchar(10))+')
			'+insert_list_with_alias+'
		FROM '+db_name()+'..'+TABLE_NAME+' AS d
		WHERE d.IsProcessingReplication IS NULL AND d.Operation = ''U''

        SELECT @msg = CAST(@@ROWCOUNT AS varchar(100)) + '' rows inserted into #Clone table in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT        
        
		IF (OBJECTPROPERTY(OBJECT_ID(''tempdb..#Clone''), ''TableHasIdentity'') = 1)
		BEGIN
			SET IDENTITY_INSERT #Clone OFF;
            SELECT @msg = ''Enable identity insert OFF for #Clone table in '+TABLE_NAME+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
            , @PrevTime = GETDATE()
            RAISERROR(@msg, 0, 0) WITH NOWAIT            
		END
			
		USE '+db_name()+'
				
		UPDATE d
		SET d.IsProcessingReplication = 1
		FROM #Clone s
		INNER JOIN '+TABLE_NAME+' d 
			ON '+pk_list+'
		WHERE (d.IsProcessingReplication IS NULL)

        SELECT @rowCount = @@ROWCOUNT, @msg = CAST(@rowCount AS varchar(100)) + '' rows updated in '+TABLE_NAME+' with IsProcessingReplication = 1. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT
		
		UPDATE s
		SET '+update_list+'
		FROM #clone d
		INNER JOIN ['+Original_table_name+'] s ON  '+pk_list+'
		
        SELECT @error = @@Error, @msg = CAST(@@ROWCOUNT AS varchar(100)) + '' rows updated in '+Original_table_name+'. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT

        
		UPDATE d
			SET 
				d.IsProcessedReplication = CASE WHEN @error > 0 THEN 0 ELSE 1 END
		FROM #Clone s
		INNER JOIN '+TABLE_NAME+' d 
			ON '+pk_list+'
		
        SELECT @msg = CAST(@@ROWCOUNT AS varchar(100)) + '' rows updated in '+TABLE_NAME+' with IsProcessedReplication. Cur Time ''+CONVERT(varchar(30), getdate(), 121)+'', Elapsed time(ms): '' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
        , @PrevTime = GETDATE()
        RAISERROR(@msg, 0, 0) WITH NOWAIT     

        SELECT @rowCount = CASE WHEN @error > 0 THEN 1 ELSE @rowCount END          
END'
INTO #Merge
from c

SELECT @msg = '--Created dynamic queries in #Merge. Cur Time '+CONVERT(varchar(30), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
, @PrevTime = GETDATE()
RAISERROR(@msg, 0, 0) WITH NOWAIT   

IF OBJECT_ID('tempdb..#CrudSequence') IS NOT NULL
BEGIN
	DROP TABLE #CrudSequence
    SELECT @msg = '--Dropped table #CrudSequence. Cur Time '+CONVERT(varchar(30), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
    , @PrevTime = GETDATE()
    RAISERROR(@msg, 0, 0) WITH NOWAIT     
END

;WITH fk_tables AS (
		SELECT s1.NAME AS from_schema
			,o1.NAME AS from_table
			,s2.NAME AS to_schema
			,o2.NAME AS to_table
		FROM sys.foreign_keys fk
		INNER JOIN sys.objects o1 ON fk.parent_object_id = o1.object_id
		INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id
		INNER JOIN sys.objects o2 ON fk.referenced_object_id = o2.object_id
		INNER JOIN sys.schemas s2 ON o2.schema_id = s2.schema_id
		/*For the purposes of finding dependency hierarchy       
        we're not worried about self-referencing tables*/
		WHERE NOT (
				s1.NAME = s2.NAME
				AND o1.NAME = o2.NAME
				)
			AND o1.is_ms_shipped = 0 and o2.is_ms_shipped = 0
			and o1.name not like 'SS_BCP_%'
			and o2.name not like 'SS_BCP_%'
		)
	,ordered_tables AS (
		SELECT s.NAME AS schemaName
			,t.NAME AS tableName
			,0 AS LEVEL
		FROM (
			SELECT *
			FROM sys.tables
			WHERE NAME <> 'sysdiagrams'
			and is_ms_shipped = 0
			and name not like 'SS_BCP_%'
			) t
		INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
		LEFT OUTER JOIN fk_tables fk ON s.NAME = fk.from_schema
			AND t.NAME = fk.from_table
		WHERE fk.from_schema IS NULL
		
		UNION ALL
		
		SELECT fk.from_schema
			,fk.from_table
			,ot.LEVEL + 1
		FROM fk_tables fk
		INNER JOIN ordered_tables ot ON fk.to_schema = ot.schemaName
			AND fk.to_table = ot.tableName
		)

SELECT DISTINCT ot.schemaName
	,ot.tableName
	,ot.LEVEL
	
INTO #CrudSequence	
FROM ordered_tables ot
INNER JOIN (
	SELECT schemaName
		,tableName
		,MAX(LEVEL) maxLevel
	FROM ordered_tables
	GROUP BY schemaName
		,tableName
	) mx ON ot.schemaName = mx.schemaName
	AND ot.tableName = mx.tableName
	AND mx.maxLevel = ot.LEVEL;

SELECT @msg = '--Populated #CrudSequence with execution sequence for CRUD. Cur Time '+CONVERT(varchar(30), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
, @PrevTime = GETDATE()
RAISERROR(@msg, 0, 0) WITH NOWAIT    

DECLARE @debugQuery nvarchar(1000) = '
SELECT insert_batch_query, delete_batch_query, update_batch_query, add_new_columns_query
	, LEN(insert_batch_query) AS insert_batch_query_length, LEN(delete_batch_query) AS delete_batch_query_length, LEN(update_batch_query) AS update_batch_query_length, LEN(add_new_columns_query) AS add_new_columns_query
FROM #Merge ORDER BY 4 DESC, 5 DESC, 6 DESC'

IF @debug = 1
BEGIN
	EXEC (@debugQuery)
END
SELECT * FROM #CrudSequence ORDER BY [LEVEL]

--************************************************************************************
--*****************EXECUTE DYNAMIC QUERIES FOR CRUD***********************************
--************************************************************************************

--Execute insert statement
RAISERROR('/************************************************************************************/', 0, 0) WITH NOWAIT 
SELECT @msg = '--Execute insert statement. Cur Time '+CONVERT(varchar(30), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
, @PrevTime = GETDATE()
RAISERROR(@msg, 0, 0) WITH NOWAIT  
RAISERROR('/************************************************************************************/', 0, 0) WITH NOWAIT 

DECLARE 
	@Original_table_name varchar(99)
	,@Table_name varchar(99)
	,@Level int
	,@ExecuteQuery varchar(max)
    ,@add_new_columns_query varchar(max)

DECLARE cur CURSOR
FOR 
	select Original_table_name, Table_name, LEVEL , insert_batch_query, add_new_columns_query 
	from #CrudSequence c
	INNER JOIN #Merge m on c.tableName = m.Original_table_name
	ORDER BY c.Level

OPEN cur
FETCH NEXT FROM cur INTO @Original_table_name, @Table_name, @Level, @ExecuteQuery, @add_new_columns_query

	WHILE @@FETCH_STATUS = 0
	BEGIN		
		PRINT '--'+ CAST(@Level AS varchar(100)) + ' - '+@Original_table_name
		PRINT '/************************************************************************************/'
        IF @debug = 1
        BEGIN
            PRINT @add_new_columns_query
            PRINT @ExecuteQuery
        END        
		IF @debug = 0
		BEGIN
            EXEC (@add_new_columns_query)
			EXEC (@ExecuteQuery)
		END
		
	 FETCH NEXT FROM cur INTO @Original_table_name, @Table_name, @Level, @ExecuteQuery, @add_new_columns_query
	END

CLOSE cur
DEALLOCATE cur
 

--Execute delete statement
RAISERROR('/************************************************************************************/', 0, 0) WITH NOWAIT 
SELECT @msg = '--Execute delete statement. Cur Time '+CONVERT(varchar(30), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
, @PrevTime = GETDATE()
RAISERROR(@msg, 0, 0) WITH NOWAIT  
RAISERROR('/************************************************************************************/', 0, 0) WITH NOWAIT 

DECLARE cur CURSOR
FOR 
	select Original_table_name, Table_name, LEVEL , delete_batch_query, add_new_columns_query 
	from #CrudSequence c
	INNER JOIN #Merge m on c.tableName = m.Original_table_name
	ORDER BY c.Level DESC

OPEN cur
FETCH NEXT FROM cur INTO @Original_table_name, @Table_name, @Level, @ExecuteQuery, @add_new_columns_query

	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT '--' + CAST(@Level AS varchar(100)) + ' - '+@Original_table_name
		PRINT '/************************************************************************************/'
        IF @debug = 1
        BEGIN
            PRINT @add_new_columns_query
            PRINT @ExecuteQuery
        END   
		IF @debug = 0
		BEGIN
            EXEC (@add_new_columns_query)
			EXEC (@ExecuteQuery)
		END
		
	 FETCH NEXT FROM cur INTO @Original_table_name, @Table_name, @Level, @ExecuteQuery, @add_new_columns_query
	END

CLOSE cur
DEALLOCATE cur

--Execute update statement
RAISERROR('/************************************************************************************/', 0, 0) WITH NOWAIT 
SELECT @msg = '--Execute update statement. Cur Time '+CONVERT(varchar(30), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
, @PrevTime = GETDATE()
RAISERROR(@msg, 0, 0) WITH NOWAIT
RAISERROR('/************************************************************************************/', 0, 0) WITH NOWAIT 

DECLARE cur CURSOR
FOR 
	select Original_table_name, Table_name, LEVEL , update_batch_query, add_new_columns_query  
	from #CrudSequence c
	INNER JOIN #Merge m on c.tableName = m.Original_table_name
	ORDER BY c.Level

OPEN cur
FETCH NEXT FROM cur INTO @Original_table_name, @Table_name, @Level, @ExecuteQuery, @add_new_columns_query

	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT '--' + CAST(@Level AS varchar(100)) + ' - '+@Original_table_name
		PRINT '/************************************************************************************/'
        IF @debug = 1
        BEGIN
            PRINT @add_new_columns_query
            PRINT @ExecuteQuery
        END   
		IF @debug = 0
		BEGIN
            EXEC (@add_new_columns_query)
			EXEC (@ExecuteQuery)
		END
	 FETCH NEXT FROM cur INTO @Original_table_name, @Table_name, @Level, @ExecuteQuery, @add_new_columns_query
	END

CLOSE cur
DEALLOCATE cur

------------------------------------------------------------------------------------------------------------
---------------------------------------------BCP processed files--------------------------------------------
------------------------------------------------------------------------------------------------------------
RAISERROR('/************************************************************************************/', 0, 0) WITH NOWAIT 
SELECT @msg = '--Execute bcp to generate logs. Cur Time '+CONVERT(varchar(30), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(ms, @PrevTime, GETDATE()) AS VARCHAR(100))
, @PrevTime = GETDATE()
RAISERROR(@msg, 0, 0) WITH NOWAIT
RAISERROR('/************************************************************************************/', 0, 0) WITH NOWAIT 
DECLARE @bcpQuery varchar(1000), @dropQuery varchar(1000)
DECLARE cur CURSOR
FOR 
	SELECT
        'bcp "SELECT * FROM '+name+' WHERE ISNULL(IsProcessedReplication, 0) = 0" QUERYOUT "'+@bcpOutFolder+name+'_log.csv" -c -C 1252, -E -T -S "' + @@SERVERNAME + '" -d "' + DB_NAME()+'"' AS Query,
        'IF EXISTS(SELECT * FROM sys.tables where name = '''+name+''')
        BEGIN
            DROP TABLE '+ name + '
            RAISERROR(''Dropped table ' +name + ''', 0, 0) WITH NOWAIT
        END' AS dropQuery        
    from sys.tables y
    where y.is_ms_shipped = 0
    and y.name like 'SS_BCP_%'
OPEN cur
FETCH NEXT FROM cur INTO @bcpQuery, @dropQuery

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @debug = 1
		BEGIN
            PRINT @bcpQuery
            PRINT @dropQuery
        END
		IF @debug = 0
		BEGIN
            exec master..xp_cmdshell @bcpQuery
            EXEC (@dropQuery)
		END
	 FETCH NEXT FROM cur INTO @bcpQuery, @dropQuery
	END
CLOSE cur
DEALLOCATE cur