INTERFACE zif_massbp_co
  PUBLIC.

  CONSTANTS gc_table_bp_centr_org TYPE tabname    VALUE 'ZEM_MBPCENTRORG'.

  CONSTANTS gc_table_cust_central TYPE tabname    VALUE 'ZEM_MBPCUSTKNA1'.
  CONSTANTS gc_table_cust_company TYPE tabname    VALUE 'ZEM_MBPCUSTKNB1'.
  CONSTANTS gc_table_cust_sales   TYPE tabname    VALUE 'ZEM_MBPCUSTKNVV'.
  CONSTANTS gc_table_cust_tax     TYPE tabname    VALUE 'ZEM_MBPCUSTKNVI'.

  CONSTANTS gc_table_vend_central TYPE tabname    VALUE 'ZEM_MBPVENDLFA1'.
  CONSTANTS gc_table_vend_company TYPE tabname    VALUE 'ZEM_MBPVENDLFB1'.
  CONSTANTS gc_table_vend_purch   TYPE tabname    VALUE 'ZEM_MBPVENDLFM1'.

  CONSTANTS gc_table_bp_postal    TYPE tabname    VALUE 'ZEM_MBPADDRPOST'.
  CONSTANTS gc_table_bp_smtp      TYPE tabname    VALUE 'ZEM_MBPADDRSMTP'.
  CONSTANTS gc_table_bp_phone     TYPE tabname    VALUE 'ZEM_MBPADDRPHONE'.

  CONSTANTS gc_para_theshold      TYPE int1       VALUE 10.
  CONSTANTS gc_massty_zmassbp     TYPE massobjtyp VALUE 'ZMASSBP'.

  CONSTANTS gc_objtask_insert     TYPE char1      VALUE 'I'.
  CONSTANTS gc_objtask_update     TYPE char1      VALUE 'U'.
  CONSTANTS gc_objtask_modify     TYPE char1      VALUE 'M'.
ENDINTERFACE.
