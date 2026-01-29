@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BV - Mass BP - BUT000, BUT020 & ADR6'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity ZBM_MASS_BP_ADDR_SMTP
  as select from but020
   
  left outer join adr6 as _Mail
    on but020.addrnumber = _Mail.addrnumber 

  association [0..*] to I_AddressCommunicationRemark_2 as _AddressCommunicationRemark
    on  $projection.addrnumber                              = _AddressCommunicationRemark.AddressID
    and $projection.persnumber                              = _AddressCommunicationRemark.AddressPersonID
    and $projection.consnumber                              = _AddressCommunicationRemark.CommMediumSequenceNumber
    and _AddressCommunicationRemark.CommunicationMediumType = 'INT'

  association [0..*] to I_AddressCommunicationUsage    as _AddressCommunicationUsage
    on  $projection.addrnumber                             = _AddressCommunicationUsage.AddressID
    and $projection.persnumber                             = _AddressCommunicationUsage.AddressPersonID
    and $projection.consnumber                             = _AddressCommunicationUsage.CommMediumSequenceNumber
    and _AddressCommunicationUsage.CommunicationMediumType = 'INT'

{
  key but020.addrnumber                                                      as addrnumber,
  key _Mail.persnumber                                                       as persnumber,
  key _Mail.consnumber                                                       as consnumber,
      // TCH - Shortened the field to be able to CHANGE IT in ZMASS.
      // Indeed, when too long, then the field is NOT EDITABLE ...
      
      but020.partner                                                         as partner,
      
      case when _Mail.persnumber is null    then ''
           when _Mail.persnumber is initial then ''
           else _Mail.persnumber  
      end                                                                    as Smtp_persnumber,

      case when _Mail.consnumber is null    then '000'
           when _Mail.consnumber is initial then '000'
           else _Mail.consnumber  
      end                                                                    as Smtp_consnumber,
      
      cast(_Mail.smtp_addr as zmassbp_ad_smtpadr )                           as E_MAIL,
      cast(_Mail.flgdefault as ad_emailcurdflt preserving type)              as STD_NO,
      cast(_Mail.flg_nouse as ad_commlinenotforunslctdcntct preserving type) as FLG_NOUSE,

      case when _Mail.valid_from is initial then '00010101'
           when _Mail.valid_from is null    then '00010101'
           else cast(substring(_Mail.valid_from, 1, 8) as abap.dats)
      end                                                              as VALID_FROM,

      case when _Mail.valid_to is initial then '99991231'
           when _Mail.valid_to is null    then '99991231'
           else cast(substring(_Mail.valid_to, 1, 8) as abap.dats)
      end                                                              as VALID_TO,

      _AddressCommunicationRemark,
      _AddressCommunicationUsage
}
