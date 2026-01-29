*&---------------------------------------------------------------------*
*& Report z_massbp_create_upl_templ_01
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_massbp_create_upl_templ_01.

CLASS lcl_container DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF gty_selection,
             ra_partner    TYPE RANGE OF bu_partner,
             file_location TYPE string,
           END OF gty_selection.

    DATA ms_selection TYPE gty_selection READ-ONLY.

    METHODS set_selection
      IMPORTING is_selection TYPE gty_selection.
ENDCLASS.


CLASS lcl_utility DEFINITION.
  PUBLIC SECTION.

    CLASS-DATA gt_fieldcat_tmp    TYPE lvc_t_fcat.
    CLASS-DATA gt_fieldcat_return TYPE slis_t_fieldcat_alv.

    CLASS-METHODS validate_file_path
      CHANGING cv_path TYPE pun_pf_dlpath.

    CLASS-METHODS display_return
      CHANGING ct_return TYPE bapiret2_t.

ENDCLASS.


CLASS lcl_controller DEFINITION
  CREATE PROTECTED.

  PUBLIC SECTION.
    CLASS-METHODS main
      IMPORTING io_container    TYPE REF TO lcl_container
      RETURNING VALUE(rv_subrc) TYPE sysubrc.

    CLASS-METHODS initialization.

    CLASS-METHODS directory_browse EXPORTING  ev_length   TYPE sysubrc
                                   CHANGING   cv_location TYPE pun_pf_dlpath
                                   EXCEPTIONS file_open_dialog_failed                                                                                                                                                                       " Open File" dialog
                                              failed
                                              cntl_error
                                              error_no_gui
                                              not_supported_by_gui.

    CLASS-METHODS filename_get EXPORTING  ev_length TYPE sysubrc
                               CHANGING   cv_file   TYPE pun_pf_dlpath
                               EXCEPTIONS file_open_dialog_failed                                                                                                                                                                       " Open File" dialog
                                          failed
                                          cntl_error
                                          error_no_gui
                                          not_supported_by_gui.

  PROTECTED SECTION.
    DATA mo_container        TYPE REF TO lcl_container.

    DATA mo_excel            TYPE REF TO zclexcel.
    DATA mo_excel_converter  TYPE REF TO zcl_excel_converter.
    DATA mo_worksheet        TYPE REF TO zcl_excel_worksheet.
    DATA mo_salv_table       TYPE REF TO cl_salv_table.

    DATA mt_zem_mbpcentrorg  TYPE STANDARD TABLE OF zem_mbpcentrorg WITH EMPTY KEY.
    DATA mt_zem_mbpaddrpost  TYPE STANDARD TABLE OF zem_mbpaddrpost WITH EMPTY KEY.
    DATA mt_zem_mbpaddrsmtp  TYPE STANDARD TABLE OF zem_mbpaddrsmtp WITH EMPTY KEY.
    DATA mt_zem_mbpaddrphone TYPE STANDARD TABLE OF zem_mbpaddrphone WITH EMPTY KEY.

    DATA mt_zem_mbpcustkna1  TYPE STANDARD TABLE OF zem_mbpcustkna1 WITH EMPTY KEY.
    DATA mt_zem_mbpcustknb1  TYPE STANDARD TABLE OF zem_mbpcustknb1 WITH EMPTY KEY.
    DATA mt_zem_mbpcustknvv  TYPE STANDARD TABLE OF zem_mbpcustknvv WITH EMPTY KEY.
    DATA mt_zem_mbpcustknvi  TYPE STANDARD TABLE OF zem_mbpcustknvi WITH EMPTY KEY.

    DATA mt_zem_mbpvendlfa1  TYPE STANDARD TABLE OF zem_mbpvendlfa1 WITH EMPTY KEY.
    DATA mt_zem_mbpvendlfb1  TYPE STANDARD TABLE OF zem_mbpvendlfb1 WITH EMPTY KEY.
    DATA mt_zem_mbpvendlfm1  TYPE STANDARD TABLE OF zem_mbpvendlfm1 WITH EMPTY KEY.

    METHODS constructor
      IMPORTING io_container TYPE REF TO lcl_container.

    METHODS process
      RETURNING VALUE(rv_subrc) TYPE sysubrc.
    METHODS select_data
      RETURNING VALUE(rv_subrc) TYPE sysubrc.
    METHODS determine_field_catalog
      IMPORTING iv_table TYPE tabname.
    METHODS determine_other_worksheets.
ENDCLASS.

