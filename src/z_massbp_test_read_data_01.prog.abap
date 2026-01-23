*&---------------------------------------------------------------------*
*& Report z_massbp_test_01
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_massbp_test_read_data_01.

PARAMETERS p_bp TYPE but000-partner.

START-OF-SELECTION.

  " Get Data
  DATA ls_master_data_in  TYPE cmds_ei_main.
  APPEND INITIAL LINE TO ls_master_data_in-customers
         ASSIGNING FIELD-SYMBOL(<ls_entity>).
  <ls_entity>-header-object_instance-kunnr = p_bp.
  <ls_entity>-header-object_task = zif_massbp_co=>gc_objtask_modify.
  cmd_ei_api_extract=>get_data(
    EXPORTING is_master_data = ls_master_data_in
    IMPORTING es_master_data = DATA(ls_master_data_out)
              es_error       = DATA(ls_error) ).

  IF ls_master_data_out-customers IS INITIAL.
    MESSAGE 'Nothing Selected' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  DATA(ls_entity) = ls_master_data_out-customers[ 1 ].

  DATA lv_output TYPE string VALUE 'STANDARD'.
  IF lv_output = 'CUSTOM'.
    DATA(lo_zoutput) = zcl_demo_output=>new( ).
    lo_zoutput->write_data( ls_master_data_out ).
    lo_zoutput->display( ).
  ELSE.

    DATA(lo_output) = cl_demo_output=>new( ).

    "Start SECTION 1
    lo_output->begin_section( |Start of ANALysis for { p_bp }| ).

    "Start Section 1.1 - HEADER
    lo_output->begin_section( |Start of HEADER for { p_bp }| ).
    lo_output->write_data(
      value = ls_entity-header ).
    "End Section 1.1
    lo_output->end_section( ).

    "Start Section 1.2 - CENTRAL DATA
    lo_output->begin_section( |Start of CENTRAL DATA for { p_bp }| ).
    lo_output->write_data(
      value = ls_entity-central_data ).
    "End Section 1.2
    lo_output->end_section( ).

    "Start Section 1.3 - COMPANY DATA
    lo_output->begin_section( |Start of COMPANY DATA for { p_bp }| ).
    lo_output->write_data(
      value = ls_entity-company_data ).
    "End Section 1.3
    lo_output->end_section( ).

    "Start Section 1.4 - SALES DATA
    lo_output->begin_section( |Start of SALES DATA for { p_bp }| ).
    lo_output->write_data(
      value = ls_entity-sales_data ).
    "End Section 1.4
    lo_output->end_section( ).

    "End SECTION 1
    lo_output->end_section( ).

    lo_output->display( ).
  ENDIF.

END-OF-SELECTION.
