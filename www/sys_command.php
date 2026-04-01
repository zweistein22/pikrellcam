<?php
	require_once(dirname(__FILE__) . '/config.php');
?>

<?php
$e_user = "andreas";

if (file_exists('user.php'))
    include 'user.php';
?>

<?php
if (isset($_GET['cmd']))
	{
	$cmd = $_GET['cmd'];

	if ($cmd === "pikrellcam_start")
		{
		$SUDO_CMD = "sudo systemctl start pikrellcam > /dev/null 2>&1 &";
		$res = exec($SUDO_CMD);
		}
	else if ($cmd === "pikrellcam_stop")
		{
		$SUDO_CMD = "sudo systemctl stop pikrellcam > /dev/null 2>&1 &";
		$res = exec($SUDO_CMD);
	    }
	}
?>
