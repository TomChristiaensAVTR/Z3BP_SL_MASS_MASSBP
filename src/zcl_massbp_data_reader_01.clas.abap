"! <p class="shorttext synchronized">Mass Upd BP - Reader - (CL_CIF_S4_BPCVI_READER)</p>
CLASS zcl_massbp_data_reader_01 DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_kunnr,
             kunnr TYPE kunnr,
           END OF ty_kunnr.
    TYPES: BEGIN OF ty_lifnr,
             lifnr TYPE lifnr,
           END OF ty_lifnr.
    TYPES: BEGIN OF ty_partners,
             partner TYPE bu_partner,
           END OF ty_partners.
    TYPES: BEGIN OF ty_customer_bp_link,
             partner  TYPE bu_partner,
             kunnr    TYPE kunnr,
             standard TYPE flag,
           END OF ty_customer_bp_link.
    TYPES: BEGIN OF ty_vendor_bp_link,
             partner  TYPE bu_partner,
             lifnr    TYPE lifnr,
             standard TYPE flag,
           END OF ty_vendor_bp_link.
    TYPES: BEGIN OF ty_partner_guids,
             partnerguid TYPE bu_partner_guid,
           END OF ty_partner_guids.
    TYPES tt_roles                  TYPE RANGE OF bu_role.
    TYPES tt_kunnr                  TYPE STANDARD TABLE OF ty_kunnr.
    TYPES tt_lifnr                  TYPE STANDARD TABLE OF ty_lifnr.
    TYPES tt_business_partners      TYPE STANDARD TABLE OF ty_partners.
    TYPES tt_customer_bp_link       TYPE STANDARD TABLE OF ty_customer_bp_link.
    TYPES tt_vendor_bp_link         TYPE STANDARD TABLE OF ty_vendor_bp_link.
    TYPES tt_business_partner_guids TYPE STANDARD TABLE OF ty_partner_guids.

    CLASS-DATA mo_reader TYPE REF TO zcl_massbp_data_reader_01.

    DATA mt_def_sel_scope_bupa      TYPE bus_ei_fragment_t.
    DATA mt_def_sel_scope_customer  TYPE tabname_md_tty.
    DATA mt_def_sel_scope_vendor    TYPE tabname_md_tty.

    DATA mt_full_sel_scope_bupa     TYPE bus_ei_fragment_t.
    DATA mt_full_sel_scope_customer TYPE tabname_md_tty.
    DATA mt_full_sel_scope_vendor   TYPE tabname_md_tty.

    DATA mt_buffered_bp_customer    TYPE cvis_ei_extern_t.
    DATA mt_buffered_bp_vendor      TYPE cvis_ei_extern_t.

    METHODS constructor.

    CLASS-METHODS get_instance
      RETURNING VALUE(ro_reader) TYPE REF TO zcl_massbp_data_reader_01.

    METHODS get_bp_from_customer
      IMPORTING it_customers         TYPE tt_kunnr
                iv_scope_full        TYPE abap_bool DEFAULT abap_true
                iv_refresh_buffer    TYPE boole_d   OPTIONAL
                iv_bypass_buffer     TYPE boole_d   OPTIONAL
      EXPORTING et_business_partners TYPE cvis_ei_extern_t.

    METHODS get_bp_from_vendor
      IMPORTING it_vendors           TYPE tt_lifnr
                iv_scope_full        TYPE abap_bool DEFAULT abap_true
                iv_refresh_buffer    TYPE boole_d   OPTIONAL
                iv_bypass_buffer     TYPE boole_d   OPTIONAL
      EXPORTING et_business_partners TYPE cvis_ei_extern_t.

    METHODS read_customer
      IMPORTING it_customer_numbers TYPE tt_kunnr
                iv_scope_full       TYPE abap_bool      DEFAULT abap_false
                it_sel_scope        TYPE tabname_md_tty OPTIONAL
      EXPORTING et_customers        TYPE cmds_ei_extern_t.

    METHODS read_vendor
      IMPORTING it_vendor_numbers TYPE tt_lifnr
                iv_scope_full     TYPE abap_bool      DEFAULT abap_false
                it_sel_scope      TYPE tabname_md_tty OPTIONAL
      EXPORTING et_vendors        TYPE vmds_ei_extern_t.

    METHODS get_bp_address_from_bp
      IMPORTING it_bp_numbers        TYPE tt_business_partners
                iv_scope_full        TYPE abap_bool         DEFAULT abap_false
                it_sel_scope         TYPE bus_ei_fragment_t OPTIONAL
      EXPORTING et_bp_data           TYPE bus_ei_extern_t
                et_business_partners TYPE cvis_ei_extern_t.

    METHODS read_bp
      IMPORTING it_bp_numbers TYPE tt_business_partners
                iv_scope_full TYPE abap_bool         DEFAULT abap_false
                it_sel_scope  TYPE bus_ei_fragment_t OPTIONAL
      EXPORTING et_bp_data    TYPE bus_ei_extern_t.

    METHODS read_cvi_links_from_bp
      IMPORTING it_bp_numbers     TYPE tt_business_partners
      EXPORTING et_customer_links TYPE tt_customer_bp_link
                et_vendor_links   TYPE tt_vendor_bp_link.
