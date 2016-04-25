<?php
    
    $con = mysql_connect("localhost:8080","root","root") or die('Could not connect: ' . mysql_error());
    mysql_select_db("projectII", $con);

    //read the json file contents
    $jsondata = file_get_contents('note.json');
    
    //convert json object to php associative array
    $data = json_decode($jsondata, true);
    
    //get the note details
    $title = $_REQUEST["title"];
    $createDate = $_REQUEST["createDate"];
    $author = $_REQUEST["author"];
    $deleteDate = $_REQUEST["deleteDate"];
    $updateDevice = $_REQUEST["updateDevice"];
    //insert into mysql table
    //$sql = sprintf("DELETE FROM notes WHERE author='%s' AND createDate='%s'",$author, $createDate);
    $sql = sprintf("UPDATE notes SET isDeleted='1', updateDevice = '%s', lastModified = '%s' WHERE author='%s' AND createDate='%s' AND lastModified <= '%s'", $updateDevice,$deleteDate,$author, $createDate, $deleteDate);
    if(!mysql_query($sql,$con) || mysql_affected_rows() == 0)
    {
        echo json_encode(array('status' => 'false'));
        die('Error : ' . mysql_error());
    }else{
        $sql = sprintf("INSERT INTO deletion(username, createDate, deleteDate) VALUES('$author', '$createDate', '$deleteDate')");
        echo json_encode(array('status' => 'true'));
        if(!mysql_query($sql,$con))
        {
            die('Error : ' . mysql_error());
        }
    }
?>

