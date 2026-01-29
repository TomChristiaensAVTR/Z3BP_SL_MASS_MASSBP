@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AbapCatalog.sqlViewName: 'ZEM_MBPCENTRORG'

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BP Central Org'

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #XL, dataClass: #MIXED }

define view ZIM_MASS_BP_COMM_CENTR_ORG
  as select from but000 as BusinessPartner
    inner join ZBM_MASS_BP_COMM_CENTR_ORG as _CentralOrgData
    on BusinessPartner.partner = _CentralOrgData.Partner

{
  key BusinessPartner.partner as Partner,

      _CentralOrgData.kna1_Exists,
      _CentralOrgData.lfa1_Exists,

      _CentralOrgData.zz1_crreason_cus,
      _CentralOrgData.zz1_s_crreason_sup,
      
      _CentralOrgData.zz1_crreason_new,    

      _CentralOrgData.NAME1,
      _CentralOrgData.NAME2,
      _CentralOrgData.NAME3,
      _CentralOrgData.NAME4,
      _CentralOrgData.LEGALFORM,
      _CentralOrgData.INDUSTRYSECTOR,
      _CentralOrgData.FOUNDATIONDATE,
      _CentralOrgData.LIQUIDATIONDATE,
      _CentralOrgData.LOC_NO_1,
      _CentralOrgData.LOC_NO_2,
      _CentralOrgData.CHK_DIGIT,
      _CentralOrgData.LEGALORG,
      _CentralOrgData.DC_NOT_REQ,
      
      BusinessPartner.valid_from,
      BusinessPartner.valid_to  
}
