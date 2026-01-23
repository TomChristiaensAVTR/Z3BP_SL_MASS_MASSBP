FUNCTION z_massbp_evt_display_object.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(KEY) TYPE  ANY OPTIONAL
*"     REFERENCE(RECORD) TYPE  ANY OPTIONAL
*"     REFERENCE(TABLE) TYPE  TABNAME OPTIONAL
*"----------------------------------------------------------------------
  " Copy of BUPA_MASS_DISPLAY_OBJECT / CL_BUPA_CENTRAL_MASSUPDATE~IF_BUPA_MASSUPDATE~DISPLAY_OBJECT

  " -- Objekte
  DATA lr_request  TYPE REF TO cl_bupa_navigation_request.
  DATA lr_options  TYPE REF TO cl_bupa_dialog_joel_options.

  " -- Felder
  DATA lv_activity TYPE bus_dialog-activity.
  DATA lv_partner  TYPE bu_partner.

  FIELD-SYMBOLS <lv_any> TYPE any.

  lr_request = NEW #( ).
  lr_options = NEW #( ).

  IF key IS NOT INITIAL.
    ASSIGN key TO <lv_any>.
  ELSE.
    ASSIGN COMPONENT cl_bupa_const_mass=>gc_partner
           OF STRUCTURE record
           TO <lv_any>.
  ENDIF.

  IF <lv_any> IS ASSIGNED.

    lv_partner = <lv_any>.
    lr_request->set_partner_number( lv_partner ).
    lv_activity = cl_bupa_navigation_request=>gc_activity_display.
    lr_request->set_bupa_activity( lv_activity ).

    cl_bupa_dialog_joel=>start_with_navigation( EXPORTING  iv_request = lr_request
                                                           iv_options = lr_options
                                                EXCEPTIONS OTHERS     = 1 ).
  ENDIF.
ENDFUNCTION.
