@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'cds  for tax invoice'
@Metadata.ignorePropagatedAnnotations: true
define view entity zsd_tax_inv_cds_amt2 as select distinct from I_BillingDocumentItemPrcgElmnt as a
left outer join I_BillingDocumentItem    as b on  a.BillingDocument = b.BillingDocument
{
    key a.BillingDocument,
     key b.BillingDocumentItem,
     case
               when a.ConditionRateAmount is not initial
                 then cast( a.ConditionRateAmount as abap.dec( 15,2 ) )
               else cast( a.ConditionRateRatio as abap.dec( 15,2 ) )
             end as conditionrate1,
             a.ConditionIsManuallyChanged,
             a.ConditionType ,
             cast(a.ConditionAmount as abap.dec(13,2)) as cond_amt,
             cast(b.BillingQuantity as  abap.dec(13,2))  as bill_qat
//              \_pricingconditiontype\_text_2[ language = 'E' ]-conditiontypename AS conditiontypename,
             
             
} 
 where     a.ConditionType = 'ZNRM'
        or a.ConditionType = 'ZEXS'
        or a.ConditionType = 'ZSHT '
        or a.ConditionType = 'ZADV'
        or a.ConditionType = 'ZINS'
        or a.ConditionType = 'ZPR0'
        or a.ConditionType = 'ZSCR'
         or a.ConditionType = 'ZFMS'
          or a.ConditionType = 'ZBAS'
