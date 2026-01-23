"! <p class="shorttext synchronized">MASSBP - SEQ/PARA - Use zcl_massbp_para_mod_v02</p>
CLASS zcl_massbp_upd_str_v02 DEFINITION
  PUBLIC
  INHERITING FROM zcl_massbp_upd_str_0abs
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS update REDEFINITION.

  PROTECTED SECTION.
    DATA ms_zmass_c_parallel TYPE zmass_c_parallel.

  PRIVATE SECTION.

    METHODS determine_parallelization
      RETURNING VALUE(rv_parallel_modify) TYPE abap_bool.
ENDCLASS.


CLASS zcl_massbp_upd_str_v02 IMPLEMENTATION.
  METHOD update.
    DATA lv_parallel_debug       TYPE abap_bool.
    DATA lv_parallel_modify      TYPE abap_bool.
    DATA lo_single_modifier      TYPE REF TO zcl_massbp_para_mod_v02.
    DATA ls_comm_update_as_value TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value.
    DATA lt_inst_4modify         TYPE cl_abap_parallel=>t_in_inst_tab.
    DATA lv_error_modify         TYPE abap_bool.

    " Central data should ALWAYS be present ...
    ASSIGN mo_container->ms_comm_update-seldata[ tabname-name = zif_massbp_co=>gc_table_cust_central ] TO FIELD-SYMBOL(<ls_seldat_central>).
    IF sy-subrc <> 0.
      " Log ERROR
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
    lv_parallel_modify = determine_parallelization(  ).

    "---------------------------------------------------------------
    " SELECTION - PREPARE posting in 1 go PER customer
    " Use the CENTRAL TABLE assuming that all customers should be in there.
    " Indeed, at VWR,  for each change the KNA1-ZZ1_CRREASON_CUS needs to be maintained
    "---------------------------------------------------------------
    LOOP AT mo_container->ms_comm_update-ref_customer_central->*
         ASSIGNING FIELD-SYMBOL(<ls_input_central>).

      CLEAR ls_comm_update_as_value.
      ls_comm_update_as_value-seldata  = mo_container->ms_comm_update-seldata.
      ls_comm_update_as_value-testmode = mo_container->ms_comm_update-testmode.

      " Take over CENTRAL DATA
      APPEND CORRESPONDING #( <ls_input_central> )
             TO ls_comm_update_as_value-customer_central.
      " COMPANY DATA can be present ...
      LOOP AT mo_container->ms_comm_update-ref_customer_company->*
           ASSIGNING FIELD-SYMBOL(<ls_input_company>)
           WHERE partner = <ls_input_central>-partner.
        APPEND CORRESPONDING #( <ls_input_company> )
               TO ls_comm_update_as_value-customer_company.
      ENDLOOP.
      " SALES DATA can be present ...
      LOOP AT mo_container->ms_comm_update-ref_customer_sales->*
           ASSIGNING FIELD-SYMBOL(<ls_input_sales>)
           WHERE partner = <ls_input_central>-partner.
        APPEND CORRESPONDING #( <ls_input_sales> )
               TO ls_comm_update_as_value-customer_sales.
      ENDLOOP.
      " BP CENTRAL ORGANIZATIONAL DATA can be present ...
      LOOP AT mo_container->ms_comm_update-ref_bp_centr_org->*
           ASSIGNING FIELD-SYMBOL(<ls_input_centr_org>)
           WHERE partner = <ls_input_central>-partner.
        APPEND CORRESPONDING #( <ls_input_centr_org> )
               TO ls_comm_update_as_value-bp_centr_org.
      ENDLOOP.
      " BP POSTAL DATA can be present ...
      LOOP AT mo_container->ms_comm_update-ref_bp_postal->*
           ASSIGNING FIELD-SYMBOL(<ls_input_postal>)
           WHERE partner = <ls_input_central>-partner.
        APPEND CORRESPONDING #( <ls_input_postal> )
               TO ls_comm_update_as_value-bp_postal.
      ENDLOOP.
      " BP SMTP DATA can be present ...
      LOOP AT mo_container->ms_comm_update-ref_bp_smtp->*
           ASSIGNING FIELD-SYMBOL(<ls_input_smtp>)
           WHERE partner = <ls_input_central>-partner.
        APPEND CORRESPONDING #( <ls_input_smtp> )
               TO ls_comm_update_as_value-bp_smtp.
      ENDLOOP.
      " BP PHONE DATA can be present ...
      LOOP AT mo_container->ms_comm_update-ref_bp_phone->*
           ASSIGNING FIELD-SYMBOL(<ls_input_phone>)
           WHERE partner = <ls_input_central>-partner.
        APPEND CORRESPONDING #( <ls_input_phone> )
               TO ls_comm_update_as_value-bp_phone.
      ENDLOOP.

      IF lv_parallel_modify = abap_true.
        " Setup of a Table with independent decoupled instances for each customer
        lo_single_modifier ?= NEW zcl_massbp_para_mod_v02( ).
        lo_single_modifier->set_comm_structure( is_comm_structure = ls_comm_update_as_value ).
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
        lo_single_modifier->set_comm_structure( ls_comm_update_as_value ).
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

  METHOD determine_parallelization.
    DATA(lv_lines) = lines( mo_container->ms_comm_update-ref_customer_central->* ).
    CLEAR ms_zmass_c_parallel.
    rv_parallel_modify = abap_false.
    SELECT FROM zmass_c_parallel
      FIELDS *
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_zmass_c_parallel).
    IF sy-subrc = 0.
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
    ENDIF.
  ENDMETHOD.
ENDCLASS.
