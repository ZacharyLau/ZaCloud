
    <?php
    $connection = mysqli_connect("localhost","root","root","projectII") or die("Error " . mysqli_error($connection));

    //fetch table rows from mysql db
    $author = $_REQUEST['author'];
    $createDate = $_REQUEST['createDate'];  
    $lockingTime = $_REQUEST['lockingTime'];
    $lockingDevice = $_REQUEST['lockingDevice'];
    $currentTime = $_REQUEST['currentTime'];        
 //echo $author;
    //echo $createDate;
   // echo $lockingDevice;
    //$sql = sprintf("select lockingDevice from notes where author = 'zach' AND createDate = '2016-3-15 09:07:37'");
    $sql = sprintf("select lockingDevice from notes where author = '%s' AND createDate = '%s'", $author, $createDate);
    $result = mysqli_query($connection, $sql) or die("Error in Selecting " . mysqli_error($connection));
    
    $row = $result->fetch_object();
    $lockingDeviceDB = $row->lockingDevice;

    //echo $lockingDeviceDB;

    if(strcmp($lockingDeviceDB,$lockingDevice) == 0){
        //echo "  Strcmp success ";
        $sql2 = sprintf("UPDATE notes SET lockingTime='%s', locked=1, lockingDevice='%s' WHERE author='%s' AND createDate = '%s' ", $lockingTime, $lockingDevice, $author, $createDate);
                //$sql2 = sprintf("UPDATE notes SET lockingDevice='%s', locked=1, lockingTime='%s'lockingDevice='%s' WHERE author='%s' AND createDate = '%s' ", $lockingDevice, $lockingTime, $author, $createDate);
        if(!mysqli_query($connection, $sql2))// || mysqli_affected_rows($connection) == 0)
        {
                // die('Error : ' . mysql_error());
                //echo mysqli_affected_rows($connection);
                echo "[";
                echo json_encode(array('status' => 'false'));           
                echo "]";
                //die('Error: '.mysqli_error($connection));
        } else {
                echo "[";
                echo json_encode(array('status' => 'true'));            
                echo "]";
                }     


    }else{
        //echo "  Strcmp fail";

        $sql1 = sprintf("UPDATE notes SET lockingTime='%s', locked=1, lockingDevice='%s' WHERE author='%s' AND createDate = '%s' AND lockingTime <= '%s'", $lockingTime, $lockingDevice, $author, $createDate, $currentTime);
        //echo $sql1;
        if(!mysqli_query($connection, $sql1) || mysqli_affected_rows($connection) == 0)
        {
                // die('Error : ' . mysql_error());//
                echo "[";
                echo json_encode(array('status' => 'false'));   
                echo "]";
                //die('Error : ' . mysqli_error());
                //echo mysqli_affected_rows($connection);

        } else {
                echo "["; 
                echo json_encode(array('status' => 'true'));            
                echo "]";
        }       


    }

   
?>


