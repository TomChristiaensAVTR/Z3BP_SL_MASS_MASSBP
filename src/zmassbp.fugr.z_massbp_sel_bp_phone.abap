FUNCTION z_massbp_sel_bp_phone.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(SINGLE) TYPE  XFELD OPTIONAL
*"     VALUE(IV_REQ_BLK_MSG) TYPE  BU_REQ_BLK_MSG DEFAULT SPACE
*"  EXPORTING
*"     VALUE(COUNT) TYPE  I
*"     REFERENCE(WASINGLE) LIKE  ZEM_MBPADDRPHONE STRUCTURE
*"        ZEM_MBPADDRPHONE
*"  TABLES
*"      SELECTTABLE STRUCTURE  ZEM_MBPADDRPHONE OPTIONAL
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

  " Internal tables
  DATA: lt_limit_list      TYPE limit_tt_list,
        lt_mbpaddrphone    TYPE TABLE OF zem_mbpaddrphone,
        lt_partner         TYPE bu_partner_t,
        ls_partner_temp    TYPE bupa_partner,
        lt_blocked_partner TYPE bu_partner_t,
        ls_blocked_partner TYPE bupa_partner,
        ls_auth_partner    TYPE ts_auth_mass,
        lt_return          TYPE bapiret2_t,
        ls_return          TYPE bapiret2.

  "Fieldsymbols
  FIELD-SYMBOLS: <lv_partner> TYPE any,
                 <ls_partner> TYPE limit_ts_list,
                 <ls_but000>  TYPE zem_mbpaddrphone.
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
    SELECT SINGLE * FROM zem_mbpaddrphone
           INTO CORRESPONDING FIELDS OF @wasingle
           WHERE partner = @wasingle-partner.
    IF NOT sy-subrc IS INITIAL.
      RAISE single_not_found.
    ENDIF.

    EXIT.
  ENDIF.
  "end single select

  REFRESH lt_limit_list.
  IF NOT limittable[] IS INITIAL.
    LOOP AT limittable.
      UNASSIGN: <ls_partner>,
                <lv_partner>.
      APPEND INITIAL LINE TO lt_limit_list
             ASSIGNING <ls_partner>.
      ASSIGN COMPONENT cl_bupa_const_mass=>gc_partner
             OF STRUCTURE limittable
             TO <lv_partner>.
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
      SELECT COUNT(*) FROM zem_mbpaddrphone
             INTO @count
             FOR ALL ENTRIES IN @lt_limit_list
             WHERE partner = @lt_limit_list-partner AND
                  (where).
    ELSE.
      "number of items in current time slices
      SELECT COUNT(*) FROM zem_mbpaddrphone
             INTO @count
             WHERE (where).
    ENDIF.
  ELSE.
*    SELECT requested data records
    IF NOT lt_limit_list[] IS INITIAL.
      "items of current time slices
      SELECT * FROM zem_mbpaddrphone
               INTO CORRESPONDING FIELDS OF TABLE @lt_mbpaddrphone
               FOR ALL ENTRIES IN @lt_limit_list
               WHERE partner = @lt_limit_list-partner AND
                    (where).
    ELSE.
      "item of current time slice
      SELECT * FROM zem_mbpaddrphone
             INTO CORRESPONDING FIELDS OF TABLE @lt_mbpaddrphone
             WHERE (where).
    ENDIF.

    REFRESH: selecttable.
    SORT lt_mbpaddrphone BY partner.
    DELETE ADJACENT DUPLICATES
           FROM lt_mbpaddrphone
           COMPARING partner
                     addrnumber
                     consnumber.

    "fill selecttable for export
    selecttable[] = CORRESPONDING #( lt_mbpaddrphone ).

    CALL FUNCTION 'BUPA_DP_AUTHCHECK_MASS'
      EXPORTING
        it_partner  = lt_partner
      IMPORTING
        et_partners = lt_blocked_partner
        ev_return   = ls_return.

    LOOP AT lt_blocked_partner INTO ls_blocked_partner.
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