DATA gs_zim_mass_bp_comm_centr_org TYPE zim_mass_bp_comm_centr_org.
SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-b00.
  SELECT-OPTIONS s_bp FOR gs_zim_mass_bp_comm_centr_org-partner.
SELECTION-SCREEN END OF BLOCK b0.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
  PARAMETERS p_locin TYPE pun_pf_dlpath DEFAULT 'C:\Users\'
                                        MODIF ID upl.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  lcl_controller=>initialization( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_locin.
  lcl_controller=>directory_browse( CHANGING cv_location = p_locin ).

AT SELECTION-SCREEN OUTPUT.
  cl_gui_frontend_services=>directory_exist( EXPORTING  directory            = CONV #( p_locin )
                                             RECEIVING  result               = DATA(lv_exists)
                                             EXCEPTIONS cntl_error           = 1
                                                        error_no_gui         = 2
                                                        wrong_parameter      = 3
                                                        not_supported_by_gui = 4
                                                        OTHERS               = 5 ).
  IF sy-subrc <> 0.
    MESSAGE |Error when checking File Path| TYPE 'W' DISPLAY LIKE 'E'.
  ENDIF.
  IF lv_exists = abap_false.
    MESSAGE |Location { p_locin } does not exist| TYPE 'W' DISPLAY LIKE 'E'.
  ENDIF.

START-OF-SELECTION.
  " Check whether the directory where to download the files exists ...
  DATA(lv_path_lenght) = strlen( p_locin ).
  lv_path_lenght -= 1.
  IF p_locin+lv_path_lenght(1) CA ',;.|:&\/*!è§)({}'.
    p_locin+lv_path_lenght(1) = ''.
  ENDIF.
  cl_gui_frontend_services=>directory_exist( EXPORTING  directory            = CONV #( p_locin )
                                             RECEIVING  result               = DATA(lv_exists)
                                             EXCEPTIONS cntl_error           = 1
                                                        error_no_gui         = 2
                                                        wrong_parameter      = 3
                                                        not_supported_by_gui = 4
                                                        OTHERS               = 5 ).
  IF sy-subrc <> 0.
    MESSAGE |Error when checking File Path| TYPE 'W' DISPLAY LIKE 'E'.
    STOP.
  ENDIF.
  IF lv_exists = abap_false.
    MESSAGE |Location { p_locin } does not exist| TYPE 'S' DISPLAY LIKE 'E'.
    STOP.
  ENDIF.

  " Add trailing "\" or "/"
  lcl_utility=>validate_file_path( CHANGING cv_path = p_locin ).

  " Setup Container Object where to store the DATA
  DATA(lo_container) = NEW lcl_container( ).
  lo_container->set_selection( VALUE #( ra_partner    = s_bp[]
                                        file_location = p_locin ) ).
  DATA(gv_subrc) = lcl_controller=>main( lo_container ).

END-OF-SELECTION.

