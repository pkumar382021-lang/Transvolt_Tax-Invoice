@AbapCatalog.viewEnhancementCategory: [#NONE] 
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'cds for sum'
@Metadata.ignorePropagatedAnnotations: true
/*+[hideWarning] { "IDS" : [ "CARDINALITY_CHECK" ]  } */
define view entity zsd_billing_qat_sum_cds as select distinct from I_BillingDocumentItem as a
 left outer join zsd_tax_inv_cds_amt  as b  on a.BillingDocument = b.BillingDocument
                                                    and a.BillingDocumentItem = b.BillingDocumentItem
                                                      
{
    key a.BillingDocument, 
//       a.BillingDocumentItem,
    
       
        sum(cast(a.NetAmount as abap.dec(13,3))  )  as netamount ,
        sum(cast(a.BillingQuantity as abap.dec(13,2))) as BillingQuantity,
        b.amt as amt,
         a.BillingDocumentItemText,
         cast(count(*  ) as abap.char(250))  as linietm ,
         b.conditionrate as conditionrate ,
         b.ConditionType,
         sum(b.cond_amt)   as  cond_amt ,
         b.ConditionQuantityUnit,
         b.ConditionTypeName
//         c.text_line
//         c.conditionrate1
         
      
         
}


group by
   
//    b.amt,
    a.BillingDocumentItemText,
//    b.conditionrate,
    b.ConditionType,
//    b.cond_amt,
    b.ConditionQuantityUnit,
//    b.ConditionTypeName,
   
//    b.BillingDocument,
//    b.cond_amt,
    b.ConditionTypeName,
    a.BillingDocument,
    b.amt,
    b.conditionrate
//    a.BillingDocumentItem
//    b.cond_amt
//    c.text_line,
//    c.BillingDocument
//    b.ConditionType
//    c.conditionrate1
 
//    b.BillingDocumentItem
