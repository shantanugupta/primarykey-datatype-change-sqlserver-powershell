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

IF OBJECT_ID('tempdb..##ReseedValues') IS NOT NULL
BEGIN
	DROP TABLE ##ReseedValues
END
CREATE TABLE ##ReseedValues ( tbl varchar(100), CurrentMax int, current_identity int, reseed int)

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
	SELECT @bcp = 'bcp "##ReseedValues" in "'+@bcpOutFolder+'reseed_tables.csv" -c -C 1252, -T -S "' + @@SERVERNAME + '" -d "' + DB_NAME()+'"';
	exec master..xp_cmdshell @bcp
	
	SELECT * FROM ##ReseedValues

	IF EXISTS(SELECT * FROM ##ReseedValues)
	BEGIN
		SELECT @query = @query + 'DBCC CHECKIDENT('''+tbl+''', RESEED, '+cast(current_identity + reseed as varchar(100))+'); 'FROM ##ReseedValues
		EXEC (@query)
		SELECT @PrintMessage = 'DBCC Checkident complete. Current time: '+CONVERT(varchar(20), getdate(), 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS 		VARCHAR(100)), @PreviousTimestamp = GETDATE()	
		RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT	
	END
END
