"! <p class="shorttext synchronized">Mass Upd BP - Modifier - Parallel - Full Scope</p>
CLASS zcl_massbp_para_mod_v02 DEFINITION
  PUBLIC
  INHERITING FROM zcl_massbp_para_mod_0abs
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA ms_comm_structure TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value READ-ONLY.
    DATA mv_guid           TYPE bu_partner_guid                                READ-ONLY.
    DATA mra_kunnr         TYPE RANGE OF kunnr                                 READ-ONLY.

    METHODS process REDEFINITION.

    METHODS constructor
      IMPORTING is_comm_update TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value OPTIONAL.

    "! <p class="shorttext synchronized">Initialize</p>
    METHODS initialize.

    "! <p class="shorttext synchronized">Setter - Communication Structure</p>
    METHODS set_comm_structure
      IMPORTING is_comm_structure TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value.

  PROTECTED SECTION.
    DATA mr_seldat_cust_central TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_cust_company TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_cust_sales   TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_bp_centr_org TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_bp_postal    TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_bp_smtp      TYPE REF TO mass_wa_tabdata.
    DATA mr_seldat_bp_phone     TYPE REF TO mass_wa_tabdata.

  PRIVATE SECTION.
    "! <p class="shorttext synchronized">Take Over COMPANY Data</p>
    METHODS copy_cust_company_data.
    "! <p class="shorttext synchronized">Take Over SALES Data</p>
    METHODS copy_cust_sales_data.
    "! <p class="shorttext synchronized">Take Over CENTRAL ORGANIZATIONAL Data</p>
    METHODS copy_bp_centr_org_data.
    "! <p class="shorttext synchronized">Take Over POSTAL Data</p>
    METHODS copy_bp_postal_data.
    "! <p class="shorttext synchronized">Take Over SMTP Data</p>
    METHODS copy_bp_smtp_data.
    "! <p class="shorttext synchronized">Take Over SMTP Data - Full</p>
    METHODS copy_bp_smtp_data_full.
    "! <p class="shorttext synchronized">Take Over SMTP Data - Delta</p>
    METHODS copy_bp_smtp_data_delta.
    "! <p class="shorttext synchronized">Take Over PHONE Data</p>
    METHODS copy_bp_phone_data.
    "! <p class="shorttext synchronized">Determine Dimension FLAGS - Full</p>
    METHODS determine_seldat_flags.
    "! <p class="shorttext synchronized">Determine Range of Customers</p>
    METHODS determine_kunnr_range.

ENDCLASS.