ENDCLASS.



CLASS zcl_massbp_data_reader_01 IMPLEMENTATION.


  METHOD constructor.
    " Business Partner Scope for selection
    " 'BUP010' - Common
    " 'BUP210' - Address Main
    " 'BUP170' - Data Controller
    mt_def_sel_scope_bupa = VALUE #( ( 'BUP010' )
                                     ( 'BUP210' )
                                     ( 'BUP170' ) ).
    mt_full_sel_scope_bupa = VALUE #( ( 'BUP010' )
                                      ( 'BUP210' )
                                      ( 'BUP170' ) ).

    " Customer Scope for selection
    mt_def_sel_scope_customer = VALUE #( ( tabname = 'KNA1' ) ).
    mt_full_sel_scope_customer = VALUE #( ( tabname = 'KNA1' )
                                          " restrict the other segments to be selected
                                          ( tabname = 'KNB1' )
                                          ( tabname = 'KNVV' )
                                          ( tabname = 'KNVP' )
                                          ( tabname = 'KNBK' )
                                          ( tabname = 'KNB5' )
                                          ( tabname = 'KNZA' )
                                          ( tabname = 'KNVL' )
                                          ( tabname = 'KNVI' )
                                          ( tabname = 'KNAS' )
                                          ( tabname = 'KNVA' )
                                          ( tabname = 'WRF12' )
                                          ( tabname = 'WRF4' )
                                          ( tabname = 'VCKUN' )
                                          ( tabname = 'VCNUM' )
                                          ( tabname = 'KNAT' )
                                          ( tabname = 'KNBW' ) ).

    " Vendor Scope for selection
    mt_def_sel_scope_vendor = VALUE #( ( tabname = 'LFA1' ) ).
    mt_full_sel_scope_vendor = VALUE #( ( tabname = 'LFA1' )
                                        ( tabname = 'LFB1' )
                                        ( tabname = 'LFM1' )
                                        ( tabname = 'LFBK' )
                                        ( tabname = 'LFAS' )
                                        ( tabname = 'LFAT' )
                                        ( tabname = 'LFB5' )
                                        ( tabname = 'LFZA' )
                                        ( tabname = 'LFBW' )
                                        ( tabname = 'WYT3' ) ).
  ENDMETHOD.


  METHOD get_instance.
    IF mo_reader IS NOT BOUND.
      mo_reader = NEW #( ).
    ENDIF.
    ro_reader = mo_reader.
  ENDMETHOD.


  METHOD get_bp_from_customer.
    "--------------------------------------------------------------------------
    " TCH - Copied & adapted from CL_CIF_S4_BPCVI_READER~if_cif_s4_bpcvi_reader~get_bp_from_customer.
    "--------------------------------------------------------------------------

    DATA lt_business_partners TYPE cvis_ei_extern_t.
    DATA lt_customer_nos      TYPE tt_kunnr.

    CLEAR et_business_partners.

    IF iv_refresh_buffer = abap_true.
      CLEAR mt_buffered_bp_customer.
    ENDIF.

    IF iv_bypass_buffer = abap_false.
      " skip the customers which are in buffer already and get the missing customers
      LOOP AT it_customers
           ASSIGNING FIELD-SYMBOL(<ls_customers_in>).
        ASSIGN mt_buffered_bp_customer[ customer-header-object_instance-kunnr = <ls_customers_in>-kunnr ] TO FIELD-SYMBOL(<ls_buffered_customers>). "#EC CI_STDSEQ
        IF sy-subrc = 0.
          et_business_partners = VALUE #( BASE et_business_partners
                                          ( <ls_buffered_customers> ) ).
        ELSE.
          lt_customer_nos = VALUE #( BASE lt_customer_nos
                                     ( kunnr = <ls_customers_in>-kunnr ) ).
        ENDIF.
      ENDLOOP.
    ELSE.
      lt_customer_nos = it_customers.
    ENDIF.

    SORT lt_customer_nos BY kunnr.
    DELETE ADJACENT DUPLICATES FROM lt_customer_nos
           COMPARING kunnr.

    IF lt_customer_nos[] IS INITIAL.
      RETURN.
    ENDIF.

    " CVI Links - Customer to BP
    SELECT c~partner,
           c~partner_guid,
           a~kunnr
      FROM kna1 AS a
             INNER JOIN
               cvi_cust_link AS b ON a~kunnr = b~customer
                 INNER JOIN
                   but000 AS c ON b~partner_guid = c~partner_guid
      INTO TABLE @DATA(lt_customer_links)  ##ITAB_KEY_IN_SELECT
      FOR ALL ENTRIES IN @lt_customer_nos
      WHERE a~kunnr      = @lt_customer_nos-kunnr
        AND a~cvp_xblck <> 'X'
        AND c~xpcpt     <> 'X'.

    SORT lt_customer_links BY partner.

    " Partial/Full Scope Reading ...
    read_bp( EXPORTING it_bp_numbers = CORRESPONDING #( lt_customer_links )
                       iv_scope_full = iv_scope_full
             IMPORTING et_bp_data    = DATA(lt_bp_data) ).
    " Partial/Full Scope Reading ...
    read_customer( EXPORTING it_customer_numbers = CORRESPONDING #( lt_customer_links )
                             iv_scope_full       = iv_scope_full
                   IMPORTING et_customers        = DATA(lt_customer_data) ).

    LOOP AT lt_bp_data
         ASSIGNING FIELD-SYMBOL(<ls_bp_data>).
      READ TABLE lt_customer_links
           ASSIGNING FIELD-SYMBOL(<ls_customer_link>)
           WITH KEY partner = <ls_bp_data>-header-object_instance-bpartner
           BINARY SEARCH.
      APPEND INITIAL LINE TO lt_business_partners
             ASSIGNING FIELD-SYMBOL(<ls_business_partners>).
      <ls_business_partners>-partner = <ls_bp_data>.
      READ TABLE lt_customer_data
           ASSIGNING FIELD-SYMBOL(<ls_cust_data>)
           WITH KEY header-object_instance-kunnr = <ls_customer_link>-kunnr
           BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_business_partners>-customer = <ls_cust_data>.
      ENDIF.
    ENDLOOP.

    IF iv_bypass_buffer = abap_false.
      mt_buffered_bp_customer = VALUE #( BASE mt_buffered_bp_customer
                                         ( LINES OF lt_business_partners ) ). "#EC CI_CONV_OK
    ENDIF.
    et_business_partners = VALUE #( BASE et_business_partners
                                    ( LINES OF lt_business_partners ) ). "#EC CI_CONV_OK
  ENDMETHOD.


  METHOD get_bp_from_vendor.
    "--------------------------------------------------------------------------
    " TCH - Copied over from CL_CIF_S4_BPCVI_READER
    "--------------------------------------------------------------------------

    DATA lt_business_partners TYPE cvis_ei_extern_t.
    DATA lt_vendor_nos        TYPE tt_lifnr.

    CLEAR et_business_partners.

    IF iv_refresh_buffer = abap_true.
      CLEAR mt_buffered_bp_vendor.
    ENDIF.

    IF iv_bypass_buffer = abap_false.
      " skip the vendors which are in buffer already and get the missing vendors
      LOOP AT it_vendors
           ASSIGNING FIELD-SYMBOL(<ls_vendors_in>).
        ASSIGN mt_buffered_bp_vendor[ vendor-header-object_instance-lifnr = <ls_vendors_in>-lifnr ] TO FIELD-SYMBOL(<ls_buffered_vendors>). "#EC CI_STDSEQ
        IF sy-subrc = 0.
          et_business_partners = VALUE #( BASE et_business_partners
                                          ( <ls_buffered_vendors> ) ).
        ELSE.
          lt_vendor_nos = VALUE #( BASE lt_vendor_nos
                                   ( lifnr = <ls_vendors_in>-lifnr ) ).
        ENDIF.
      ENDLOOP.
    ELSE.
      lt_vendor_nos = it_vendors.
    ENDIF.

    SORT lt_vendor_nos BY lifnr.
    DELETE ADJACENT DUPLICATES FROM lt_vendor_nos
           COMPARING lifnr.

    IF lt_vendor_nos[] IS INITIAL.
      RETURN.
    ENDIF.

    " CVI Links - Vendor to BP
    SELECT c~partner,
           c~partner_guid,
           a~lifnr
      FROM lfa1 AS a
             INNER JOIN
               cvi_vend_link AS b ON a~lifnr = b~vendor
                 INNER JOIN
                   but000 AS c ON b~partner_guid = c~partner_guid
      INTO TABLE @DATA(lt_vendor_links)  ##ITAB_KEY_IN_SELECT
      FOR ALL ENTRIES IN @lt_vendor_nos
      WHERE a~lifnr      = @lt_vendor_nos-lifnr
        AND a~cvp_xblck <> 'X'
        AND c~xpcpt     <> 'X'.

    SORT lt_vendor_links BY partner.

    read_bp( EXPORTING it_bp_numbers = CORRESPONDING #( lt_vendor_links )
                       iv_scope_full = iv_scope_full
             IMPORTING et_bp_data    = DATA(lt_bp_data) ).

    read_vendor( EXPORTING it_vendor_numbers = CORRESPONDING #( lt_vendor_links )
                           iv_scope_full     = iv_scope_full
                 IMPORTING et_vendors        = DATA(lt_vendor_data) ).

    LOOP AT lt_bp_data
         ASSIGNING FIELD-SYMBOL(<ls_bp_data>).
      READ TABLE lt_vendor_links
           ASSIGNING FIELD-SYMBOL(<ls_vendor_link>)
           WITH KEY partner = <ls_bp_data>-header-object_instance-bpartner
           BINARY SEARCH.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO lt_business_partners
             ASSIGNING FIELD-SYMBOL(<ls_business_partners>).
      <ls_business_partners>-partner = <ls_bp_data>.
      READ TABLE lt_vendor_data
           ASSIGNING FIELD-SYMBOL(<ls_cust_data>)
           WITH KEY header-object_instance-lifnr = <ls_vendor_link>-lifnr
           BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_business_partners>-vendor = <ls_cust_data>.
      ENDIF.
    ENDLOOP.

    IF iv_bypass_buffer = abap_false.
      mt_buffered_bp_vendor = VALUE #( BASE mt_buffered_bp_vendor
                                       ( LINES OF lt_business_partners ) ). "#EC CI_CONV_OK
    ENDIF.
    et_business_partners = VALUE #( BASE et_business_partners
                                    ( LINES OF lt_business_partners ) ). "#EC CI_CONV_OK
  ENDMETHOD.


  METHOD get_bp_address_from_bp.

    read_bp( EXPORTING it_bp_numbers = it_bp_numbers
             IMPORTING et_bp_data    = et_bp_data  ).

    IF et_business_partners IS REQUESTED.
      LOOP AT et_bp_data
           ASSIGNING FIELD-SYMBOL(<ls_bp_data>).
        APPEND INITIAL LINE TO et_business_partners
               ASSIGNING FIELD-SYMBOL(<ls_business_partners>).
        <ls_business_partners>-partner = <ls_bp_data>.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD read_bp.
    DATA lt_idlist TYPE TABLE OF bus_ei_instance.

    IF iv_scope_full = abap_false.
      DATA(lt_sel_scope) = it_sel_scope.
      IF lt_sel_scope IS INITIAL.
        lt_sel_scope = mt_full_sel_scope_bupa.
      ENDIF.
    ELSE.
      CLEAR lt_sel_scope.
    ENDIF.

    CLEAR et_bp_data.
    LOOP AT it_bp_numbers
         ASSIGNING FIELD-SYMBOL(<ls_bp_numbers>).
      lt_idlist = VALUE #( BASE lt_idlist
                           ( bpartner = <ls_bp_numbers>-partner ) ).
    ENDLOOP.

    IF lt_idlist IS NOT INITIAL.
      CALL FUNCTION 'BUPA_OUTBOUND_BPS_FILL_CENTRAL'
        EXPORTING
          iv_mode      = 'E' " Transmit mode
          iv_rep       = 'X' " DPP ( End of purpose ) blocked BPs are not returned in replication mode
        TABLES
          it_idlist    = lt_idlist
          it_fragments = lt_sel_scope
        CHANGING
          ct_bp_extern = et_bp_data.
    ENDIF.

  ENDMETHOD.


  METHOD read_customer.
    DATA ls_customers TYPE cmds_ei_main.

    IF iv_scope_full = abap_false.
      DATA(lt_sel_scope) = it_sel_scope.
      IF lt_sel_scope IS INITIAL.
        lt_sel_scope = mt_full_sel_scope_customer.
      ENDIF.
    ELSE.
      CLEAR lt_sel_scope.
    ENDIF.

    CLEAR et_customers.
    LOOP AT it_customer_numbers
         ASSIGNING FIELD-SYMBOL(<ls_customers>).
      ls_customers-customers = VALUE #( BASE ls_customers-customers
                                        ( header-object_instance-kunnr = <ls_customers>-kunnr
                                          header-object_task           = zif_massbp_co=>gc_objtask_modify ) ).
    ENDLOOP.

    IF ls_customers-customers IS INITIAL.
      RETURN.
    ENDIF.

    cmd_ei_api_extract=>get_data( EXPORTING is_master_data = ls_customers
                                            it_table_list  = lt_sel_scope
                                  IMPORTING es_master_data = DATA(ls_customer_data) ).

    " Filter the DPP entries - End of Purpose Flag
    " These records are not transmitted
    LOOP AT ls_customer_data-customers
         ASSIGNING FIELD-SYMBOL(<ls_customer_data>)
         WHERE central_data-central-data-cvp_xblck <> 'X'. "#EC CI_STDSEQ
      et_customers = VALUE #( BASE et_customers
                              ( <ls_customer_data> ) ).
    ENDLOOP.

    SORT et_customers BY header-object_instance-kunnr.
  ENDMETHOD.


  METHOD read_vendor.
    DATA ls_vendor TYPE vmds_ei_main.

    IF iv_scope_full = abap_false.
      DATA(lt_sel_scope) = it_sel_scope.
      IF lt_sel_scope IS INITIAL.
        lt_sel_scope = mt_full_sel_scope_vendor.
      ENDIF.
    ELSE.
      CLEAR lt_sel_scope.
    ENDIF.

    CLEAR et_vendors.
    LOOP AT it_vendor_numbers
         ASSIGNING FIELD-SYMBOL(<ls_vendors>).
      ls_vendor-vendors = VALUE #( BASE ls_vendor-vendors
                                   ( header-object_instance-lifnr = <ls_vendors>-lifnr
                                     header-object_task           = zif_massbp_co=>gc_objtask_modify ) ).
    ENDLOOP.

    IF ls_vendor-vendors IS INITIAL.
      RETURN.
    ENDIF.

    vmd_ei_api_extract=>get_data( EXPORTING is_master_data = ls_vendor
                                            it_table_list  = lt_sel_scope
                                  IMPORTING es_master_data = DATA(ls_vendor_data) ).

    " Filter the DPP entries - End of Purpose Flag
    " These records are not transmitted
    LOOP AT ls_vendor_data-vendors
         ASSIGNING FIELD-SYMBOL(<ls_vendor_data>)
         WHERE central_data-central-data-cvp_xblck <> 'X'. "#EC CI_STDSEQ
      et_vendors = VALUE #( BASE et_vendors
                            ( <ls_vendor_data> ) ).
    ENDLOOP.

    SORT et_vendors BY header-object_instance-lifnr.
  ENDMETHOD.


  METHOD read_cvi_links_from_bp.
    DATA ls_customer_links TYPE ty_customer_bp_link.
    DATA ls_vendor_links   TYPE ty_customer_bp_link.

    CLEAR: et_customer_links,
           et_vendor_links.

    " Customers and Vendors from cvi_cust_link and cvi_vend_link are standard assignments to the Business Partner
    " In S/4HANA multiple customers and vendors can be assigned to a Business Partner
    " Only the standard assignment is used in PPDS for location creation, hence only the standard assignments are selected
    " if non std assignment is required, it can be differentiated with field "standard"

    " BP with End of Purpose Flag set are not selected
    " BP linked to the customer with End of Purpose Flag set are not selected
    " BP linked to the Vendor with End of Purpose Flag set are not selected

    IF it_bp_numbers IS INITIAL.
      RETURN.
    ENDIF.

    SELECT a~partner,
           c~kunnr
      FROM but000 AS a
             INNER JOIN
               cvi_cust_link AS b ON a~partner_guid = b~partner_guid
                 INNER JOIN
                   kna1 AS c ON b~customer = c~kunnr
      INTO TABLE @et_customer_links
      FOR ALL ENTRIES IN @it_bp_numbers
      WHERE a~partner    = @it_bp_numbers-partner
        AND a~xpcpt     <> 'X'
        AND c~cvp_xblck <> 'X' ##TOO_MANY_ITAB_FIELDS.

    ls_customer_links-standard = 'X'.
    MODIFY et_customer_links FROM ls_customer_links
           TRANSPORTING standard
           WHERE standard = space.                       "#EC CI_STDSEQ

    SELECT a~partner,
           c~lifnr
      FROM but000 AS a
             INNER JOIN
               cvi_vend_link AS b ON a~partner_guid = b~partner_guid
                 INNER JOIN
                   lfa1 AS c ON b~vendor = c~lifnr
      INTO TABLE @et_vendor_links
      FOR ALL ENTRIES IN @it_bp_numbers
      WHERE a~partner    = @it_bp_numbers-partner
        AND a~xpcpt     <> 'X'
        AND c~cvp_xblck <> 'X' ##TOO_MANY_ITAB_FIELDS.

    ls_vendor_links-standard = 'X'.
    MODIFY et_vendor_links FROM ls_vendor_links
           TRANSPORTING standard
           WHERE standard = space.                       "#EC CI_STDSEQ

    SORT et_customer_links BY partner.
    SORT et_vendor_links BY partner.
  ENDMETHOD.
ENDCLASS.
