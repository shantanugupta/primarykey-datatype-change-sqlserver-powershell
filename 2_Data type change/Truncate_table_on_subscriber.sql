use TestDB

if exists(select * from sys.tables where name = 'SS_20161228_Db_Disk_Space_Stats_subscriber')
begin
    truncate table dbo.SS_20161228_Db_Disk_Space_Stats_subscriber
    print 'SS_20161228_Db_Disk_Space_Stats_subscriber truncated'
end