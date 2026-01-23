"! <p class="shorttext synchronized">Mass Upd BP - Abstract Modifier</p>
CLASS zcl_massbp_para_mod_0abs DEFINITION
  PUBLIC ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA ms_bp_new   TYPE cvis_ei_extern   READ-ONLY.
    DATA mt_bp_new   TYPE cvis_ei_extern_t READ-ONLY.
    DATA ms_bp_old   TYPE cvis_ei_extern   READ-ONLY.
    DATA mt_bp_old   TYPE cvis_ei_extern_t READ-ONLY.
    DATA mt_bapiretm TYPE bapiretm         READ-ONLY.

    INTERFACES if_abap_parallel.

    "! <p class="shorttext synchronized">Main Process</p>
    METHODS process ABSTRACT.

  PROTECTED SECTION.
    "! <p class="shorttext synchronized">Is the MODIFY of the BP successful?</p>
    METHODS is_successfull
      IMPORTING it_bapiretm           TYPE bapiretm
      RETURNING VALUE(rv_successfull) TYPE abap_bool.
ENDCLASS.


CLASS zcl_massbp_para_mod_0abs IMPLEMENTATION.
  METHOD if_abap_parallel~do.
    process( ).
  ENDMETHOD.

  METHOD is_successfull.
    rv_successfull = abap_true.
    LOOP AT it_bapiretm
         ASSIGNING FIELD-SYMBOL(<ls_bapiretm>).

      LOOP AT <ls_bapiretm>-object_msg
           ASSIGNING FIELD-SYMBOL(<ls_object_msg>).

        IF    <ls_object_msg>-type = 'E'
           OR <ls_object_msg>-type = 'A'.
          " Error occurred
          rv_successfull = abap_false.
        ENDIF.
      ENDLOOP.
      IF sy-subrc <> 0.
        " NO messages triggered at all by SAP API - I BOLDLY/TRUMPLY assume all went well  ...
        DATA ls_bapiret2 TYPE bapiret2.
        CLEAR ls_bapiret2.
        MESSAGE ID     'ZMASSBP'
                TYPE   'S'
                NUMBER '001'
                INTO   ls_bapiret2-message.
        ls_bapiret2-type       = sy-msgty.
        ls_bapiret2-id         = sy-msgid.
        ls_bapiret2-number     = sy-msgno.
        ls_bapiret2-message_v1 = sy-msgv1.
        ls_bapiret2-message_v2 = sy-msgv2.
        ls_bapiret2-message_v3 = sy-msgv3.
        ls_bapiret2-message_v4 = sy-msgv4.
        APPEND CORRESPONDING #( ls_bapiret2 )
               TO <ls_bapiretm>-object_msg.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
