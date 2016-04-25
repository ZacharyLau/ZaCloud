

<?php
    //open connection to mysql db
    $connection = mysqli_connect("localhost","root","root","projectII") or die("Error " . mysqli_error($connection));

    //fetch table rows from mysql db
    $username = $_REQUEST['username'];
	$password = $_REQUEST['password'];                                                                                                 
    $sql = sprintf("select * from users where username = '%s'", $username);
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


<?php
	$connection = mysqli_connect("localhost","root","root","projectII") or die("Error " . mysqli_error($connection));

    //fetch table rows from mysql db
    $username = $_REQUEST['username'];
	$password = $_REQUEST['password'];                                                                                                 
    $sql = sprintf("select * from users where username = '%s'", $username);
    $result = mysqli_query($connection, $sql) or die("Error in Selecting " . mysqli_error($connection));
	
		$result_array = array();
		$row = $result->fetch_object();
		$check_username = $row->username;
		$check_password = $row->password;
	
	
	if(strcmp($username, $check_username) == 0 && strcmp($password, $check_password) == 0 ) {
		echo json_encode(array('status' => 'true'));		
	} else {
		echo json_encode(array('status' => 'false'));		
	} 
?>