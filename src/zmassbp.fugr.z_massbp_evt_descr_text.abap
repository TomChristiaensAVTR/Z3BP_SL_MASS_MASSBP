FUNCTION z_massbp_evt_descr_text.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(TABNAME) TYPE  TABNAME
*"     REFERENCE(SELECTION) TYPE  STANDARD TABLE
*"  EXPORTING
*"     REFERENCE(D_STRUCT) TYPE  MASS_STRUCTNAME
*"     REFERENCE(D_FIELDS) TYPE  MASS_LISTFIELDS
*"     REFERENCE(DESCRIPTION) TYPE  STANDARD TABLE
*"--------------------------------------------------------------------

  DATA lv_text   TYPE string.                   "#EC NEEDED
  DATA ls_tb053  LIKE tb053.
  DATA oref      TYPE REF TO cx_root.

ENDFUNCTION.
