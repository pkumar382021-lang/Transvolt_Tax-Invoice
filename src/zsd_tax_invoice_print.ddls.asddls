@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Tax invoice print'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZSD_TAX_INVOICE_PRINT 
  as select from zsdt_taxinv_prnt
{
  key bill_doc                  as BillDoc,
      cast('' as abap.char(4))  as BillDocType,
      cast('' as spart )        as Division,
      form_name                 as FormName,
      file_contents             as FileContents,
      cast('' as abap_boolean ) as BSalesFlag,
      cast('' as abap_boolean ) as AckDateFlag,
      sto_qty                   as STOQty,
      sto_unit                  as STOUnit

}
