@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'cds for amt'
@Metadata.ignorePropagatedAnnotations: true
define view entity zsd_tax_inv_cds_amt as select distinct from I_BillingDocItemPrcgElmntBasic as  a
left outer join zsd_tax_inv_cds_type_name as b on   a.ConditionType = b.ConditionType
                     
{
    key a.BillingDocument,
    key a.BillingDocumentItem,
       sum(cast(a.ConditionRateValue as abap.dec(13,2))) as amt  ,
       
        case
               when a.ConditionRateAmount is not initial
                 then cast( a.ConditionRateAmount as  abap.dec( 15,2 ) )
//               else cast( a.ConditionRateRatio as abap.dec( 15,2 ) )
             end as conditionrate,
             a.ConditionIsManuallyChanged ,
             a.ConditionType ,
             b.ConditionTypeName,
//             c.BillingDocumentItemText,
            
             
              sum(cast(a.ConditionAmount as abap.dec(13,2))) as cond_amt,
//               @ObjectModel.foreignKey.association: '_ConditionQuantityUnit'
              a.ConditionQuantityUnit
             
}
where
 a.ConditionType = 'ZNRM'
        or a.ConditionType = 'ZEXS'
        or a.ConditionType = 'ZSHT '
        or a.ConditionType = 'ZADV'
        or a.ConditionType = 'ZINS'
        or a.ConditionType = 'ZPR0'
        or a.ConditionType = 'ZSCR'
         or a.ConditionType = 'ZFMS'
          or a.ConditionType = 'ZBAS'
          
// where   a.ConditionIsManuallyChanged  <> 'X' 

// and  
// a.ConditionType = 'JOCG'

group by
    a.BillingDocument,
    a.ConditionRateAmount,
    a.ConditionRateRatio,
    a.ConditionIsManuallyChanged,
    a.ConditionType,
    a.ConditionQuantityUnit,
    b.ConditionTypeName,
    a.BillingDocumentItem
//    c.BillingDocumentItemText
//    b.ConditionTypeName
 
//    ConditionAmount
