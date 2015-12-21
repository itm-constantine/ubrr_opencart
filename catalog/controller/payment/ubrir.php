<?php
class ControllerPaymentubrir extends Controller {
  protected function index() {
    $this->language->load('payment/ubrir');
    $this->data['button_confirm'] = $this->language->get('button_confirm');
  
  	// Подгрузка параметров заказа
    $this->load->model('checkout/order');
    $order_info = $this->model_checkout_order->getOrder($this->session->data['order_id']);
    if ($order_info) {
      // $this->data['entry_merchant'] = trim($this->config->get('entry_merchant')); 
      // $this->data['entry_uniteller_id'] = trim($this->config->get('entry_uniteller_id')); 
      // $this->data['entry_url_ca'] = trim($this->config->get('entry_url_ca')); 
      $this->data['orderid'] = $this->session->data['order_id'];
      $this->data['callbackurl'] = $this->url->link('payment/ubrir/callback');
      $this->data['currency'] = $order_info['currency_code'];
      $this->data['orderamount'] = $this->currency->format($order_info['total'], $this->data['currency'] , false, false);
      $this->data['two_processing'] = trim($this->config->get('entry_two_processing'));

      if (file_exists(DIR_TEMPLATE . $this->config->get('config_template') . '/template/payment/ubrir.tpl')){
        $this->template = $this->config->get('config_template') . '/template/payment/ubrir.tpl';
      } else {
        $this->template = 'default/template/payment/ubrir.tpl';
      }
  
      $this->render();
    }
  }

//  Чтение ответа от банка на запрос CREATE ORDER и сохранение в данных в таблицу twpg_orders
  function xml_extract_result($xml_string) {
    $parse_it = simplexml_load_string($xml_string);
    // print_r($parse_it);
    $response_status = $parse_it->Response->Status[0];
    switch ($response_status) {
      case '00':
        $response_order = $parse_it->Response->Order;
        $url = $response_order->URL[0];
        $order_id = $response_order->OrderID[0];
        $sessionid = $response_order->SessionID[0];
        $this->db->query("INSERT INTO `".DB_PREFIX."twpg_orders` (`shoporderid`, `OrderID`, `SessionID`) VALUES ('".$_GET['orderid']."', '".$order_id."', '".$sessionid."') ON DUPLICATE KEY UPDATE `shoporderid`='".$_GET['orderid']."', `OrderID`='".$order_id."', `SessionID`='".$sessionid."'");
          echo '<meta http-equiv="Refresh" content="0; url='.$url.'?orderid='.$order_id.'&sessionid='.$sessionid.'">';
        break;
      case '30';
      echo "<h1>Код:30</h1>";
        echo '<h2>Неверные данные или заполнены не все поля</h2>';
        break;
      default:
        # code...
        break;
    }
  }
  function xml_extract_status_result($xml, $shoporderid, $old_orderstatus) {
    $parse_it = simplexml_load_string($xml);
    $status = $parse_it->Response->Status[0];
    if ($status=='00') {
        $orderstatus=$parse_it->Response->Order->OrderStatus[0];
        if (strcmp($orderstatus,$old_orderstatus)==0) {
          return true;
        } else { return false;}
      } else {return false;}
    }
// отправка XML в банк
  function send_xml($xml) {
    $ch = curl_init("https://twpg.ubrr.ru:8443/Exec"); 
            curl_setopt($ch, CURLOPT_POST, 1);
            curl_setopt($ch, CURLOPT_CAINFO, DIR_SYSTEM.'certs'.DIRECTORY_SEPARATOR.'bank.crt');
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
            curl_setopt($ch, CURLOPT_SSLCERT, DIR_SYSTEM.'certs'.DIRECTORY_SEPARATOR.'user.pem');
            curl_setopt($ch, CURLOPT_SSLKEY, DIR_SYSTEM.'certs'.DIRECTORY_SEPARATOR.'user.key');
            curl_setopt($ch, CURLOPT_SSLKEYPASSWD, $this->config->get('entry_sslkeypass'));
            curl_setopt($ch, CURLOPT_POSTFIELDS, $xml);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
            curl_setopt($ch, CURLOPT_VERBOSE, 1);
    if( ! $answer = curl_exec($ch)) { 
      echo curl_error($ch)."<br>";
      echo curl_errno($ch);
    } 
    curl_close($ch);
    return $answer;
  }

