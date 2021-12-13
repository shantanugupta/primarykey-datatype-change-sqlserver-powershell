SET QUOTED_IDENTIFIER ON --Must be set to ON for filtered indexes
	
DECLARE 
	  @PrintMessage varchar(2000)
	, @PreviousTimestamp datetime

SELECT 	
	 @PrintMessage 				= ''
	,@PreviousTimestamp 		= getdate()

-----------------------------------------------------------------------------
-----------------------------Add SId column (M-1950)----------------------
-----------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Table1' AND COLUMN_NAME = 'SId')
BEGIN
	SELECT @PrintMessage  =  'Adding column SId to Table1'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE Table1
	ADD SId INT NULL
END

-----------------------------------------------------------------------------
-----------------------------Truncate logs of AuditLog table-----------------
-----------------------------------------------------------------------------

IF (SELECT COUNT(1) FROM UserArrAuditLog) > 1
BEGIN
    SELECT @PrintMessage  =  'Adding column SId to Table1'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
    TRUNCATE TABLE UserArrAuditLog
END
    
-----------------------------------------------------------------------------
-----------------------------DROP DEPENDENCIES-------------------------------
-----------------------------------------------------------------------------

--Dropping dependencies from UserArr
IF OBJECT_ID('fkUserArr_ArrID_AppUser') IS NOT NULL
BEGIN
	SELECT @PrintMessage  = 'Dropping constraint fkUserArr_ArrID_AppUser.'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;	
	
	ALTER TABLE UserArr DROP CONSTRAINT fkUserArr_ArrID_AppUser
END	
		
IF OBJECT_ID('fkUserArr_ArgeId_AppUser') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint fkUserArr_ArgeId_AppUser'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE UserArr DROP CONSTRAINT fkUserArr_ArgeId_AppUser
END	

IF OBJECT_ID('pkUserArr') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint pkUserArr'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE UserArr DROP CONSTRAINT pkUserArr
END


--Dropping dependencies from Table1
IF OBJECT_ID('fkTable1_AppUser') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint fkTable1_AppUser'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE Table1 DROP CONSTRAINT fkTable1_AppUser
END

IF EXISTS(SELECT * FROM sys.indexes where name = 'ixcTable1_AppUserID')
BEGIN
	SELECT @PrintMessage  =  'Dropping index ixcTable1_AppUserID'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	DROP INDEX ixcTable1_AppUserID On Table1
END

IF EXISTS(SELECT * FROM sys.indexes where name = 'ixuf_Table1_AppUserID_PId')
BEGIN
	SELECT @PrintMessage  =  'Dropping index ixuf_Table1_AppUserID_PId'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	DROP INDEX ixuf_Table1_AppUserID_PId On Table1
END



--Dropping dependencies from UserArrInvite
IF OBJECT_ID('fkUserArrInvite_AppUser') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint fkUserArrInvite_AppUser'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE UserArrInvite DROP CONSTRAINT fkUserArrInvite_AppUser
END


--Dropping dependencies from AppUserTmp
IF OBJECT_ID('fkAppUserTmp_AppUser') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint fkAppUserTmp_AppUser'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE AppUserTmp DROP CONSTRAINT fkAppUserTmp_AppUser
END

IF OBJECT_ID('pkAppUserTmp') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint pkAppUserTmp'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE AppUserTmp DROP CONSTRAINT pkAppUserTmp
END

--Dropping dependencies from TArp
IF OBJECT_ID('fkTArp_AppUser') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint fkTArp_AppUser'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE TArp DROP CONSTRAINT fkTArp_AppUser
END


--Dropping dependencies from TpUsr
IF OBJECT_ID('fkTpUsr_AppUser') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint fkTpUsr_AppUser'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE TpUsr DROP CONSTRAINT fkTpUsr_AppUser
END	

IF OBJECT_ID('fkTpUsr_ArId') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint fkTpUsr_ArId'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE TpUsr DROP CONSTRAINT fkTpUsr_ArId
END

IF EXISTS(SELECT * FROM sys.indexes where name = 'ixTpUsr_AppUserID_TptId_SId')
BEGIN
	SELECT @PrintMessage  =  'Dropping index ixTpUsr_AppUserID_TptId_SId'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	DROP INDEX ixTpUsr_AppUserID_TptId_SId On TpUsr
END

IF EXISTS(SELECT * FROM sys.indexes where name = 'ixTpUsr_TpUsrID_TptId_ArId_SId')
BEGIN
	SELECT @PrintMessage  =  'Dropping index ixTpUsr_TpUsrID_TptId_ArId_SId'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	DROP INDEX ixTpUsr_TpUsrID_TptId_ArId_SId On TpUsr
END


--Dropping dependencies from AppUser
IF OBJECT_ID('fkAppUser_Arm') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint fkAppUser_Arm'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE AppUser DROP CONSTRAINT fkAppUser_Arm
END

