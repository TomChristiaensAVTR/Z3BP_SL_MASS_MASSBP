"! <p class="shorttext synchronized">Mass Upd BP - Reader - Parallel</p>
CLASS zcl_massbp_para_reader_01 DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_abap_parallel.

    METHODS constructor
      IMPORTING it_customers TYPE zcl_massbp_data_reader_01=>tt_kunnr OPTIONAL.

    METHODS set_customers
      IMPORTING it_customers TYPE zcl_massbp_data_reader_01=>tt_kunnr.

    DATA mt_customers TYPE zcl_massbp_data_reader_01=>tt_kunnr.
    DATA mt_bp        TYPE cvis_ei_extern_t READ-ONLY.
ENDCLASS.


CLASS zcl_massbp_para_reader_01 IMPLEMENTATION.
  METHOD constructor.
    mt_customers = it_customers.
  ENDMETHOD.

  METHOD if_abap_parallel~do.
    " Get Data
    DATA(lo_reader) = zcl_massbp_data_reader_01=>get_instance( ).
    lo_reader->get_bp_from_customer( EXPORTING it_customers         = mt_customers
                                               iv_bypass_buffer     = abap_true
                                               iv_scope_full        = abap_true
                                     IMPORTING et_business_partners = mt_bp ).
  ENDMETHOD.

  METHOD set_customers.
    mt_customers = it_customers.
  ENDMETHOD.
ENDCLASS.
