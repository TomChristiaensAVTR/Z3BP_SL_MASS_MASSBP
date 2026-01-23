FUNCTION-POOL zmassbp.                      "MESSAGE-ID ..

TYPES gty_szmassbp_cust_central TYPE STANDARD TABLE OF zmassbp_cust_central WITH DEFAULT KEY.
TYPES gty_szmassbp_cust_company TYPE STANDARD TABLE OF zmassbp_cust_company WITH DEFAULT KEY.
TYPES gty_szmassbp_cust_sales   TYPE STANDARD TABLE OF zmassbp_cust_sales WITH DEFAULT KEY.
TYPES gty_massgenchange         TYPE massgenchange_t.

INCLUDE lzmassbpd01.                       " Local class definition
