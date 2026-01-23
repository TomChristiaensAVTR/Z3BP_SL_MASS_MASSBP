*&---------------------------------------------------------------------*
*& Report z_massbp_disp_appl_log_01
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_massbp_disp_appl_log_01.

DATA external_number LIKE balhdr-extnumber.

PARAMETERS: extno TYPE mgidocnr MEMORY ID dcn. "note 316937

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-001.
  PARAMETERS     datvon  LIKE balhdr-aldate DEFAULT sy-datlo.
  PARAMETERS     zeitvon LIKE balhdr-altime DEFAULT '000000'.
  SELECTION-SCREEN SKIP 1.
  PARAMETERS     datbis  LIKE balhdr-aldate DEFAULT sy-datlo.
  PARAMETERS     zeitbis LIKE balhdr-altime DEFAULT sy-uzeit.
SELECTION-SCREEN END OF BLOCK bl1.

START-OF-SELECTION.

  IF extno IS INITIAL.
    external_number = '*'.
  ELSE.
    external_number = extno.
  ENDIF.

  DATA(lv_object_type)    = CONV balobj_d( 'MASS' ).
  DATA(lv_subobject_type) = CONV balsubobj( zif_massbp_co=>gc_massty_zmassbp ).
  CALL FUNCTION 'APPL_LOG_DISPLAY'
    EXPORTING
      object                         = lv_object_type
      subobject                      = lv_subobject_type
      external_number                = external_number
      object_attribute               = 1
      subobject_attribute            = 1
      external_number_attribute      = 0
      date_from                      = datvon
      time_from                      = zeitvon
      date_to                        = datbis
      time_to                        = zeitbis
*     TITLE_SELECTION_SCREEN         = ' '
*     TITLE_LIST_SCREEN              = ' '
*     COLUMN_SELECTION               = '11112221122   '
      suppress_selection_dialog      = 'X'
*     COLUMN_SELECTION_MSG_JUMP      = '1'
      external_number_display_length = 16           " ToDo !!!!!
*    IMPORTING
*     NUMBER_OF_PROTOCOLS            =
    EXCEPTIONS
      no_authority                   = 1
      OTHERS                         = 2.

END-OF-SELECTION.
