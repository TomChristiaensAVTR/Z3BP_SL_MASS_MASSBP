@AbapCatalog.sqlViewName: 'ZEM_MBPCENTRORG'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'BP Central Org'
define view ZIM_MASS_BP_COMM_CENTR_ORG
  as select from but000 as BusinessPartner
{
  key BusinessPartner.partner as Partner,
      name_org1               as NAME1,
      name_org2               as NAME2,
      name_org3               as NAME3,
      name_org4               as NAME4,
      legal_enty              as LEGALFORM,
      ind_sector              as INDUSTRYSECTOR,
      found_dat               as FOUNDATIONDATE,
      liquid_dat              as LIQUIDATIONDATE,
      location_1              as LOC_NO_1,
      location_2              as LOC_NO_2,
      location_3              as CHK_DIGIT,
      legal_org               as LEGALORG,
      dc_not_req              as DC_NOT_REQ
}
