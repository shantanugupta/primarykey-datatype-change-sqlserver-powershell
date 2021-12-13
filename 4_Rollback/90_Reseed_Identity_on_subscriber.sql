USE TestDB

DECLARE 
	 @PrintMessage 			varchar(1000)
	,@PreviousTimestamp 	datetime
	
SELECT 	
	 @PrintMessage 				= ''
	,@PreviousTimestamp 		= getdate()

SET NOCOUNT ON;

DECLARE @bcpOutFolder varchar(100)

DECLARE 
	 @bcp nvarchar(4000)
	, @ErrorMessage varchar(8000)
	, @dir	varchar(100)
	, @needAccessTo varchar(1000)
	, @query varchar(4000)

DECLARE  @bcpAccess Table([Values] varchar(1000))
declare @ReseedValues table ( tbl varchar(100), CurrentMax int, current_identity int, reseed int)

SELECT 
	@bcpOutFolder = '\\FileServer\ReplicationToAWS\Rollback_Identity\'
	, @dir = 'dir /b "' + @bcpOutFolder + '"'
	, @query = ''

insert into @bcpAccess([Values])
exec master..xp_cmdshell @dir

--check if bcp has access to folder for creating file
IF EXISTS(select * from @bcpAccess WHERE [Values] = 'Access is denied.')
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
	SELECT @query = ''
	
	SELECT @PrintMessage = 'Generating dynamic queries for getting maximum no of identities generated in last 3 month. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS 		VARCHAR(100)), @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT	
	
	select 
		@query = @query + 
			'UNION
			select '''+t.name+''' AS [table], ISNULL(max(cnt), 0) AS CurrentMax, IDENT_CURRENT('''+t.name+''') as current_identity, ISNULL(max(cnt), 1)*3 As Reseed from(
			select cast(CreateDate as date) as dt, count(*) as cnt from '+t.name+' WITH(NOLOCK)
			where cast(CreateDate as date) > dateadd(month, -3, getdate())
			group by cast(CreateDate as date)
			)t
			'
	from sys.columns c
	inner join sys.tables t on c.object_id = t.object_id
	where is_identity = 1 and t.name not like 'SS_BCP_%' and t.is_ms_shipped = 0
	and exists(select * from sys.columns x where x.object_id = t.object_id and x.name  = 'CreateDate')

	select @query = stuff(@query, 1, 7, '') + ' ORDER BY Reseed DESC'

	PRINT @query
	
	SELECT @PrintMessage = 'Executing dynamic queries on each table having identity column. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS 		VARCHAR(100)), @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT	

	insert into @ReseedValues(tbl, CurrentMax, current_identity, reseed)
	EXEC (@query)	

	IF OBJECT_ID('tempdb..##ReseedValues') IS NOT NULL
	BEGIN
		DROP TABLE ##ReseedValues
	END
	select * INTO ##ReseedValues from @ReseedValues

	SELECT * FROM ##ReseedValues

	SELECT @PrintMessage = 'Export identity values for each table in reseed_tables.csv. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS 		VARCHAR(100)), @PreviousTimestamp = GETDATE()	
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT	
	SELECT @bcp = 'bcp "##ReseedValues" out "'+@bcpOutFolder+'reseed_tables.csv" -c -C 1252, -T -S "' + @@SERVERNAME + '" -d "' + DB_NAME()+'"';
	print @bcp
	exec master..xp_cmdshell @bcp
END