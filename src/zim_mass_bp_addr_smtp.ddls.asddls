@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AbapCatalog.sqlViewName: 'ZEM_MBPADDRSMTP'

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BP SMTP Address'

// TCH - To be able to use the result DIRECTLY with cl_md_bp_maintain=>maintain
// we need to use the fieldnames as in BAPIADSMTP
// TCH - See BAPI_ADDRESSORG_GETDETAIL for the names 
// TCH - Smtp_XXXXXX field in key is due to otherwise MASS transaction deletes entries 
//       due to comparison with other tables (PHONE) ....

define view ZIM_MASS_BP_ADDR_SMTP
  as select from but020                as BusinessPartnerAddress
  association [0..1] to ZBM_MASS_BP_ADDR_SMTP as _AddressEmailAddress 
    on  _AddressEmailAddress.addrnumber      = BusinessPartnerAddress.addrnumber
    and _AddressEmailAddress.VALID_TO        = '99991231'
    and _AddressEmailAddress.Smtp_persnumber = ''

  association [1..1] to I_BusinessPartner as _BusinessPartner 
    on $projection.Partner = _BusinessPartner.BusinessPartner

{
      // TCH - Mass BP - BUT000, BUT020 & ADRC
      // TCH - Translate the fields to the BAPI Fieldnames
      // TCH - See I_BusinessPartAddress_2 for more information ...
  key BusinessPartnerAddress.partner        as Partner,
  key _AddressEmailAddress.addrnumber       as addrnumber,
  key _AddressEmailAddress.Smtp_consnumber  as Smtp_consnumber,  
      _AddressEmailAddress.consnumber       as consnumber,  
      _AddressEmailAddress.persnumber       as persnumber,
      _AddressEmailAddress.STD_NO,
      _AddressEmailAddress.FLG_NOUSE,
      _AddressEmailAddress.VALID_FROM,
      _AddressEmailAddress.VALID_TO,
      _AddressEmailAddress.E_MAIL,
      _AddressEmailAddress._AddressCommunicationRemark,
      _AddressEmailAddress._AddressCommunicationUsage,
      
      BusinessPartnerAddress.address_guid
}

