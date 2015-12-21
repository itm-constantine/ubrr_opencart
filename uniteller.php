<?php 
header("Location: index.php?route=payment/ubrir/callback&SIGN=".$_POST['SIGN']."&SHOP_ID=".$_POST['SHOP_ID']."&ORDER_ID=".$_POST['ORDER_ID']."&STATE=".$_POST['STATE']);
?>