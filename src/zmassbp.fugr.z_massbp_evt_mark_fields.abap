FUNCTION z_massbp_evt_mark_fields.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      DATAFIELDS_VIEW STRUCTURE  MASSFVIEW
*"----------------------------------------------------------------------

*  READ TABLE datafields_view
*       ASSIGNING FIELD-SYMBOL(<ls_datafields_view>)
*       WITH KEY tabname   = 'ZEM_MBPCUSTKNA1'
*                fieldname = 'ZZ1_CRREASON_CUS'.
*  IF sy-subrc = 0.
*    <ls_datafields_view>-checkbox = abap_true.
*  ENDIF.
ENDFUNCTION.
