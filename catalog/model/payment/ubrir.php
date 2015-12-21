<?php
class ModelPaymentUbrir extends Model {
  public function getMethod($address, $total) {
    $this->load->language('payment/ubrir');
  
    $method_data = array(
      'code'     => 'ubrir',
      'title'    => $this->language->get('text_title'),
      'sort_order' => $this->config->get('ubrir_sort_order')
    );
  
    return $method_data;
  }
}