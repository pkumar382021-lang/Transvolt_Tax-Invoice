@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'F4 help for tax invoice'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZSD_TAX_INVOICE_F4 
  as select from I_BillingDocument
{
  key BillingDocument     as BillDoc,
      BillingDocumentType as BillDocType,
      Division            as Division
}
where
      BillingDocumentType = 'F2'   //Bridge Sales Invoice & Track Invoice
  or BillingDocumentType = 'F8'   //Bridge STO Invoice
  or BillingDocumentType = 'JSTO' //Bridge STO Invoice
  or BillingDocumentType  = 'G2'
  or BillingDocumentType = 'L2'