CLASS lcl_container IMPLEMENTATION.
  METHOD set_selection.
    ms_selection = CORRESPONDING #( is_selection ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_controller IMPLEMENTATION.
  METHOD constructor.
    mo_container ?= io_container.
  ENDMETHOD.

  METHOD main.
    DATA(lo_controller) = NEW lcl_controller( io_container ).
    rv_subrc = lo_controller->process( ).
  ENDMETHOD.

  METHOD process.
    "--------------------------------------------------------------------------
    " Select ALL DATA
    "--------------------------------------------------------------------------
    rv_subrc = select_data( ).
    IF rv_subrc <> 0.
      RETURN.
    ENDIF.

    TRY.
        "--------------------------------------------------------------------------
        " CREATE first worksheet
        "--------------------------------------------------------------------------
        " First create an SALV object to manage the field catalog
        cl_salv_table=>factory( EXPORTING list_display = abap_false
                                IMPORTING r_salv_table = mo_salv_table
                                CHANGING  t_table      = mt_zem_mbpcentrorg ).

        " DATA(lt_fcat) = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
        "                    r_columns      = mo_salv_table->get_columns( )
        "                    r_aggregations = mo_salv_table->get_aggregations( ) ).

        determine_field_catalog( zif_massbp_co=>gc_table_bp_centr_org ).

        " Now start converting ...
        mo_excel_converter = NEW zcl_excel_converter( ).
        mo_excel_converter->convert( EXPORTING io_alv   = mo_salv_table
                                               it_table = mt_zem_mbpcentrorg
                                     CHANGING  co_excel = mo_excel ).

        mo_worksheet = mo_excel->get_active_worksheet( ).
        mo_worksheet->set_title( CONV #( zif_massbp_co=>gc_table_bp_centr_org ) ).
        mo_worksheet->freeze_panes( ip_num_rows = 1 ).

        "--------------------------------------------------------------------------
        " Now add the other worksheets ...
        "--------------------------------------------------------------------------
        determine_other_worksheets( ).

        "--------------------------------------------------------------------------
        " Now write/download the excel file to the
        "--------------------------------------------------------------------------
        DATA(lo_excel_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007( ) ).
        DATA(lv_excel_data) = lo_excel_writer->write_file( mo_excel ).  " XSTRING ...
        DATA(lt_raw_data) = cl_bcs_convert=>xstring_to_solix( iv_xstring = lv_excel_data ).
        DATA(lv_filename) = |{ mo_container->ms_selection-file_location }{ sy-datum }_{ sy-uzeit }.xlsx|.

        cl_gui_frontend_services=>gui_download( EXPORTING filename     = lv_filename
                                                          filetype     = 'BIN'
                                                          bin_filesize = xstrlen( lv_excel_data )
                                                CHANGING  data_tab     = lt_raw_data ).

      CATCH cx_root INTO DATA(lx_root).
        WRITE / lx_root->get_text( ).
    ENDTRY.
  ENDMETHOD.

  METHOD select_data.

    " Select from MAIN CENTRAL ORGANIZATION Table
    rv_subrc = 0.
    SELECT FROM zem_mbpcentrorg
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpcentrorg.
    IF sy-subrc <> 0.
      " TO DO: Generate LOG and bail out ...
      rv_subrc = 4.
      RETURN.
    ENDIF.

    SELECT FROM zem_mbpaddrpost
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpaddrpost.

    SELECT FROM zem_mbpaddrsmtp
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpaddrsmtp.

    SELECT FROM zem_mbpaddrphone
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpaddrphone.

    SELECT FROM zem_mbpcustkna1
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpcustkna1.

    SELECT FROM zem_mbpcustknb1
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpcustknb1.

    SELECT FROM zem_mbpcustknvv
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpcustknvv.

    SELECT FROM zem_mbpcustknvi
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpcustknvi.

    SELECT FROM zem_mbpvendlfa1
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpvendlfa1.

    SELECT FROM zem_mbpvendlfb1
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpvendlfb1.

    SELECT FROM zem_mbpvendlfm1
      FIELDS *
      WHERE partner IN @mo_container->ms_selection-ra_partner
      ORDER BY PRIMARY KEY
      INTO TABLE @mt_zem_mbpvendlfm1.
  ENDMETHOD.

  METHOD determine_field_catalog.
    DATA lo_columns TYPE REF TO cl_salv_columns_table.
    DATA lo_column  TYPE REF TO cl_salv_column_table.

    " Make sure that the fields texts are set to the technical name
    lo_columns = mo_salv_table->get_columns( ).
    DATA(lt_columns) = lo_columns->get( ).
    LOOP AT lt_columns
         ASSIGNING FIELD-SYMBOL(<ls_column>).
      lo_column ?= <ls_column>-r_column.
      lo_column->set_short_text( CONV #( <ls_column>-columnname ) ).
      lo_column->set_medium_text( CONV #( <ls_column>-columnname ) ).
      lo_column->set_long_text( CONV #( <ls_column>-columnname ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD determine_other_worksheets.
    " POSTAL ADDRESS
    CLEAR mo_salv_table.
    cl_salv_table=>factory( EXPORTING list_display = abap_false
                            IMPORTING r_salv_table = mo_salv_table
                            CHANGING  t_table      = mt_zem_mbpaddrpost ).
    determine_field_catalog( zif_massbp_co=>gc_table_bp_postal  ).

    mo_worksheet = mo_excel->add_new_worksheet( ip_title = to_upper( 'zem_mbpaddrpostp' ) ).
    mo_excel_converter->convert( EXPORTING io_alv       = mo_salv_table
                                           it_table     = mt_zem_mbpaddrpost
                                           io_worksheet = mo_worksheet
                                 CHANGING  co_excel     = mo_excel ).
    " SMTP ADDRESS
    CLEAR mo_salv_table.
    cl_salv_table=>factory( EXPORTING list_display = abap_false
                            IMPORTING r_salv_table = mo_salv_table
                            CHANGING  t_table      = mt_zem_mbpaddrsmtp ).
    determine_field_catalog( zif_massbp_co=>gc_table_bp_smtp ).

    mo_worksheet = mo_excel->add_new_worksheet( ip_title = to_upper( 'zem_mbpaddrsmtp' ) ).
    mo_excel_converter->convert( EXPORTING io_alv       = mo_salv_table
                                           it_table     = mt_zem_mbpaddrsmtp
                                           io_worksheet = mo_worksheet
                                 CHANGING  co_excel     = mo_excel ).
    " PHONE ADDRESS
    CLEAR mo_salv_table.
    cl_salv_table=>factory( EXPORTING list_display = abap_false
                            IMPORTING r_salv_table = mo_salv_table
                            CHANGING  t_table      = mt_zem_mbpaddrphone ).
    determine_field_catalog( zif_massbp_co=>gc_table_bp_phone ).

    mo_worksheet = mo_excel->add_new_worksheet( ip_title = to_upper( 'zem_mbpaddrphone' ) ).
    mo_excel_converter->convert( EXPORTING io_alv       = mo_salv_table
                                           it_table     = mt_zem_mbpaddrphone
                                           io_worksheet = mo_worksheet
                                 CHANGING  co_excel     = mo_excel ).
    " KNA1
    CLEAR mo_salv_table.
    cl_salv_table=>factory( EXPORTING list_display = abap_false
                            IMPORTING r_salv_table = mo_salv_table
                            CHANGING  t_table      = mt_zem_mbpcustkna1 ).
    determine_field_catalog( zif_massbp_co=>gc_table_cust_central ).

    mo_worksheet = mo_excel->add_new_worksheet( ip_title = to_upper( 'ZEM_MBPCUSTKNA1' ) ).
    mo_excel_converter->convert( EXPORTING io_alv       = mo_salv_table
                                           it_table     = mt_zem_mbpcustkna1
                                           io_worksheet = mo_worksheet
                                 CHANGING  co_excel     = mo_excel ).

    " KNB1
    CLEAR mo_salv_table.
    cl_salv_table=>factory( EXPORTING list_display = abap_false
                            IMPORTING r_salv_table = mo_salv_table
                            CHANGING  t_table      = mt_zem_mbpcustknb1 ).
    determine_field_catalog( zif_massbp_co=>gc_table_cust_company ).

    mo_worksheet = mo_excel->add_new_worksheet( ip_title = to_upper( 'ZEM_MBPCUSTKNB1' ) ).
    mo_excel_converter->convert( EXPORTING io_alv       = mo_salv_table
                                           it_table     = mt_zem_mbpcustknb1
                                           io_worksheet = mo_worksheet
                                 CHANGING  co_excel     = mo_excel ).
    " KNVV
    CLEAR mo_salv_table.
    cl_salv_table=>factory( EXPORTING list_display = abap_false
                            IMPORTING r_salv_table = mo_salv_table
                            CHANGING  t_table      = mt_zem_mbpcustknvv ).
    determine_field_catalog( zif_massbp_co=>gc_table_cust_sales ).

    mo_worksheet = mo_excel->add_new_worksheet( ip_title = to_upper( 'ZEM_MBPCUSTKNVV' ) ).
    mo_excel_converter->convert( EXPORTING io_alv       = mo_salv_table
                                           it_table     = mt_zem_mbpcustknvv
                                           io_worksheet = mo_worksheet
                                 CHANGING  co_excel     = mo_excel ).

    " KNVI
    CLEAR mo_salv_table.
    cl_salv_table=>factory( EXPORTING list_display = abap_false
                            IMPORTING r_salv_table = mo_salv_table
                            CHANGING  t_table      = mt_zem_mbpcustknvi ).
    determine_field_catalog( zif_massbp_co=>gc_table_cust_tax ).

    mo_worksheet = mo_excel->add_new_worksheet( ip_title = to_upper( 'ZEM_MBPCUSTKNVI' ) ).
    mo_excel_converter->convert( EXPORTING io_alv       = mo_salv_table
                                           it_table     = mt_zem_mbpcustknvi
                                           io_worksheet = mo_worksheet
                                 CHANGING  co_excel     = mo_excel ).
  ENDMETHOD.

  METHOD directory_browse.
    " TODO: parameter EV_LENGTH is never cleared or assigned (ABAP cleaner)

    DATA lv_window_title    TYPE string.
    DATA lv_initial_folder  TYPE string.
    DATA lv_selected_folder TYPE string.

    lv_window_title = 'Select Location to download C4C Object ID Mapping file'.
    lv_initial_folder = cv_location.
    cl_gui_frontend_services=>directory_browse( EXPORTING  window_title         = lv_window_title
                                                           initial_folder       = lv_initial_folder
                                                CHANGING   selected_folder      = lv_selected_folder
                                                EXCEPTIONS cntl_error           = 1
                                                           error_no_gui         = 2
                                                           not_supported_by_gui = 3
                                                           OTHERS               = 4 ).
    IF sy-subrc <> 0.
      " Implement suitable error handling here
      CASE sy-subrc.
        WHEN 1.
          RAISE cntl_error.
        WHEN 2.
          RAISE error_no_gui.
        WHEN 3.
          RAISE not_supported_by_gui.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
    ENDIF.

    cv_location = lv_selected_folder.
  ENDMETHOD.

  METHOD filename_get.
    DATA lv_window_title TYPE string.
    DATA lt_file_names   TYPE filetable.

    lv_window_title = 'Select Object ID Mapping file to update table ZC4C_OBJMAP_01'.
    cl_gui_frontend_services=>file_open_dialog( EXPORTING  window_title            = lv_window_title
                                                CHANGING   file_table              = lt_file_names
                                                           rc                      = ev_length
                                                EXCEPTIONS file_open_dialog_failed = 1
                                                           cntl_error              = 2
                                                           error_no_gui            = 3
                                                           not_supported_by_gui    = 4
                                                           OTHERS                  = 5 ).
    IF sy-subrc <> 0.
      " / Implement suitable error handling here
      CASE sy-subrc.
        WHEN 1.
          RAISE file_open_dialog_failed.
        WHEN 2.
          RAISE cntl_error.
        WHEN 3.
          RAISE error_no_gui.
        WHEN 4.
          RAISE not_supported_by_gui.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
    ENDIF.

    READ TABLE lt_file_names INTO DATA(ls_file_table_line) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    cv_file = ls_file_table_line-filename.
  ENDMETHOD.

  METHOD initialization.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_utility IMPLEMENTATION.
  METHOD display_return.
    " / Local Structures
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA ls_exit_caused_by_user TYPE slis_exit_by_user.

    " / Local Fields
    DATA lv_title               TYPE sytitle.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lv_selfield_tabindex   TYPE sytabix.

    CHECK ct_return[] IS NOT INITIAL.

    IF gt_fieldcat_return IS INITIAL.
      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name   = 'BAPIRET2'
          i_bypassing_buffer = abap_true
        CHANGING
          ct_fieldcat        = gt_fieldcat_tmp.
      gt_fieldcat_return = CORRESPONDING #( gt_fieldcat_return ).

      LOOP AT gt_fieldcat_return
           ASSIGNING FIELD-SYMBOL(<ls_fieldcat>).
        <ls_fieldcat>-seltext_l = COND #( WHEN <ls_fieldcat>-fieldname = 'TYPE'       THEN 'MessageType'
                                          WHEN <ls_fieldcat>-fieldname = 'NUMBER'     THEN 'MessageNumber'
                                          WHEN <ls_fieldcat>-fieldname = 'MESSAGE'    THEN 'MessageText'
                                          WHEN <ls_fieldcat>-fieldname = 'MESSAGE_V1' THEN 'MessageV1'
                                          WHEN <ls_fieldcat>-fieldname = 'MESSAGE_V2' THEN 'MessageV2'
                                          WHEN <ls_fieldcat>-fieldname = 'MESSAGE_V3' THEN 'MessageV3'
                                          WHEN <ls_fieldcat>-fieldname = 'MESSAGE_V4' THEN 'MessageV4' ).
      ENDLOOP.
    ENDIF.

    lv_title = 'Error/Information/Success Messages'.
    CALL FUNCTION 'S_TWB_U_F4_ALV_POPUP'
      EXPORTING
        i_title                = lv_title
        it_fieldcat            = gt_fieldcat_return
        i_screen_start_column  = '20'
        i_screen_start_line    = '1'
        i_screen_end_column    = '120'
        i_screen_end_line      = '20'
      IMPORTING
        e_selfield_tabindex    = lv_selfield_tabindex
        es_exit_caused_by_user = ls_exit_caused_by_user
      TABLES
        t_outtab               = ct_return
      EXCEPTIONS
        program_error          = 1
        OTHERS                 = 2.
    IF sy-subrc <> 0.
      MESSAGE ID     sy-msgid
              TYPE   sy-msgty
              NUMBER sy-msgno
              WITH   sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDMETHOD.

  METHOD validate_file_path.
    IF cv_path CA '/'.
      REPLACE REGEX '([^/])\s*$' IN cv_path WITH '$1/'.
    ELSE.
      REPLACE REGEX '([^\\])\s*$' IN cv_path WITH '$1\\'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
