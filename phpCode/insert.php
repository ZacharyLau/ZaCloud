<?php
    
    $con = mysql_connect("localhost:8080","root","root") or die('Could not connect: ' . mysql_error());
    mysql_select_db("projectII", $con);

    //read the json file contents
    $jsondata = file_get_contents('note.json');
    
    //convert json object to php associative array
    $data = json_decode($jsondata, true);
    
    //get the note details
    $title = $_REQUEST["title"];
    $note = $_REQUEST["note"];
    $lastModified = $_REQUEST["lastModified"];
    $createDate = $_REQUEST["createDate"];
    $author = $_REQUEST["author"];
    $locked = $_REQUEST["locked"];
    $lockingTime = $_REQUEST["lockingTime"];
     $updateDevice = $_REQUEST["updateDevice"];
    //insert into mysql table
    $sql = "INSERT INTO notes(title, note, author, lastModified, createDate, locked, lockingTime, updateDevice, isDeleted)
    VALUES('$title', '$note', '$author', '$lastModified', '$createDate', '$locked', '$lockingTime', '$updateDevice', 0)";
    if(!mysql_query($sql,$con))
    {
        die('Error : ' . mysql_error());
    }
?>