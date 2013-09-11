<?php

if ($_GET['host'] == 'ontheroad') {
    system("/path/to/dns-update.pl /path/to/transfer.key ontheroad.example.com " . $_SERVER['REMOTE_ADDR']);
}

?>
