*&---------------------------------------------------------------------*
*& Report z_massbp_test_01
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_massbp_test_read_data_02.

PARAMETERS p_bp TYPE but000-partner.

START-OF-SELECTION.

  " Get Data
  DATA(lo_reader) = zcl_massbp_data_reader_01=>get_instance(  ).
  lo_reader->get_bp_from_customer(
    EXPORTING it_customers         = VALUE #( ( CONV #( p_bp ) ) )
              iv_bypass_buffer     = abap_true
              iv_scope_full        = abap_true
    IMPORTING et_business_partners = DATA(lt_business_partners) ).

  IF lt_business_partners IS INITIAL.
    MESSAGE 'Nothing Selected' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  DATA(ls_entity) = lt_business_partners[ 1 ].

  DATA(lo_output) = cl_demo_output=>new( ).

  "Start SECTION 1
  lo_output->begin_section( |Start of ANALysis for { p_bp }| ).

  "Start Section 1.1 - PARTNER
  lo_output->begin_section( |Start of PARTNER for { p_bp }| ).

  "Start Section 1.1.1 - PARTNER-HEADER
  lo_output->begin_section( |Start of PARTNER.HEADER for { p_bp }| ).

  IF ls_entity-partner-header IS NOT INITIAL.
    lo_output->write_data(
      value = ls_entity-partner-header ).
  ENDIF.

  "End Section 1.1.1
  lo_output->end_section( ).

  "Start Section 1.1.2 - PARTNER-CENTRAL_DATA
  lo_output->begin_section( |Start of PARTNER.CENTRAL for { p_bp }| ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-common-data-bp_control ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-common-data-bp_centraldata ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-common-datax-bp_centraldata ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-common-data-bp_organization ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-common-datax-bp_organization ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-common-data-ci_include ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-common-datax-ci_include ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-common-time_dependent_data-current_state ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-common-time_dependent_data-common_data ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-role-current_state ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-role-roles ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-role-time_dependent ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-taxnumber-current_state ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-taxnumber-common-data ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-taxnumber-common-datax ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-taxnumber-taxnumbers ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-taxnumber_adr ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-phone-current_state ).
  LOOP AT ls_entity-partner-central_data-communication-phone-phone
     ASSIGNING FIELD-SYMBOL(<ls_bp_phone>).
    lo_output->write_data(
      value = <ls_bp_phone>-comm_usage-current_state
      name  = |ENTRY: ls_entity-partner-central_data-communication-phone-phone-comm_usage-current_state| ).
    lo_output->write_data(
      value = <ls_bp_phone>-comm_usage-comm_usages
      name  = |ENTRY: ls_entity-partner-central_data-communication-phone-phone-comm_usage-comm_usages| ).
    lo_output->write_data(
      value = <ls_bp_phone>-currently_valid
      name  = |ENTRY: ls_entity-partner-central_data-communication-phone-phone-currently_valid| ).
    lo_output->write_data(
      value = <ls_bp_phone>-contact-task
      name  = |ls_entity-partner-central_data-communication-phone-phone-contact-task| ).
    lo_output->write_data(
      value = <ls_bp_phone>-contact-data
      name  = |ENTRY: ls_entity-partner-central_data-communication-phone-phone-contact-data| ).
    lo_output->write_data(
      value = <ls_bp_phone>-contact-datax
      name  = |ENTRY: ls_entity-partner-central_data-communication-phone-phone-contact-datax| ).
    lo_output->write_data(
      value = <ls_bp_phone>-remark
      name  = |ENTRY: ls_entity-partner-central_data-communication-phone-phone-remark| ).
  ENDLOOP.

  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-fax-current_state ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-fax-fax ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-ttx ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-tlx ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-smtp-current_state ).
  LOOP AT ls_entity-partner-central_data-communication-smtp-smtp
     ASSIGNING FIELD-SYMBOL(<ls_bp_comm_smtp>).
    lo_output->write_data(
      value = <ls_bp_comm_smtp>-comm_usage-current_state
      name  = |ENTRY: ls_entity-partner-central_data-communication-smtp-smtp-comm_usage-current_state| ).
    lo_output->write_data(
      value = <ls_bp_comm_smtp>-comm_usage-comm_usages
      name  = |ENTRY: ls_entity-partner-central_data-communication-smtp-smtp-comm_usage-comm_usages| ).
    lo_output->write_data(
      value = <ls_bp_comm_smtp>-currently_valid
      name  = |ENTRY: ls_entity-partner-central_data-communication-smtp-smtp-currently_valid| ).
    lo_output->write_data(
      value = <ls_bp_comm_smtp>-contact-task
      name  = |ENTRY: ls_entity-partner-central_data-communication-smtp-smtp-contact-task| ).
    lo_output->write_data(
      value = <ls_bp_comm_smtp>-contact-data
      name  = |ENTRY: ls_entity-partner-central_data-communication-smtp-smtp-contact-data| ).
    lo_output->write_data(
      value = <ls_bp_comm_smtp>-contact-datax
      name  = |ENTRY: ls_entity-partner-central_data-communication-smtp-smtp-contact-datax| ).
    lo_output->write_data(
      value = <ls_bp_comm_smtp>-remark
      name  = |ENTRY: ls_entity-partner-central_data-communication-smtp-smtp-remark| ).
  ENDLOOP.

  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-rml ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-x400 ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-rfc ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-prt ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-ssf ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-uri ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-pager ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-communication-time_dependent ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-address-current_state ).
  LOOP AT ls_entity-partner-central_data-address-addresses
       ASSIGNING FIELD-SYMBOL(<ls_bp_address>).

    lo_output->write_data(
      value = <ls_bp_address>-task
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-task| ).
    lo_output->write_data(
      value = <ls_bp_address>-data_key
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data_key| ).
    lo_output->write_data(
      value = <ls_bp_address>-currently_valid
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-currently_valid| ).

    lo_output->write_data(
      value = <ls_bp_address>-data-addr_usage-current_state
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-addr_usage-current_state| ).
    LOOP AT <ls_bp_address>-data-addr_usage-addr_usages
         ASSIGNING FIELD-SYMBOL(<ls_bp_address_addr_usage>).
      lo_output->write_data(
        value = <ls_bp_address_addr_usage>-task
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-addr_usage-addr_usages-addr_usages-task| ).
     lo_output->write_data(
        value = <ls_bp_address_addr_usage>-currently_valid
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-addr_usage-addr_usages-addr_usages-currently_valid| ).
      lo_output->write_data(
        value = <ls_bp_address_addr_usage>-data_key
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-addr_usage-addr_usages-addr_usages-data_key| ).
      lo_output->write_data(
        value = <ls_bp_address_addr_usage>-data
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-addr_usage-addr_usages-addr_usages-data| ).
      lo_output->write_data(
        value = <ls_bp_address_addr_usage>-datax
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-addr_usage-addr_usages-addr_usages-datax| ).
    ENDLOOP.

    lo_output->write_data(
      value = <ls_bp_address>-data-postal-data
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-postal-data| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-postal-datax
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-postal-datax| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-communication-fax
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-fax| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-communication-pager
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-pager| ).

    lo_output->write_data(
      value = <ls_bp_address>-data-communication-phone-current_state
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-phone-current_state| ).
    LOOP AT <ls_bp_address>-data-communication-phone-phone
         ASSIGNING FIELD-SYMBOL(<ls_bp_address_phone>).
      lo_output->write_data(
        value = <ls_bp_address_phone>-comm_usage
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-phone-phone-comm_usage| ).
      lo_output->write_data(
        value = <ls_bp_address_phone>-contact-task
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-phone-phone-contact-task| ).
      lo_output->write_data(
        value = <ls_bp_address_phone>-contact-data
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-phone-phone-contact-data| ).
      lo_output->write_data(
        value = <ls_bp_address_phone>-contact-datax
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-phone-phone-contact-datax| ).
      lo_output->write_data(
        value = <ls_bp_address_phone>-currently_valid
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-phone-phone-currently_valid| ).
      lo_output->write_data(
        value = <ls_bp_address_phone>-remark
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-phone-phone-remark| ).
    ENDLOOP.

    lo_output->write_data(
      value = <ls_bp_address>-data-communication-prt
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-prt| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-communication-rfc
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-rfc| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-communication-rml
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-rml| ).

    lo_output->write_data(
      value = <ls_bp_address>-data-communication-smtp-current_state
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-smtp-current_state| ).
    LOOP AT <ls_bp_address>-data-communication-smtp-smtp
         ASSIGNING FIELD-SYMBOL(<ls_bp_address_smtp>).
      lo_output->write_data(
        value = <ls_bp_address_smtp>-comm_usage
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-smtp-smtp-comm_usage| ).
      lo_output->write_data(
        value = <ls_bp_address_smtp>-contact-task
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-smtp-smtp-contact-task| ).
      lo_output->write_data(
        value = <ls_bp_address_smtp>-contact-data
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-smtp-smtp-contact-data| ).
      lo_output->write_data(
        value = <ls_bp_address_smtp>-contact-datax
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-smtp-smtp-contact-datax| ).
      lo_output->write_data(
        value = <ls_bp_address_smtp>-currently_valid
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-smtp-smtp-currently_valid| ).
      lo_output->write_data(
        value = <ls_bp_address_smtp>-remark
        name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-smtp-smtp-remark| ).
    ENDLOOP.

    lo_output->write_data(
      value = <ls_bp_address>-data-communication-ssf
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-ssf| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-communication-time_dependent
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-time_dependent| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-communication-tlx
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-tlx| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-communication-ttx
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-ttx| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-communication-uri
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-uri| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-communication-x400
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-communication-x400| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-version
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-version| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-addr_dep_attr
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-addr_dep_attr| ).
    lo_output->write_data(
      value = <ls_bp_address>-data-remark
      name  = |ENTRY: ls_entity-partner-central_data-address-addresses-data-remark| ).
  ENDLOOP.

  lo_output->write_data(
    value = ls_entity-partner-central_data-status-current_state ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-status-status ).

  lo_output->write_data(
    value = ls_entity-partner-central_data-taxclassification-current_state ).
  lo_output->write_data(
    value = ls_entity-partner-central_data-taxclassification-taxclasses ).

  "End Section 1.1.2
  lo_output->end_section( ).
  "End Section 1.1
  lo_output->end_section( ).

  "Start Section 1.2 - PARTNER RELATION
  lo_output->begin_section( |Start of PARTNER_RELATION for { p_bp }| ).
  lo_output->write_data(
    value = ls_entity-partner_relation ).
  "End Section 1.2
  lo_output->end_section( ).

  "Start Section 1.3 - CUSTOMER.HEADER
  lo_output->begin_section( |Start of CUSTOMER.HEADER for { p_bp }| ).
  lo_output->write_data(
    value = ls_entity-customer-header-object_task ).
  lo_output->write_data(
    value = ls_entity-customer-header-object_instance ).
  "End Section 1.3
  lo_output->end_section( ).

  "Start Section 1.4 - CENTRAL DATA
  lo_output->begin_section( |Start of CUSTOMER.CENTRAL_DATA for { p_bp }| ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-central-data ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-central-datax ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-central-central_address-current_state ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-central-central_address-central_addr ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-postal-data ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-address-postal-datax ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-fax-current_state ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-fax-fax ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-pager-current_state ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-pager-pager ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-phone-current_state ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-phone-phone ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-prt-current_state ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-prt-prt ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-rfc ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-rml ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-smtp-current_state ).
  LOOP AT ls_entity-customer-central_data-address-communication-smtp-smtp
       ASSIGNING FIELD-SYMBOL(<ls_cust_smtp>).
    lo_output->write_data(
      value = <ls_cust_smtp>-contact-task
      name  = |ENTRY: ls_entity-customer-central_data-address-communication-smtp-smtp-contact-task| ).
    lo_output->write_data(
      value = <ls_cust_smtp>-contact-data
      name  = |ENTRY: ls_entity-customer-central_data-address-communication-smtp-smtp-contact-data| ).
    lo_output->write_data(
      value = <ls_cust_smtp>-contact-datax
      name  = |ENTRY: ls_entity-customer-central_data-address-communication-smtp-smtp-contact-datax| ).
  ENDLOOP.

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-ssf ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-tlx ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-ttx ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-uri ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-address-communication-x400 ).

  lo_output->write_data(
    value = ls_entity-customer-central_data-text ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-vat_number ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-tax_grouping ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-tax_ind ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-export ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-loading ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-receiving ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-department ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-contact ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-creditcard ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-bankdetail ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-alt_payee ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-tax_licenses ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-loading_address ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-receiving_address ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-department_address ).
  lo_output->write_data(
    value = ls_entity-customer-central_data-ext_ref_address ).
  "End Section 1.2
  lo_output->end_section( ).

  "Start Section 1.5 - COMPANY DATA
  lo_output->begin_section( |Start of COMPANY DATA for { p_bp }| ).
  lo_output->write_data(
    value = ls_entity-customer-company_data-current_state ).
  LOOP AT ls_entity-customer-company_data-company
       ASSIGNING FIELD-SYMBOL(<ls_company>).
    lo_output->write_data(
      value = <ls_company>-task ).
    lo_output->write_data(
      value = <ls_company>-data_key ).
    lo_output->write_data(
      value = <ls_company>-data ).
    lo_output->write_data(
      value = <ls_company>-datax ).
    lo_output->write_data(
      value = <ls_company>-dunning ).
    lo_output->write_data(
      value = <ls_company>-wtax_type ).
    lo_output->write_data(
      value = <ls_company>-texts ).
    lo_output->write_data(
      value = <ls_company>-alt_payee ).
  ENDLOOP.

  "End Section 1.5
  lo_output->end_section( ).

  "Start Section 1.6 - SALES DATA
  lo_output->begin_section( |Start of SALES DATA for { p_bp }| ).
  lo_output->write_data(
    value = ls_entity-customer-sales_data-current_state ).
  lo_output->write_data(
    value = ls_entity-customer-sales_data-sales ).
  "End Section 1.6
  lo_output->end_section( ).

  "End SECTION 1
  lo_output->end_section( ).

  lo_output->display( ).

END-OF-SELECTION.
