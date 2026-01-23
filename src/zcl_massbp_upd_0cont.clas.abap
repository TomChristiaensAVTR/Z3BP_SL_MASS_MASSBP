"! <p class="shorttext synchronized">MASSBP - Data Container</p>
CLASS zcl_massbp_upd_0cont DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF gty_comm_update_as_ref,
             seldata              TYPE mass_tabdata,
             testmode             TYPE char1,
             ref_msg              TYPE REF TO mass_msgs,
             ref_customer_central TYPE REF TO zmassbp_cust_central_tt,
             ref_customer_company TYPE REF TO zmassbp_cust_company_tt,
             ref_customer_sales   TYPE REF TO zmassbp_cust_sales_tt,
             ref_bp_centr_org     TYPE REF TO zmassbp_bp_centr_org_tt,
             ref_bp_postal        TYPE REF TO zmassbp_bp_addr_postal_tt,
             ref_bp_smtp          TYPE REF TO zmassbp_bp_addr_smtp_tt,
             ref_bp_phone         TYPE REF TO zmassbp_bp_addr_phone_tt,
             ref_massgenchange    TYPE REF TO massgenchange_t,
           END OF gty_comm_update_as_ref.
    TYPES gty_comm_update_as_ref_tt TYPE STANDARD TABLE OF gty_comm_update_as_ref WITH DEFAULT KEY.

    TYPES: BEGIN OF gty_comm_update_as_value,
             seldata          TYPE mass_tabdata,
             testmode         TYPE char1,
             ref_msg          TYPE mass_msgs,
             customer_central TYPE zmassbp_cust_central_tt,
             customer_company TYPE zmassbp_cust_company_tt,
             customer_sales   TYPE zmassbp_cust_sales_tt,
             bp_centr_org     TYPE zmassbp_bp_centr_org_tt,
             bp_postal        TYPE zmassbp_bp_addr_postal_tt,
             bp_smtp          TYPE zmassbp_bp_addr_smtp_tt,
             bp_phone         TYPE zmassbp_bp_addr_phone_tt,
             massgenchange    TYPE massgenchange_t,
           END OF gty_comm_update_as_value.
    TYPES gty_comm_update_as_value_tt TYPE STANDARD TABLE OF gty_comm_update_as_value WITH DEFAULT KEY.

    DATA ms_comm_update TYPE gty_comm_update_as_ref READ-ONLY.

    METHODS constructor
      IMPORTING is_comm_update TYPE gty_comm_update_as_ref OPTIONAL.

    METHODS set_comm_update
      IMPORTING is_comm_update TYPE gty_comm_update_as_ref.

    METHODS get_comm_update
      RETURNING VALUE(rs_comm_update) TYPE gty_comm_update_as_ref.

  PROTECTED SECTION.
    CLASS-DATA go_singleton TYPE REF TO zcl_massbp_upd_0cont.
ENDCLASS.


CLASS zcl_massbp_upd_0cont IMPLEMENTATION.
  METHOD constructor.
    ms_comm_update = CORRESPONDING #( is_comm_update ).
  ENDMETHOD.

  METHOD set_comm_update.
    ms_comm_update = CORRESPONDING #( is_comm_update ).
  ENDMETHOD.

  METHOD get_comm_update.
    rs_comm_update = CORRESPONDING #( me->ms_comm_update ).
  ENDMETHOD.
ENDCLASS.
