

<?php
    //open connection to mysql db
    $connection = mysqli_connect("localhost","root","root","projectII") or die("Error " . mysqli_error($connection));

    //fetch table rows from mysql db
    $author = $_REQUEST["author"];
    $lastSyncDate = $_REQUEST["lastSyncDate"];
    $updateDevice = $_REQUEST["updateDevice"];
    $dateString = "1990-01-01 00:00:00";
    if (!(strpos($lastSyncDate,$dateString) !== false)){
        $sql = "select * from notes where author='$author' AND isDeleted = 0 AND createDate >='$lastSyncDate' AND updateDevice <> '$updateDevice'";
    $result = mysqli_query($connection, $sql) or die("Error in Selecting " . mysqli_error($connection));

    //create an array
    $emparray = array();
    while($row =mysqli_fetch_assoc($result))
    {
        $emparray[] = $row;
    }
    echo json_encode($emparray);

    //close the db connection
    mysqli_close($connection);
        
    }else{
    $sql = "select * from notes where author='$author' AND isDeleted = 0 ";
    $result = mysqli_query($connection, $sql) or die("Error in Selecting " . mysqli_error($connection));

    //create an array
    $emparray = array();
    while($row =mysqli_fetch_assoc($result))
    {
        $emparray[] = $row;
    }
    echo json_encode($emparray);

    //close the db connection
    mysqli_close($connection);
    }
?>
                                                
                                                     
                                                     