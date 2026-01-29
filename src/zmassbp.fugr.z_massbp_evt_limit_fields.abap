FUNCTION z_massbp_evt_limit_fields.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      ALL_FIELDS TYPE  MASS_ALLFIELDS OPTIONAL
*"----------------------------------------------------------------------

  LOOP AT all_fields
       ASSIGNING FIELD-SYMBOL(<ls_zem_mbpcentrorg>).

    IF <ls_zem_mbpcentrorg>-scrtext_m CA '(Z'.
      SPLIT <ls_zem_mbpcentrorg>-scrtext_m AT '('
            INTO TABLE DATA(lt_parts).
      IF sy-subrc = 0.
        <ls_zem_mbpcentrorg>-scrtext_m = lt_parts[ 1 ].
      ENDIF.
      CLEAR lt_parts.
    ENDIF.

    IF <ls_zem_mbpcentrorg>-scrtext_l CA '(Z'.
      SPLIT <ls_zem_mbpcentrorg>-scrtext_m AT '('
            INTO TABLE lt_parts.
      IF sy-subrc = 0.
        <ls_zem_mbpcentrorg>-scrtext_l = lt_parts[ 1 ].
      ENDIF.
      CLEAR lt_parts.
    ENDIF.

    IF  <ls_zem_mbpcentrorg>-tabname   = zif_massbp_co=>gc_table_bp_centr_org
    AND <ls_zem_mbpcentrorg>-fieldname = 'KNA1_EXISTS'.
      " Just for INTO - no change allowed
      <ls_zem_mbpcentrorg>-displ_only = abap_true.
    ENDIF.

    IF  <ls_zem_mbpcentrorg>-tabname   = zif_massbp_co=>gc_table_bp_centr_org
    AND <ls_zem_mbpcentrorg>-fieldname = 'LFA1_EXISTS'.
      " Just for INTO - no change allowed
      <ls_zem_mbpcentrorg>-displ_only = abap_true.
    ENDIF.

    IF  <ls_zem_mbpcentrorg>-tabname   = zif_massbp_co=>gc_table_bp_centr_org
    AND <ls_zem_mbpcentrorg>-fieldname = 'ZZ1_CRREASON_CUS'.
      " Just for INTO - no change allowed
      <ls_zem_mbpcentrorg>-displ_only = abap_true.
    ENDIF.

    IF  <ls_zem_mbpcentrorg>-tabname   = zif_massbp_co=>gc_table_bp_centr_org
    AND <ls_zem_mbpcentrorg>-fieldname = 'ZZ1_S_CRREASON_SUP'.
      " Just for INTO - no change allowed
      <ls_zem_mbpcentrorg>-displ_only = abap_true.
    ENDIF.

  ENDLOOP.
ENDFUNCTION.
