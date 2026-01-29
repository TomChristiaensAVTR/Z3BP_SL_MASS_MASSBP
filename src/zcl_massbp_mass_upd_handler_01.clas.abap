"! <p class="shorttext synchronized" lang="en">Mass Upd BP - Handler 4 ZXD99 extensions (Z Flds & File Upl)</p>
CLASS zcl_massbp_mass_upd_handler_01 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-DATA go_singleton TYPE REF TO zcl_massbp_mass_upd_handler_01 READ-ONLY.

    CLASS-METHODS class_constructor.

    "! <p class="shorttext synchronized">File Upl. - At CL_MASS_SPSH_IMP_INT - At start SETUP_TABLES</p>
    METHODS at_mass_setup_tables_start
      RETURNING VALUE(rv_zmassbp_multi_tab_enabled) TYPE abap_bool.

    "! <p class="shorttext synchronized">File Upl. - At CL_MASS_SPSH_IMP_INT - Before SETUP_TABLES</p>
    METHODS at_mass_setup_tables_before
      IMPORTING iv_zmassbp_multi_tab_enabled TYPE abap_bool.

    "! <p class="shorttext synchronized">Field Number Limitation - At SAPMMSDL - FORM build_tables_tab</p>
    METHODS at_build_tables_tab
      IMPORTING it_selected_fields TYPE mass_selfields
      CHANGING  cv_subrc           TYPE sysubrc.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_massbp_mass_upd_handler_01 IMPLEMENTATION.


  METHOD at_mass_setup_tables_start.

    " Called in Implicit enhancement in CL_MASS_SPSH_IMP_INT->IF_MASS_SPSH_IMP_INT~SETUP_TABLES
    " REASON: We bail out of the call of the above method.
    " REASON of bailing out: SAP has EXPLICITLY BLOCKED the possibility to load a file with
    " multiple TABS (eg. a TAB for KNA1, KNB1, etc ...).
    " HOWEVER the code of CL_MASS_SPSH_IMP_INT->IF_MASS_SPSH_IMP_INT~SETUP_TABLES needs to be
    " executed. As suc there is also a PRE-EXIT defined for CL_MASS_SPSH_IMP_INT->IF_MASS_SPSH_IMP_INT~SETUP_TABLES
    " where we execute the same code as CL_MASS_SPSH_IMP_INT->IF_MASS_SPSH_IMP_INT~SETUP_TABLES, now without the check
    " on the multiple tabs.

    rv_zmassbp_multi_tab_enabled = abap_true.
  ENDMETHOD.


  METHOD at_mass_setup_tables_before.
  ENDMETHOD.


  METHOD at_build_tables_tab.
  ENDMETHOD.


  METHOD class_constructor.
    " Instantiate the SINGLETON instance only once ...
    go_singleton = NEW #( ).
  ENDMETHOD.
ENDCLASS.
