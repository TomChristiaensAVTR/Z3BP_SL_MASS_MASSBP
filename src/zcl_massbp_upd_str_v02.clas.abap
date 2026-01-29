"! <p class="shorttext synchronized">MASSBP - SEQ/PARA - Use zcl_massbp_para_mod_v02</p>
CLASS zcl_massbp_upd_str_v02 DEFINITION
  PUBLIC
  INHERITING FROM zcl_massbp_upd_str_0abs
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS update REDEFINITION.

  PROTECTED SECTION.
    DATA ms_zmass_c_parallel     TYPE zmass_c_parallel.
    DATA mr_input_central        TYPE REF TO zem_mbpcentrorg.
    DATA ms_comm_update_as_value TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value.

  PRIVATE SECTION.
    METHODS determine_parallelization
      RETURNING VALUE(rv_parallel_modify) TYPE abap_bool.

    METHODS determine_seldat_kna1
      CHANGING cs_comm_update_as_value TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value.

    METHODS determine_seldat_lfa1
      CHANGING cs_comm_update_as_value TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value.

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

    "! <p class="shorttext synchronized">Take Over PHONE Data</p>
    METHODS copy_bp_phone_data
      RETURNING VALUE(rv_success) TYPE abap_bool.

ENDCLASS.


CLASS zcl_massbp_upd_str_v02 IMPLEMENTATION.
  METHOD update.
    DATA lv_parallel_debug  TYPE abap_bool.
    DATA lv_parallel_modify TYPE abap_bool.
    DATA lo_single_modifier TYPE REF TO zcl_massbp_para_mod_v02.
    DATA lt_inst_4modify    TYPE cl_abap_parallel=>t_in_inst_tab.
    DATA lv_error_modify    TYPE abap_bool.

    " Central organizational data should ALWAYS be present ...
    ASSIGN mo_container->ms_comm_update-seldata[ tabname-name = zif_massbp_co=>gc_table_bp_centr_org ] TO FIELD-SYMBOL(<ls_seldat_central>).
    IF sy-subrc <> 0.
      " Log ERROR & Bail out ...
      APPEND VALUE #( )
             TO mo_container->ms_comm_update-ref_msg->*
             ASSIGNING FIELD-SYMBOL(<ls_msg>).
      DATA ls_bapiret2 TYPE bapiret2 ##NEEDED.
      CLEAR ls_bapiret2.
      MESSAGE ID     'ZMASSBP'
              TYPE   'S'
              NUMBER '002'
              INTO   ls_bapiret2-message.
      <ls_msg>-msgty = sy-msgty.
      <ls_msg>-msgid = sy-msgid.
      <ls_msg>-msgno = sy-msgno.
      <ls_msg>-msgv1 = sy-msgv1.
      <ls_msg>-msgv2 = sy-msgv2.
      <ls_msg>-msgv3 = sy-msgv3.
      <ls_msg>-msgv4 = sy-msgv4.
      RETURN.
    ENDIF.

    "---------------------------------------------------------------
    " Decide whether to parallelize ...
    "---------------------------------------------------------------
    lv_parallel_modify = determine_parallelization( ).

    "---------------------------------------------------------------
    " SELECTION - PREPARE posting in 1 go PER BP (customer and/or vendor)
    " Use the CENTRAL TABLE assuming that all BP's should be in there.
    " Indeed, at VWR the below rules apply:
    " - for each customer change the KNA1-ZZ1_CRREASON_CUS needs to be maintained ...
    " - for each vendor change the LFA1-ZZ1_S_CRREASON_SUP needs to be maintained ...
    " - for each change to common structures (addresses), both need to be maintained ...
    "---------------------------------------------------------------
    LOOP AT mo_container->ms_comm_update-ref_bp_centr_org->*
         REFERENCE INTO mr_input_central.

      CLEAR ms_comm_update_as_value.
      ms_comm_update_as_value-seldata  = mo_container->ms_comm_update-seldata.
      ms_comm_update_as_value-testmode = mo_container->ms_comm_update-testmode.

      " Take over CENTRAL ORGNIZATIONAL DATA
      APPEND CORRESPONDING #( mr_input_central->* )
             TO ms_comm_update_as_value-bp_centr_org.

      " CUSTOMER CENTRAL DATA can be present ...
      copy_cust_central_data( ).

      " CUSTOMER COMPANY DATA can be present ...
      copy_cust_company_data( ).

      " CUSTOMER SALES DATA can be present ...
      copy_cust_sales_data( ).

      " CUSTOMER TAX DATA can be present ...
      copy_cust_tax_data( ).

      " VENDOR CENTRAL DATA can be present ...
      copy_vend_central_data( ).

      " VENDOR COMPANY DATA can be present ...
      copy_vend_company_data( ).

      " VENDOR PURCHASING DATA can be present ...
      copy_vend_purch_data( ).

      " BP POSTAL DATA can be present ...
      copy_bp_postal_data( ).

      " BP SMTP DATA can be present ...
      copy_bp_smtp_data( ).

      " BP PHONE DATA can be present ...
      copy_bp_phone_data( ).


      IF lv_parallel_modify = abap_true.
        " Setup of a Table with independent decoupled instances for each customer
        lo_single_modifier ?= NEW zcl_massbp_para_mod_v02( ).
        lo_single_modifier->set_comm_structure( is_comm_structure = ms_comm_update_as_value ).
        APPEND lo_single_modifier
               TO lt_inst_4modify.
      ELSE.
        " ------------------------------------------------------------------------------
        " DIRECT SEQUENTIALLY call API per PARTNER - doing all changes in 1 GO & Check Result
        " See https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/5a1b852d92f6427c92b045409b8f1680/53872683ee3046f7ab517c1a2bcc3ab7.html?version=1709+001
        " ------------------------------------------------------------------------------
        IF lo_single_modifier IS NOT BOUND.
          lo_single_modifier ?= NEW zcl_massbp_para_mod_v02( ).
        ENDIF.
        " Set the COMMUNICATION Structure
        lo_single_modifier->initialize( ).
        lo_single_modifier->set_comm_structure( ms_comm_update_as_value ).
        " Post the result
        lo_single_modifier->process( ).
        " Check posting result & update MSG table
        update_msg_at_maintain( EXPORTING io_modifier = lo_single_modifier
                                IMPORTING ev_error    = lv_error_modify ).
      ENDIF.
    ENDLOOP.

    "---------------------------------------------------------------
    " PARALLEL POSTING
    "---------------------------------------------------------------
    IF lv_parallel_modify = abap_true.
      " PARALLEL: Now loop over the different customers to be updated and do parallel update
      DATA(lo_parallel_runner) = NEW cl_abap_parallel( p_percentage = CONV #( ms_zmass_c_parallel-max_utilization )
                                                       p_num_tasks  = ms_zmass_c_parallel-max_procs ).
      " Run each encapsulated instance for change in parallel
      lo_parallel_runner->run_inst( EXPORTING p_in_tab  = lt_inst_4modify     " Table of instances to be processed
                                              p_debug   = lv_parallel_debug   " Force parallel processing for debugging ...
                                    IMPORTING p_out_tab = DATA(lt_out_tab) ).
      LOOP AT lt_out_tab
           INTO DATA(ls_out_tab).
        " Cast the reference to the caller instance.
        CLEAR lo_single_modifier.
        lo_single_modifier ?= ls_out_tab-inst.
        " Collecting the posting results from different sessions.
        IF lo_single_modifier IS BOUND.
          " Check posting result & update MSG table
          update_msg_at_maintain( EXPORTING io_modifier = lo_single_modifier
                                  IMPORTING ev_error    = lv_error_modify ).
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD copy_bp_centr_org_data.
  ENDMETHOD.

  METHOD copy_bp_postal_data.
    LOOP AT mo_container->ms_comm_update-ref_bp_postal->*
         ASSIGNING FIELD-SYMBOL(<ls_input_postal>)
         WHERE partner = mr_input_central->partner.
      APPEND CORRESPONDING #( <ls_input_postal> )
             TO ms_comm_update_as_value-bp_postal.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_bp_smtp_data.
    LOOP AT mo_container->ms_comm_update-ref_bp_smtp->*
         ASSIGNING FIELD-SYMBOL(<ls_input_smtp>)
         WHERE partner = mr_input_central->partner.
      APPEND CORRESPONDING #( <ls_input_smtp> )
             TO ms_comm_update_as_value-bp_smtp.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_bp_phone_data.
    LOOP AT mo_container->ms_comm_update-ref_bp_phone->*
       ASSIGNING FIELD-SYMBOL(<ls_input_phone>)
       WHERE partner = mr_input_central->partner.
      APPEND CORRESPONDING #( <ls_input_phone> )
             TO ms_comm_update_as_value-bp_phone.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_cust_central_data.

    LOOP AT mo_container->ms_comm_update-ref_customer_central->*
         ASSIGNING FIELD-SYMBOL(<ls_input_cust_central>)
         WHERE partner = mr_input_central->partner.

      APPEND CORRESPONDING #( <ls_input_cust_central> )
             TO ms_comm_update_as_value-customer_central
             ASSIGNING FIELD-SYMBOL(<ls_cust_central>).

      " VWR specific: We force the change of ZZ1_CRREASON_CUS in KNA1
      determine_seldat_kna1( CHANGING cs_comm_update_as_value = ms_comm_update_as_value ).
    ENDLOOP.
    IF sy-subrc <> 0.
      " Check whether KNA1 exists ....
      IF mr_input_central->kna1_exists = abap_true.
        SELECT SINGLE FROM zim_mass_bp_cust_centr
          FIELDS *
          WHERE partner = @mr_input_central->partner
          INTO @DATA(ls_zim_mass_bp_cust_centr).
        IF sy-subrc = 0.
          " VWR specific: If no KNA1 record is to be changed, we force the change of ZZ1_CRREASON_CUS in KNA1
          APPEND CORRESPONDING #( ls_zim_mass_bp_cust_centr )
                 TO ms_comm_update_as_value-customer_central
                 ASSIGNING <ls_cust_central>.
          <ls_cust_central>-zz1_crreason_cus = mr_input_central->zz1_crreason_new.
          determine_seldat_kna1( CHANGING cs_comm_update_as_value = ms_comm_update_as_value ).
        ENDIF.
        CLEAR ls_zim_mass_bp_cust_centr.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD copy_cust_company_data.
    LOOP AT mo_container->ms_comm_update-ref_customer_company->*
         ASSIGNING FIELD-SYMBOL(<ls_input_cust_company>)
         WHERE partner = mr_input_central->partner.
      APPEND CORRESPONDING #( <ls_input_cust_company> )
             TO ms_comm_update_as_value-customer_company.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_cust_sales_data.
    LOOP AT mo_container->ms_comm_update-ref_customer_sales->*
         ASSIGNING FIELD-SYMBOL(<ls_input_cust_sales>)
         WHERE partner = mr_input_central->partner.
      APPEND CORRESPONDING #( <ls_input_cust_sales> )
             TO ms_comm_update_as_value-customer_sales.
    ENDLOOP.

  ENDMETHOD.

  METHOD copy_cust_tax_data.
    LOOP AT mo_container->ms_comm_update-ref_customer_tax->*
         ASSIGNING FIELD-SYMBOL(<ls_input_cust_tax>)
         WHERE partner = mr_input_central->partner.
      APPEND CORRESPONDING #( <ls_input_cust_tax> )
             TO ms_comm_update_as_value-customer_tax.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_vend_central_data.
    LOOP AT mo_container->ms_comm_update-ref_vendor_central->*
         ASSIGNING FIELD-SYMBOL(<ls_input_vend_central>)
         WHERE partner = mr_input_central->partner.

      APPEND CORRESPONDING #( <ls_input_vend_central> )
             TO ms_comm_update_as_value-vendor_central
             ASSIGNING FIELD-SYMBOL(<ls_vend_central>).

      " VWR specific: We force the change of ZZ1_S_CRREASON_SUP in LFA1
      determine_seldat_lfa1( CHANGING cs_comm_update_as_value = ms_comm_update_as_value ).
    ENDLOOP.
    IF sy-subrc <> 0.
      " Check whether LFA1 exists ....
      IF mr_input_central->lfa1_exists = abap_true.
        SELECT SINGLE FROM zim_mass_bp_vend_centr
          FIELDS *
          WHERE partner = @mr_input_central->partner
          INTO @DATA(ls_zim_mass_bp_vend_centr).
        IF sy-subrc = 0.
          " VWR specific: If no LFA1 record is to be changed, we force the change of ZZ1_S_CRREASON_SUP in LFA1
          APPEND CORRESPONDING #( ls_zim_mass_bp_vend_centr )
                 TO ms_comm_update_as_value-vendor_central
                 ASSIGNING <ls_vend_central>.
          <ls_vend_central>-zz1_s_crreason_sup = mr_input_central->zz1_crreason_new.
          determine_seldat_lfa1( CHANGING cs_comm_update_as_value = ms_comm_update_as_value ).
        ENDIF.
        CLEAR ls_zim_mass_bp_vend_centr.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD copy_vend_company_data.
    LOOP AT mo_container->ms_comm_update-ref_vendor_company->*
         ASSIGNING FIELD-SYMBOL(<ls_input_vend_company>)
         WHERE partner = mr_input_central->partner.
      APPEND CORRESPONDING #( <ls_input_vend_company> )
             TO ms_comm_update_as_value-vendor_company.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_vend_purch_data.
    LOOP AT mo_container->ms_comm_update-ref_vendor_purch->*
         ASSIGNING FIELD-SYMBOL(<ls_input_vend_purch>)
         WHERE partner = mr_input_central->partner.
      APPEND CORRESPONDING #( <ls_input_vend_purch> )
             TO ms_comm_update_as_value-vendor_purch.
    ENDLOOP.
  ENDMETHOD.

  METHOD determine_parallelization.
    DATA(lv_lines) = lines( mo_container->ms_comm_update-ref_customer_central->* ).
    CLEAR ms_zmass_c_parallel.
    rv_parallel_modify = abap_false.
    SELECT FROM zmass_c_parallel
      FIELDS *
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_zmass_c_parallel).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    READ TABLE lt_zmass_c_parallel
         INTO ms_zmass_c_parallel
         WITH KEY appl_id = zif_massbp_co=>gc_massty_zmassbp.
    IF sy-subrc = 0.
    ELSE.
      READ TABLE lt_zmass_c_parallel
           INTO ms_zmass_c_parallel
           WITH KEY appl_id = ''.
    ENDIF.

    IF     lv_lines             > zif_massbp_co=>gc_para_theshold
       AND ms_zmass_c_parallel IS NOT INITIAL.
      rv_parallel_modify = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD determine_seldat_kna1.
    ASSIGN cs_comm_update_as_value-seldata[ tabname-name = zif_massbp_co=>gc_table_cust_central ] TO FIELD-SYMBOL(<ls_seldat_kna1>).
    IF sy-subrc <> 0.
      APPEND VALUE #( tabname-name      = zif_massbp_co=>gc_table_cust_central
                      tabname-name_db   = zif_massbp_co=>gc_table_cust_central
                      tabname-no_newseg = abap_true
                      tabname-tabtext   = 'Customer KNA1'
                      keyfieldnames     = VALUE #( ( 'PARTNER' ) ) )
             TO cs_comm_update_as_value-seldata
             ASSIGNING <ls_seldat_kna1>.
    ENDIF.
    READ TABLE <ls_seldat_kna1>-fieldnames
         " TODO: variable is assigned but never used (ABAP cleaner)
         ASSIGNING FIELD-SYMBOL(<ls_fn_zz1_crreason_cus>)
         WITH KEY table_line = 'ZZ1_CRREASON_CUS'.
    IF sy-subrc <> 0.
      APPEND CONV #( 'ZZ1_CRREASON_CUS' ) TO <ls_seldat_kna1>-fieldnames.
    ENDIF.
  ENDMETHOD.

  METHOD determine_seldat_lfa1.
    ASSIGN cs_comm_update_as_value-seldata[ tabname-name = zif_massbp_co=>gc_table_vend_central ] TO FIELD-SYMBOL(<ls_seldat_lfa1>).
    IF sy-subrc <> 0.
      APPEND VALUE #( tabname-name      = zif_massbp_co=>gc_table_vend_central
                      tabname-name_db   = zif_massbp_co=>gc_table_vend_central
                      tabname-no_newseg = abap_true
                      tabname-tabtext   = 'Vendor LFA1'
                      keyfieldnames     = VALUE #( ( 'PARTNER' ) ) )
             TO cs_comm_update_as_value-seldata
             ASSIGNING <ls_seldat_lfa1>.
    ENDIF.
    READ TABLE <ls_seldat_lfa1>-fieldnames
         " TODO: variable is assigned but never used (ABAP cleaner)
         ASSIGNING FIELD-SYMBOL(<ls_fn_zz1_crreason_cus>)
         WITH KEY table_line = 'ZZ1_S_CRREASON_SUP'.
    IF sy-subrc <> 0.
      APPEND CONV #( 'ZZ1_S_CRREASON_SUP' ) TO <ls_seldat_lfa1>-fieldnames.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
