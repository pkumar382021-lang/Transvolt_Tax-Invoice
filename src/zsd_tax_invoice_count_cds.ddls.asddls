@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'cds for tax  invoice'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSD_Tax_invoice_count_cds as select distinct from I_BillingDocumentItem
{
   key BillingDocument,
    key BillingDocumentItemText,
      cast(count( * ) as abap.char(200)) as  text_line 
}
group by
    BillingDocument,
    BillingDocumentItemText
