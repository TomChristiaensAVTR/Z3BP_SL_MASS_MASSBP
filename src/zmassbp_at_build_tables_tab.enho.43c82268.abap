"Name: \PR:SAPMMSDL\FO:BUILD_TABLES_TAB\SE:END\EI
ENHANCEMENT 0 ZMASSBP_AT_BUILD_TABLES_TAB.
TRY.
    DATA(lv_subrc) = sy-subrc.
    zcl_massbp_mass_upd_handler_01=>go_singleton->at_build_tables_tab(
      EXPORTING it_selected_fields = selected_fields[]
      CHANGING  cv_subrc           = lv_subrc ).
    sy-subrc = lv_subrc.
  CATCH cx_root.
ENDTRY.
ENDENHANCEMENT.
