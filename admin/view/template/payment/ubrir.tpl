    <?php 
      //  Получение статуса заказа ============================================================================================
      if (isset($_GET['shoporderidforstatus'])) {
         if ($_GET['shoporderidforstatus']=="") {
          echo 'Неверный номер заказа';
          die;
         }
        // Получить orderid sessionid из таблицы twpg_orders
        $sql_req='SELECT * FROM `oc_twpg_orders` WHERE `shoporderid`="'.$_GET['shoporderidforstatus'].'"';
        $sql_response = $this->db->query($sql_req);
        if ($sql_response->num_rows ==1 ) {
          $sql_response = $sql_response->row;
          $orderid = $sql_response['OrderID'];
          $sessionid = $sql_response['SessionID'];
          $data = '<?xml version = "1.0" encoding = "UTF-8"?>
                  <TKKPG>
                    <Request>
                      <Operation>GetOrderStatus</Operation>
                      <Language>RU</Language>
                      <Order>
                        <Merchant>'.$this->config->get('entry_merchant').'</Merchant>
                        <OrderID>'.$orderid.'</OrderID>
                      </Order>
                      <SessionID>'.$sessionid.'</SessionID>
                    </Request>
                  </TKKPG>
          ';
          // Извлекаем результат запроса и обновляем статус заказа в базе
          // передаем объект $this для выполнения запроса к базе по другому не работает =(
          xml_extract_status_result(send_request($data,$this->config->get('entry_sslkeypass')),$this);
        } else {
          echo 'Неверный номер заказа';
        }
         die;
      }

      //  Получение детальной информации заказа ===============================================================================
      if (isset($_GET['shoporderidfordetailstatus'])) {
        if ($_GET['shoporderidfordetailstatus']=="") {
         echo 'Неверный номер заказа';
         die;
        }
        // Получить orderid sessionid из таблицы twpg_orders
        $sql_req='SELECT * FROM `oc_twpg_orders` WHERE `shoporderid`='.$_GET['shoporderidfordetailstatus'];
        $sql_response = $this->db->query($sql_req);
        if ($sql_response->num_rows ==1) {
          $sql_response = $sql_response->row;
          $orderid = $sql_response['OrderID'];
          $sessionid = $sql_response['SessionID'];
          $data = '<?xml version = "1.0" encoding = "UTF-8"?>
                  <TKKPG>
                    <Request>
                      <Operation>GetOrderInformation</Operation>
                      <Language>RU</Language>
                      <Order>
                        <Merchant>'.$this->config->get('entry_merchant').'</Merchant>
                        <OrderID>'.$orderid.'</OrderID>
                      </Order>
                      <SessionID>'.$sessionid.'</SessionID>
                      <SessionID>'.$sessionid.'</SessionID>
                      <ShowParams>true</ShowParams>
                      <ShowOperations>true</ShowOperations>
                      <ClassicView>true</ClassicView>
                    </Request>
                  </TKKPG>
          ';
          // Извлекаем результат запроса и обновляем статус заказа в базе
          // передаем объект $this для выполнения запроса к базе по другому не работает =(
          xml_extract_detailstatus_result(send_request($data,$this->config->get('entry_sslkeypass')));
        } else {
          echo 'Неверный ID';
        }
         die;
      }
      //  Реверс заказа =======================================================================================================
      if (isset($_GET['reversorder'])) {
        if ($_GET['reversorder']=="") {
         echo 'Неверный номер заказа';
         die;
        }
        // Проверить статус заказа
        $check_req = "SELECT * FROM `".DB_PREFIX."order` WHERE `order_id`='".$_GET['reversorder']."'";
        $check_resp = $this->db->query($check_req);
        if ($check_resp->num_rows>1 or $check_resp->num_rows==0) {
          echo "Неверный ID";
          die;
        }
        $check_resp = $check_resp->row;
        if ($check_resp['order_status_id']!=2) {
          echo "Заказ не может быть отменен";
          die;
        }
        // Получить orderid sessionid из таблицы twpg_orders
        $sql_req='SELECT * FROM `oc_twpg_orders` WHERE `shoporderid`='.$_GET['reversorder'];
        $sql_response = $this->db->query($sql_req);
        if ($sql_response->num_rows ==1) {
          $sql_response = $sql_response->row;
          $orderid = $sql_response['OrderID'];
          $sessionid = $sql_response['SessionID'];
          $tranid_req = '<?xml version = "1.0" encoding = "UTF-8"?>
            <TKKPG>
              <Request>
                <Operation>GetOrderInformation</Operation>
                <Language>RU</Language>
                <Order>
                  <Merchant>'.$this->config->get('entry_merchant').'</Merchant>
                  <OrderID>'.$orderid.'</OrderID>
                </Order>
                <SessionID>'.$sessionid.'</SessionID>
                <ShowParams>true</ShowParams>
                <ShowOperations>true</ShowOperations>
                <ClassicView>true</ClassicView>
              </Request>
            </TKKPG>
          ';
          $tranid_resp = send_request($tranid_req,$this->config->get('entry_sslkeypass'));
          $tranid_parse = simplexml_load_string($tranid_resp);
          $tran_rows = $tranid_parse->Response->Order->row->OrderOperations->row;
          for ($i=0; $i < sizeof($tran_rows); $i++) { 
            if ($tran_rows[$i]->OperName[0] == 'Purchase') {
              $tranid = $tran_rows[$i]->twoId[0];
            }
          }
          $data = '<?xml version = "1.0" encoding = "UTF-8"?>
            <TKKPG>
              <Request>
                <Operation>Reverse</Operation>
                <Language>RU</Language>
                <Order>
                  <Merchant>'.$this->config->get('entry_merchant').'</Merchant>
                  <OrderID>'.$orderid.'</OrderID>
                </Order>
                <SessionID>'.$sessionid.'</SessionID>
                <TranID>'.$tranid.'</TranID>
              </Request>
            </TKKPG>
            ';
          // Извлекаем результат запроса и обновляем статус заказа в базе
          // передаем объект $this для выполнения запроса к базе по другому не работает =(
          xml_extract_revers_result(send_request($data,$this->config->get('entry_sslkeypass')), $this);
        } else {
          echo 'Неверный ID';
        }
         die;
      }
      // Сверка итогов
      if (isset($_GET['recresult'])) {
        $data = '<?xml version = "1.0" encoding = "UTF-8"?>
                <TKKPG>
                  <Request>
                    <Operation>Reconcile</Operation>
                    <Language>RU</Language>
                    <Merchant>'.$this->config->get('entry_merchant').'</Merchant>
                  </Request>
                </TKKPG>
                ';
        xml_extract_recresult_result(send_request($data,$this->config->get('entry_sslkeypass')));
        die;
      }
      // Вывод журнала операций
      if (isset($_GET['journal'])) {
        $data = '<?xml version = "1.0" encoding = "UTF-8"?>
                <TKKPG>
                  <Request>
                    <Operation>TransactionLog</Operation>
                    <Language>RU</Language>
                    <Merchant>'.$this->config->get('entry_merchant').'</Merchant>
                  </Request>
                </TKKPG>
                ';
        xml_extract_journal_result(send_request($data,$this->config->get('entry_sslkeypass')));
        die;
      }

      // Запрос журнала юнителлера
      if (isset($_GET['unilogin']) & isset($_GET['unipass'])) {
        $data="LOGIN=".$_GET['unilogin'];
        $data.="&PSWD=".$_GET['unipass'];
        $uni_ch = curl_init(); 
        curl_setopt($uni_ch, CURLOPT_URL, "https://91.208.121.201/estore_result.php");
        curl_setopt($uni_ch, CURLOPT_POST, 1);
        curl_setopt($uni_ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($uni_ch, CURLOPT_SSL_VERIFYHOST, false);
        curl_setopt($uni_ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($uni_ch, CURLOPT_POSTFIELDS, $data);
        if( ! $curl_answer = curl_exec($uni_ch)) { 
          echo "Ошибка соединения с банком (".curl_errno($uni_ch).")";
          die;
        }
        curl_close($uni_ch);
        xml_extract_uni_journal($curl_answer);
        die;
      }

      if(isset($_GET['mailsubject'])) {
        if($_GET['mailsubject'] == 'Выберите тему') {
            echo "Не выбрана тема обращения";
            die;
          } elseif (empty($_GET['mailem'])) {
            echo "Не заполнен номер телефона";
            die;
          } elseif(empty($_GET['maildesc'])) {
            echo "Не заполнена причина обращения";
            die;
          }

       $to = 'ibank@ubrr.ru';
       $subject = htmlspecialchars($_GET['mailsubject'], ENT_QUOTES);
       $message = 'Отправитель: '.htmlspecialchars($_GET['mailem'], ENT_QUOTES).' | '.htmlspecialchars($_GET['maildesc'], ENT_QUOTES);
       $headers = 'From: '.$_SERVER["HTTP_HOST"];
       if (mail($to, $subject, $message, $headers)) {
         echo "<h2>Сообщение отправлено</h2>";
       } else {
         echo "<h2>Сообщение временно не может быть отправлено</h2>";
       }
      die;
      }
      // Все вспомогательные функции
      // Извлекаем ответ для получения статуса заказа из TWPG и обновляем его в базе
      function xml_extract_status_result($xml, $object) {
          $parse_it = simplexml_load_string($xml);
          $status = $parse_it->Response->Status[0];
          switch ($status) {
            case '00':
              $orderstatus=$parse_it->Response->Order->OrderStatus[0];
		   function status_decode($status){
			 switch ($status) {
			  case 'APPROVED':
				return 'Одобрен (оплата прошла успешно)';
				break;
			  case 'CANCELED':
				return 'Отменен (клиент прервал выполнение операции)';
				break;
			  case 'DECLINED':
				return 'Отказ в оплате';
				break;
			  case 'REVERSED':
				return 'Реверсирован';
				break;    
			  case 'REFUNDED':
				return 'Осуществлен возврат товара';
				break;    
			  case 'PREAUTH-APPROVED':
				return 'Выполнена предавторизация';
				break;     
			 case 'EXPIRED':
				return 'Истек срок действия заказа';
				break; 
			 case 'ON-PAYMENT':
				return 'На оплате';
				break; 		
			 default:
				return $status;
				break;
			}
		  };
          echo "<p>Статус - ".status_decode($orderstatus)."</p>";
              $update_status ="";
             /*  switch ($orderstatus) {
                case 'CANCELED':
                  $update_status = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id`="7" WHERE `order_id`= "'.$_GET['shoporderidforstatus'].'"';
                  break;
                case 'APPROVED':
                  $update_status = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id`="2" WHERE `order_id`= "'.$_GET['shoporderidforstatus'].'"';
                  break;
                case 'CREATED':
                  $update_status = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id`="1" WHERE `order_id`= "'.$_GET['shoporderidforstatus'].'"';
                  break;
                case 'REVERSED':
                  $update_status = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id`="8" WHERE `order_id`= "'.$_GET['shoporderidforstatus'].'"';
                  break;
                case 'DECLINED':
                  $update_status = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id`="9" WHERE `order_id`= "'.$_GET['shoporderidforstatus'].'"';
                  break;
                case 'EXPIRED':
                  $update_status = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id`="10" WHERE `order_id`= "'.$_GET['shoporderidforstatus'].'"';
                  break;
              } 
              $object->db->query($update_status);*/
              break;
            case '30':
              echo "<h2>Код:30 - Неверный формат запроса</h2>";
              break;
            case '95':
              echo "<h2>95</h2>";
              break;
            case '10':
              echo "<h2>Код:10 - ИМ не имеет доступа к этой операции</h2>";
              break;    
            case '54':
              echo "<h2>Код:54 - Недопустимая операция</h2>";
              break;    
            case '96':
              echo "<h2>Код:96 - Системная ошибка</h2>";
              break;              
            default:
              # code...
              break;
          }
      }
      // Извлекаем детальную информацию о заказе
      function xml_extract_detailstatus_result($xml) {
        $parse_it = simplexml_load_string($xml);
        // print_r($parse_it);
        // die;
        // print_r($parse_it);
        $status = $parse_it->Response->Status[0];
        $row = $parse_it->Response->Order->row;
          switch ($status) {
          case '00':
            echo "<table><tr><td>ID</td><td>".$row->id[0]."</td></tr>";
            echo "<tr><td>SessionID</td><td>".$row->SessionID[0]."</td></tr>";
            echo "<tr><td>createDate</td><td>".$row->createDate[0]."</td></tr>";
            echo "<tr><td>lastUpdateDate</td><td>".$row->lastUpdateDate[0]."</td></tr>";
            echo "<tr><td>payDate</td><td>".$row->payDate[0]."</td></tr>";
            echo "<tr><td>MerchantID</td><td>".$row->MerchantID[0]."</td></tr>";
            echo "<tr><td>Amount</td><td>".$row->Amount[0]."</td></tr>";
            echo "<tr><td>Currency</td><td>".$row->Currency[0]."</td></tr>";
            echo "<tr><td>OrderLanguage</td><td>".$row->OrderLanguage[0]."</td></tr>";
            echo "<tr><td>Description</td><td>".$row->Description[0]."</td></tr>";
            echo "<tr><td>ApproveURL</td><td>".$row->ApproveURL[0]."</td></tr>";
            echo "<tr><td>CancelURL</td><td>".$row->CancelURL[0]."</td></tr>";
            echo "<tr><td>DeclineURL</td><td>".$row->DeclineURL[0]."</td></tr>";
            echo "<tr><td>Orderstatus</td><td>".$row->Orderstatus[0]."</td></tr>";
            echo "<tr><td>RefundAmount</td><td>".$row->RefundAmount[0]."</td></tr>";
            echo "<tr><td>RefundCurrency</td><td>".$row->RefundCurrency[0]."</td></tr>";
            echo "<tr><td>ExtSystemProcess</td><td>".$row->ExtSystemProcess[0]."</td></tr>";
            echo "<tr><td>OrderType</td><td>".$row->OrderType[0]."</td></tr>";
            echo "<tr><td>Fee</td><td>".$row->Fee[0]."</td></tr>";
            echo "<tr><td>RefundDate</td><td>".$row->RefundDate[0]."</td></tr>";
            echo "<tr><td>TWODate</td><td>".$row->TWODate[0]."</td></tr>";
            echo "<tr><td>TWOTime</td><td>".$row->TWOTime[0]."</td></tr>";
            $operations = $row->OrderOperations->row;
            for ($i=0; $i < count($operations) ; $i++) { 
              echo "<tr><td>id</td><td>".$operations[$i]->id[0]."</td></tr>";
              echo "<tr><td>PackageId</td><td>".$operations[$i]->PackageId[0]."</td></tr>";
              echo "<tr><td>createDate</td><td>".$operations[$i]->createDate[0]."</td></tr>";
              echo "<tr><td>MerchantID</td><td>".$operations[$i]->MerchantID[0]."</td></tr>";
              echo "<tr><td>OperType</td><td>".$operations[$i]->OperType[0]."</td></tr>";
              echo "<tr><td>OperName</td><td>".$operations[$i]->OperName[0]."</td></tr>";
              echo "<tr><td>OrderId</td><td>".$operations[$i]->OrderId[0]."</td></tr>";
              echo "<tr><td>Amount</td><td>".$operations[$i]->Amount[0]."</td></tr>";
              echo "<tr><td>Currency</td><td>".$operations[$i]->Currency[0]."</td></tr>";
              echo "<tr><td>Approval</td><td>".$operations[$i]->Approval[0]."</td></tr>";
              echo "<tr><td>twoId</td><td>".$operations[$i]->twoId[0]."</td></tr>";
            }
            echo "</table>";
            break;
          case '30':
            echo "<h2>Код:30 - Неверный формат запроса</h2>";
            break;
          case '95':
            echo "<h2>95</h2>";
            break;
          case '10':
            echo "<h2>Код:10 - ИМ не имеет доступа к этой операции</h2>";
            break;    
          case '54':
            echo "<h2>Код:54 - Недопустимая операция</h2>";
            break;    
          case '96':
            echo "<h2>Код:96 - Системная ошибка</h2>";
            break;              
          default:
            # code...
            break;
        }
      }
      // Извлекаем ответ запроса на реверс заказа
      function xml_extract_revers_result($xml_string, $object) {
        $parse_it = simplexml_load_string($xml_string);
        $status = $parse_it->Response->Status[0];
        switch ($status) {
          case '00':
            $update_status = 'UPDATE `'.DB_PREFIX.'order` SET `order_status_id`="8" WHERE `order_id`= "'.$_GET['reversorder'].'"';
            $object->db->query($update_status);
            echo "<h2>Операция отменена</h2>";
            break;
          case '30':
            echo "<h2>Код:30 - Неверный формат запроса</h2>";
            break;
          case '95':
            echo "<h2>95</h2>";
            break;
          case '10':
            echo "<h2>Код:10 - ИМ не имеет доступа к этой операции</h2>";
            break;    
          case '54':
            echo "<h2>Код:54 - Недопустимая операция</h2>";
            break;    
          case '96':
            echo "<h2>Код:96 - Системная ошибка</h2>";
            break;              
          default:
            # code...
            break;
        }
      }
      // Извлекаем ответ на запрос сверки итогов
      function xml_extract_recresult_result($xml) {
        $parse_it = simplexml_load_string($xml);
        $status = $parse_it->Response->Status[0];
            // $totals = $parse_it->Response->Totals;
        // var_dump($totals->Debit->Count);
        // die;
        switch ($status) {
          case '00':
            $totals = $parse_it->Response->Totals;
            echo "<h2>Успешно</h2>";
            echo '<p>Итоги совпали - '.$parse_it->Response->Reconcilation[0].'</p>';
            echo '<p>Дебит:</p><p>Количество операций: '.$totals->Debit->Count[0].'</p>';
            echo '<p>Общая сумма: '.number_format(((int)$totals->Debit->Amount[0])/100,2,'.','').'</p>';
            echo '<p>Кредит:</p><p>Количество операций: '.$totals->Credit->Count[0].'</p>';
            echo '<p>Общая сумма: '.number_format(((int)$totals->Credit->Amount[0])/100,2,'.','').'</p>';
            break;
          case '30':
            echo "<h2>Код:30 - Неверный формат запроса</h2>";
            break;
          case '95':
            echo "<h2>95</h2>";
            break;
          case '10':
            echo "<h2>Код:10 - ИМ не имеет доступа к этой операции</h2>";
            break;    
          case '54':
            echo "<h2>Код:54 - Недопустимая операция</h2>";
            break;    
          case '96':
            echo "<h2>Код:96 - Системная ошибка</h2>";
            break;              
          default:
            # code...
            break;
        }
      }
      // Извлекаем ответ на запрос журнала операций
      function xml_extract_journal_result($xml) {
        $parse_it = simplexml_load_string($xml);
        $status = $parse_it->Response->Status[0];
        switch ($status) {
          case '00':
            $count = $parse_it->Response->Operations->Count[0];
            echo '<h2>Операций в журнале:'.$count.'</h2>';
            $orders = $parse_it->Response->Operations->Order;
            echo '<table>
                <tr>
                  <td>ID</td>
                  <td>Время</td>
                  <td>Сумма</td>
                  <td>Тип Валюты</td>
                  <td>Тип</td>
                  <td>Статус</td>
                  <td>Доп. ID</td>
                  <td>Код операции</td>
                  <td>Название Операции</td>
                </tr>
              ';
            foreach ($orders as $order) {
              echo '<tr>
                  <td>'.$order['ID'].'</td>
                  <td>'.parse_time($order->Time[0]).'</td>
                  <td>'.(($order->Amount[0])/100).'</td>
                  <td>'.currency_set($order->Currency[0]).'</td>
                  <td>'.type_decode($order->Type[0]).'</td>
                  <td>'.translate_journal_status($order->Status[0]).'</td>
                  <td>'.$order->twoId[0].'</td>
                  <td>'.$order->OperType[0].'</td>
                  <td>'.oper_decode($order->OperName[0]).'</td>
                </tr>';
            }
            echo '</table>';
            break;
          case '30':
            echo "<h2>Код:30 - Неверный формат запроса</h2>";
            break;
          case '95':
            echo "<h2>95</h2>";
            break;
          case '10':
            echo "<h2>Код:10 - ИМ не имеет доступа к этой операции</h2>";
            break;    
          case '54':
            echo "<h2>Код:54 - Недопустимая операция</h2>";
            break;    
          case '96':
            echo "<h2>Код:96 - Системная ошибка</h2>";
            break;              
          default:
            # code...
            break;
        }
      }
      //  Расшифровка статусов журнала
      function translate_journal_status($string) {
        switch ($string) {
            case 'APPROVED':
            return 'Одобрен';
            break;
            case 'CANCELED':
            return 'Отменен ';
            break;
            case 'DECLINED':
            return 'Отказано';
            break;
            case 'REVERSED':
            return 'Реверсирован';
            break;    
            case 'REFUNDED':
            return 'Возврат';
            break;    
            case 'PREAUTH-APPROVED':
            return 'Предавторизован';
            break;     
            case 'EXPIRED':
            return 'Истек';
            break; 
            case 'ON-PAYMENT':
            return 'На оплате';
        }
      }
     
       function type_decode($type)
       {
       switch ($type) {
       case 'Purchase':
       return 'Покупка';
       break; 
       case 'Reverse':
       return 'Реверс оплаты';
       break; 
       default:
       return $type;
       break;
       }
       } 
       
       
        function oper_decode($oper)
       {
       switch ($oper) {
       case 'CreateOrder':
       return 'Создание заказа на покупку';
       break; 
       case 'GetOrderStatus':
       return 'Получение статуса заказа';
       break;
       case 'Purchase':
       return 'Покупка';
       break; 
       case 'Reverse':
       return 'Реверс оплаты';
       break; 
       case 'Reconcile':
       return 'Сверка итогов';
       break; 
       case 'TransactionLog':
       return 'Журнал операций';
       break; 
       case 'GetOrderInformation':
       return 'Получение информации о заказе';
       break; 
       default:
       return $oper;
       break;
       }
       }
      // Парсим журнал юнителлера
      function xml_extract_uni_journal($xml) {
        $parse_it = simplexml_load_string($xml);
        // print_r($parse_it);
        $count = $parse_it['count'];
        echo "<table><tr>
        <td>Номер заказа</td>
        <td>Время начала обработки</td>
        <td>Код состояния платежа</td>
        <td>Расшифровка кода</td>
        <td>Код результата операции</td>
        <td>Расшифровка кода результата операции</td>
        <td>Дата последней операции по платежу</td>
        <td>Идентификатор платежа</td>
        <td>Имя держателя карты</td>
        <td>Маскированный номер карты</td>
        <td>Код подтверждения транзакции</td>
        <td>Идентификатор платежа в ПС</td>
        <td>Сумма платежа</td>
        </tr>";
        for ($i=0; $i < $count; $i++) { 
          $order=$parse_it->estore->order[$i];
          echo "<tr>
        <td>".$order['estore_order']."</td>
        <td>".$order['start_dt']."</td>
        <td>".$order['state_code']."</td>
        <td>".$order['state_msg']."</td>
        <td>".$order['oper_code']."</td>
        <td>".$order['oper_msg']."</td>
        <td>".$order['last_dt']."</td>
        <td>".$order['rrn']."</td>
        <td>".$order['cardholder']."</td>
        <td>".$order['pan']."</td>
        <td>".$order['app_code']."</td>
        <td>".$order['pay_trans']."</td>
        <td>".$order['pay_sum']."</td>
        </tr>";
        }
        echo "</table>";
      }
      // Парсим время для журнала операций
      function parse_time($string) {
        //date
        $str = substr($string, 0,2);
        //month
        $str .= '/'.substr($string, 2,2);
        //year
        $str .= '/'.substr($string, 4,4);
        //hour
        $str .= ' '.substr($string, 8,2);
        //minuts
        $str .= ':'.substr($string, 10,2);
        //seconds
        $str .= ':'.substr($string, 12,2);
        return $str;
      }
      // Парсим тип валюты
      function currency_set($bd_value) {
        switch ($bd_value) {
          case '643':
            return 'RUB';
            break;
          case '810':
            return 'RUB';
            break;
          case '840';
            return 'USD';
            break;
          default:
            return 'unknown';
            break;
        }
      }
      // Отправка XML запроса в TWPG
      function send_request($request , $sslkey) {
        $ch = curl_init("https://twpg.ubrr.ru:8443/Exec"); 
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_CAINFO, DIR_SYSTEM.'certs'.DIRECTORY_SEPARATOR.'bank.crt');
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
        curl_setopt($ch, CURLOPT_SSLCERT, DIR_SYSTEM.'certs'.DIRECTORY_SEPARATOR.'user.pem');
        curl_setopt($ch, CURLOPT_SSLKEY, DIR_SYSTEM.'certs'.DIRECTORY_SEPARATOR.'user.key');
        curl_setopt($ch, CURLOPT_SSLKEYPASSWD, $sslkey);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_VERBOSE, 1);
        if( ! $curl_answer = curl_exec($ch)) { 
          echo "Ошибка соединения с банком (".curl_errno($ch).")";
          die;
        } 
        curl_close($ch);
        return $curl_answer;
      }
    ?>
