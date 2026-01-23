"! <p class="shorttext synchronized">Mass Upd BP - Validator - Parallel</p>
CLASS zcl_massbp_para_validator_01 DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_abap_parallel.

    METHODS constructor
      IMPORTING is_bp TYPE cvis_ei_extern OPTIONAL.

    METHODS set_bp
      IMPORTING is_bp TYPE cvis_ei_extern.

    DATA ms_bp         TYPE cvis_ei_extern     READ-ONLY.
    DATA mt_return_map TYPE mdg_bs_bp_msgmap_t READ-ONLY.
ENDCLASS.


CLASS zcl_massbp_para_validator_01 IMPLEMENTATION.
  METHOD constructor.
    ms_bp = is_bp.
  ENDMETHOD.

  METHOD if_abap_parallel~do.
    cl_md_bp_maintain=>validate_single( EXPORTING i_data        = ms_bp
                                        IMPORTING et_return_map = mt_return_map ).
  ENDMETHOD.

  METHOD set_bp.
    ms_bp = is_bp.
  ENDMETHOD.
ENDCLASS.
