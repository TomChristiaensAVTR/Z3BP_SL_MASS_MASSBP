"! <p class="shorttext synchronized">Mass Upd BP - Modifier - Parallel - Full Scope</p>
CLASS zcl_massbp_para_mod_v02 DEFINITION
  PUBLIC
  INHERITING FROM zcl_massbp_para_mod_0abs
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA ms_comm_structure TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value READ-ONLY.
    DATA mv_guid           TYPE bu_partner_guid                                READ-ONLY.
    DATA mra_kunnr         TYPE RANGE OF kunnr                                 READ-ONLY.
    DATA mra_partner       TYPE RANGE OF bu_partner                            READ-ONLY.

    METHODS process REDEFINITION.

    METHODS constructor
      IMPORTING is_comm_update TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value OPTIONAL.

    "! <p class="shorttext synchronized">Initialize</p>
    METHODS initialize.

    "! <p class="shorttext synchronized">Setter - Communication Structure</p>
    METHODS set_comm_structure
      IMPORTING is_comm_structure TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value.

  PROTECTED SECTION.
    DATA mr_seldat_bp_centr_org TYPE REF TO mass_wa_tabdata.

    DATA mr_seldat_bp_postal    TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_bp_smtp      TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_bp_phone     TYPE REF TO mass_wa_tabdata.

    DATA mr_seldat_cust_central TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_cust_company TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_cust_sales   TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_cust_tax     TYPE REF TO mass_wa_tabdata.

    DATA mr_seldat_vend_central TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_vend_company TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_vend_purch   TYPE REF TO mass_wa_tabdata.

  PRIVATE SECTION.
    "! <p class="shorttext synchronized">Take Over CENTRAL ORGANIZATIONAL Data</p>
    METHODS copy_bp_centr_org_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over CUSTOMER CENTRAL Data</p>
    METHODS copy_cust_central_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over CUSTOMER COMPANY Data</p>
    METHODS copy_cust_company_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over CUSTOMER SALES Data</p>
    METHODS copy_cust_sales_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over CUSTOMER TAX Data</p>
    METHODS copy_cust_tax_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over VENDOR CENTRAL Data</p>
    METHODS copy_vend_central_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over VENDOR COMPANY Data</p>
    METHODS copy_vend_company_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over VENDOR PURCH Data</p>
    METHODS copy_vend_purch_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over POSTAL Data</p>
    METHODS copy_bp_postal_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over SMTP Data</p>
    METHODS copy_bp_smtp_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over SMTP Data - Full</p>
    METHODS copy_bp_smtp_data_full
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over SMTP Data - Delta</p>
    METHODS copy_bp_smtp_data_delta
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Take Over PHONE Data</p>
    METHODS copy_bp_phone_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

    "! <p class="shorttext synchronized">Determine Dimension FLAGS - Full</p>
    METHODS determine_seldat_flags.

    "! <p class="shorttext synchronized">Determine Range of Customers</p>
    METHODS determine_kunnr_range.

    "! <p class="shorttext synchronized">Determine Range of partners</p>
    METHODS determine_partner_range.

ENDCLASS.


