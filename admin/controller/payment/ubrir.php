<?php
class ControllerPaymentubrir extends Controller {
  private $error = array();
 
  public function index() {
    $this->language->load('payment/ubrir');
    $this->document->setTitle('УБРиР');
    $this->load->model('setting/setting');
 
    if (($this->request->server['REQUEST_METHOD'] == 'POST')) {
      $this->model_setting_setting->editSetting('ubrir', $this->request->post);
      $this->session->data['success'] = 'Saved.';
      $this->redirect($this->url->link('extension/payment', 'token=' . $this->session->data['token'], 'SSL'));
    }
 
    // ЭТИ ПЕРЕМЕННЫЕ БЕРУТЬСЯ ИЗ ЯЗЫКОВОГО ФАЙЛА
    $this->data['heading_title'] = $this->language->get('heading_title');
    // Настройки модуля
    // TWPG
    $this->data['merchant'] = $this->language->get('merchant');
    $this->data['order_description'] = $this->language->get('order_description');
    $this->data['url_client_ca'] = $this->language->get('url_client_ca');
    $this->data['url_privatekey_ca'] = $this->language->get('url_privatekey_ca');
    $this->data['url_ca'] = $this->language->get('url_ca');

    // Uniteller
    $this->data['uniteller_id'] = $this->language->get('uniteller_id');
    $this->data['uniteller_login'] = $this->language->get('uniteller_login');
    $this->data['uniteller_pass'] = $this->language->get('uniteller_pass');
    $this->data['uniteller_user_pass'] = $this->language->get('uniteller_user_pass');
    $this->data['two_processing'] = $this->language->get('two_processing');

    $this->data['button_save'] = $this->language->get('text_button_save');
    $this->data['button_cancel'] = $this->language->get('text_button_cancel');
    $this->data['text_enabled'] = $this->language->get('text_enabled');
    $this->data['text_disabled'] = $this->language->get('text_disabled');
    $this->data['entry_order_status'] = $this->language->get('entry_order_status');
    $this->data['entry_status'] = $this->language->get('entry_status');
    $this->data['sslkeypass'] = $this->language->get('sslkeypass');
 
    $this->data['action'] = $this->url->link('payment/ubrir', 'token=' . $this->session->data['token'], 'SSL');
    $this->data['cancel'] = $this->url->link('extension/payment', 'token=' . $this->session->data['token'], 'SSL');
 
      // ЭТИ ПЕРЕМЕННЫЕ БЕРУТЬСЯ ИЗ БАЗЫ
      // TWPG
      // merchant id
      if (isset($this->request->post['entry_merchant'])) {
        $this->data['entry_merchant'] = $this->request->post['entry_merchant'];
      } else {
        $this->data['entry_merchant'] = $this->config->get('entry_merchant');
      } 
      //description
      if (isset($this->request->post['entry_order_description'])) {
        $this->data['entry_order_description'] = $this->request->post['entry_order_description'];
      } else {
        $this->data['entry_order_description'] = $this->config->get('entry_order_description');
      } 
      // url ca
      if (isset($this->request->post['entry_url_ca'])) {
        $this->data['entry_url_ca'] = $this->request->post['entry_url_ca'];
      } else {
        $this->data['entry_url_ca'] = $this->config->get('entry_url_ca');
      }
      // id uniteller
      if (isset($this->request->post['entry_uniteller_id'])) {
        $this->data['entry_uniteller_id'] = $this->request->post['entry_uniteller_id'];
      } else {
        $this->data['entry_uniteller_id'] = $this->config->get('entry_uniteller_id');
      }
      //login
      if (isset($this->request->post['entry_uniteller_login'])) {
        $this->data['entry_uniteller_login'] = $this->request->post['entry_uniteller_login'];
      } else {
        $this->data['entry_uniteller_login'] = $this->config->get('entry_uniteller_login');
      }
      // pass
      if (isset($this->request->post['entry_uniteller_pass'])) {
        $this->data['entry_uniteller_pass'] = $this->request->post['entry_uniteller_pass'];
      } else {
        $this->data['entry_uniteller_pass'] = $this->config->get('entry_uniteller_pass');
      }
      // user pass
      if (isset($this->request->post['entry_uniteller_user_pass'])) {
        $this->data['entry_uniteller_user_pass'] = $this->request->post['entry_uniteller_user_pass'];
      } else {
        $this->data['entry_uniteller_user_pass'] = $this->config->get('entry_uniteller_user_pass');
      }
      // two proccessing
      if (isset($this->request->post['entry_two_processing'])) {
        $this->data['entry_two_processing'] = $this->request->post['entry_two_processing'];
      } else {
        $this->data['entry_two_processing'] = $this->config->get('entry_two_processing');
      }
      
      if (isset($this->request->post['ubrir_status'])) {
        $this->data['ubrir_status'] = $this->request->post['ubrir_status'];
      } else {
        $this->data['ubrir_status'] = $this->config->get('ubrir_status');
      }      
      if (isset($this->request->post['entry_sslkeypass'])) {
        $this->data['entry_sslkeypass'] = $this->request->post['entry_sslkeypass'];
      } else {
        $this->data['entry_sslkeypass'] = $this->config->get('entry_sslkeypass');
      }
 
    $this->load->model('localisation/order_status');
    $this->data['order_statuses'] = $this->model_localisation_order_status->getOrderStatuses();
    $this->template = 'payment/ubrir.tpl';
            
    $this->children = array(
      'common/header',
      'common/footer'
    );
 
    $this->response->setOutput($this->render());
  }
}