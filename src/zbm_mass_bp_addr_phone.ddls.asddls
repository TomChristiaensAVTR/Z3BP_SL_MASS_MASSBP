@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BV - Mass BP - BUT000, BUT020 & ADR2'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

// TCH - To be able to use the result DIRECTLY with cl_md_bp_maintain=>maintain
// we need to use the fieldnames as in BAPIADSMTP
// TCH - See BAPI_ADDRESSORG_GETDETAIL for the names

define view entity ZBM_MASS_BP_ADDR_PHONE
  as select from adr2

  association [0..*] to I_AddressCommunicationRemark_2 as _AddressCommunicationRemark
    on  $projection.addrnumber = _AddressCommunicationRemark.AddressID
    and $projection.persnumber = _AddressCommunicationRemark.AddressPersonID
    and $projection.consnumber = _AddressCommunicationRemark.CommMediumSequenceNumber
    and _AddressCommunicationRemark.CommunicationMediumType = 'TEL'

  association [0..*] to I_AddressCommunicationUsage    as _AddressCommunicationUsage
    on  $projection.addrnumber = _AddressCommunicationUsage.AddressID
    and $projection.persnumber = _AddressCommunicationUsage.AddressPersonID
    and $projection.consnumber = _AddressCommunicationUsage.CommMediumSequenceNumber
    and _AddressCommunicationUsage.CommunicationMediumType = 'TEL'

  association [0..1] to I_Country                      as _PhoneNumberCountry
    on $projection.COUNTRY = _PhoneNumberCountry.Country

  association [0..1] to I_PhoneNumberType              as _PhoneNumberType
    on $projection.R_3_USER = _PhoneNumberType.PhoneNumberType

{
  key addrnumber                                                       as addrnumber,
  key persnumber                                                       as persnumber,
  key consnumber                                                       as consnumber,

      // TCH - BAPI format to be used ...
      adr2.country                                                     as COUNTRY,
      tel_number                                                       as TELEPHONE,
      telnr_long                                                       as TEL_NO,
      telnr_call                                                       as CALLER_NO,
      cast(flgdefault as ad_phnmbrcurovrldflt preserving type)         as STD_NO,
      cast(flg_nouse as ad_commlinenotforunslctdcntct preserving type) as FLG_NOUSE,
      dft_receiv                                                       as STD_RECIP,
      cast(r3_user    as ad_phonenumbertype preserving type)           as R_3_USER,
      tel_extens                                                       as EXTENSION,

      case valid_from
          when '' then '00010101'
          else cast(substring(valid_from, 1, 8) as abap.dats)
      end                                                              as VALID_FROM,

      case valid_to
          when '' then '99991231'
          else cast(substring(valid_to, 1, 8) as abap.dats)
      end                                                              as VALID_TO
}
