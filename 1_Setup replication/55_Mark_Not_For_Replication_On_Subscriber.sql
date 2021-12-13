DECLARE 
	 @PrintMessage 			varchar(1000)
	,@PreviousTimestamp 	datetime
	
SELECT 	
	 @PrintMessage 				= ''
	,@PreviousTimestamp 		= getdate()

DECLARE @SchemaName SYSNAME
	,@tableName SYSNAME
	,@columnName SYSNAME
	,@query NVARCHAR(4000)

DECLARE cur CURSOR
FOR
SELECT QUOTENAME(SCHEMA_NAME(t.schema_id)) AS SchemaName
	,QUOTENAME(t.NAME) AS TableName
	,c.NAME AS ColumnName
	--,c.object_id AS ObjectID
	--,c.is_not_for_replication
	,'EXEC sys.sp_identitycolumnforreplication ' + cast(c.object_id AS VARCHAR(20)) 
		+ ', 1 ;' AS CommandTORun_SetIdendityNOTForReplication
FROM sys.identity_columns AS c
INNER JOIN sys.tables AS t ON t.[object_id] = c.[object_id]
WHERE c.is_identity = 1
	AND c.is_not_for_replication = 0
	AND t.name IN ('Table1'
					,'Table2'
					,'Table3')

OPEN cur

FETCH NEXT
FROM cur
INTO @SchemaName
	,@tableName
	,@columnName
	,@query

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT 'Setting Not_For_Replication property to 1 for (Schema.Table.Column): ' 
	+ @SchemaName + '.' + @tableName + '.' + @columnName

	EXEC (@query)
	
	FETCH NEXT
	FROM cur
	INTO @SchemaName
		,@tableName
		,@columnName
		,@query
END

CLOSE cur

DEALLOCATE cur


