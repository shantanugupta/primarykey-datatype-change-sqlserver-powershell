use TestDB

if exists(select * from sys.tables where name = 'SS_20161228_Db_Disk_Space_Stats')
begin
    truncate table dbo.SS_20161228_Db_Disk_Space_Stats
    print 'SS_20161228_Db_Disk_Space_Stats truncated'
end