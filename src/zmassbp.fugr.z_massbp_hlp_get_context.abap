FUNCTION z_massbp_hlp_get_context.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(EV_SUCCESS) TYPE  ABAP_BOOL
*"  CHANGING
*"     REFERENCE(CS_CONTEXT) TYPE  ZCL_MASSBP_UPD_0CONT=>GTY_CONTEXT
*"----------------------------------------------------------------------

  DATA lt_fields      TYPE STANDARD TABLE OF sval.
  DATA lv_popup_title TYPE string.
  DATA lv_returncode  TYPE c.

  ev_success = abap_true.
  lt_fields = VALUE #( ( tabname    = 'KNA1'
                         fieldname  = 'ZZ1_CRREASON_CUS'
                         value      = cs_context-zz1_crreason_new
                         field_obl  = abap_true ) ).
  lv_popup_title = |Entry of MASSBP Context|.
  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      no_value_check  = ' '
      popup_title     = lv_popup_title
      start_column    = '5'
      start_row       = '5'
    IMPORTING
      returncode      = lv_returncode
    TABLES
      fields          = lt_fields
    EXCEPTIONS
      error_in_fields = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
    ev_success = abap_false.
    RETURN.
  ELSE.
    cs_context-zz1_crreason_new = lt_fields[ tabname   = 'KNA1'
                                             fieldname = 'ZZ1_CRREASON_CUS' ]-value.
  ENDIF.
ENDFUNCTION.
