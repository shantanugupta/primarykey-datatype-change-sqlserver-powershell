cls;

$scriptPath = '.';
cd $scriptPath;

$schemaOption = '0x000000000803509F';


$sqlVariables = gc '.\Replication variables.sql'  | Out-String;

#GENERATE ARTICLES FILE USING LIST OF TABLE PASSED

if((Test-Path '.\30_Add_Articles_To_Publisher.sql').ToString() -eq 'True'){del '..\30_Add_Articles_To_Publisher.sql'}

Import-Csv '.\tables_to_replicate.csv' | foreach-object{
    $article ="EXEC sp_addarticle @publication = @publication
	            ,@article = N'"+$_.table+"'
	            ,@source_owner = N'"+$_.schema+"'
	            ,@source_object = N'"+$_.table+"'
	            ,@type = N'logbased'
	            ,@description = NULL
	            ,@creation_script = NULL
	            ,@pre_creation_cmd = N'drop'
	            ,@schema_option = "+$schemaOption+"
	            ,@identityrangemanagementoption = N'manual'
	            ,@destination_table = N'"+$_.table+"'
	            ,@destination_owner = N'"+$_.schema+"'
	            ,@vertical_partition = N'false'
	            ,@ins_cmd = N'CALL sp_MSins_"+$_.schema+$_.table+"'
	            ,@del_cmd = N'CALL sp_MSdel_"+$_.schema+$_.table+"'
	            ,@upd_cmd = N'SCALL sp_MSupd_"+$_.schema+$_.table+"';
    
RAISERROR('Article added for replication: "+$_.table+"', 0, 1)  WITH NOWAIT
            ";
    $article >> '.\30_Add_Articles_To_Publisher.sql'
}
'------------------Generated articles script 06_Add_Articles_To_Publisher---------------------';

#MODIFY SCRIPTS TO CORRESPONDING SERVER
$list = @();
$scripts = @((1, "01_Cleanup_Subscriber.sql", 1),
	#(2, "02_Cleanup_Publisher.sql", 1),
	#(3, "03_ConfigureDistribution.sql", 1),
	#(4, "04_Configure_Distributor_Properties.sql", 1),
	#(5, "05_CreatePublication.sql", 1),
	#(6, "06_Add_Articles_To_Publisher.sql", 1),
	#(7, "07_Publisher_Backup.sql", 0),
	#(8, "08_Restore_published_database_to_subscriber.sql", 0),
	#(9, "09_Add_subscriber_to_publisher.sql", 1),
	#(10, "10_NewSubscription.sql", 1),
	#(11, "11_Mark_Not_For_Replication_On_Subscriber.sql", 0),
	#(12, "12_Change_datatype_on_subscriber_ExpUser.sql", 0)
);

$scripts | %{$i=0;}{ $list+=[pscustomobject]@{
												id=$_[0];
												file=$_[1];
												append_parameters = $_[2];
											};
					$i++};

foreach($i in $list){
    $scriptToExecute = ('.\' + $i.file);
	
    #Append variable declaration script to all the scripts
    $sql = gc $scriptToExecute | Out-String;    
    
	if(($sql).StartsWith($sqlVariables) -eq 0 -and $i.append_parameters -eq 1){
		#Set-Content $scriptToExecute -Value $sqlVariables, $sql -Force;
        $scriptToExecute;
	}
};

read-host