IF OBJECT_ID('dfAppUser_ArId') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint dfAppUser_ArId'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE AppUser DROP CONSTRAINT dfAppUser_ArId
END

IF EXISTS(SELECT * FROM sys.indexes where name = 'uixfiAppUser_PsoKey_ArId')
BEGIN
	SELECT @PrintMessage  =  'Dropping index uixfiAppUser_PsoKey_ArId'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	DROP INDEX uixfiAppUser_PsoKey_ArId On AppUser
END

IF EXISTS(SELECT * FROM sys.indexes where name = 'uixfiAppUser_Email_ArId_PsoKey')
BEGIN
	SELECT @PrintMessage  =  'Dropping index uixfiAppUser_Email_ArId_PsoKey'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	DROP INDEX uixfiAppUser_Email_ArId_PsoKey On AppUser
END

IF EXISTS(SELECT * FROM sys.indexes where name = 'ixfiAppUser_PsoKey_ArId')
BEGIN
	SELECT @PrintMessage  =  'Dropping index ixfiAppUser_PsoKey_ArId'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	DROP INDEX ixfiAppUser_PsoKey_ArId On AppUser
END

IF EXISTS(SELECT * FROM sys.indexes where name = 'ixAppUser_Email_ArId_PsoKey')
BEGIN
	SELECT @PrintMessage  =  'Dropping index ixAppUser_Email_ArId_PsoKey'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	DROP INDEX ixAppUser_Email_ArId_PsoKey On AppUser
END

IF OBJECT_ID('pkAppUser') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint pkAppUser'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE AppUser DROP CONSTRAINT pkAppUser
END


--Dropping dependencies from Arm
IF OBJECT_ID('pkArm') IS NOT NULL
BEGIN
	SELECT @PrintMessage  =  'Dropping constraint pkArm'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE Arm DROP CONSTRAINT pkArm
END

-----------------------------------------------------------------------------
-----------------------------CHANGE DATA TYPES-------------------------------
-----------------------------------------------------------------------------
--Change data type in Arm Table
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Arm' AND COLUMN_NAME = 'ArId' AND DATA_TYPE = 'tinyint')
BEGIN
	SELECT @PrintMessage  =  'Changing data type of ArId in Arm'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE Arm
	ALTER COLUMN ArId INT NOT NULL
END

--Change data type in UserArr Table
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserArr' AND COLUMN_NAME = 'TarrAppUserID' AND DATA_TYPE = 'int')
BEGIN
	SELECT @PrintMessage  =  'Changing data type of TarrAppUserID in UserArr'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE UserArr
	ALTER COLUMN TarrAppUserID BIGINT NOT NULL
END	

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserArr' AND COLUMN_NAME = 'UserArrAppUserID' AND DATA_TYPE = 'int')
BEGIN
	SELECT @PrintMessage  =  'Changing data type of UserArrAppUserID in UserArr'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE UserArr
	ALTER COLUMN UserArrAppUserID BIGINT NOT NULL
END	

--Change data type in Table1 Table
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Table1' AND COLUMN_NAME = 'AppUserID' AND DATA_TYPE = 'int')
BEGIN
	SELECT @PrintMessage  =  'Changing data type of AppUserId in Table1'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE Table1
	ALTER COLUMN AppUserID BIGINT NOT NULL
END	

--Change data type in UserArrInvite Table
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserArrInvite' AND COLUMN_NAME = 'AppUserID' AND DATA_TYPE = 'int')
BEGIN
	SELECT @PrintMessage  =  'Changing data type of AppUserId in UserArrInvite'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE UserArrInvite
	ALTER COLUMN AppUserID BIGINT NOT NULL
END	

--Change data type in AppUserTmp Table
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AppUserTmp' AND COLUMN_NAME = 'AppUserID' AND DATA_TYPE = 'int')
BEGIN
	SELECT @PrintMessage  =  'Changing data type of AppUserID in AppUserTmp'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE AppUserTmp
	ALTER COLUMN AppUserID BIGINT NOT NULL
END	

--Change data type in TArp Table
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TArp' AND COLUMN_NAME = 'AppUserID' AND DATA_TYPE = 'int')
BEGIN
	SELECT @PrintMessage  =  'Changing data type of AppUserID in TArp'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE TArp
	ALTER COLUMN AppUserID BIGINT 
END	

--Change data type in TpUsr Table
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TpUsr' AND COLUMN_NAME = 'ArId' AND DATA_TYPE = 'tinyint')
BEGIN
	
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE TpUsr
	ALTER COLUMN ArId INT NOT NULL
END

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TpUsr' AND COLUMN_NAME = 'AppUserID' AND DATA_TYPE = 'int')
BEGIN
	
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT
	
	ALTER TABLE TpUsr
	ALTER COLUMN AppUserID BIGINT NOT NULL