CLASS ZCL_MASSBP_PARA_MOD_V02 IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).
    ms_comm_structure = is_comm_update.
  ENDMETHOD.


  METHOD set_comm_structure.
    ms_comm_structure = is_comm_structure.
  ENDMETHOD.


  METHOD process.

    DATA ls_bapiret2  TYPE bapiret2.
    DATA lt_customers TYPE zcl_massbp_data_reader_01=>tt_kunnr.

    initialize( ).

    " Central data should ALWAYS be present ...
    IF ms_comm_structure-customer_central IS INITIAL.
      RETURN.
    ENDIF.

    " Central data should ALWAYS be present ...
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_cust_central
         WITH KEY tabname-name = zif_massbp_co=>gc_table_cust_central.
    IF sy-subrc <> 0.
      " ERROR !! - TO DO: Log ERROR
      RETURN.
    ENDIF.

    " COMPANY, SALES, POSTAL, CENTRAL ORG, POSTAL, PHONE, SMTP data CAN be present ...
    determine_seldat_flags( ).

    " Setup of a range of involved customers
    determine_kunnr_range( ).

    " Get the OLD BP DATA ...
    lt_customers = CORRESPONDING #( mra_kunnr[] MAPPING kunnr = low ).
    DATA(lo_reader) = zcl_massbp_data_reader_01=>get_instance( ).
    lo_reader->get_bp_from_customer( EXPORTING it_customers         = lt_customers
                                               iv_bypass_buffer     = abap_false
                                               iv_scope_full        = abap_true
                                     IMPORTING et_business_partners = mt_bp_old ).

    LOOP AT ms_comm_structure-customer_central
         ASSIGNING FIELD-SYMBOL(<ls_input_central>).

      " Get the OLD DATA as template ...
      CLEAR ms_bp_old.
      READ TABLE mt_bp_old
           INTO ms_bp_old
           WITH KEY partner-header-object_instance-bpartner = <ls_input_central>-partner.
      IF sy-subrc <> 0.
        " TO DO: Generate Error - ONLY CHANGE is in scope
        CONTINUE.
      ENDIF.

      " UPDATE: Set the context for the BP
      CLEAR ms_bp_new.
      ms_bp_new-partner-header-object_task = zif_massbp_co=>gc_objtask_update.
      ms_bp_new-partner-header-object_instance-bpartner = |{ <ls_input_central>-partner ALPHA = IN }|.

      CLEAR mv_guid.
      CALL FUNCTION 'BUPA_NUMBERS_GET'
        EXPORTING iv_partner      = ms_bp_new-partner-header-object_instance-bpartner
        IMPORTING ev_partner_guid = mv_guid.
      ms_bp_new-partner-header-object_instance-bpartnerguid = mv_guid.

      " Set the context for the KUNNR
      ms_bp_new-customer-header-object_instance-kunnr = |{ <ls_input_central>-kunnr ALPHA = IN }|.

      " Take over CUSTOMER CENTRAL DATA
      ms_bp_new-customer-header-object_task = zif_massbp_co=>gc_objtask_update.
      ms_bp_new-customer-central_data-central-data = CORRESPONDING #( <ls_input_central> ).

      " Set the change flags for the CUSTOMER CENTRAL DATA
      LOOP AT mr_seldat_cust_central->fieldnames
           ASSIGNING FIELD-SYMBOL(<lv_central_fieldname>).
        ASSIGN COMPONENT <lv_central_fieldname>
               OF STRUCTURE ms_bp_new-customer-central_data-central-datax
               TO FIELD-SYMBOL(<lv_central_fieldvalue>).
        <lv_central_fieldvalue> = abap_true.
      ENDLOOP.

      " CUSTOMER COMPANY DATA can be present ...
      IF mr_seldat_cust_company IS BOUND.
        " Take over COMPANY DATA
        copy_cust_company_data( ).
      ENDIF.
      " CUSTOMER SALES DATA can be present ...
      IF mr_seldat_cust_sales IS BOUND.
        " Take over SALES DATA
        copy_cust_sales_data( ).
      ENDIF.
      " BP COMMON ORGANIZATIONAL DATA can be present ...
      IF mr_seldat_bp_centr_org IS BOUND.
        " Take over SALES DATA
        copy_bp_centr_org_data( ).
      ENDIF.
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

      " Do the API Call (In TEST or REAL)
      CLEAR mt_bp_new.
      INSERT ms_bp_new INTO TABLE mt_bp_new.
      cl_md_bp_maintain=>maintain( EXPORTING i_data     = mt_bp_new
                                             i_test_run = ms_comm_structure-testmode
                                   IMPORTING e_return   = mt_bapiretm ).

      DATA(lv_successfull) = is_successfull( mt_bapiretm ).
      IF ms_comm_structure-testmode = abap_false.
        IF lv_successfull = abap_true.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING wait   = abap_true
            IMPORTING return = ls_bapiret2.
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
            IMPORTING return = ls_bapiret2.
        ENDIF.

        " Add the COMMIT/ROLLBACK errors to the return
        DATA(ls_bapiretm) = COND #( WHEN mt_bapiretm IS NOT INITIAL THEN mt_bapiretm[ 1 ] ).
        IF  ls_bapiretm IS NOT INITIAL
        AND ls_bapiret2 IS NOT INITIAL.
          APPEND CORRESPONDING #( ls_bapiret2 )
                 TO ls_bapiretm-object_msg.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD determine_seldat_flags.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_cust_company
         WITH KEY tabname-name = zif_massbp_co=>gc_table_cust_company.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_cust_sales
         WITH KEY tabname-name = zif_massbp_co=>gc_table_cust_sales.
    READ TABLE ms_comm_structure-seldata
         REFERENCE INTO mr_seldat_bp_centr_org
         WITH KEY tabname-name = zif_massbp_co=>gc_table_bp_centr_org.
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


  METHOD copy_cust_company_data.
    DATA lv_object_counter TYPE i.

    LOOP AT ms_comm_structure-customer_company
         ASSIGNING FIELD-SYMBOL(<ls_input>).

      " Take over COMPANY DATA
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

    LOOP AT ms_comm_structure-customer_sales
         ASSIGNING FIELD-SYMBOL(<ls_input>).

      " Take over COMPANY DATA
      APPEND INITIAL LINE TO ms_bp_new-customer-sales_data-sales
             ASSIGNING FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-task = zif_massbp_co=>gc_objtask_update.
      <ls_upd>-data_key-vkorg = <ls_input>-vkorg.
      <ls_upd>-data_key-vtweg = <ls_input>-vtweg.
      <ls_upd>-data_key-spart = <ls_input>-spart.
      <ls_upd>-data = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the COMPANY data
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


  METHOD copy_bp_centr_org_data.
    DATA lv_object_counter TYPE i.

    LOOP AT ms_comm_structure-bp_centr_org
         ASSIGNING FIELD-SYMBOL(<ls_input>).

      ASSIGN ms_bp_new-partner-central_data-common TO FIELD-SYMBOL(<ls_upd>).
      <ls_upd>-data-bp_organization = CORRESPONDING #( <ls_input> ).

      " Set the change flags for the COMPANY data
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

    " API format: Get the actual valid old address
    READ TABLE ms_bp_old-partner-central_data-address-addresses
         INTO DATA(ls_bp_old_address)
         WITH KEY currently_valid = abap_true.
    IF ls_bp_old_address-data-communication-smtp-smtp IS INITIAL.
      " TO DO: Generate Error - ONLY CHANGE is in scope
      RETURN.
    ENDIF.

    " CDS Format: Get the OLD SMTP data from the CDS view to get the address number
    SELECT FROM zim_mass_bp_addr_postal
      FIELDS *
      WHERE partner = @lv_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_cds_postal_old).

    LOOP AT ms_comm_structure-bp_postal
         ASSIGNING FIELD-SYMBOL(<ls_input_new>).

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

    " API format: Get the actual valid old address
    READ TABLE ms_bp_old-partner-central_data-address-addresses
         INTO DATA(ls_bp_old_address)
         WITH KEY currently_valid = abap_true.
    IF ls_bp_old_address-data-communication-smtp-smtp IS INITIAL.
      " TO DO: Generate Error - ONLY CHANGE is in scope
      RETURN.
    ENDIF.

    " CDS Format: Get the OLD SMTP data from the CDS view to get the address number
    SELECT FROM zim_mass_bp_addr_smtp
      FIELDS *
      WHERE partner = @lv_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_cds_smtp_old).

    LOOP AT ms_comm_structure-bp_smtp
         ASSIGNING FIELD-SYMBOL(<ls_input_new>).

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

    " API format: Get the actual valid old address
    READ TABLE ms_bp_old-partner-central_data-address-addresses
         INTO DATA(ls_bp_old_address)
         WITH KEY currently_valid = abap_true.
    IF ls_bp_old_address-data-communication-smtp-smtp IS INITIAL.
      " TO DO: Generate Error - ONLY CHANGE is in scope
      RETURN.
    ENDIF.

    " CDS Format: Get the OLD SMTP data from the CDS view to get the address number
    SELECT FROM zim_mass_bp_addr_smtp
      FIELDS *
      WHERE partner = @lv_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_cds_smtp_old).

    LOOP AT ms_comm_structure-bp_smtp
         ASSIGNING FIELD-SYMBOL(<ls_input_new>).

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

    " API format: Get the actual valid old address
    READ TABLE ms_bp_old-partner-central_data-address-addresses
         INTO DATA(ls_bp_old_address)
         WITH KEY currently_valid = abap_true.
    IF ls_bp_old_address-data-communication-phone-phone IS INITIAL.
      " TO DO: Generate Error - ONLY CHANGE is in scope
      RETURN.
    ENDIF.

    " CDS Format: Get the OLD SMTP data from the CDS view to get the address number
    SELECT FROM zim_mass_bp_addr_phone
      FIELDS *
      WHERE partner = @lv_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_cds_phone_old).

    LOOP AT ms_comm_structure-bp_phone
         ASSIGNING FIELD-SYMBOL(<ls_input_new>).

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
    CLEAR mr_seldat_cust_central.
    CLEAR mr_seldat_cust_company.
    CLEAR mr_seldat_cust_sales.
    CLEAR mr_seldat_bp_centr_org.
    CLEAR mr_seldat_bp_postal.
    CLEAR mr_seldat_bp_smtp.
    CLEAR mr_seldat_bp_phone.

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
ENDCLASS.
