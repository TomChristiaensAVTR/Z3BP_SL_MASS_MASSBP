FUNCTION z_massbp_update.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SELDATA) TYPE  MASS_TABDATA
*"     VALUE(TESTMODE) TYPE  ANY OPTIONAL
*"     VALUE(MASSSAVEINFOS) LIKE  MASSSAVINF STRUCTURE  MASSSAVINF
*"       OPTIONAL
*"  EXPORTING
*"     VALUE(MSG) TYPE  MASS_MSGS
*"  TABLES
*"      SZEM_MBPCUSTKNA1 STRUCTURE  ZEM_MBPCUSTKNA1 OPTIONAL
*"      SZEM_MBPCUSTKNB1 STRUCTURE  ZEM_MBPCUSTKNB1 OPTIONAL
*"      SZEM_MBPCUSTKNVV STRUCTURE  ZEM_MBPCUSTKNVV OPTIONAL
*"      SZEM_MBPCENTRORG STRUCTURE  ZEM_MBPCENTRORG OPTIONAL
*"      SZMASSBP_EI_POSTAL STRUCTURE  ZMASSBP_EI_POSTAL OPTIONAL
*"      SZMASSBP_EI_SMTP STRUCTURE  ZMASSBP_EI_SMTP OPTIONAL
*"      SZEM_MBPADDRPOST STRUCTURE  ZEM_MBPADDRPOST OPTIONAL
*"      SZEM_MBPADDRSMTP STRUCTURE  ZEM_MBPADDRSMTP OPTIONAL
*"      SZEM_MBPADDRPHONE STRUCTURE  ZEM_MBPADDRPHONE OPTIONAL
*"      MASSGENCHANGE TYPE  MASSGENCHANGE_T OPTIONAL
*"----------------------------------------------------------------------


  " Create central data container with the called communication signature ...
  DATA(lo_container) = NEW zcl_massbp_upd_0cont(
    VALUE #(
      seldata              = seldata
      testmode             = testmode
      ref_msg              = REF #( msg[] )
      ref_customer_central = REF #( szem_mbpcustkna1[] )
      ref_customer_company = REF #( szem_mbpcustknb1[] )
      ref_customer_sales   = REF #( szem_mbpcustknvv[] )
      ref_bp_centr_org     = REF #( szem_mbpcentrorg[] )
      ref_bp_postal        = REF #( szem_mbpaddrpost[] )
      ref_bp_smtp          = REF #( szem_mbpaddrsmtp[] )
      ref_bp_phone         = REF #( szem_mbpaddrphone[] )
      ref_massgenchange    = REF #( massgenchange[] ) ) ).

  DATA lo_process  TYPE REF TO zcl_massbp_upd_str_0abs.
  DATA lv_strategy TYPE string.

  " Delegate to specialized Class
  lv_strategy = 'NEW_OO_V02'.
  IF lv_strategy = 'NEW_OO_V02'.
    lo_process ?= NEW zcl_massbp_upd_str_v02( lo_container ).
  ELSE.
    lo_process ?= NEW zcl_massbp_upd_str_v01( lo_container ).
  ENDIF.

  lo_process->update( ).
ENDFUNCTION.
