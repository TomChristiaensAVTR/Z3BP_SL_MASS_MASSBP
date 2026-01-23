"! <p class="shorttext synchronized" lang="en">MASSBP - Sequential - Use MASSGENCHANGE</p>
CLASS zcl_massbp_upd_str_v01 DEFINITION PUBLIC
  INHERITING FROM zcl_massbp_upd_str_0abs.
  PUBLIC SECTION.
    METHODS update REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_massbp_upd_str_v01 IMPLEMENTATION.


  METHOD update.

    DATA lv_guid     TYPE bu_partner_guid.
    DATA lv_partner  TYPE bu_partner.
    DATA ls_bp       TYPE cvis_ei_extern.
    DATA lt_bp       TYPE cvis_ei_extern_t.
    DATA lt_bapiretm TYPE bapiretm.
    DATA ls_bapiret2 TYPE bapiret2.

    FIELD-SYMBOLS <lt_zmassbp_cust_central> TYPE zmassbp_cust_central_tt.

    " Setup of ls_bp
    LOOP AT mo_container->ms_comm_update-seldata
         ASSIGNING FIELD-SYMBOL(<ls_seldat>).
      " Loop over all the involved tables/dimensions
      LOOP AT mo_container->ms_comm_update-ref_massgenchange->*
           ASSIGNING FIELD-SYMBOL(<ls_massgenchange>)
           WHERE name = <ls_seldat>-tabname-name.

        " Dereference the changed data
        ASSIGN <ls_massgenchange>-data->* TO <lt_zmassbp_cust_central>.

        LOOP AT <lt_zmassbp_cust_central>
             ASSIGNING FIELD-SYMBOL(<ls_input_central>).

          " Set the context for the BP
          CLEAR ls_bp.
          ls_bp-partner-header-object_task = zif_massbp_co=>gc_objtask_update.
          ls_bp-partner-header-object_instance-bpartner = |{ <ls_input_central>-partner ALPHA = IN }|.

          CLEAR lv_guid.
          CALL FUNCTION 'BUPA_NUMBERS_GET'
            EXPORTING
              iv_partner      = ls_bp-partner-header-object_instance-bpartner
            IMPORTING
              ev_partner      = lv_partner
              ev_partner_guid = lv_guid.
          ls_bp-partner-header-object_instance-bpartnerguid = lv_guid.

          " Set the context for the KUNNR
          ls_bp-customer-header-object_instance-kunnr = |{ <ls_input_central>-kunnr ALPHA = IN }|.

          " Move the changed data
          ls_bp-customer-header-object_task = zif_massbp_co=>gc_objtask_update.
          ls_bp-customer-central_data-central-data = CORRESPONDING #( <ls_input_central> ).

          " Set the change flags
          LOOP AT <ls_seldat>-fieldnames
               ASSIGNING FIELD-SYMBOL(<lv_central_fieldname>).
            ASSIGN COMPONENT <lv_central_fieldname>
                   OF STRUCTURE ls_bp-customer-central_data-central-datax
                   TO FIELD-SYMBOL(<lv_central_fieldvalue>).
            <lv_central_fieldvalue> = abap_true.
          ENDLOOP.

          "------------------------------------------------------------------------------
          " Validate data
          "------------------------------------------------------------------------------
          cl_md_bp_maintain=>validate_single( EXPORTING i_data        = ls_bp
                                              IMPORTING et_return_map = DATA(lt_return_map) ).
          IF    line_exists( lt_return_map[ type = 'E' ] )
             OR line_exists( lt_return_map[ type = 'A' ] ).
            " TO DO: Log the error ...
            CONTINUE.
          ELSE.
            INSERT ls_bp INTO TABLE lt_bp.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

    " ------------------------------------------------------------------------------
    " Call API FOR 1 BP doing all changes in 1 GO & Check Result
    " ------------------------------------------------------------------------------
    CLEAR lt_bapiretm.
    cl_md_bp_maintain=>maintain( EXPORTING i_data   = lt_bp
                                 IMPORTING e_return = lt_bapiretm ).

*    " Check result
*    DATA lv_error TYPE abap_bool.
*    update_msg_at_maintain( EXPORTING it_bapiretm = lt_bapiretm
*                            IMPORTING ev_error    = lv_error ).
*
*    IF lv_error IS INITIAL.
*      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*        EXPORTING
*          wait   = abap_true
*        IMPORTING
*          return = ls_bapiret2.
*    ELSE.
*      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
*        IMPORTING
*          return = ls_bapiret2.
*    ENDIF.

  ENDMETHOD.
ENDCLASS.
