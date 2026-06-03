@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'cds for tax invoice'
@Metadata.ignorePropagatedAnnotations: true
define view entity zsd_tax_inv_cds_type_name as select distinct from I_ConditionTypeText
{
    key ConditionType,
       ConditionTypeName
}
