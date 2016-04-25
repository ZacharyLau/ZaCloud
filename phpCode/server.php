<?php
    //open connection to mysql db
    $connection = mysqli_connect("localhost","root","root","projectII") or die("Error " . mysqli_error($connection));

    //fetch table rows from mysql db
    $author = $_REQUEST["author"];
    $lastSyncDate = $_REQUEST["lastSyncDate"];
    $updateDevice = $_REQUEST["updateDevice"];
    $sql = "select * from notes where author='$author' AND lastModified >= '$lastSyncDate' AND isDeleted = 0  AND updateDevice <> '$updateDevice'";
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
?>


