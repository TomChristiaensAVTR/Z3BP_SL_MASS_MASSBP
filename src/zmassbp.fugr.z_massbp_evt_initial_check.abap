FUNCTION z_massbp_evt_initial_check.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(NODIALOG) TYPE  CHAR1 OPTIONAL
*"  CHANGING
*"     REFERENCE(TABLES_TAB) TYPE  MASS_TABLES
*"     REFERENCE(APPEXITS) TYPE  MASS_APPEXITS OPTIONAL
*"  EXCEPTIONS
*"      EXIT_FROM_PROG
*"----------------------------------------------------------------------
  DATA(lv_nr_of_tables) = lines( tables_tab ).



ENDFUNCTION.