END

--Change data type in AppUser Table
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AppUser' AND COLUMN_NAME = 'AppUserId' AND DATA_TYPE = 'int')
BEGIN
	SELECT @PrintMessage  =  'Changing data type of AppUserId in AppUser'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE AppUser
	ALTER COLUMN AppUserId BIGINT NOT NULL
END

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AppUser' AND COLUMN_NAME = 'ArId' AND DATA_TYPE = 'tinyint')
BEGIN
	SELECT @PrintMessage  =  'Changing data type of ArId in AppUser'
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	ALTER TABLE AppUser
	ALTER COLUMN ArId INT NOT NULL
END


-----------------------------------------------------------------------------
-----------------------------CREATE DEPDENDENCIES----------------------------
-----------------------------------------------------------------------------

--Create constraints for Arm
if object_id('dbo.pkArm') is null begin;
    SELECT @PrintMessage  =  'Creating primary key constraint pkArm.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.Arm
       add constraint pkArm 
           primary key clustered (ArId);
end;

--Create constraints for AppUser
if object_id('dbo.pkAppUser') is null begin;
    SELECT @PrintMessage  =  'Creating primary key constraint dbo.pkAppUser.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.AppUser
       add constraint pkAppUser 
           primary key clustered (AppUserID);
end;

if (indexproperty(object_id('dbo.AppUser'),'ixAppUser_Email_ArId_PsoKey', 'IsClustered') is null) begin;
    SELECT @PrintMessage  =  'Creating index AppUser.ixAppUser_Email_ArId_PsoKey';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    create nonclustered index ixAppUser_Email_ArId_PsoKey
        on dbo.AppUser (
           Email ASC,
           ArId ASC,
           PsoKey ASC            
           )
         with (online = off, maxdop=4);
end;

if (indexproperty(object_id('dbo.AppUser'),'ixfiAppUser_PsoKey_ArId', 'IsClustered') is null) begin;
    SELECT @PrintMessage  =  'Creating index AppUser.ixfiAppUser_PsoKey_ArId';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    create nonclustered index ixfiAppUser_PsoKey_ArId
        on dbo.AppUser (
           PsoKey ASC,  
           ArId ASC                     
           )
    where PsoKey is not null
    with (online = off, maxdop=4);
end;

if (indexproperty(object_id('dbo.AppUser'),'uixfiAppUser_Email_ArId_PsoKey', 'IsClustered') is null) begin;
    SELECT @PrintMessage  =  'Creating index AppUser.uixfiAppUser_Email_ArId_PsoKey';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
		
    create unique nonclustered index uixfiAppUser_Email_ArId_PsoKey
        on dbo.AppUser (
           Email ASC,
           ArId ASC,
           PsoKey ASC            
           )
        where AppUserStatusID = 1
        with (online = off, maxdop=4);
end;

if (indexproperty(object_id('dbo.AppUser'),'uixfiAppUser_PsoKey_ArId', 'IsClustered') is null) begin;
    SELECT @PrintMessage  =  'Creating index AppUser.uixfiAppUser_PsoKey_ArId';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    create unique nonclustered index uixfiAppUser_PsoKey_ArId
        on dbo.AppUser (
           PsoKey ASC,  
           ArId ASC                     
           )
    where PsoKey is not null and AppUserStatusID = 1
    with (online = off, maxdop=4);
end;

if object_id('dbo.dfAppUser_ArId') is null begin;
    SELECT @PrintMessage  =  'Creating default constraint dbo.dfAppUser_ArId.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.AppUser
        add constraint dfAppUser_ArId
            default (1) for ArId;
end;

if object_id('dbo.fkAppUser_Arm') is null begin;
    SELECT @PrintMessage  =  'Creating foreign key constraint fkAppUser_Arm.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.AppUser
       add constraint fkAppUser_Arm 
           foreign key (ArId)
           references dbo.Arm (ArId)
           not for replication;
end;

--Create constraints for TpUsr
if (indexproperty(object_id('dbo.TpUsr'),'ixTpUsr_TpUsrID_TptId_ArId_SId', 'IsClustered') is null) begin;
    SELECT @PrintMessage  =  'Creating index TpUsr.ixTpUsr_TpUsrID_TptId_ArId_SId';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    create unique nonclustered index ixTpUsr_TpUsrID_TptId_ArId_SId
        on dbo.TpUsr (
           TpUsrID asc,
           TptId asc,
           ArId asc,
           SId asc
           )
        with (online = off, maxdop=4);
end;

