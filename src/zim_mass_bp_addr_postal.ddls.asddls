@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AbapCatalog.sqlViewName: 'ZEM_MBPADDRPOST'

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BP Postal Address'

// TCH - To be able to use the result DIRECTLY with cl_md_bp_maintain=>maintain
// we need to use the fieldnames as in bapibus1006_address

define view ZIM_MASS_BP_ADDR_POSTAL
  as select from but020            as BusinessPartnerAddress

    inner join   I_BusinessPartner as _BusinessPartner       on BusinessPartnerAddress.partner = _BusinessPartner.BusinessPartner

  association [1..1] to I_Address_2          as _Address
    on  $projection.addrnumber           = _Address.AddressID
    and _Address.AddressRepresentationCode is initial
    and $projection.PersonNumber         = _Address.AddressPersonID

  association [0..1] to I_BPProtectedAddress as _BPProtectedAddress
    on  $projection.businesspartner = _BPProtectedAddress.BusinessPartner
    and $projection.addressnumber   = _BPProtectedAddress.AddressID

{
      // TCH - Mass BP - BUT000, BUT020 & ADRC
      // TCH - Translate the fields to the BAPI Fieldnames
      // TCH - See I_BusinessPartAddress_2 for more information ...
  key BusinessPartnerAddress.partner         as Partner,
  key BusinessPartnerAddress.addrnumber      as addrnumber,

      _BusinessPartner.PersonNumber          as PersonNumber,
      BusinessPartnerAddress.addr_valid_from as ValidityStartDate,
      BusinessPartnerAddress.addr_valid_to   as ValidityEndDate,
      BusinessPartnerAddress.address_guid    as BusinessPartnerAddressUUID,
      BusinessPartnerAddress.move_addr       as BPTargetAddressID,
      BusinessPartnerAddress.addr_move_date  as BPAddressMoveDateTime,
      _Address.HouseNumber                   as House_No,
      _Address.HouseNumberSupplementText     as House_No2,
      _Address.StreetName                    as Street,
      _Address.PostalCode                    as Postl_Cod1,
      _Address.POBox                         as Po_Box,
      _Address.CityName                      as City,
      _Address.DistrictName                  as District,
      _Address.TransportZone                 as Transpzone,
      _Address.StreetPrefixName1             as Str_Suppl1,
      _Address.StreetPrefixName2             as Str_Suppl2,
      _Address.StreetSuffixName1             as Str_Suppl3,
      _Address.StreetSuffixName2             as Location,
      _Address.Building                      as Building,
      _Address.Floor                         as Floor,
      _Address.AddressTimeZone               as Time_Zone,
      
      BusinessPartnerAddress.address_guid
}
