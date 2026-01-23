FUNCTION z_massbp_sel_cust_company.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(SINGLE) TYPE  XFELD OPTIONAL
*"     VALUE(IV_REQ_BLK_MSG) TYPE  BU_REQ_BLK_MSG DEFAULT SPACE
*"  EXPORTING
*"     VALUE(COUNT) TYPE  I
*"     REFERENCE(WASINGLE) LIKE  ZEM_MBPCUSTKNB1 STRUCTURE
*"        ZEM_MBPCUSTKNB1
*"  TABLES
*"      SELECTTABLE STRUCTURE  ZEM_MBPCUSTKNB1 OPTIONAL
*"      LIMITTABLE OPTIONAL
*"      WHERE OPTIONAL
*"  EXCEPTIONS
*"      BLOCKED_PARTNER
*"----------------------------------------------------------------------

  " Reference copied from BUPA_MASS_SEL_BUT000

  TYPES: BEGIN OF limit_ts_list,
           partner TYPE bu_partner,
         END OF limit_ts_list,
         limit_tt_list TYPE STANDARD TABLE OF limit_ts_list.

  TYPES: BEGIN OF ts_auth_mass,
           partner     TYPE bu_partner,
           bp_activity TYPE bu_aktyp,
         END OF ts_auth_mass.

  CONSTANTS: lc_tzone  TYPE ttzz-tzone VALUE 'UTC'.

*Internal tables
  DATA: lt_limit_list      TYPE limit_tt_list,
        lt_mass_bp_knb1    TYPE TABLE OF zim_mass_bp_knb1,
        lt_partner         TYPE bu_partner_t,
        ls_partner_temp    TYPE bupa_partner,
        lt_blocked_partner TYPE bu_partner_t,
        ls_blocked_partner TYPE bupa_partner,
        ls_auth_partner    TYPE ts_auth_mass,
        lt_return          TYPE bapiret2_t,
        ls_return          TYPE bapiret2.

*Fieldsymbols
  FIELD-SYMBOLS: <lv_partner> TYPE any,
                 <ls_partner> TYPE limit_ts_list,
                 <ls_but000>  TYPE zim_mass_bp_knb1.

  DATA lv_count  TYPE i.
  DATA lv_count1 TYPE i.
  IF where IS NOT INITIAL.
    FIND ALL OCCURRENCES OF REGEX '[;.]'
         IN where
         MATCH COUNT lv_count1.
    IF lv_count1 IS NOT INITIAL.
      MESSAGE e036(r1).
      EXIT.
    ENDIF.
  ENDIF.

  DATA ls_master_data_in  TYPE cmds_ei_main.
  DATA lt_table_list_in   TYPE tabname_md_tty.

  "begin single select -> check existence in case of creating new records
  IF single IS NOT INITIAL.
    "Check only table BUT000, because items of table BUT000_TD will exist
    "only if items of table BUT000 are available.
    SELECT SINGLE * FROM zim_mass_bp_knb1
           INTO CORRESPONDING FIELDS OF @wasingle
           WHERE partner = @wasingle-partner.
    IF NOT sy-subrc IS INITIAL.
      RAISE single_not_found.
    ENDIF.

    wasingle-kunnr = wasingle-partner.
    APPEND INITIAL LINE TO ls_master_data_in-customers
           ASSIGNING FIELD-SYMBOL(<ls_customer>).
    <ls_customer>-header-object_instance-kunnr = wasingle-kunnr.
    <ls_customer>-header-object_task = zif_massbp_co=>gc_objtask_modify.

    <ls_customer>-company_data-current_state = abap_true.
    APPEND VALUE #( task     = zif_massbp_co=>gc_objtask_modify
                    data_key = '' )
           TO <ls_customer>-company_data-company.

    cmd_ei_api_extract=>get_data(
      EXPORTING is_master_data = ls_master_data_in
                it_table_list  = VALUE #( ( CONV #( 'KNB1' ) ) )
      IMPORTING es_master_data = DATA(ls_master_data_out)
                es_error       = DATA(ls_error) ).
    wasingle = CORRESPONDING #( BASE ( wasingle ) ls_master_data_out-customers[ 1 ]-central_data-central ).
    EXIT.
  ENDIF.
  "end single select

  REFRESH lt_limit_list.
  IF NOT limittable[] IS INITIAL.
    LOOP AT limittable.
      UNASSIGN: <ls_partner>,
                <lv_partner>.
      APPEND INITIAL LINE TO lt_limit_list ASSIGNING <ls_partner>.
      ASSIGN COMPONENT cl_bupa_const_mass=>gc_partner
             OF STRUCTURE limittable TO <lv_partner>.
      <ls_partner>-partner = <lv_partner>.
    ENDLOOP.
    IF NOT lt_limit_list[] IS INITIAL.
      SORT lt_limit_list BY partner.
      DELETE ADJACENT DUPLICATES FROM lt_limit_list.
    ENDIF.
  ENDIF.

  REFRESH selecttable.
  IF NOT selecttable IS REQUESTED.
    "select number of data records for preselection
    IF NOT lt_limit_list[] IS INITIAL.
      "number of items in current time slices
      SELECT COUNT(*) FROM zim_mass_bp_knb1
             INTO @count
             FOR ALL ENTRIES IN @lt_limit_list
             WHERE partner = @lt_limit_list-partner AND
                  (where).
    ELSE.
      "number of items in current time slices
      SELECT COUNT(*) FROM zim_mass_bp_knb1
             INTO @count
             WHERE (where).
    ENDIF.
  ELSE.
