*&---------------------------------------------------------------------*
*& Report z_massbp_disp_appl_log_01
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_massbp_disp_appl_log_01.

CLASS lcl_main_controller DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS main.

    METHODS determine_display_profile
      CHANGING cs_display_profile TYPE bal_s_prof.

  PROTECTED SECTION.
    METHODS bal_set_visibility
      IMPORTING iv_fieldname       TYPE c
                iv_visibility      TYPE c
      CHANGING  cs_display_profile TYPE bal_s_prof.
    METHODS process.
ENDCLASS.

SELECTION-SCREEN BEGIN OF BLOCK bl0 WITH FRAME TITLE TEXT-000.
  PARAMETERS p_extno TYPE mgidocnr MEMORY ID dcn.
SELECTION-SCREEN END OF BLOCK bl0.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-001.
  PARAMETERS p_datvon LIKE balhdr-aldate DEFAULT sy-datlo.
  PARAMETERS p_zeitvo LIKE balhdr-altime DEFAULT '000000'.
  SELECTION-SCREEN SKIP 1.
  PARAMETERS p_datbis LIKE balhdr-aldate DEFAULT sy-datlo.
  PARAMETERS p_zeitbi LIKE balhdr-altime DEFAULT sy-uzeit.
SELECTION-SCREEN END OF BLOCK bl1.

START-OF-SELECTION.
  lcl_main_controller=>main( ).


END-OF-SELECTION.

CLASS lcl_main_controller IMPLEMENTATION.
  METHOD main.

    DATA(lo_controller) = NEW lcl_main_controller(  ).
    lo_controller->process(  ).
  ENDMETHOD.

  METHOD process.
    DATA lv_repid           TYPE sy-repid.
    DATA ls_display_profile TYPE bal_s_prof.
    DATA lv_external_number TYPE balhdr-extnumber.

    determine_display_profile( CHANGING cs_display_profile = ls_display_profile ).

    IF p_extno IS INITIAL.
      lv_external_number = '*'.
    ELSE.
      lv_external_number = p_extno.
    ENDIF.

    DATA(lv_object_type)    = CONV balobj_d( 'MASS' ).
    DATA(lv_subobject_type) = CONV balsubobj( zif_massbp_co=>gc_massty_zmassbp ).
    CALL FUNCTION 'APPL_LOG_DISPLAY'
      EXPORTING
        object                         = lv_object_type
        subobject                      = lv_subobject_type
        external_number                = lv_external_number
        object_attribute               = 1  " 0 = ready for input, 1 = display, 2 = hide
        subobject_attribute            = 1  " 0 = ready for input, 1 = display, 2 = hide
        external_number_attribute      = 1  " 0 = ready for input, 1 = display, 2 = hide
        date_from                      = p_datvon
        time_from                      = p_zeitvo
        date_to                        = p_datbis
        time_to                        = p_zeitbi
        title_selection_screen         = 'MASSBP - Application Log'
        title_list_screen              = 'MASSBP - Application Log'
*       COLUMN_SELECTION               = '11112221122   '
        suppress_selection_dialog      = 'X'
*       COLUMN_SELECTION_MSG_JUMP      = '1'
        external_number_display_length = 16           " ToDo !!!!!
*    IMPORTING
*       NUMBER_OF_PROTOCOLS            =
      EXCEPTIONS
        no_authority                   = 1
        OTHERS                         = 2.
  ENDMETHOD.

  METHOD bal_set_visibility.
    FIELD-SYMBOLS <ls_fcat> TYPE bal_s_fcat.

    ASSIGN cs_display_profile-lev1_fcat[ ref_table = 'BAL_S_SHOW'
                                         ref_field = iv_fieldname ] TO <ls_fcat>.
    IF sy-subrc = 0.
      IF iv_visibility = space.
        <ls_fcat>-no_out = abap_true.
      ELSE.
        <ls_fcat>-no_out = abap_false.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD determine_display_profile.
    " Local structures
    DATA ls_column_selection TYPE baldisp VALUE '11111111111111'.

    CALL FUNCTION 'BAL_DSP_PROFILE_SINGLE_LOG_GET'
      IMPORTING
        e_s_display_profile = cs_display_profile
      EXCEPTIONS
        OTHERS              = 1.
    IF sy-subrc <> 0.
      MESSAGE ID     sy-msgid
              TYPE   sy-msgty
              NUMBER sy-msgno
              WITH   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    cs_display_profile-disvariant-report = sy-cprog.

    cs_display_profile-use_grid = abap_true.

    bal_set_visibility( EXPORTING iv_fieldname       = 'LOGNUMBER'
                                  iv_visibility      = ls_column_selection-number
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'OBJECT'
                                  iv_visibility      = ls_column_selection-object
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'T_OBJECT'
                                  iv_visibility      = ls_column_selection-object
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'SUBOBJECT'
                                  iv_visibility      = ls_column_selection-subobject
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'T_SUBOBJ'
                                  iv_visibility      = ls_column_selection-subobject
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'EXTNUMBER'
                                  iv_visibility      = ls_column_selection-ext_number
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'ALTCODE'
                                  iv_visibility      = ls_column_selection-tcode
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'T_ALTCODE'
                                  iv_visibility      = ls_column_selection-tcode
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'PROBCLSSH'
                                  iv_visibility      = ls_column_selection-probclass
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'T_PROBCLSH'
                                  iv_visibility      = ls_column_selection-probclass
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'ALMODE'
                                  iv_visibility      = ls_column_selection-mode
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'T_ALMODE'
                                  iv_visibility      = ls_column_selection-mode
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'DATE_DEL'
                                  iv_visibility      = ls_column_selection-date_del
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'DEL_BEFORE'
                                  iv_visibility      = ls_column_selection-del_before
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'ALSTATE'
                                  iv_visibility      = ls_column_selection-state
                        CHANGING  cs_display_profile = cs_display_profile ).

    bal_set_visibility( EXPORTING iv_fieldname       = 'T_ALSTATE'
                                  iv_visibility      = ls_column_selection-state
                        CHANGING  cs_display_profile = cs_display_profile ).

    " Set the header text
    cs_display_profile-head_text  = 'MASSBP Applciation Log'.

    " Define up to which level the tree should be expanded
    " cs_display_profile-exp_level  = 0.

    " Set the tree on the side of the screen (TRUE)
    cs_display_profile-tree_ontop = abap_false.

    " Show all messages directly
    cs_display_profile-show_all   = abap_false.

    " Use ALV grid for messages
    cs_display_profile-use_grid   = abap_true.
  ENDMETHOD.
ENDCLASS.
