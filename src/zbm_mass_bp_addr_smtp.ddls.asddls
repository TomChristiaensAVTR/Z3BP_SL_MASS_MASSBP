@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BV - Mass BP - BUT000, BUT020 & ADR6'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity ZBM_MASS_BP_ADDR_SMTP
  as select from adr6

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
  key addrnumber                                                       as addrnumber,
  key persnumber                                                       as persnumber,
  key consnumber                                                       as consnumber,
      // TCH - Shortened the field to be able to CHANGE IT in ZMASS.
      // Indeed, when too long, then the field is NOT EDITABLE ...
      cast(smtp_addr as zmassbp_ad_smtpadr )                           as E_MAIL,
      cast(flgdefault as ad_emailcurdflt preserving type)              as STD_NO,
      cast(flg_nouse as ad_commlinenotforunslctdcntct preserving type) as FLG_NOUSE,

      case valid_from
          when '' then '00010101'
          else cast(substring(valid_from, 1, 8) as abap.dats)
      end                                                              as VALID_FROM,

      case valid_to
          when '' then '99991231'
          else cast(substring(valid_to, 1, 8) as abap.dats)
      end                                                              as VALID_TO,

      _AddressCommunicationRemark,
      _AddressCommunicationUsage
}
