@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'BV - Mass BP BUT000 - Central Organization'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #XL, dataClass: #MIXED }

define view entity ZBM_MASS_BP_COMM_CENTR_ORG
  as select from    but000 as CentralOrgData

    left outer join kna1   as _KNA1 on CentralOrgData.partner = _KNA1.kunnr
    left outer join lfa1   as _LFA1 on CentralOrgData.partner = _LFA1.lifnr

{
  key CentralOrgData.partner                                                             as Partner,

      CentralOrgData.name_org1                                                           as NAME1,
      CentralOrgData.name_org2                                                           as NAME2,
      CentralOrgData.name_org3                                                           as NAME3,
      CentralOrgData.name_org4                                                           as NAME4,
      CentralOrgData.legal_enty                                                          as LEGALFORM,
      CentralOrgData.ind_sector                                                          as INDUSTRYSECTOR,
      CentralOrgData.found_dat                                                           as FOUNDATIONDATE,
      CentralOrgData.liquid_dat                                                          as LIQUIDATIONDATE,
      CentralOrgData.location_1                                                          as LOC_NO_1,
      CentralOrgData.location_2                                                          as LOC_NO_2,
      CentralOrgData.location_3                                                          as CHK_DIGIT,
      CentralOrgData.legal_org                                                           as LEGALORG,
      CentralOrgData.dc_not_req                                                          as DC_NOT_REQ,

      cast( case when _KNA1.kunnr is null then ''
            else 'X' end as zmassbp_kna1_exists preserving type )                        as kna1_Exists,

      cast( case when _LFA1.kunnr is null then ''
            else 'X' end as zmassbp_lfa1_exists preserving type )                        as lfa1_Exists,

      cast( case when _KNA1.zz1_crreason_cus is null then ''
            else _KNA1.zz1_crreason_cus end as zmassbp_crreason_kna1 preserving type )   as zz1_crreason_cus,
      cast( case when _LFA1.zz1_s_crreason_sup is null then ''
            else _LFA1.zz1_s_crreason_sup end as zmassbp_crreason_lfa1 preserving type ) as zz1_s_crreason_sup,

      cast( cast( '' as abap.char( 40 ) ) as zmassbp_crreason_new preserving type )      as zz1_crreason_new
}
