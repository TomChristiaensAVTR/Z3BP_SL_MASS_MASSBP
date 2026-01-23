*&---------------------------------------------------------------------*
*& Report z_massbp_test_modify_02
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_massbp_test_modify_02.

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

    DATA ms_comm_update TYPE zcl_massbp_upd_0cont=>gty_comm_update_as_value READ-ONLY.

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

    " Set the ms_comm_update communication Structure .
    LOOP AT lt_zim_mass_bp_kna1
         ASSIGNING FIELD-SYMBOL(<ls_zim_mass_bp_kna1>).
      <ls_zim_mass_bp_kna1>-zz1_crreason_cus = sy-uzeit.
      APPEND CORRESPONDING #( <ls_zim_mass_bp_kna1> )
             TO ms_comm_update-customer_central.
    ENDLOOP.
    LOOP AT lt_zim_mass_bp_knb1
         ASSIGNING FIELD-SYMBOL(<ls_zim_mass_bp_knb1>).
      APPEND CORRESPONDING #( <ls_zim_mass_bp_knb1> )
             TO ms_comm_update-customer_company.
    ENDLOOP.
    LOOP AT lt_zim_mass_bp_knvv
         ASSIGNING FIELD-SYMBOL(<ls_zim_mass_bp_knvv>).
      APPEND CORRESPONDING #( <ls_zim_mass_bp_knvv> )
             TO ms_comm_update-customer_sales.
    ENDLOOP.
    LOOP AT lt_zim_mass_bp_addr_postal
         ASSIGNING FIELD-SYMBOL(<ls_zim_mass_bp_postal>).
      IF p_postal IS NOT INITIAL.
        <ls_zim_mass_bp_postal>-city = p_city.
      ENDIF.
      APPEND CORRESPONDING #( <ls_zim_mass_bp_postal> )
             TO ms_comm_update-bp_postal.
    ENDLOOP.
    LOOP AT lt_zim_mass_bp_addr_smtp
         ASSIGNING FIELD-SYMBOL(<ls_zim_mass_bp_smtp>).
      IF p_smtp IS NOT INITIAL.
        <ls_zim_mass_bp_smtp>-e_mail = p_mail.
      ENDIF.
      APPEND CORRESPONDING #( <ls_zim_mass_bp_smtp> )
             TO ms_comm_update-bp_smtp.
    ENDLOOP.

    IF p_postal IS NOT INITIAL.
      ms_comm_update-seldata = VALUE #(
        BASE ms_comm_update-seldata
        ( tabname-name      = 'ZEM_MBPADDRPOST'
          tabname-lower_tab = 'ZMASSBP_CUST_CENTRAL'
          tabname-name_db   = 'ZEM_MBPADDRPOST'
          tabname-sel_func  = ''
          tabname-no_newseg = 'X'
          tabname-new_only  = ''
          tabname-tabtext   = 'BP Postal Address'
          keyfieldnames     = VALUE #( ( 'PARTNER' )
                                       ( 'ADDRNUMBER' ) )
          fieldnames        = VALUE #( ( 'CITY' ) ) ) ).
    ENDIF.
    IF p_smtp IS NOT INITIAL.
      ms_comm_update-seldata = VALUE #(
        BASE ms_comm_update-seldata
        ( tabname-name      = 'ZEM_MBPADDRSMTP'
          tabname-lower_tab = 'ZMASSBP_CUST_CENTRAL'
          tabname-name_db   = 'ZEM_MBPADDRSMTP'
          tabname-sel_func  = ''
          tabname-no_newseg = 'X'
          tabname-new_only  = ''
          tabname-tabtext   = 'BP SMTP Address'
          keyfieldnames     = VALUE #( ( 'PARTNER' )
                                       ( 'ADDRNUMBER' )
                                       ( 'CONSNUMBER' ) )
          fieldnames        = VALUE #( ( 'E_MAIL' ) ) ) ).
    ENDIF.
    ms_comm_update-seldata = VALUE #(
      BASE ms_comm_update-seldata
      ( tabname-name      = 'ZMASSBP_CUST_CENTRAL'
        tabname-lower_tab = 'ZMASSBP_CUST_CENTRAL'
        tabname-name_db   = 'ZMASSBP_CUST_CENTRAL'
        tabname-sel_func  = 'Z_MASSBP_SEL_CUST_CENTRAL'
        tabname-no_newseg = 'X'
        tabname-new_only  = ''
        tabname-tabtext   = 'CUSTOMER Central Data'
        keyfieldnames     = VALUE #( ( 'PARTNER' ) )
        fieldnames        = VALUE #( ( 'ZZ1_CRREASON_CUS' ) ) ) ).

    DATA lo_single_modifier TYPE REF TO zcl_massbp_para_mod_v02.
    lo_single_modifier = NEW #(  ).
    lo_single_modifier->set_comm_structure( ms_comm_update ).
    lo_single_modifier->process(  ).

    DATA(lo_output) = cl_demo_output=>new( ).
    lo_output->write_data( lo_single_modifier->mt_bapiretm[ 1 ]-object_msg ).
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
