FUNCTION z_massbp_evt_limit_sel_fields .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(MODE_ID) TYPE  I
*"  TABLES
*"      TABLIST STRUCTURE  MASSTABLIST
*"      FIELDLIST STRUCTURE  MASSFIELDLIST
*"      FIELDEXCL STRUCTURE  MASSFIELDLIST
*"----------------------------------------------------------------------

  DATA lv_text               TYPE string.                   "#EC NEEDED
  DATA ls_tb053              LIKE tb053.
  DATA oref                  TYPE REF TO cx_root.

  DATA ls_fieldlist    TYPE massfieldlist.

  LOOP AT fieldlist
       ASSIGNING  FIELD-SYMBOL(<ls_fieldlist>).

    DATA(lv_tabix) = sy-tabix.

    CASE <ls_fieldlist>-tabname.
      WHEN 'ZEM_MBPADDRSMTP'.
        IF <ls_fieldlist>-fieldname = 'SMTP_CONSNUMBER'.
          APPEND <ls_fieldlist> TO fieldexcl.
          DELETE fieldlist INDEX lv_tabix.
        ENDIF.
      WHEN 'ZEM_MBPADDRPHONE'.
        IF <ls_fieldlist>-fieldname = 'PHONE_CONSNUMBER'.
          APPEND <ls_fieldlist> TO fieldexcl.
          DELETE fieldlist INDEX lv_tabix.
        ENDIF.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
ENDFUNCTION.
