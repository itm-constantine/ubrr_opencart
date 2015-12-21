<form action="<?php echo $callbackurl.'&orderid='.$orderid; ?>" method="post" hidden>
<label for="orderid" hidden="hidden">Номер заказа</label>
  <input name="orderid" value="<?php echo $orderid; ?>" hidden="hidden"/>
  <label for="callbackurl" hidden="hidden">Ссылка</label>
  <input name="callbackurl" value="<?php echo $callbackurl; ?>" hidden="hidden"/>
  <label for="currency" hidden="hidden">Валюта</label>
  <input name="currency" value="<?php echo $currency; ?>" hidden="hidden"/>
  <label for="orderamount" hidden="hidden">Сумма заказа</label>
  <input name="orderamount" value="<?php echo $orderamount; ?>" hidden="hidden"/>
  
  <?php 
  ?>
  <div class="buttons">
    <div class="right">
    <?php if ($two_processing == 1) {
        echo  '<input type="submit" name="mcorder" value="Оплатить MasterCard" class="button mcbutton" />';
      } 
    ?>
    <input type="submit" name="visaorder" value="Оплатить VISA" class="button visabutton" />
    </div>
  </div>
</form>