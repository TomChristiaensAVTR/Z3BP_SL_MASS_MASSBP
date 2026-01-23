FUNCTION z_massbp_evt_msg_show_detail.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(MSG) TYPE  MASS_MSG
*"----------------------------------------------------------------------
  SET PARAMETER ID 'DCN' FIELD msg-msgv1.
  SUBMIT z_massbp_disp_appl_log_01
         WITH extno = msg-msgv1
         AND RETURN.
ENDFUNCTION.
