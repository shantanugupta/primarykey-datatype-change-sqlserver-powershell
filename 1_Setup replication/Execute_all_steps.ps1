cls;
$scriptPath = 'C:\Replication AWS08 to AWS16';
cd $scriptPath;

'****************JOBS NOT IMPORTED YET****************';

$startedAt = get-date;
$startedAt
$publisher = '"EC2AMAZ-JIJNK27"';
$subscriber = '"EC2AMAZ-QKGAFIV"';
$publisher_db_server = '"EC2AMAZ-JIJNK27"';
$subscriber_db_server = '"EC2AMAZ-QKGAFIV"';
$job_server_publisher = '"EC2AMAZ-JIJNK27"'
$job_server_subscriber = '"EC2AMAZ-QKGAFIV"'
$publisher_db = '"ExpUserProfile"';
$publication = '"ExpUserProfileWholeDb"';
$destination_db = '"ExpUserProfile"';
$distributor = '"EC2AMAZ-JIJNK27"';
$distributor_db = '"distribution"';#ExpDistribution
$distributor_password = '"YO1iftBkQSUf0x7wsdAqzisg"';
$distributor_data_file = '"C:\Program Files\Microsoft SQL Server\MSSQL10_50.AWSSQL08\MSSQL\DATA"';
$distributor_log_file = '"C:\Program Files\Microsoft SQL Server\MSSQL10_50.AWSSQL08\MSSQL\LOG"';
$SnapshotFolder	= '"\\EC2AMAZ-JIJNK27\Users\shangupta\Documents\AWS\ReplicaSet"';

$publisher_db_backup_path_1 = '"\\EC2AMAZ-JIJNK27\Users\shangupta\Documents\AWS\Backup\ExpUserProfile_A.bak"';
$publisher_db_backup_path_2 = '"\\EC2AMAZ-JIJNK27\Users\shangupta\Documents\AWS\Backup\ExpUserProfile_B.bak"';
$db_restore_db_path_1 = '"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\ExpUserProfile.ndf"'
$db_restore_db_path_2 = '"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\ExpUserProfile_Data2.mdf"'
$db_restore_db_path_3 = '"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\ExpUserProfile_Data3.ndf"'
$db_restore_db_path_4 = '"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\ExpUserProfile_Data4.ndf"'
$db_restore_db_path_5 = '"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\ExpUserProfile_Data5.ndf"'
$db_restore_db_path_6 = '"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\LOG\ExpUserProfile_log.ldf"'


#EXECUTE SCRIPTS TO CORRESPONDING SERVER
$list = @();
$scripts = @(
	(1 , $publisher , "01_SQL_job_for_stats_collection_On_Publisher.sql", "msdb", 1, $publisher_db_server),
	(42, $subscriber, "02_SQL_job_for_stats_collection_On_Subscriber.sql", "msdb", 1, $subscriber_db_server),
    (5 , $subscriber, "05_Cleanup_Subscriber.sql", "tempdb", 1, $subscriber_db_server),
	(10, $publisher , "10_Cleanup_Publisher.sql", "ExpUserProfile", 1, $publisher_db_server),
	(15, $publisher , "15_ConfigureDistribution.sql", "master", 1, $publisher_db_server),
	(20, $publisher , "20_Configure_Distributor_Properties.sql", "distribution", 1, $publisher_db_server),
	(25, $publisher , "25_CreatePublication.sql", "ExpUserProfile", 1, $publisher_db_server),
	(30, $publisher , "30_Add_Articles_To_Publisher.sql", "ExpUserProfile", 1, $publisher_db_server),
	(35, $publisher , "35_Publisher_Backup.sql", "master", 1, $publisher_db_server),
	(40, $subscriber, "40_Restore_published_database_to_subscriber.sql", "master", 1, $subscriber_db_server),
	(45, $publisher , "45_Add_subscriber_to_publisher.sql", "ExpUserProfile", 1, $publisher_db_server)
	#(50, $subscriber, "50_NewSubscription.sql", "ExpUserProfile", 1, $subscriber_db_server),
	#(55, $subscriber, "55_Mark_Not_For_Replication_On_Subscriber.sql", "ExpUserProfile", 0, $subscriber_db_server),
	#(60, $subscriber, "60_Change_datatype_on_subscriber_ExpUser.sql", "ExpUserProfile", 0, $subscriber_db_server),
    #(65, $publisher , "65_Reseed_Identity_on_publisher_ExpUser.sql", "ExpUserProfile", 0, $publisher_db_server),
	#(66, $subscriber, "66_Reseed_Identity_on_subscriber_ExpUser.sql", "ExpUserProfile", 0, $subscriber_db_server),
	#(70, $subscriber, "70_Enable_cdc_on_subscriber.sql", "ExpUserProfile", 0, $subscriber_db_server)
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