  public function callback() {

    // Uniteller слушатель ответов банка
    if (isset($_GET['SIGN'])) {
      $sign =  strtoupper(md5(md5($_GET['SHOP_ID']).'&'.md5($_GET['ORDER_ID']).'&'.md5($_GET['STATE'])));
      if ($_GET['SIGN'] == $sign) {
        switch ($_GET['STATE']) {
            case 'authorized':
              $sql = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id` = 1 WHERE `order_id` = '.$_GET['ORDER_ID'];
              break;
            case 'paid':
              $sql = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id` = 2 WHERE `order_id` = '.$_GET['ORDER_ID'];
              break;
            case 'canceled':
              $sql = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id` = 7 WHERE `order_id` = '.$_GET['ORDER_ID'];
              break;
            default:
              break;
          }
        $this->db->query($sql);
      }
    }  
    // Возвращение клиента от юнителлера
    if (isset($_GET['status'])) {
      if ($_GET['status'] ==1) {
        $shoporderid=$_GET['?ORDER_ID'];
        $this->language->load('payment/ubrir');
        $this->load->model('checkout/order');
        // это чистит корзину и выводит сообщение о удачной оплате
        echo '<meta http-equiv="Refresh" content="0; url='.$this->url->link('checkout/success').'">';
      } else {
        echo '<meta charset="utf-8">';
        echo "<h2>Оплата не произведена <a href=http://".$_SERVER['HTTP_HOST'].dirname($_SERVER['PHP_SELF']).">вернуться в магазин</a></h2>";
      }
      die;
    }

    // проверка ответа от twpg
    if (isset($_POST['xmlmsg'])) {
      // При CancelURL xmlmsg приходит не шифрованным
      if (stripos($_POST["xmlmsg"], "CANCELED")) {
        echo '<meta charset="utf-8">';
        echo "<h2>Оплата отменена пользователем <a href=http://".$_SERVER['HTTP_HOST'].dirname($_SERVER['PHP_SELF']).">вернуться в магазин</a></h2>";
        die;
      }
        $xml_string = base64_decode($_POST['xmlmsg']);
        $parse_it = simplexml_load_string($xml_string);
      // Дергаем статус заказа
      $order_status = $parse_it->OrderStatus[0];
      // берем orderid sessionid shopid
        $sql_resp = $this->db->query("SELECT * FROM `".DB_PREFIX."twpg_orders` WHERE OrderID=".$parse_it->OrderID[0]);
        if ($sql_resp->num_rows == 1) {
          $sql_resp= $sql_resp->rows[0];
          $shoporderid = $sql_resp['shoporderid'];
          $sessionid = $sql_resp['SessionID'];
          $orderid = $parse_it->OrderID[0];
          // делаем запрос статус заказа
            $data = '<?xml version = "1.0" encoding = "UTF-8"?>
              <TKKPG>
                <Request>
                  <Operation>GetOrderStatus</Operation>
                  <Language>RU</Language>
                  <Order>
                    <Merchant>'.trim($this->config->get('entry_merchant')).'</Merchant>
                    <OrderID>'.$orderid.'</OrderID>
                  </Order>
                  <SessionID>'.$sessionid.'</SessionID>
                </Request>
              </TKKPG>
          ';
          // пишем статус в базу
          // echo $order_status;
          switch ($order_status) {
            case 'APPROVED':
              if ($this->xml_extract_status_result($this->send_xml($data), $shoporderid, $order_status)) {
                $this->load->model('checkout/order');
                $this->model_checkout_order->confirm($shoporderid, $this->config->get('ubrir_order_status_id'));
                //Это очистка корзины и перенаправление на страницу с сообщением об удачной оплате. 
                echo '<meta http-equiv="Refresh" content="0; url='.$this->url->link('checkout/success').'">';
                $update_status = 'UPDATE `checkout` SET `Status`="2" WHERE `Id`= "'.$shoporderid.'"';
              }
            break;
            case 'DECLINED':
            echo '<meta charset="utf-8">';
            echo "<h2>Оплата отклонена банком <a href=http://".$_SERVER['HTTP_HOST'].dirname($_SERVER['PHP_SELF']).">вернуться в магазин</a></h2>";
            break;
          }
        }
      die;
    }
    // Проверка ответа от Uniteller

    // Проверка передачи формы оплаты через VISA(TWPG)
    if (isset($_POST['visaorder'])) { 
      // print_r($_POST);
      $order_id = $_POST['orderid'];
      //  Данные заказа
      $entry_merchant = trim($this->config->get('entry_merchant'));
      $orderamount = $_POST['orderamount'];
      $callbackurl = $_POST['callbackurl'];
      // echo $entry_merchant;
      // echo $orderamount;
      // echo $callbackurl;
        $data = '<?xml version = "1.0" encoding = "UTF-8"?>
        <TKKPG>
          <Request>
            <Operation>CreateOrder</Operation>
            <Language>RU</Language>
            <Order>
              <OrderType>Purchase</OrderType>
              <Merchant>'.$entry_merchant.'</Merchant>
              <Amount>'.($orderamount*100).'</Amount>
              <Currency>643</Currency>
              <Description> </Description>
              <ApproveURL>'.$callbackurl.'</ApproveURL>
              <CancelURL>'.$callbackurl.'</CancelURL>
              <DeclineURL>'.$callbackurl.'</DeclineURL>
            </Order>
          </Request>
        </TKKPG>
        ';
      // echo $data;
      $this->xml_extract_result($this->send_xml($data));
      die;
    }
    // Проверка передачи формы оплаты через MC(Uniteller)
    if (isset($_POST['mcorder'])) {
      $id = trim($this->config->get('entry_uniteller_id'));
      $login = trim($this->config->get('entry_uniteller_login'));
      $pass = trim($this->config->get('entry_uniteller_pass')); 
      $orderid =$_POST['orderid'];   
      $amount = $_POST['orderamount'];    
      $callbackurl = $_POST['callbackurl'];
      $sign = strtoupper(md5(md5($id).'&'.md5($login).'&'.md5($pass).'&'.md5($orderid).'&'.md5($amount)));
      echo '<form action="https://91.208.121.201/estore_listener.php" name="uniteller" method="post" hidden>
        <input type="number" name="SHOP_ID" value="'.$id.'">
        <input type="text" name="LOGIN" value="'.$login.'">
        <input type="number" name="ORDER_ID" value="'.$orderid.'">
        <input type="number" name="PAY_SUM" value="'.$amount.'">
        <input type="number" name="VALUE_1" value="'.$orderid.'">
        <input type="text" name="URL_OK" value="'.$callbackurl.'&status=1&">
        <input type="text" name="URL_NO" value="'.$callbackurl.'&status=0&">
        <input type="text" name="SIGN" value="'.$sign.'">
        <input type="text" name="LANG" value="RU">
      </form>';
      // die;
      echo '
      <script>
      window.onload = function() {
        document.forms.uniteller.submit();
      }
      </script>
      ';
      die;
    }
  }
}
?>
