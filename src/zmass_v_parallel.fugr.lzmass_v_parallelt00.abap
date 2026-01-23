*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZMASS_V_PARALLEL................................*
TABLES: ZMASS_V_PARALLEL, *ZMASS_V_PARALLEL. "view work areas
CONTROLS: TCTRL_ZMASS_V_PARALLEL
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_ZMASS_V_PARALLEL. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZMASS_V_PARALLEL.
* Table for entries selected to show on screen
DATA: BEGIN OF ZMASS_V_PARALLEL_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZMASS_V_PARALLEL.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZMASS_V_PARALLEL_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZMASS_V_PARALLEL_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZMASS_V_PARALLEL.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZMASS_V_PARALLEL_TOTAL.

*.........table declarations:.................................*
TABLES: ZMASS_C_PARALLEL               .
