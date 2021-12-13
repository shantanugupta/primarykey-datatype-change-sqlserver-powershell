cls;
$scriptPath = 'C:\ReplicationAWS08AWS16';
cd $scriptPath;

$startedAt = get-date;
$startedAt
$publisher = '"pub-host"';
$subscriber = '"sub-host"';
$publisher_db_server = '"pub-host"';
$subscriber_db_server = '"sub-host"';
$job_server_publisher = '"pub-host"'
$job_server_subscriber = '"sub-host"'
$publisher_db = '"TestDB"';
$publication = '"TestDBWholeDb"';
$destination_db = '"TestDB"';
$distributor = '"pub-host"';
$distributor_db = '"distribution"';
$distributor_password = '"dist_password"';
$distributor_data_file = '"D:\Data1"';
$distributor_log_file = '"D:\Log"';
$SnapshotFolder	= '"\\SnapshotFolder\ReplicaSet"';

$publisher_db_backup_path_1 = '"\\SnapshotFolder\d$\Backup01\TestDB_A.bak"';
$publisher_db_backup_path_2 = '"\\SnapshotFolder\d$\Backup01\TestDB_B.bak"';
$db_restore_db_path_1 = '"D:\Data01\TestDB.ndf"'
$db_restore_db_path_2 = '"D:\Data02\TestDB_Data2.mdf"'
$db_restore_db_path_3 = '"D:\Data03\TestDB_Data3.ndf"'
$db_restore_db_path_4 = '"D:\Data04\TestDB_Data4.ndf"'
$db_restore_db_path_5 = '"D:\Data04\TestDB_Data5.ndf"'
$db_restore_db_path_6 = '"D:\Log01\TestDB_log.ldf"'

#EXECUTE SCRIPTS TO CORRESPONDING SERVER
$list = @();
$scripts = @(
	(1, $publisher , "72_Drop_SQL_job_for_stats_collection_On_Publisher.sql", "TestDB", 1, $publisher_db_server),
	(2, $subscriber, "73_Drop_SQL_job_for_stats_collection_On_Subscriber.sql", "TestDB", 1, $subscriber_db_server),
    (3, $subscriber, "74_Cleanup_Subscriber.sql", "tempdb", 1, $subscriber_db_server),
	(4, $publisher , "75_Cleanup_Publisher.sql", "TestDB", 1, $publisher_db_server)
);

$scripts | Sort @{Expression = {$_[0]}} | %{$i=0;}{ $list+=[pscustomobject]@{
												id=$_[0];
												server=$_[1];
												file=$_[2];
												default_db = $_[3];
												append_parameters = $_[4];
											};
					$i++};

'Execution sequence'
$list | Format-Table;

if((Test-Path '.\Logs').ToString() -eq 'False'){md 'Logs'}
if((Test-Path '.\BCP').ToString() -eq 'False'){md 'BCP'}

foreach($i in $list){        
    $scriptToExecute = '.\' + $i.file;
	
	$OutputPath = '.\Logs\'+$scriptToExecute.Replace('.sql', '')+'.txt';
	$srvr = $i.server;
    Write-Host ('Executing (' + $scriptToExecute + ') executed on (' + $srvr + '). Starting at: ' + (get-date));	
	
    sqlcmd -S $srvr -E -d $i.default_db -i $scriptToExecute -o $OutputPath -v publisher = $publisher_db_server publisher_db = $publisher_db publication = $publication subscriber = $subscriber_db_server destination_db = $destination_db distributor = $distributor distributor_db = $distributor_db distributor_password = $distributor_password distributor_data_file = $distributor_data_file distributor_log_file = $distributor_log_file job_server_publisher = $job_server_publisher job_server_subscriber = $job_server_subscriber SnapshotFolder = $SnapshotFolder publisher_db_backup_path_1 = $publisher_db_backup_path_1 publisher_db_backup_path_2 = $publisher_db_backup_path_2 db_restore_db_path_1 = $db_restore_db_path_1 db_restore_db_path_2 = $db_restore_db_path_2 db_restore_db_path_3 = $db_restore_db_path_3 db_restore_db_path_4 = $db_restore_db_path_4 db_restore_db_path_5 = $db_restore_db_path_5 db_restore_db_path_6 = $db_restore_db_path_6;
	
    Write-Host ('Elapsed time(hh:MM:ss fffffff): {0:g}' -f (New-TimeSpan $startedAt (get-date)));	
	$startedAt = get-date
}

'Finished execution'
