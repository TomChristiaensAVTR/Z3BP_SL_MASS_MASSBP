@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AbapCatalog.sqlViewName: 'ZEM_MBPADDRPHONE'

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BP Phone Address'

// TCH - To be able to use the result DIRECTLY with cl_md_bp_maintain=>maintain
// we need to use the fieldnames as in BAPIADTEL
// TCH - See BAPI_ADDRESSORG_GETDETAIL for the names
// TCH - Phone_XXXXXX field in key is due to otherwise MASS transaction deletes entries 
//       due to comparison with other tables (SMTP) ....

define view ZIM_MASS_BP_ADDR_PHONE
  as select from but020                 as BusinessPartnerAddress

    inner join   ZBM_MASS_BP_ADDR_PHONE as _AddressPhoneNumber    on _AddressPhoneNumber.addrnumber = BusinessPartnerAddress.addrnumber

  association [1..1] to I_BusinessPartner as _BusinessPartner on $projection.Partner = _BusinessPartner.BusinessPartner

{
  key BusinessPartnerAddress.partner  as Partner,
  key _AddressPhoneNumber.addrnumber  as addrnumber,
  key _AddressPhoneNumber.consnumber  as Phone_consnumber,

      _AddressPhoneNumber.consnumber  as consnumber,
      _AddressPhoneNumber.persnumber,
      _AddressPhoneNumber.COUNTRY,
      _AddressPhoneNumber.TELEPHONE,
      _AddressPhoneNumber.TEL_NO,
      _AddressPhoneNumber.CALLER_NO,
      _AddressPhoneNumber.STD_NO,
      _AddressPhoneNumber.FLG_NOUSE,
      _AddressPhoneNumber.STD_RECIP,
      _AddressPhoneNumber.R_3_USER,
      _AddressPhoneNumber.EXTENSION,
      _AddressPhoneNumber.VALID_FROM,
      _AddressPhoneNumber.VALID_TO,

      BusinessPartnerAddress.address_guid
}

where persnumber is initial
  and VALID_TO    = '99991231'
