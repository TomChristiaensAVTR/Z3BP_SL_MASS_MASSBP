"! <p class="shorttext synchronized" lang="en">MASSBP - Abstract Update Strategy</p>
CLASS zcl_massbp_upd_str_0abs DEFINITION PUBLIC ABSTRACT.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_container TYPE REF TO zcl_massbp_upd_0cont.
    "! <p class="shorttext synchronized" lang="en">ABSTRACT MAIN UPDATE Method</p>
    METHODS update ABSTRACT.
  PROTECTED SECTION.
    DATA mo_container TYPE REF TO zcl_massbp_upd_0cont.
    METHODS update_msg_at_maintain
      IMPORTING io_modifier TYPE REF TO zcl_massbp_para_mod_0abs
      EXPORTING ev_error    TYPE abap_bool.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_massbp_upd_str_0abs IMPLEMENTATION.
  METHOD constructor.
    me->mo_container ?= io_container.
  ENDMETHOD.

  METHOD update_msg_at_maintain.

    LOOP AT io_modifier->mt_bapiretm
         INTO DATA(ls_bapiretm).

      DATA(lv_partner) = io_modifier->ms_bp_new-partner-header-object_instance-bpartner.

      LOOP AT ls_bapiretm-object_msg
           ASSIGNING FIELD-SYMBOL(<ls_object_msg>).

        APPEND VALUE #( objkey = lv_partner )
               TO mo_container->ms_comm_update-ref_msg->*
               ASSIGNING FIELD-SYMBOL(<ls_msg>).

        <ls_msg> = CORRESPONDING #(
          BASE ( <ls_msg> )
          <ls_object_msg>
          MAPPING msgid = id
                  msgno = number
                  msgty = type
                  msgv1 = message_v1
                  msgv2 = message_v2
                  msgv3 = message_v3
                  msgv4 = message_v4 ).

        IF    <ls_object_msg>-type = 'E'
           OR <ls_object_msg>-type = 'A'.
          " Error occurred
          ev_error = abap_true.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