<?php echo $header; ?>
<script src="view/javascript/uploader.min.js"></script>
<div id="content">
  <div class="box">
    <div class="heading">
      <h1><img src="view/image/payment.png" alt="" /> <?php echo $heading_title; ?></h1>
      <div class="buttons"><a onclick="$('#form').submit();" class="button"><?php echo $button_save; ?></a><a href="<?php echo $cancel; ?>" class="button"><?php echo $button_cancel; ?></a></div>
    </div>
    <div class="content">
      <form action="<?php echo $action; ?>" method="post" enctype="multipart/form-data" id="form">
        <table class="form">
          <tr>
            <td><?php echo $entry_status; ?></td>
            <td><select name="ubrir_status">
                <?php if ($ubrir_status) { ?>
                <option value="1" selected="selected"><?php echo $text_enabled; ?></option>
                <option value="0"><?php echo $text_disabled; ?></option>
                <?php } else { ?>
                <option value="1"><?php echo $text_enabled; ?></option>
                <option value="0" selected="selected"><?php echo $text_disabled; ?></option>
                <?php } ?>
              </select></td>
          </tr>
        </table>

      <!-- Форма создание базы -->
      <?php 
          $create = "CREATE TABLE IF NOT EXISTS `".DB_PREFIX."twpg_orders` (`shoporderid` VARCHAR(11), `OrderID` int(11) NOT NULL,`SessionID` VARCHAR(40) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8";
          $this->db->query($create);
      ?>

          <table class="form">
            <tr>
              <td><?php echo $entry_order_status; ?></td>
              <td><select name="ubrir_order_status_id">
                  <?php foreach ($order_statuses as $order_status) { ?>
                  <?php if ($order_status['order_status_id'] == $ubrir_order_status_id) { ?>
                  <option value="<?php echo $order_status['order_status_id']; ?>" selected="selected"><?php echo $order_status['name']; ?></option>
                  <?php } else { ?>
                  <option value="<?php echo $order_status['order_status_id']; ?>"><?php echo $order_status['name']; ?></option>
                  <?php } ?>
                  <?php } ?>
                </select></td>
            </tr>
            <!-- two proccess -->
            <tr>
              <td><?php echo $two_processing; ?></td>
              <td>
                <select name="entry_two_processing">
                  <option value="1" <?php if ($entry_two_processing==1){ echo "selected='selected'";} ?> >Вкл.</option>
                  <option value="0" <?php if ($entry_two_processing==0){ echo "selected='selected'";} ?>>Выкл.</option>
                </select>
              </td> 
            </tr>

          </table>  
      <!-- Раздел настроек модулей TWPG и Uniteller -->

        <h2>Настройки для VISA</h2>
        <table class="form">
             <!-- ID магазина -->
            <tr>
              <td>ID интернет-магазина для VISA</td>
              <td><input type="text" name="entry_merchant" value="<?php echo $entry_merchant; ?>" size="10" /></td>
            </tr>       
             <!-- SSL private key password -->
            <tr>
              <td>Пароль к сертификату VISA</td>
              <td><input type="text" name="entry_sslkeypass" value="<?php echo $entry_sslkeypass; ?>" size="16" /></td>
            </tr>         
            </table>
    <!-- Кнопки запросов TWPG -->
    <!-- TWPG статус заказа -->
      <input type="text" name="shoporderidforstatus" id="shoporderidforstatus" value="" placeholder="№ заказа" size="8">
      <input type="button" id="statusbutton" value="Запросить статус заказа"><br>
    <!-- TWPG Детальная информация заказа -->
      <input type="text" name="shoporderidfordetailstatus" id="shoporderidfordetailstatus" value="" placeholder="№ заказа" size="8">
      <input type="button" id="detailstatusbutton" value="Информация о заказе"><br>
    <!-- TWPG Реверс заказа -->
      <input type="text" name="reversorder" id="reversorder" value="" placeholder="№ заказа" size="8">
      <input type="button" id="reversbutton" value="Отмена заказа"><br>
    <!-- TWPG сверка итогов -->
      <input type="button" id="recresultbutton" value="Сверка итогов">
    <!-- TWPG журнал операции -->
      <input type="button" id="journalbutton" value="Журнал операций Visa">

            <h2>Настройки для MasterCard</h2>
            <table class="form">
            <h3>URL обработки ответов ПЦ <span style="color:red"><?php echo HTTP_CATALOG."uniteller.php" ?></span></h3>
            <!-- Uni id -->
            <tr>
              <td>ID интернет-магазина для MasterCard</td>
              <td><input type="text" name="entry_uniteller_id" value="<?php echo $entry_uniteller_id; ?>" size="10" /></td> 
            </tr>
            <!-- Uni login -->
            <tr>
              <td>Логин личного кабинета MasterCard</td>
              <td><input type="text" name="entry_uniteller_login" value="<?php echo $entry_uniteller_login; ?>" size="10" /></td> 
            </tr>
            <!-- Uni pass -->
            <tr>
              <td>Пароль интернет-магазина для MasterCard</td>
              <td><input type="text" name="entry_uniteller_pass" value="<?php echo $entry_uniteller_pass; ?>" size="10" /></td> 
            </tr>
            <!-- Uni user pass -->
            <tr>
              <td>Пароль личного кабинета MasterCard</td>
              <td><input type="text" name="entry_uniteller_user_pass" value="<?php echo $entry_uniteller_user_pass; ?>" size="10" /></td> 
            </tr>
        </table>
      <!-- Uniteller статистика платежей -->
      <input type="text" name="unilogin" id="unilogin" value="<?php echo trim($this->config->get('entry_uniteller_login')) ?>" placeholder="логин" size="8">
      <input type="text" name="unipass" id="unipass" value="<?php echo trim($this->config->get('entry_uniteller_user_pass')) ?>" placeholder="пароль" size="8">
      <input type="button" id="unijournalbutton" value="Журнал операций MasterCard">
      <input type="button" onclick="jQuery('#callback').toggle()" value="Написать в банк">
      <div id="callback" style="display: none;">
 <table>
 <tr>
 <h2 onclick="show(this);" style="text-align: center; cursor:pointer;">Обратная связь<span style="margin-left: 20px; font-size: 80%; color: grey;" onclick="jQuery('#callback').toggle();">[X]</span></h2>
 </tr>
 <tr>
 <td>Тема</td>
 <td>
 <select name="subject" id="mailsubject" style="width:150px">
 <option selected disabled>Выберите тему</option>
 <option value="Подключение услуги">Подключение услуги</option>
 <option value="Продление Сертификата">Продление Сертификата</option>
 <option value="Технические вопросы">Технические вопросы</option>
 <option value="Юридические вопросы">Юридические вопросы</option>
 <option value="Бухгалтерия">Бухгалтерия</option>
 <option value="Другое">Другое</option>
 </select>
 </td>
 </tr>
 <tr>
 <td>Телефон</td>
 <td>
 <input type="text" name="email" id="mailem" style="width:150px">
 </td>
 </tr>
 <tr>
 <td>Сообщение</td>
 <td>
 <textarea name="maildesc" id="maildesc" cols="30" rows="10" style="width:150px;resize:none;"></textarea>
 </td>
 </tr>
 <tr><td></td>
 <td>
 <input id="sendmail"  type="button" name="sendmail" value="Отправить">
 </tr>
 <tr>
 </tr>
 <tr><td></td><td id="mailresponse"></td><td>8 (800) 1000-200</td></tr>
 </table>
 </div>
    <div id="showresponse"></div>
    </form>
    <style>
      .button {
        float: left;
        padding: 5px 15px;
        cursor: pointer;
        border-radius: 3px;
        border: 1px solid #ccc;
        margin-right: 3px;
      }
      .show{
        padding-top: 10px;
        height: 270px !important;
      }
      .hide {
        padding-top: 10px;
        height: 50px;
        overflow: hidden;
      }