if (indexproperty(object_id('dbo.TpUsr'),'ixTpUsr_AppUserID_TptId_SId', 'IsClustered') is null) begin;
    SELECT @PrintMessage  =  'Creating index TpUsr.ixTpUsr_AppUserID_TptId_SId';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    create unique nonclustered index ixTpUsr_AppUserID_TptId_SId
        on dbo.TpUsr (
           AppUserID asc,
           TptId asc,
           SId asc
           )
        with (online = off, maxdop=4);
end;

if object_id('dbo.fkTpUsr_ArId') is null begin;
    SELECT @PrintMessage  =  'Creating foreign key constraint fkTpUsr_ArId.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.TpUsr
       add constraint fkTpUsr_ArId 
           foreign key (ArId)
           references dbo.Arm (ArId)
           not for replication;
end;

if object_id('dbo.fkTpUsr_AppUser') is null begin;
    SELECT @PrintMessage  =  'Creating foreign key constraint fkTpUsr_AppUser.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.TpUsr
       add constraint fkTpUsr_AppUser 
           foreign key (AppUserID)
           references dbo.AppUser (AppUserID)
           not for replication;
end;

--Create constraints for TArp

--Create constraints for AppUserTmp
if object_id('dbo.pkAppUserTmp') is null begin;
	SELECT @PrintMessage  =  'Creating primary key constraint dbo.pkAppUserTmp.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.AppUserTmp
       add constraint pkAppUserTmp 
           primary key clustered (AppUserID,TmpTypeID);
end;

if object_id('dbo.fkAppUserTmp_AppUser') is null begin;
    SELECT @PrintMessage  =  'Creating foreign key constraint fkAppUserTmp_AppUser.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.AppUserTmp
       add constraint fkAppUserTmp_AppUser 
           foreign key (AppUserID)
           references dbo.AppUser (AppUserID)
           not for replication;
end;

--Create constraints for UserArrInvite
if object_id('dbo.fkUserArrInvite_AppUser') is null begin;
    SELECT @PrintMessage  =  'Creating foreign key constraint fkUserArrInvite_AppUser.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.UserArrInvite
       add constraint fkUserArrInvite_AppUser
           foreign key (AppUserID)
           references dbo.AppUser (AppUserID)
           not for replication;
end;

--Create constraints for Table1
if (indexproperty(object_id('dbo.Table1'),'ixcTable1_AppUserID', 'IsClustered') is null) begin;
    SELECT @PrintMessage  =  'Creating index Table1.ixcTable1_AppUserID';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    create clustered index ixcTable1_AppUserID
        on dbo.Table1 (
           AppUserID ASC
           );
end;


if (indexproperty(object_id('dbo.Table1'),'ixuf_Table1_AppUserID_PId', 'IsClustered') is null) begin;
    SELECT @PrintMessage  =  'Creating index Table1.ixuf_Table1_AppUserID_PId';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
	CREATE UNIQUE NONCLUSTERED INDEX [ixuf_Table1_AppUserID_PId] ON [dbo].[Table1]
	(
		[AppUserID] ASC,
		[PId] ASC
	)
	WHERE ([ISRegisteredUser]=(1));
end;


if object_id('dbo.fkTable1_AppUser') is null begin;
    SELECT @PrintMessage  =  'Creating foreign key constraint fkTable1_AppUser.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.Table1
       add constraint fkTable1_AppUser 
           foreign key (AppUserID)
           references dbo.AppUser (AppUserID)
           not for replication;
end;

--Create constraints for UserArr
if object_id('dbo.pkUserArr') is null begin;
    SELECT @PrintMessage  =  'Creating primary key constraint dbo.pkUserArr.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.UserArr
       add constraint pkUserArr 
           primary key clustered (UserArrAppUserID, TarrAppUserID);
end;

if object_id('dbo.fkUserArr_ArrID_AppUser') is null begin;
    SELECT @PrintMessage  =  'Creating foreign key constraint fkUserArr_ArrID_AppUser.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.UserArr
       add constraint fkUserArr_ArrID_AppUser
           foreign key (UserArrAppUserID)
           references dbo.AppUser (AppUserID)
           not for replication;
end;

if object_id('dbo.fkUserArr_ArgeId_AppUser') is null begin;
    SELECT @PrintMessage  =  'Creating foreign key constraint fkUserArr_ArgeId_AppUser.';
	SELECT @PrintMessage  = @PrintMessage +'. Current time: '+CONVERT(varchar(30), current_timestamp, 121)+', Elapsed time(ms): ' + CAST(DATEDIFF(millisecond, @PreviousTimestamp, GETDATE()) AS VARCHAR(100)), @PreviousTimestamp = GETDATE()
	RAISERROR(@PrintMessage, 0, 0) WITH NOWAIT;
	
    alter table dbo.UserArr
       add constraint fkUserArr_ArgeId_AppUser
           foreign key (TarrAppUserID)
           references dbo.AppUser (AppUserID)
           not for replication;
end;