*&---------------------------------------------------------------------*
*& Report Z_MASSBP_TEST_MODIFY_01
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_massbp_test_modify_01.

PARAMETERS p_bp     TYPE but000-partner.
PARAMETERS p_postal TYPE abap_bool AS CHECKBOX.
PARAMETERS p_city   TYPE char40.
PARAMETERS p_smtp   TYPE abap_bool AS CHECKBOX.
PARAMETERS p_mail   TYPE char40.
PARAMETERS p_phon   TYPE abap_bool AS CHECKBOX.
PARAMETERS p_phone  TYPE char40.

CLASS lcl_controller DEFINITION
  CREATE PRIVATE.

  PUBLIC SECTION.
    DATA mv_bp        TYPE but000-partner.
    DATA ms_bp        TYPE cvis_ei_extern READ-ONLY.
    DATA mt_bp        TYPE cvis_ei_extern_t READ-ONLY.
    DATA mt_bapiretm  TYPE bapiretm READ-ONLY.

    CLASS-METHODS main.

    METHODS constructor
      IMPORTING iv_bp TYPE but000-partner.

  PROTECTED SECTION.
    METHODS process.
    METHODS is_successfull
      IMPORTING it_bapiretm           TYPE bapiretm
      RETURNING VALUE(rv_successfull) TYPE abap_bool.
ENDCLASS.

START-OF-SELECTION.

  lcl_controller=>main( ).

END-OF-SELECTION.