#callback {
 padding: 20px;
 position: fixed;
 width:335px;
 bottom: 0;
 left: 0;
 height: 340px;
 z-index:999;
 background-color: white;
 box-shadow: 0 0 25px 3px;
 border-radius: 3px;
 margin: 20px;
 text-align: left;
 }
    </style>
    <!-- Обработчики кнопок запросов -->
    <script>
      // Обработчик обратной связи
      $("#sendmail").click(function(){
        var mailsubject = $('#mailsubject').val();
        var maildesc = $('#maildesc').val();
        var mailem = $('#mailem').val();
        $.ajax({
        type: "GET",
        url: location.href,
        data: {mailsubject:mailsubject, maildesc:maildesc, mailem:mailem },
        success: function(response){
        $("#mailresponse").html(response);
        $("#maildesc").val(null);
        $("#mailsubject").val(null);
        $('#mailem').val(null);
      }
      });
      return false;
      });
      // Обработчик кнопки статус заказа
      $("#statusbutton").click(function(){
        var fdt = $('#shoporderidforstatus').val();
        $.ajax({
        type: "GET",
        url: location.href,
        data: {shoporderidforstatus:fdt},
        success: function(response){
        $("#showresponse").html(response);
        $("#shoporderidforstatus").val(null);
      }
      });
      return false;
      });
      // Обработчик кнопки детальной информации
      $("#detailstatusbutton").click(function(){
        var fdt = $('#shoporderidfordetailstatus').val();
        $.ajax({
        type: "GET",
        url: location.href,
        data: {shoporderidfordetailstatus:fdt},
        success: function(response){
        $("#showresponse").html(response);
        $("#shoporderidfordetailstatus").val(null);
      }
      });
      return false;
      });
      // Обработчик кнопки реверса операции
      $("#reversbutton").click(function(){
        var fdt = $('#reversorder').val();
        $.ajax({
        type: "GET",
        url: location.href,
        data: {reversorder:fdt},
        success: function(response){
        $("#showresponse").html(response);
        $("#reversorder").val(null);
      }
      });
      return false;
      });
      // Обработчик кнопки сверки итогов
      $("#recresultbutton").click(function(){
        $.ajax({
        type: "GET",
        url: location.href,
        data: {recresult:1},
        success: function(response){
        $("#showresponse").html(response);
      }
      });
      return false;
      });
      // Обработчик кнопки журнал операций
      $("#journalbutton").click(function(){
        $.ajax({
        type: "GET",
        url: location.href,
        data: {journal:1},
        success: function(response){
        $("#showresponse").html(response);
      }
      });
      return false;
      });
      // Обработчик кнопки статистика платежей
      $("#unijournalbutton").click(function(){
        var unilogin = $('#unilogin').val();
        var unipass = $('#unipass').val();
        $.ajax({
        type: "GET",
        url: location.href,
        data: {unilogin:unilogin,unipass:unipass},
        success: function(response){
        $("#showresponse").html(response);
      }
      });
      return false;
      });
    </script>
    </div>
  </div>
</div>
<?php echo $footer; ?>