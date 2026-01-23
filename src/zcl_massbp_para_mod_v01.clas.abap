"! <p class="shorttext synchronized">Mass Upd BP - Modifier - Parallel - Update Only</p>
CLASS zcl_massbp_para_mod_v01 DEFINITION
  INHERITING FROM zcl_massbp_para_mod_0abs
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS process REDEFINITION.

    METHODS constructor
      IMPORTING is_bp_new TYPE cvis_ei_extern OPTIONAL.

    METHODS set_bp_new
      IMPORTING is_bp_new TYPE cvis_ei_extern   OPTIONAL
                it_bp_new TYPE cvis_ei_extern_t OPTIONAL.

    METHODS set_bp_old
      IMPORTING is_bp_old TYPE cvis_ei_extern   OPTIONAL
                it_bp_old TYPE cvis_ei_extern_t OPTIONAL.

  PROTECTED SECTION.
ENDCLASS.


CLASS zcl_massbp_para_mod_v01 IMPLEMENTATION.
  METHOD constructor.
    super->constructor(  ).
    ms_bp_new = is_bp_new.
  ENDMETHOD.

  METHOD process.
    DATA ls_bapiret2 TYPE bapiret2.

    " See https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/5a1b852d92f6427c92b045409b8f1680/53872683ee3046f7ab517c1a2bcc3ab7.html?version=1709+001
    INSERT me->ms_bp_new INTO TABLE me->mt_bp_new.
    cl_md_bp_maintain=>maintain( EXPORTING i_data   = mt_bp_new
                                 IMPORTING e_return = mt_bapiretm ).
    DATA(lv_successfull) = is_successfull( mt_bapiretm ).
    IF lv_successfull = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait   = abap_true
        IMPORTING
          return = ls_bapiret2.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
        IMPORTING
          return = ls_bapiret2.
    ENDIF.

    " Add the COMMIT/ROLLBACK errors to the return
    DATA(ls_bapiretm) = COND #( WHEN mt_bapiretm IS NOT INITIAL THEN mt_bapiretm[ 1 ] ).
    IF ls_bapiretm IS NOT INITIAL.
      APPEND CORRESPONDING #( ls_bapiret2 )
             TO ls_bapiretm-object_msg.
    ENDIF.
  ENDMETHOD.

  METHOD set_bp_new.
    ms_bp_new = is_bp_new.
    mt_bp_new = it_bp_new.
  ENDMETHOD.

  METHOD set_bp_old.
    ms_bp_old = is_bp_old.
    mt_bp_old = it_bp_old.
  ENDMETHOD.
ENDCLASS.