CLASS lcl_controller IMPLEMENTATION.

  METHOD constructor.
    mv_bp = iv_bp.
  ENDMETHOD.

  METHOD main.
    DATA(lo_controller) = NEW lcl_controller( p_bp ).
    lo_controller->process(  ).
  ENDMETHOD.

  METHOD process.
    DATA lv_guid     TYPE bu_partner_guid.
    DATA ls_bapiret2 TYPE bapiret2.

    " READ: Get Data
    DATA(lo_reader) = zcl_massbp_data_reader_01=>get_instance(  ).
    lo_reader->get_bp_from_customer(
      EXPORTING it_customers         = VALUE #( ( CONV #( mv_bp ) ) )
                iv_bypass_buffer     = abap_true
      IMPORTING et_business_partners = DATA(lt_pb_old) ).
    DATA(ls_bp_old) = lt_pb_old[ 1 ].

    SELECT FROM zv_massbp_postal
           FIELDS *
           WHERE partner = @mv_bp
           INTO TABLE @DATA(lt_zv_massbp_postal).
    IF sy-subrc = 0.
      DATA(ls_zv_massbp_postal) = lt_zv_massbp_postal[ 1 ].
    ENDIF.
    SELECT FROM zv_massbp_smtp
           FIELDS *
           WHERE partner = @mv_bp
           INTO TABLE @DATA(lt_zv_massbp_smtp).
    IF sy-subrc = 0.
      DATA(ls_zv_massbp_smtp) = lt_zv_massbp_smtp[ 1 ].
    ENDIF.
    SELECT FROM zim_mass_bp_kna1
           FIELDS *
           WHERE partner = @mv_bp
           INTO TABLE @DATA(lt_zim_mass_bp_kna1).
    IF sy-subrc = 0.
      DATA(ls_zim_mass_bp_kna1) = lt_zim_mass_bp_kna1[ 1 ].
    ENDIF.
    SELECT FROM zim_mass_bp_knb1
           FIELDS *
           WHERE partner = @mv_bp
           INTO TABLE @DATA(lt_zim_mass_bp_knb1).
    IF sy-subrc = 0.
      DATA(ls_zim_mass_bp_knb1) = lt_zim_mass_bp_knb1[ 1 ].
    ENDIF.
    SELECT FROM zim_mass_bp_knvv
           FIELDS *
           WHERE partner = @mv_bp
           INTO TABLE @DATA(lt_zim_mass_bp_knvv).
    IF sy-subrc = 0.
      DATA(ls_zim_mass_bp_knvv) = lt_zim_mass_bp_knvv[ 1 ].
    ENDIF.
    SELECT FROM zim_mass_bp_addr_postal
           FIELDS *
           WHERE partner = @mv_bp
           INTO TABLE @DATA(lt_zim_mass_bp_addr_postal).
    IF sy-subrc = 0.
      DATA(ls_zim_mass_bp_addr_postal) = lt_zim_mass_bp_addr_postal[ 1 ].
    ENDIF.
    SELECT FROM zim_mass_bp_addr_smtp
           FIELDS *
           WHERE partner = @mv_bp
           INTO TABLE @DATA(lt_zim_mass_bp_addr_smtp).
    IF sy-subrc = 0.
      DATA(ls_zim_mass_bp_addr_smtp) = lt_zim_mass_bp_addr_smtp[ 1 ].
    ENDIF.
    SELECT FROM zim_mass_bp_addr_phone
           FIELDS *
           WHERE partner = @mv_bp
           INTO TABLE @DATA(lt_zim_mass_bp_addr_phone).
    IF sy-subrc = 0.
      DATA(ls_zim_mass_bp_addr_phone) = lt_zim_mass_bp_addr_phone[ 1 ].
    ENDIF.

    " MODIFY: Set the context for the BP
    CLEAR me->ms_bp.
    me->ms_bp-partner-header-object_task = zif_massbp_co=>gc_objtask_update.
    me->ms_bp-partner-header-object_instance-bpartner = |{ mv_bp ALPHA = IN }|.

    CLEAR lv_guid.
    CALL FUNCTION 'BUPA_NUMBERS_GET'
      EXPORTING
        iv_partner      = me->ms_bp-partner-header-object_instance-bpartner
      IMPORTING
        ev_partner_guid = lv_guid.
    me->ms_bp-partner-header-object_instance-bpartnerguid = lv_guid.

    " Change the name ...
    me->ms_bp-partner-central_data-common-data-bp_organization-name3 = |{ sy-datum }_{ sy-uzeit }|.
    me->ms_bp-partner-central_data-common-datax-bp_organization-name3 = abap_true.

    "" Set the context for the KUNNR
    "me->ms_bp-customer-header-object_instance-kunnr = |{ mv_bp ALPHA = IN }|.

    IF p_postal = abap_true
    OR p_smtp   = abap_true
    OR p_phon   = abap_true.

      " Change the Address ...

      " DO NOT SET THIS !! - this overwrites the whole address if passed along ;..
      "me->ms_bp-partner-central_data-address-current_state = abap_true.

      APPEND VALUE #( task = zif_massbp_co=>gc_objtask_update )
             TO me->ms_bp-partner-central_data-address-addresses
             ASSIGNING FIELD-SYMBOL(<ls_centraldata_address>).

      " Set the BP ADDRESS GUID
      <ls_centraldata_address>-data_key-guid = ls_zv_massbp_postal-address_guid.

      " Get the OLD ADDRESS ...
      DATA(ls_centraldata_address_old) = ls_bp_old-partner-central_data-address-addresses[ currently_valid = abap_true ].

      IF p_city IS NOT INITIAL.
        <ls_centraldata_address>-data-postal-data = CORRESPONDING #( ls_centraldata_address_old-data-postal-data ).
        " Then start changing the new fields ...

        <ls_centraldata_address>-data-postal-data-city      = p_city.
        <ls_centraldata_address>-data-postal-datax-city     = abap_true.
        <ls_centraldata_address>-data-postal-data-country   = 'BE'.
        <ls_centraldata_address>-data-postal-datax-country  = abap_true.
        <ls_centraldata_address>-data-postal-data-house_no  = sy-uzeit.
        <ls_centraldata_address>-data-postal-datax-house_no = abap_true.

      ENDIF.

      IF p_mail IS NOT INITIAL.
        DATA(ls_smtp_old) = ls_centraldata_address_old-data-communication-smtp-smtp[ currently_valid = abap_true ].
        READ TABLE <ls_centraldata_address>-data-communication-smtp-smtp
             ASSIGNING FIELD-SYMBOL(<ls_communication_smtp_new>)
             INDEX 1.
        IF sy-subrc <> 0.
          APPEND VALUE #( contact-task = zif_massbp_co=>gc_objtask_update
                          contact-data = CORRESPONDING #( ls_smtp_old-contact ) )
                 TO <ls_centraldata_address>-data-communication-smtp-smtp
                 ASSIGNING <ls_communication_smtp_new>.
        ENDIF.

        <ls_communication_smtp_new>-contact-data = CORRESPONDING #( ls_smtp_old-contact-data ).
        <ls_communication_smtp_new>-comm_usage   = CORRESPONDING #( ls_smtp_old-comm_usage ).
        "LOOP AT <ls_communication_smtp_new>-comm_usage-comm_usages
        "     ASSIGNING FIELD-SYMBOL(<ls_comm_usage>).
        "  <ls_comm_usage>-task  = zif_massbp_co=>gc_objtask_update.
        "  <ls_comm_usage>-datax-def_usage  = abap_true.
        "  <ls_comm_usage>-datax-valid_from = abap_true.
        " ENDLOOP.

        <ls_communication_smtp_new>-contact-data-e_mail  = p_mail.
        <ls_communication_smtp_new>-contact-datax-e_mail = abap_true.
        <ls_communication_smtp_new>-contact-datax-valid_from = abap_true.
        <ls_communication_smtp_new>-contact-datax-valid_to   = abap_true.

        <ls_communication_smtp_new>-contact-datax-consnumber = abap_true.
      ENDIF.
    ENDIF.

    " See https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/5a1b852d92f6427c92b045409b8f1680/53872683ee3046f7ab517c1a2bcc3ab7.html?version=1709+001
    INSERT me->ms_bp INTO TABLE mt_bp.
    cl_md_bp_maintain=>maintain( EXPORTING i_data   = mt_bp
                                 IMPORTING e_return = mt_bapiretm ).
    DATA(lv_successfull) = is_successfull( mt_bapiretm ).
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

    DATA(lo_output) = cl_demo_output=>new( ).
    lo_output->write_data( mt_bapiretm[ 1 ]-object_msg ).
    lo_output->display( ).
  ENDMETHOD.

  METHOD is_successfull.

    rv_successfull = abap_true.
    LOOP AT it_bapiretm
         INTO DATA(ls_bapiretm).

      LOOP AT ls_bapiretm-object_msg
           INTO DATA(ls_object_msg).

        IF    ls_object_msg-type = 'E'
           OR ls_object_msg-type = 'A'.
          " Error occurred
          rv_successfull = abap_false.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