*    SELECT requested data records
    IF NOT lt_limit_list[] IS INITIAL.
      "items of current time slices
      SELECT * FROM zim_mass_bp_knb1
               INTO CORRESPONDING FIELDS OF TABLE @lt_mass_bp_knb1
               FOR ALL ENTRIES IN @lt_limit_list
               WHERE partner = @lt_limit_list-partner AND
                    (where).
    ELSE.
      "item of current time slice
      SELECT * FROM zim_mass_bp_knb1
               INTO CORRESPONDING FIELDS OF TABLE @lt_mass_bp_knb1
               WHERE (where).
      LOOP AT lt_mass_bp_knb1
           ASSIGNING  <ls_but000>
           WHERE td_switch IS INITIAL.
        CALL FUNCTION 'BUPA_TD_PARTNER_SWITCH'
          EXPORTING
            i_partner = <ls_but000>-partner
            i_but000  = <ls_but000>
          IMPORTING
            e_but000  = <ls_but000>.
      ENDLOOP.
    ENDIF.

    REFRESH: selecttable.
    SORT lt_mass_bp_knb1 BY partner
                      valid_from
                      valid_to.
    DELETE ADJACENT DUPLICATES
           FROM lt_mass_bp_knb1
           COMPARING partner
                     valid_from
                     valid_to.

    "fill selecttable for export
    CLEAR ls_master_data_in.
    CLEAR ls_master_data_out.
    CLEAR ls_error.
    LOOP AT lt_mass_bp_knb1
         ASSIGNING FIELD-SYMBOL(<ls_but000_tmp>)
         GROUP BY ( partner = <ls_but000_tmp>-partner
                    kunnr   = <ls_but000_tmp>-kunnr
                    size    = GROUP SIZE
                    index   = GROUP INDEX )
         ASSIGNING FIELD-SYMBOL(<lt_but000>).

      "APPEND INITIAL LINE TO selecttable
      "       ASSIGNING <ls_selecttable>.
      "MOVE-CORRESPONDING <ls_but000> TO <ls_selecttable>.   "#EC ENHOK
      ""get date from
      "CONVERT TIME STAMP <ls_but000>-valid_from
      "        TIME ZONE lc_tzone
      "        INTO DATE <ls_selecttable>-dvalid_from.
      ""get date to
      "CONVERT TIME STAMP <ls_but000>-valid_to
      "        TIME ZONE lc_tzone
      "        INTO DATE <ls_selecttable>-dvalid_to.

      ls_partner_temp = <lt_but000>-partner.
      APPEND ls_partner_temp TO lt_partner.

      APPEND VALUE #( header-object_instance-kunnr = <lt_but000>-partner
                      header-object_task = zif_massbp_co=>gc_objtask_modify )
             TO ls_master_data_in-customers
             ASSIGNING FIELD-SYMBOL(<ls_master_data_in_customers>).
      LOOP AT GROUP <lt_but000>
           ASSIGNING <ls_but000>.
        "<ls_master_data_in_customers>-company_data-current_state = abap_true.
        <ls_master_data_in_customers>-company_data-company = VALUE #(
          BASE <ls_master_data_in_customers>-company_data-company
          ( task = zif_massbp_co=>gc_objtask_modify
            data_key-bukrs = <ls_but000>-bukrs ) ).
      ENDLOOP.
    ENDLOOP.

    IF ls_master_data_in-customers IS NOT INITIAL.
      cmd_ei_api_extract=>get_data(
        EXPORTING is_master_data = ls_master_data_in
                  "it_table_list  = VALUE #( ( CONV #( 'KNB1' ) ) )
        IMPORTING es_master_data = ls_master_data_out
                  es_error       = ls_error ).
      LOOP AT ls_master_data_out-customers
           ASSIGNING FIELD-SYMBOL(<ls_customer_data>).
        LOOP AT <ls_customer_data>-company_data-company
             ASSIGNING FIELD-SYMBOL(<ls_company>).
          APPEND VALUE #( kunnr   = <ls_customer_data>-header-object_instance-kunnr
                          partner = <ls_customer_data>-header-object_instance-kunnr )
                 TO selecttable
                 ASSIGNING FIELD-SYMBOL(<ls_selecttable_ins>).
          <ls_selecttable_ins>-bukrs = <ls_company>-data_key-bukrs.
          <ls_selecttable_ins> = CORRESPONDING #( BASE ( <ls_selecttable_ins> ) <ls_company>-data ).
        ENDLOOP.
      ENDLOOP.
    ENDIF.

    CALL FUNCTION 'BUPA_DP_AUTHCHECK_MASS'
      EXPORTING
        it_partner  = lt_partner
      IMPORTING
        et_partners = lt_blocked_partner
        ev_return   = ls_return.

    LOOP AT lt_blocked_partner
         INTO ls_blocked_partner.
      DELETE selecttable WHERE partner = ls_blocked_partner-partner.
    ENDLOOP.

    IF ls_return IS NOT INITIAL.
      "check whether the application need the error or exception
      IF iv_req_blk_msg = 'X'." if yes throw the error message
        MESSAGE i003(r11) RAISING blocked_partner.
        EXIT.
      ENDIF.
    ENDIF.

    "DCPD authorization check for both partners
    LOOP AT selecttable
         ASSIGNING FIELD-SYMBOL(<ls_selecttable>).

      MOVE-CORRESPONDING <ls_selecttable> TO ls_auth_partner.

      ls_auth_partner-bp_activity  = cl_bupa_dcp_util=>gc_display.
      cl_bupa_dcp_util=>check_authority_bp_processing(
        EXPORTING iv_partner     = ls_auth_partner-partner
                  iv_bp_activity = ls_auth_partner-bp_activity
        IMPORTING et_return      = lt_return ).

      LOOP AT lt_return
           INTO ls_return
           WHERE type CA 'AEX'.
        DELETE selecttable WHERE partner = ls_auth_partner-partner.
      ENDLOOP.
      CLEAR ls_auth_partner.
      REFRESH lt_return[].
    ENDLOOP.
  ENDIF.
ENDFUNCTION.
