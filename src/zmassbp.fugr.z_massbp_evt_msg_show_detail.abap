FUNCTION z_massbp_evt_msg_show_detail.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(MSG) TYPE  MASS_MSG
*"----------------------------------------------------------------------
  IF gs_context-masssaveinfos IS NOT INITIAL.
    DATA(lv_extno) = gs_context-masssaveinfos-run.
  ENDIF.

  SUBMIT z_massbp_disp_appl_log_01
         WITH p_extno = lv_extno
         AND RETURN.
ENDFUNCTION.