CLASS zcl_massbp_para_mod_v02 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    ms_comm_structure = is_comm_update.
  ENDMETHOD.

  METHOD set_comm_structure.
    ms_comm_structure = is_comm_structure.
  ENDMETHOD.

  METHOD process.

    "---------------------------------------------------------------------------------
    " TCH - 29JAN2026 - For the moment this method is enabled to do the update of 1 BP.
    " In the next versions, I will try to make this method enabled to update multiple BP's
    " in 1 go. This is assuming that cl_md_bp_maintain=>maintain is able to do this ...
    " The reason that this is enabled for 1 BP only is because I didn't check whether when multiple
    " are updated in 1 go, and 1 is in error, whether the others are posted ...
    "---------------------------------------------------------------------------------

    DATA ls_bapiret2 TYPE bapiret2.
    DATA lt_partners TYPE zcl_massbp_data_reader_01=>tt_business_partners.

    initialize( ).

    " Central data should ALWAYS be present ...
    IF ms_comm_structure-customer_central IS INITIAL.
      " ERROR !! - TO DO: Log ERROR
      RETURN.
    ENDIF.

    " Central data should ALWAYS be present ...
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_bp_centr_org
         WITH KEY tabname-name = zif_massbp_co=>gc_table_bp_centr_org.
    IF sy-subrc <> 0.
      " ERROR !! - TO DO: Log ERROR
      RETURN.
    ENDIF.

    " COMPANY, SALES, POSTAL, CENTRAL ORG, POSTAL, PHONE, SMTP data CAN be present ...
    determine_seldat_flags( ).

    " Setup of a range of involved BP's (customers and/or vendors)
    determine_partner_range( ).

    " Get the OLD BP DATA ...
    lt_partners = CORRESPONDING #( mra_partner[] MAPPING partner = low ).
    DATA(lo_reader) = zcl_massbp_data_reader_01=>get_instance( ).
    " lo_reader->read_cvi_links_from_bp( EXPORTING it_bp_numbers     = lt_partners
    "                                    IMPORTING et_customer_links = DATA(lt_customer_links)
    "                                              et_vendor_links   = DATA(lt_vendor_links) ).

    " We need to fetch the old address data since this needs to be passed on at MODIFY
    lo_reader->get_bp_address_from_bp( EXPORTING it_bp_numbers        = lt_partners
                                       IMPORTING et_business_partners = mt_bp_old ).

    LOOP AT ms_comm_structure-bp_centr_org
         ASSIGNING FIELD-SYMBOL(<ls_input_central_org>).

      " Get the OLD DATA as template (TO BE USED for the ADDRESS update ...)
      CLEAR ms_bp_old.
      READ TABLE mt_bp_old
           INTO ms_bp_old
           WITH KEY partner-header-object_instance-bpartner = <ls_input_central_org>-partner.
      IF sy-subrc <> 0.
        " TO DO: Generate Error since we're changing a customer without central address - ONLY CHANGE is in scope
        CONTINUE.
      ENDIF.

      "-------------------------------------------------------------------------------
      " UPDATE: Set the GENERAL context for the BP
      "-------------------------------------------------------------------------------
      CLEAR ms_bp_new.
      ms_bp_new-partner-header-object_task = zif_massbp_co=>gc_objtask_update.
      ms_bp_new-partner-header-object_instance-bpartner = |{ <ls_input_central_org>-partner ALPHA = IN }|.

      CLEAR mv_guid.
      CALL FUNCTION 'BUPA_NUMBERS_GET'
        EXPORTING
          iv_partner      = ms_bp_new-partner-header-object_instance-bpartner
        IMPORTING
          ev_partner_guid = mv_guid.
      ms_bp_new-partner-header-object_instance-bpartnerguid = mv_guid.

      "-------------------------------------------------------------------------------
      " Set the BP Central Organizational Data
      "-------------------------------------------------------------------------------
      ASSIGN ms_bp_new-partner-central_data-common TO FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-data-bp_organization = CORRESPONDING #( <ls_input_central_org> ).

      " Set the change flags for the CENTRAL ORG data
      LOOP AT mr_seldat_bp_centr_org->fieldnames
           ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
        ASSIGN COMPONENT <lv_fieldname>
               OF STRUCTURE <ls_upd>-datax-bp_organization
               TO FIELD-SYMBOL(<lv_fieldvalue>).
        IF sy-subrc = 0.
          <lv_fieldvalue> = abap_true.
        ENDIF.
      ENDLOOP.

      " BP POSTAL DATA can be present ...
      IF mr_seldat_bp_postal IS BOUND.
        " Take over POSTAL DATA
        copy_bp_postal_data( ).
      ENDIF.

      " BP SMTP DATA can be present ...
      IF mr_seldat_bp_smtp IS BOUND.
        " Take over SMTP DATA
        copy_bp_smtp_data( ).
      ENDIF.

      " BP PHONE DATA can be present ...
      IF mr_seldat_bp_phone IS BOUND.
        " Take over SMTP DATA
        copy_bp_phone_data( ).
      ENDIF.

      IF    mr_seldat_cust_central IS BOUND
         OR mr_seldat_cust_company IS BOUND
         OR mr_seldat_cust_sales   IS BOUND
         OR mr_seldat_cust_tax     IS BOUND.

        " Set the context for the KUNNR
        ms_bp_new-customer-header-object_instance-kunnr = |{ <ls_input_central_org>-partner ALPHA = IN }|.
        ms_bp_new-customer-header-object_task = zif_massbp_co=>gc_objtask_update.

        " CUSTOMER CENTRAL DATA can be present ...
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_copy_cust_centr_ok) = COND #(
          WHEN mr_seldat_cust_central IS BOUND
          THEN copy_cust_central_data( )
          ELSE abap_false ).

        " CUSTOMER COMPANY DATA can be present ...
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_copy_cust_comp_ok) = COND #(
          WHEN mr_seldat_cust_company IS BOUND
          THEN copy_cust_company_data( )
          ELSE abap_false ).

        " CUSTOMER SALES DATA can be present ...
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_copy_cust_sales_ok) = COND #(
          WHEN mr_seldat_cust_sales IS BOUND
          THEN copy_cust_sales_data( )
          ELSE abap_false ).

        " CUSTOMER TAX DATA can be present ...
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_copy_cust_tax_ok) = COND #(
          WHEN mr_seldat_cust_tax IS BOUND
          THEN copy_cust_tax_data( )
          ELSE abap_false ).

      ENDIF.

      IF    mr_seldat_vend_central IS BOUND
         OR mr_seldat_vend_company IS BOUND
         OR mr_seldat_vend_purch   IS BOUND.

        " Set the context for the LIFNR
        ms_bp_new-vendor-header-object_instance-lifnr = |{ <ls_input_central_org>-partner ALPHA = IN }|.
        ms_bp_new-vendor-header-object_task = zif_massbp_co=>gc_objtask_update.

        " VENDOR CENTRAL DATA can be present ...
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_copy_vend_centr_ok) = COND #(
          WHEN mr_seldat_vend_central IS BOUND
          THEN copy_vend_central_data( )
          ELSE abap_false ).

        " VENDOR COMPANY DATA can be present ...
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_copy_vend_company_ok) = COND #(
          WHEN mr_seldat_vend_company IS BOUND
          THEN copy_vend_company_data( )
          ELSE abap_false ).

        " VENDOR PURCHASING DATA can be present ...
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_copy_vend_purch_ok) = COND #(
          WHEN mr_seldat_vend_purch IS BOUND
          THEN copy_vend_purch_data( )
          ELSE abap_false ).
      ENDIF.

      " Do the API Call (In TEST or REAL)
      CLEAR mt_bp_new.
      INSERT ms_bp_new INTO TABLE mt_bp_new.
      cl_md_bp_maintain=>maintain( EXPORTING i_data     = mt_bp_new
                                             i_test_run = ms_comm_structure-testmode
                                   IMPORTING e_return   = mt_bapiretm ).

      is_successfull( IMPORTING ev_successfull = DATA(lv_successfull)
                      CHANGING  ct_bapiretm    = mt_bapiretm ).
      " Add the context for the MT_BAPIRETM --> we add the first PARTNER
      CLEAR ls_bapiret2.
      MESSAGE ID     'ZMASSBP'
              TYPE   'S'
              NUMBER '003'
              WITH   ms_bp_new-partner-header-object_instance-bpartner
              INTO   ls_bapiret2-message.
      ls_bapiret2-type       = sy-msgty.
      ls_bapiret2-id         = sy-msgid.
      ls_bapiret2-number     = sy-msgno.
      ls_bapiret2-message_v1 = sy-msgv1.
      ls_bapiret2-message_v2 = sy-msgv2.
      ls_bapiret2-message_v3 = sy-msgv3.
      ls_bapiret2-message_v4 = sy-msgv4.
      ASSIGN mt_bapiretm[ 1 ] TO FIELD-SYMBOL(<ls_bapiretm>).
      IF sy-subrc = 0.
        INSERT CORRESPONDING #( ls_bapiret2 )
               INTO <ls_bapiretm>-object_msg
               INDEX 1.
      ENDIF.

      " If required, commit/rollback the CRUD of the BP
      IF ms_comm_structure-testmode = abap_false.
        IF lv_successfull = abap_true.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait   = abap_true
            IMPORTING
              return = ls_bapiret2.
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
            IMPORTING
              return = ls_bapiret2.
        ENDIF.

        " Add the COMMIT/ROLLBACK errors to the return
        DATA(ls_bapiretm) = COND #( WHEN mt_bapiretm IS NOT INITIAL THEN mt_bapiretm[ 1 ] ).
        IF     ls_bapiretm IS NOT INITIAL
           AND ls_bapiret2 IS NOT INITIAL.
          APPEND CORRESPONDING #( ls_bapiret2 )
                 TO ls_bapiretm-object_msg.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD determine_seldat_flags.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_bp_centr_org
         WITH KEY tabname-name = zif_massbp_co=>gc_table_bp_centr_org.

    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_cust_central
         WITH KEY tabname-name = zif_massbp_co=>gc_table_cust_central.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_cust_company
         WITH KEY tabname-name = zif_massbp_co=>gc_table_cust_company.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_cust_sales
         WITH KEY tabname-name = zif_massbp_co=>gc_table_cust_sales.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_cust_tax
         WITH KEY tabname-name = zif_massbp_co=>gc_table_cust_tax.

    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_vend_central
         WITH KEY tabname-name = zif_massbp_co=>gc_table_vend_central.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_vend_company
         WITH KEY tabname-name = zif_massbp_co=>gc_table_vend_company.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_vend_purch
         WITH KEY tabname-name = zif_massbp_co=>gc_table_vend_purch.

    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_bp_postal
         WITH KEY tabname-name = zif_massbp_co=>gc_table_bp_postal.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_bp_smtp
         WITH KEY tabname-name = zif_massbp_co=>gc_table_bp_smtp.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_bp_phone
         WITH KEY tabname-name = zif_massbp_co=>gc_table_bp_phone.
  ENDMETHOD.

  METHOD copy_cust_central_data.
    DATA lv_object_counter TYPE i.

    rv_success = abap_true.
    LOOP AT ms_comm_structure-customer_central
         ASSIGNING FIELD-SYMBOL(<ls_input>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " Take over CUSTOMER CENTRAL DATA
      ASSIGN ms_bp_new-customer-central_data-central
             TO FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-data = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the COMPANY data
      lv_object_counter += 1.
      IF lv_object_counter = 1.
        LOOP AT mr_seldat_cust_central->fieldnames
             ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_upd>-datax
                 TO FIELD-SYMBOL(<lv_fieldvalue>).
          <lv_fieldvalue> = abap_true.
        ENDLOOP.
        DATA(ls_bp_datax) = <ls_upd>-datax.
      ELSE.
        <ls_upd>-datax = ls_bp_datax.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_cust_company_data.
    DATA lv_object_counter TYPE i.

    rv_success = abap_true.
    LOOP AT ms_comm_structure-customer_company
         ASSIGNING FIELD-SYMBOL(<ls_input>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " Take over CUSTOMER COMPANY DATA
      APPEND INITIAL LINE TO ms_bp_new-customer-company_data-company
             ASSIGNING FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-task = zif_massbp_co=>gc_objtask_update.
      <ls_upd>-data_key-bukrs = <ls_input>-bukrs.
      <ls_upd>-data = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the COMPANY data
      lv_object_counter += 1.
      IF lv_object_counter = 1.
        LOOP AT mr_seldat_cust_company->fieldnames
             ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_upd>-datax
                 TO FIELD-SYMBOL(<lv_fieldvalue>).
          <lv_fieldvalue> = abap_true.
        ENDLOOP.
        DATA(ls_bp_datax) = <ls_upd>-datax.
      ELSE.
        <ls_upd>-datax = ls_bp_datax.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_cust_sales_data.
    DATA lv_object_counter TYPE i.

    rv_success = abap_true.
    LOOP AT ms_comm_structure-customer_sales
         ASSIGNING FIELD-SYMBOL(<ls_input>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " Take over CUSTOMER SALES DATA
      APPEND INITIAL LINE TO ms_bp_new-customer-sales_data-sales
             ASSIGNING FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-task = zif_massbp_co=>gc_objtask_update.
      <ls_upd>-data_key-vkorg = <ls_input>-vkorg.
      <ls_upd>-data_key-vtweg = <ls_input>-vtweg.
      <ls_upd>-data_key-spart = <ls_input>-spart.
      <ls_upd>-data = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the CUSTOMER SALES DATA
      lv_object_counter += 1.
      IF lv_object_counter = 1.
        LOOP AT mr_seldat_cust_sales->fieldnames
             ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_upd>-datax
                 TO FIELD-SYMBOL(<lv_fieldvalue>).
          <lv_fieldvalue> = abap_true.
        ENDLOOP.
        DATA(ls_bp_datax) = <ls_upd>-datax.
      ELSE.
        <ls_upd>-datax = ls_bp_datax.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_cust_tax_data.
    DATA lv_object_counter TYPE i.

    rv_success = abap_true.
    LOOP AT ms_comm_structure-customer_tax
         ASSIGNING FIELD-SYMBOL(<ls_input>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " Take over CUSTOMER TAX DATA
      APPEND INITIAL LINE TO ms_bp_new-customer-central_data-tax_ind-tax_ind
             ASSIGNING FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-task = zif_massbp_co=>gc_objtask_update.
      <ls_upd>-data_key-aland = <ls_input>-aland.
      <ls_upd>-data_key-tatyp = <ls_input>-tatyp.
      <ls_upd>-data = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the CUSTOMER TAX DATA
      lv_object_counter += 1.
      IF lv_object_counter = 1.
        LOOP AT mr_seldat_cust_tax->fieldnames
             ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_upd>-datax
                 TO FIELD-SYMBOL(<lv_fieldvalue>).
          <lv_fieldvalue> = abap_true.
        ENDLOOP.
        DATA(ls_bp_datax) = <ls_upd>-datax.
      ELSE.
        <ls_upd>-datax = ls_bp_datax.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_vend_central_data.
    DATA lv_object_counter TYPE i.

    rv_success = abap_true.
    LOOP AT ms_comm_structure-vendor_central
         ASSIGNING FIELD-SYMBOL(<ls_input>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " Take over VENDOR CENTRAL DATA
      ASSIGN ms_bp_new-customer-central_data-central
             TO FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-data = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the COMPANY data
      lv_object_counter += 1.
      IF lv_object_counter = 1.
        LOOP AT mr_seldat_cust_central->fieldnames
             ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_upd>-datax
                 TO FIELD-SYMBOL(<lv_fieldvalue>).
          <lv_fieldvalue> = abap_true.
        ENDLOOP.
        DATA(ls_bp_datax) = <ls_upd>-datax.
      ELSE.
        <ls_upd>-datax = ls_bp_datax.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_vend_company_data.
    DATA lv_object_counter TYPE i.

    rv_success = abap_true.
    LOOP AT ms_comm_structure-vendor_company
         ASSIGNING FIELD-SYMBOL(<ls_input>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " Take over VENDOR COMPANY DATA
      APPEND INITIAL LINE TO ms_bp_new-vendor-company_data-company
             ASSIGNING FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-task = zif_massbp_co=>gc_objtask_update.
      <ls_upd>-data_key-bukrs = <ls_input>-bukrs.
      <ls_upd>-data = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the COMPANY data
      lv_object_counter += 1.
      IF lv_object_counter = 1.
        LOOP AT mr_seldat_cust_company->fieldnames
             ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_upd>-datax
                 TO FIELD-SYMBOL(<lv_fieldvalue>).
          <lv_fieldvalue> = abap_true.
        ENDLOOP.
        DATA(ls_bp_datax) = <ls_upd>-datax.
      ELSE.
        <ls_upd>-datax = ls_bp_datax.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_vend_purch_data.
    DATA lv_object_counter TYPE i.

    rv_success = abap_true.
    LOOP AT ms_comm_structure-vendor_purch
         ASSIGNING FIELD-SYMBOL(<ls_input>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " Take over VENDOR PURCHASING DATA
      APPEND INITIAL LINE TO ms_bp_new-vendor-purchasing_data-purchasing
             ASSIGNING FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-task = zif_massbp_co=>gc_objtask_update.
      <ls_upd>-data_key-ekorg = <ls_input>-ekorg.
      <ls_upd>-data = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the COMPANY data
      lv_object_counter += 1.
      IF lv_object_counter = 1.
        LOOP AT mr_seldat_cust_company->fieldnames
             ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_upd>-datax
                 TO FIELD-SYMBOL(<lv_fieldvalue>).
          <lv_fieldvalue> = abap_true.
        ENDLOOP.
        DATA(ls_bp_datax) = <ls_upd>-datax.
      ELSE.
        <ls_upd>-datax = ls_bp_datax.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_bp_centr_org_data.
    DATA lv_object_counter TYPE i.

    rv_success = abap_true.
    LOOP AT ms_comm_structure-bp_centr_org
         ASSIGNING FIELD-SYMBOL(<ls_input>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      ASSIGN ms_bp_new-partner-central_data-common TO FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-data-bp_organization = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the CENTRAL ORG data
      lv_object_counter += 1.
      IF lv_object_counter = 1.
        LOOP AT mr_seldat_bp_centr_org->fieldnames
             ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_upd>-datax-bp_organization
                 TO FIELD-SYMBOL(<lv_fieldvalue>).
          <lv_fieldvalue> = abap_true.
        ENDLOOP.
        DATA(ls_bp_datax) = <ls_upd>-datax.
      ELSE.
        <ls_upd>-datax = ls_bp_datax.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_bp_postal_data.
    DATA lv_object_counter TYPE i.

    DATA(lv_partner) = ms_bp_new-partner-header-object_instance-bpartner.
    rv_success = abap_true.

    " API FORMAT: Get the actual valid old address
    READ TABLE ms_bp_old-partner-central_data-address-addresses
         INTO DATA(ls_bp_old_address)
         WITH KEY currently_valid = abap_true.
    IF ls_bp_old_address-data-communication-smtp-smtp IS INITIAL.
      " TO DO: Generate Error - ONLY CHANGE is in scope
      RETURN.
    ENDIF.

    " CDS FORMAT: Get the OLD SMTP data from the CDS view to get the address number
    SELECT FROM zim_mass_bp_addr_postal
      FIELDS *
      WHERE partner = @lv_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_cds_postal_old).

    LOOP AT ms_comm_structure-bp_postal
         ASSIGNING FIELD-SYMBOL(<ls_input_new>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " CDS FORMAT: Get the OLD Address line
      ASSIGN lt_cds_postal_old[ partner    = ms_bp_new-partner-header-object_instance-bpartner
                                addrnumber = <ls_input_new>-addrnumber ] TO FIELD-SYMBOL(<ls_cds_postal_old>).
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        RETURN.
      ENDIF.

      " API FORMAT: Get the OLD Address line
      ASSIGN ms_bp_old-partner-central_data-address-addresses[ data_key-guid = <ls_cds_postal_old>-address_guid ] TO FIELD-SYMBOL(<ls_bp_address_old>).
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        RETURN.
      ENDIF.

      " API FORMAT: Get the old POSTAL Address line
      " TODO: variable is assigned but never used (ABAP cleaner)
      ASSIGN <ls_bp_address_old>-data-postal-data TO FIELD-SYMBOL(<ls_bp_smtp_old>).
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        RETURN.
      ENDIF.

      " API FORMAT: Get the NEW Address line
      ASSIGN ms_bp_new-partner-central_data-address-addresses[ data_key-guid = <ls_cds_postal_old>-address_guid ] TO FIELD-SYMBOL(<ls_bp_addresses_new>).
      IF sy-subrc = 0.
      ELSE.
        APPEND INITIAL LINE
               TO ms_bp_new-partner-central_data-address-addresses
               ASSIGNING <ls_bp_addresses_new>.
      ENDIF.

      " Take over POSTAL DATA FROM OLD VALUE
      <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
      <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).
      <ls_bp_addresses_new>-data-postal-data = CORRESPONDING #( <ls_bp_address_old>-data-postal-data ).

      " Set the change flags for the POSTAL data
      lv_object_counter += 1.
      LOOP AT mr_seldat_bp_postal->fieldnames
           ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
        " Move only the changed fields
        ASSIGN COMPONENT <lv_fieldname>
               OF STRUCTURE <ls_bp_addresses_new>-data-postal-data
               TO FIELD-SYMBOL(<lv_data_fieldvalue>).
        ASSIGN COMPONENT <lv_fieldname>
               OF STRUCTURE <ls_input_new>
               TO FIELD-SYMBOL(<lv_input_fieldvalue>).
        <lv_data_fieldvalue> = <lv_input_fieldvalue>.

        IF lv_object_counter = 1.
          " Manage DATAX structure
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_bp_addresses_new>-data-postal-datax
                 TO FIELD-SYMBOL(<lv_datax_fieldvalue>).
          <lv_datax_fieldvalue> = abap_true.
        ENDIF.
      ENDLOOP.
      IF lv_object_counter = 1.
        DATA(ls_bp_datax) = <ls_bp_addresses_new>-data-postal-datax.
      ELSE.
        <ls_bp_addresses_new>-data-postal-datax = ls_bp_datax.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD copy_bp_smtp_data.
    DATA lv_copy_full TYPE abap_bool.

    lv_copy_full = abap_true.
    IF lv_copy_full = abap_true.
      copy_bp_smtp_data_full( ).
    ELSE.
      copy_bp_smtp_data_delta( ).
    ENDIF.
  ENDMETHOD.

  METHOD copy_bp_smtp_data_full.
    DATA lv_object_counter TYPE i.

    DATA(lv_partner) = ms_bp_new-partner-header-object_instance-bpartner.
    rv_success = abap_true.

    " API FORMAT: Get the actual valid old address
    READ TABLE ms_bp_old-partner-central_data-address-addresses
         INTO DATA(ls_bp_old_address)
         WITH KEY currently_valid = abap_true.
    IF ls_bp_old_address-data-communication-smtp-smtp IS INITIAL.
      " TO DO: Generate Error - ONLY CHANGE is in scope
      RETURN.
    ENDIF.

    " CDS FORMAT: Get the OLD SMTP data from the CDS view to get the address number
    SELECT FROM zim_mass_bp_addr_smtp
      FIELDS *
      WHERE partner = @lv_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_cds_smtp_old).

    LOOP AT ms_comm_structure-bp_smtp
         ASSIGNING FIELD-SYMBOL(<ls_input_new>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " CDS FORMAT: Get the OLD Address line
      ASSIGN lt_cds_smtp_old[ partner    = ms_bp_new-partner-header-object_instance-bpartner
                              addrnumber = <ls_input_new>-addrnumber
                              consnumber = <ls_input_new>-consnumber ] TO FIELD-SYMBOL(<ls_cds_smtp_old>).
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        RETURN.
      ENDIF.

      " API FORMAT: Get the OLD Address line
      ASSIGN ms_bp_old-partner-central_data-address-addresses[ data_key-guid = <ls_cds_smtp_old>-address_guid ] TO FIELD-SYMBOL(<ls_bp_address_old>).
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        RETURN.
      ENDIF.

      " API FORMAT: Get the old SMTP Address line
      " In the loop check whether it IS CHANGED
      LOOP AT <ls_bp_address_old>-data-communication-smtp-smtp
           ASSIGNING FIELD-SYMBOL(<ls_bp_smtp_old>).

        IF <ls_bp_smtp_old>-contact-data-consnumber = <ls_input_new>-consnumber.
          "--------------------------------------------------------------------------
          " The SMTP is being updated
          "--------------------------------------------------------------------------

          " API FORMAT: Get the NEW Address line
          ASSIGN ms_bp_new-partner-central_data-address-addresses[ data_key-guid = <ls_cds_smtp_old>-address_guid ] TO FIELD-SYMBOL(<ls_bp_addresses_new>).
          IF sy-subrc = 0.
            <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
            <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).
          ELSE.
            APPEND INITIAL LINE
                   TO ms_bp_new-partner-central_data-address-addresses
                   ASSIGNING <ls_bp_addresses_new>.
          ENDIF.

          <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
          <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).

          " API FORMAT: Get the NEW SMTP Address line
          ASSIGN <ls_bp_addresses_new>-data-communication-smtp-smtp[
                     contact-data-consnumber = <ls_input_new>-consnumber ] TO FIELD-SYMBOL(<ls_bp_smtp_new>).
          IF sy-subrc = 0.
          ELSE.
            APPEND INITIAL LINE
                   TO <ls_bp_addresses_new>-data-communication-smtp-smtp
                   ASSIGNING <ls_bp_smtp_new>.
          ENDIF.

          <ls_bp_smtp_new>-contact-task = zif_massbp_co=>gc_objtask_update.
          <ls_bp_smtp_new>-contact-data = CORRESPONDING #( <ls_bp_smtp_old>-contact-data ).

          <ls_bp_smtp_new>-contact-datax-consnumber = abap_true.
          <ls_bp_smtp_new>-contact-datax-valid_to   = abap_true.
          <ls_bp_smtp_new>-contact-datax-consnumber = abap_true.

          " Set the updated fields ...
          " Set the change flags for the SMTP data
          lv_object_counter += 1.
          LOOP AT mr_seldat_bp_smtp->fieldnames
               ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
            " Move only the changed fields
            ASSIGN COMPONENT <lv_fieldname>
                   OF STRUCTURE <ls_bp_smtp_new>-contact-data
                   TO FIELD-SYMBOL(<lv_data_fieldvalue>).
            ASSIGN COMPONENT <lv_fieldname>
                   OF STRUCTURE <ls_input_new>
                   TO FIELD-SYMBOL(<lv_input_fieldvalue>).
            <lv_data_fieldvalue> = <lv_input_fieldvalue>.

            IF lv_object_counter = 1.
              " Manage DATAX structure
              ASSIGN COMPONENT <lv_fieldname>
                     OF STRUCTURE <ls_bp_smtp_new>-contact-datax
                     TO FIELD-SYMBOL(<lv_datax_fieldvalue>).
              <lv_datax_fieldvalue> = abap_true.
            ENDIF.
          ENDLOOP.
          IF lv_object_counter = 1.
            DATA(ls_bp_datax) = <ls_bp_smtp_new>-contact-datax.
          ELSE.
            <ls_bp_smtp_new>-contact-datax = ls_bp_datax.
          ENDIF.

        ELSE.
          "--------------------------------------------------------------------------
          " The SMTP is taken over AS IS
          "--------------------------------------------------------------------------

          " API FORMAT: Get the NEW Address line
          ASSIGN ms_bp_new-partner-central_data-address-addresses[ data_key-guid = <ls_cds_smtp_old>-address_guid ] TO <ls_bp_addresses_new>.
          IF sy-subrc = 0.
            <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
            <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).
          ELSE.
            APPEND INITIAL LINE
                   TO ms_bp_new-partner-central_data-address-addresses
                   ASSIGNING <ls_bp_addresses_new>.
          ENDIF.

          <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
          <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).

          " API FORMAT: Get the NEW SMTP Address line WITH THE OLD CONSNUMBER
          ASSIGN <ls_bp_addresses_new>-data-communication-smtp-smtp[
                     contact-data-consnumber = <ls_bp_smtp_old>-contact-data-consnumber ] TO <ls_bp_smtp_new>.
          IF sy-subrc = 0.
            " OLD SMTP Address line is ALREADY taken over
            CONTINUE.
          ELSE.
            APPEND INITIAL LINE
                   TO <ls_bp_addresses_new>-data-communication-smtp-smtp
                   ASSIGNING <ls_bp_smtp_new>.
          ENDIF.

          "<ls_bp_smtp_new>-contact-task = zif_massbp_co=>gc_objtask_update.
          <ls_bp_smtp_new>-contact-data = CORRESPONDING #( <ls_bp_smtp_old>-contact-data ).

          "<ls_bp_smtp_new>-contact-datax-consnumber = abap_true.
          "<ls_bp_smtp_new>-contact-datax-valid_to   = abap_true.
          "<ls_bp_smtp_new>-contact-datax-consnumber = abap_true.

        ENDIF.

      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_bp_smtp_data_delta.
    DATA lv_object_counter TYPE i.

    DATA(lv_partner) = ms_bp_new-partner-header-object_instance-bpartner.
    rv_success = abap_true.

    " API FORMAT: Get the actual valid old address
    READ TABLE ms_bp_old-partner-central_data-address-addresses
         INTO DATA(ls_bp_old_address)
         WITH KEY currently_valid = abap_true.
    IF ls_bp_old_address-data-communication-smtp-smtp IS INITIAL.
      " TO DO: Generate Error - ONLY CHANGE is in scope
      RETURN.
    ENDIF.

    " CDS FORMAT: Get the OLD SMTP data from the CDS view to get the address number
    SELECT FROM zim_mass_bp_addr_smtp
      FIELDS *
      WHERE partner = @lv_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_cds_smtp_old).

    LOOP AT ms_comm_structure-bp_smtp
         ASSIGNING FIELD-SYMBOL(<ls_input_new>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " CDS FORMAT: Get the OLD Address line
      ASSIGN lt_cds_smtp_old[ partner    = ms_bp_new-partner-header-object_instance-bpartner
                              addrnumber = <ls_input_new>-addrnumber
                              consnumber = <ls_input_new>-consnumber ] TO FIELD-SYMBOL(<ls_cds_smtp_old>).
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        RETURN.
      ENDIF.

      " API FORMAT: Get the OLD Address line
      ASSIGN ms_bp_old-partner-central_data-address-addresses[ data_key-guid = <ls_cds_smtp_old>-address_guid ] TO FIELD-SYMBOL(<ls_bp_address_old>).
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        RETURN.
      ENDIF.

      " API FORMAT: Get the old SMTP Address line
      " In the loop check whether it IS CHANGED
      LOOP AT <ls_bp_address_old>-data-communication-smtp-smtp
           ASSIGNING FIELD-SYMBOL(<ls_bp_smtp_old>)
           WHERE contact-data-consnumber = <ls_input_new>-consnumber.

        "--------------------------------------------------------------------------
        " The SMTP is being updated
        "--------------------------------------------------------------------------

        " API FORMAT: Get the NEW Address line
        ASSIGN ms_bp_new-partner-central_data-address-addresses[ data_key-guid = <ls_cds_smtp_old>-address_guid ] TO FIELD-SYMBOL(<ls_bp_addresses_new>).
        IF sy-subrc = 0.
          <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
          <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).
        ELSE.
          APPEND INITIAL LINE
                 TO ms_bp_new-partner-central_data-address-addresses
                 ASSIGNING <ls_bp_addresses_new>.
        ENDIF.

        <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
        <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).

        " API FORMAT: Get the NEW SMTP Address line
        ASSIGN <ls_bp_addresses_new>-data-communication-smtp-smtp[ contact-data-consnumber = <ls_input_new>-consnumber ] TO FIELD-SYMBOL(<ls_bp_smtp_new>).
        IF sy-subrc = 0.
        ELSE.
          APPEND INITIAL LINE
                 TO <ls_bp_addresses_new>-data-communication-smtp-smtp
                 ASSIGNING <ls_bp_smtp_new>.
        ENDIF.

        <ls_bp_smtp_new>-contact-task = zif_massbp_co=>gc_objtask_update.
        <ls_bp_smtp_new>-contact-data = CORRESPONDING #( <ls_bp_smtp_old>-contact-data ).

        <ls_bp_smtp_new>-contact-datax-consnumber = abap_true.
        <ls_bp_smtp_new>-contact-datax-valid_to   = abap_true.
        <ls_bp_smtp_new>-contact-datax-consnumber = abap_true.

        " Set the updated fields ...
        " Set the change flags for the SMTP data
        lv_object_counter += 1.
        LOOP AT mr_seldat_bp_smtp->fieldnames
             ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
          " Move only the changed fields
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_bp_smtp_new>-contact-data
                 TO FIELD-SYMBOL(<lv_data_fieldvalue>).
          ASSIGN COMPONENT <lv_fieldname>
                 OF STRUCTURE <ls_input_new>
                 TO FIELD-SYMBOL(<lv_input_fieldvalue>).
          <lv_data_fieldvalue> = <lv_input_fieldvalue>.

          IF lv_object_counter = 1.
            " Manage DATAX structure
            ASSIGN COMPONENT <lv_fieldname>
                   OF STRUCTURE <ls_bp_smtp_new>-contact-datax
                   TO FIELD-SYMBOL(<lv_datax_fieldvalue>).
            <lv_datax_fieldvalue> = abap_true.
          ENDIF.
        ENDLOOP.
        IF lv_object_counter = 1.
          DATA(ls_bp_datax) = <ls_bp_smtp_new>-contact-datax.
        ELSE.
          <ls_bp_smtp_new>-contact-datax = ls_bp_datax.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_bp_phone_data.
    DATA lv_object_counter TYPE i.

    DATA(lv_partner) = ms_bp_new-partner-header-object_instance-bpartner.
    rv_success = abap_true.

    " API FORMAT: Get the actual valid old address
    READ TABLE ms_bp_old-partner-central_data-address-addresses
         INTO DATA(ls_bp_old_address)
         WITH KEY currently_valid = abap_true.
    IF ls_bp_old_address-data-communication-phone-phone IS INITIAL.
      " TO DO: Generate Error - ONLY CHANGE is in scope
      RETURN.
    ENDIF.

    " CDS FORMAT: Get the OLD SMTP data from the CDS view to get the address number
    SELECT FROM zim_mass_bp_addr_phone
      FIELDS *
      WHERE partner = @lv_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_cds_phone_old).

    LOOP AT ms_comm_structure-bp_phone
         ASSIGNING FIELD-SYMBOL(<ls_input_new>)
         WHERE partner = ms_bp_new-partner-header-object_instance-bpartner.

      " CDS FORMAT: Get the OLD Address line
      ASSIGN lt_cds_phone_old[ partner    = ms_bp_new-partner-header-object_instance-bpartner
                               addrnumber = <ls_input_new>-addrnumber
                               consnumber = <ls_input_new>-consnumber ] TO FIELD-SYMBOL(<ls_cds_phone_old>).
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        RETURN.
      ENDIF.

      " API FORMAT: Get the OLD Address line
      ASSIGN ms_bp_old-partner-central_data-address-addresses[ data_key-guid = <ls_cds_phone_old>-address_guid ] TO FIELD-SYMBOL(<ls_bp_address_old>).
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        RETURN.
      ENDIF.

      " API FORMAT: Get the old PHONE Address line
      " In the loop check whether it IS CHANGED
      LOOP AT <ls_bp_address_old>-data-communication-phone-phone
           ASSIGNING FIELD-SYMBOL(<ls_bp_phone_old>).

        IF <ls_bp_phone_old>-contact-data-consnumber = <ls_input_new>-consnumber.
          "--------------------------------------------------------------------------
          " The PHONE is being updated
          "--------------------------------------------------------------------------

          " API FORMAT: Get the NEW Address line
          ASSIGN ms_bp_new-partner-central_data-address-addresses[ data_key-guid = <ls_cds_phone_old>-address_guid ] TO FIELD-SYMBOL(<ls_bp_addresses_new>).
          IF sy-subrc = 0.
          ELSE.
            APPEND INITIAL LINE
                   TO ms_bp_new-partner-central_data-address-addresses
                   ASSIGNING <ls_bp_addresses_new>.
          ENDIF.

          <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
          <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).

          " API FORMAT: Get the NEW PHONE Address line
          ASSIGN <ls_bp_addresses_new>-data-communication-phone-phone[
                     contact-data-consnumber = <ls_input_new>-consnumber ] TO FIELD-SYMBOL(<ls_bp_phone_new>).
          IF sy-subrc = 0.
          ELSE.
            APPEND INITIAL LINE
                   TO <ls_bp_addresses_new>-data-communication-phone-phone
                   ASSIGNING <ls_bp_phone_new>.
          ENDIF.

          <ls_bp_phone_new>-contact-task = zif_massbp_co=>gc_objtask_update.
          <ls_bp_phone_new>-contact-data = CORRESPONDING #( <ls_bp_phone_old>-contact-data ).

          <ls_bp_phone_new>-contact-datax-valid_from = abap_true.
          <ls_bp_phone_new>-contact-datax-valid_to   = abap_true.
          <ls_bp_phone_new>-contact-datax-consnumber = abap_true.

          " Set the updated fields ...
          " Set the change flags for the PHONE data
          lv_object_counter += 1.
          LOOP AT mr_seldat_bp_phone->fieldnames
               ASSIGNING FIELD-SYMBOL(<lv_fieldname>).
            " Move only the changed fields
            ASSIGN COMPONENT <lv_fieldname>
                   OF STRUCTURE <ls_bp_phone_new>-contact-data
                   TO FIELD-SYMBOL(<lv_data_fieldvalue>).
            ASSIGN COMPONENT <lv_fieldname>
                   OF STRUCTURE <ls_input_new>
                   TO FIELD-SYMBOL(<lv_input_fieldvalue>).
            <lv_data_fieldvalue> = <lv_input_fieldvalue>.

            IF lv_object_counter = 1.
              " Manage DATAX structure
              ASSIGN COMPONENT <lv_fieldname>
                     OF STRUCTURE <ls_bp_phone_new>-contact-datax
                     TO FIELD-SYMBOL(<lv_datax_fieldvalue>).
              <lv_datax_fieldvalue> = abap_true.
            ENDIF.
          ENDLOOP.
          IF lv_object_counter = 1.
            DATA(ls_bp_datax) = <ls_bp_phone_new>-contact-datax.
          ELSE.
            <ls_bp_phone_new>-contact-datax = ls_bp_datax.
          ENDIF.
        ELSE.
          "--------------------------------------------------------------------------
          " The PHONE is taken over AS IS
          "--------------------------------------------------------------------------

          " API FORMAT: Get the NEW Address line
          ASSIGN ms_bp_new-partner-central_data-address-addresses[ data_key-guid = <ls_cds_phone_old>-address_guid ] TO <ls_bp_addresses_new>.
          IF sy-subrc = 0.
            <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
            <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).
          ELSE.
            APPEND INITIAL LINE
                   TO ms_bp_new-partner-central_data-address-addresses
                   ASSIGNING <ls_bp_addresses_new>.
          ENDIF.

          <ls_bp_addresses_new>-task     = zif_massbp_co=>gc_objtask_update.
          <ls_bp_addresses_new>-data_key = CORRESPONDING #( <ls_bp_address_old>-data_key ).

          " API FORMAT: Get the NEW SMTP Address line WITH THE OLD CONSNUMBER
          ASSIGN <ls_bp_addresses_new>-data-communication-phone-phone[
                     contact-data-consnumber = <ls_bp_phone_old>-contact-data-consnumber ] TO <ls_bp_phone_new>.
          IF sy-subrc = 0.
            " OLD SMTP Address line is ALREADY taken over
            CONTINUE.
          ELSE.
            APPEND INITIAL LINE
                   TO <ls_bp_addresses_new>-data-communication-phone-phone
                   ASSIGNING <ls_bp_phone_new>.
          ENDIF.

          "<ls_bp_phone_new>-contact-task = zif_massbp_co=>gc_objtask_update.
          <ls_bp_phone_new>-contact-data = CORRESPONDING #( <ls_bp_phone_old>-contact-data ).

          "<ls_bp_phone_new>-contact-datax-consnumber = abap_true.
          "<ls_bp_phone_new>-contact-datax-valid_to   = abap_true.
          "<ls_bp_phone_new>-contact-datax-consnumber = abap_true.

        ENDIF.

      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD initialize.
    CLEAR mr_seldat_bp_centr_org.
    CLEAR mr_seldat_bp_postal.
    CLEAR mr_seldat_bp_smtp.
    CLEAR mr_seldat_bp_phone.

    CLEAR mr_seldat_cust_central.
    CLEAR mr_seldat_cust_company.
    CLEAR mr_seldat_cust_sales.

    CLEAR mr_seldat_vend_central.
    CLEAR mr_seldat_vend_company.
    CLEAR mr_seldat_vend_purch.

    CLEAR mra_kunnr.
    CLEAR mt_bp_old.
    CLEAR mt_bp_new.
    CLEAR mt_bapiretm.
  ENDMETHOD.

  METHOD determine_kunnr_range.
    CLEAR mra_kunnr.
    mra_kunnr = VALUE #( FOR <line> IN ms_comm_structure-customer_central
                         ( sign   = 'I'
                           option = 'EQ'
                           low    = <line>-kunnr ) ).
    SORT mra_kunnr.
    DELETE ADJACENT DUPLICATES FROM mra_kunnr
           COMPARING ALL FIELDS.
  ENDMETHOD.

  METHOD determine_partner_range.
    CLEAR mra_partner.
    mra_partner = VALUE #( FOR <line> IN ms_comm_structure-bp_centr_org
                           ( sign   = 'I'
                             option = 'EQ'
                             low    = <line>-partner ) ).
    SORT mra_partner.
    DELETE ADJACENT DUPLICATES FROM mra_partner
           COMPARING ALL FIELDS.
  ENDMETHOD.
ENDCLASS.
