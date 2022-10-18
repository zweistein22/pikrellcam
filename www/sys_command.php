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
		$SUDO_CMD = "sudo -u " . $e_user . " " . PIKRELLCAM . " > /dev/null 2>&1 &";
		$res = exec($SUDO_CMD);
		}
	else if ($cmd === "pikrellcam_stop")
		{
		$fifo = fopen(FIFO_FILE,"w");
		fwrite($fifo, "quit");
		fclose($fifo);
		usleep(500000);
		exec("pgrep pikrellcam", $output, $return);
		if ($return == 0)
			exec('killall pikrellcam');
		}
	}
?>
