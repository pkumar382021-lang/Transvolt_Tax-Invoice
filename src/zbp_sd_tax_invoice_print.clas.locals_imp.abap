CLASS lhc_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA mt_buffer TYPE STANDARD TABLE OF zsdt_taxinv_prnt.
ENDCLASS.
CLASS lhc_zsd_tax_invoice_print DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zsd_tax_invoice_print RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zsd_tax_invoice_print RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE zsd_tax_invoice_print.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zsd_tax_invoice_print.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zsd_tax_invoice_print.

    METHODS read FOR READ
      IMPORTING keys FOR READ zsd_tax_invoice_print RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zsd_tax_invoice_print.
    METHODS get_xml_tag_value
      IMPORTING
        iv_xml          TYPE string
        iv_tag          TYPE string
      RETURNING
        value(r_result) TYPE string.

ENDCLASS.

CLASS lhc_zsd_tax_invoice_print IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.

*
****------------------------------------- IRN Details -------------------------------------***


 DATA(ls_entity) = VALUE #( entities[ 1 ] OPTIONAL ).

    IF ls_entity-billdoc IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_billingdoc) = |{ ls_entity-billdoc ALPHA = IN }|.

*-- All TYPES must be declared first before any DATA --*
TYPES: BEGIN OF tys_irn_item,
         sap_uuid            TYPE string,
         irn                 TYPE string,
         qrcode1             TYPE string,
         qrcode2             TYPE string,
         acknowledgementtime TYPE string,
         acknowledgementdate TYPE string,
         acknowledgementno   TYPE string,
         ewaybillvalidtotime TYPE string,
         ewaybillvalidtodate TYPE string,
         ewaybillvalidfromdate TYPE string,
         ewaybillvalidfromtime TYPE string,
         ewaybill            TYPE string,
         billingdocumenttype TYPE string,
         billingdate         TYPE string,
         companycode         TYPE string,
         billingdocument     TYPE string,
         fiscalyear          TYPE string,
         customer            TYPE string,
         currency            TYPE string,
         sap_createdbyuser   TYPE string,
       END OF tys_irn_item.

TYPES: tyt_irn_items TYPE STANDARD TABLE OF tys_irn_item WITH DEFAULT KEY.

" OData v2 wrapper: d.results[]
TYPES: BEGIN OF tys_results,
         results TYPE tyt_irn_items,
       END OF tys_results.

TYPES: BEGIN OF tys_irn_result,
         d TYPE tys_results,
       END OF tys_irn_result.



    types:       BEGIN OF tys_company_add,
             companyname   TYPE string,
             plantaddress1 TYPE string,
             plantaddress2 TYPE string,
             plantaddress3 TYPE string,
             gstin         TYPE string,
             statename     TYPE string,
             companyemail  TYPE string,
           END OF tys_company_add,

           BEGIN OF tys_ship_to_add,
             shiptoname      TYPE string,
             shiptoaddress1  TYPE string,
             shiptoaddress2  TYPE string,
             shiptoaddress3  TYPE string,
             shiptoaddress4  TYPE string,
             shiptogstin     TYPE string,
             shiptostatename TYPE string,
           END OF tys_ship_to_add,

           BEGIN OF tys_bill_to_add,
             billtoname     TYPE string,
             billtoaddress1 TYPE string,
             billtoaddress2 TYPE string,
             billtoaddress3 TYPE string,
             billtoaddress4 TYPE string,
             biillgstin     TYPE string,
             billstatename  TYPE string,
           END OF tys_bill_to_add,

           BEGIN OF tys_invoice_details,
             invoiceno      TYPE string,
             invoicedate    TYPE string,
             delchallanno   TYPE string,
             delchallandate TYPE string,
             payterm        TYPE string,
             referenceno    TYPE string,
             loaordno       TYPE string,
             loaorddate     TYPE string,
             transportname  TYPE string,
             grno           TYPE string,
             grdate         TYPE string,
             vehicleno      TYPE string,
             destination    TYPE string,
           END OF tys_invoice_details,

           BEGIN OF tys_head_det,
             formname   TYPE string,
             companyadd TYPE tys_company_add,
             shiptoadd  TYPE tys_ship_to_add,
             billtoadd  TYPE tys_bill_to_add,
             invdet     TYPE tys_invoice_details,
           END OF tys_head_det,

           BEGIN OF tys_footer_det,
             companyname TYPE string,
             companypan  TYPE string,
           END OF tys_footer_det,

           BEGIN OF tys_customer,
             shiptocustomer TYPE kunnr,
             billtocustomer TYPE kunnr,
           END OF tys_customer.

*-- All DATA declarations together after TYPES --*
    DATA: ls_irn_result TYPE tys_irn_result,
          lv_irn        TYPE string,
          lv_qrcode     TYPE string,
          QRCODE        TYPE xstring,
          lv_ack_no     TYPE string,
          lv_ack_date   TYPE string,
          ls_head       TYPE tys_head_det,
          ls_footer_det TYPE tys_footer_det,
          lv_template   TYPE string,
          lv_xml        TYPE string,
          lv_formname   TYPE zsd_tax_invoice_print-formname,
          ls_customer   TYPE tys_customer,
          lv_qr_xstring  TYPE xstring,
           ssb_image1    type string .


TRY.
    DATA(lv_base_url) = |https://{ cl_abap_context_info=>get_system_url( ) }:443|.
    DATA(lv_path) = |/sap/opu/odata/sap/YY1_SDIRNGETDATA_CDS/YY1_SDIRNGETDATA|.

    DATA(lv_full_url) = |{ lv_base_url }{ lv_path }|.

    DATA(lo_dest) = cl_http_destination_provider=>create_by_url( lv_full_url ).
    DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
    DATA(lo_request) = lo_http_client->get_http_request( ).

    lo_request->set_authorization_basic(
        i_username = 'SD-IRN'
        i_password = '2</EpCU3A&-6/WrrhP293xwAS[%E7Aby5cP$9Xzr' ).


    lo_request->set_header_fields( VALUE #(
      ( name = 'Accept' value = 'application/json' )
    ) ).

    DATA(lv_filter_path) = |{ lv_path }?$filter=BillingDocument eq '{ lv_billingdoc }'&$format=json|.
    lo_request->set_uri_path( lv_filter_path ).

    DATA(lo_response) = lo_http_client->execute( if_web_http_client=>get ).
    DATA(lv_response_str) = lo_response->get_text( ).


    IF lv_response_str CS '<feed' OR lv_response_str CS '<entry' OR lv_response_str CS '<m:properties'.
      " It's XML — parse with iXML
      DATA: lv_irn_xml       TYPE string,
            lv_qrcode_xml    TYPE string,
            lv_ack_no_xml    TYPE string,
            lv_ack_date_xml  TYPE string.

      " Parse XML using simple string operations or iXML
      " Simple approach: extract values between tags
      lv_irn_xml = get_xml_tag_value(
        iv_xml = lv_response_str
        iv_tag = 'd:IRN' ).

      lv_qrcode_xml = get_xml_tag_value(
        iv_xml = lv_response_str
        iv_tag = 'd:QRCode' ).

      lv_ack_no_xml = get_xml_tag_value(
        iv_xml = lv_response_str
        iv_tag = 'd:AcknowledgementNo' ).

      lv_ack_date_xml = get_xml_tag_value(
        iv_xml = lv_response_str
        iv_tag = 'd:AcknowledgementDate' ).

      lv_irn      = lv_irn_xml.
      lv_qrcode   = lv_qrcode_xml.
      lv_ack_no   = lv_ack_no_xml.
      lv_ack_date = lv_ack_date_xml.

    ELSE.

      /ui2/cl_json=>deserialize(
        EXPORTING json        = lv_response_str
                  pretty_name = /ui2/cl_json=>pretty_mode-camel_case
        CHANGING  data        = ls_irn_result ).
 IF ls_irn_result-d-results IS NOT INITIAL.
        lv_irn      = ls_irn_result-d-results[ 1 ]-irn.

        lv_ack_no   = ls_irn_result-d-results[ 1 ]-acknowledgementno.
        lv_ack_date = ls_irn_result-d-results[ 1 ]-acknowledgementdate.

        DATA(lv_qr_jwt) =
ls_irn_result-d-results[ 1 ]-qrcode1  &&  ls_irn_result-d-results[ 1 ]-qrcode2.

      ELSE.
        lv_irn = ''. lv_qrcode = ''. lv_ack_no = ''. lv_ack_date = ''.
      ENDIF.

*DATA(lv_qr_jwt) =
*ls_irn_result-d-results[ 1 ]-qrcode1  &&  ls_irn_result-d-results[ 1 ]-qrcode2.



lv_qrcode = |https://uat.logitax.in/TransactionAPI/GetBarCodeImage?BarCodeString={ lv_qr_jwt }|.

TRY.
          DATA(lo_dest2)   = cl_http_destination_provider=>create_by_url( lv_qrcode ).
          DATA(lo_client2) = cl_web_http_client_manager=>create_by_http_destination( lo_dest2 ).
          DATA(lo_resp2)   = lo_client2->execute( if_web_http_client=>get ).


        IF lo_resp2->get_status( )-code = 200.
  lv_qr_xstring = lo_resp2->get_binary( ).
ENDIF.

IF lv_qr_xstring IS NOT INITIAL.
  ssb_image1 = xco_cp=>xstring( lv_qr_xstring
                   )->as_string( xco_cp_binary=>text_encoding->base64
                   )->value.
ENDIF.







        CATCH cx_web_http_client_error cx_http_dest_provider_error.
          CLEAR: lv_qr_xstring, ssb_image1.
      ENDTRY.





    ENDIF.

  CATCH cx_web_http_client_error cx_web_message_error cx_http_dest_provider_error INTO DATA(lx_error).
    lv_irn      = ''.
    lv_qrcode   = ''.
    lv_ack_no   = ''.
    lv_ack_date = ''.
ENDTRY.



"""""""""""""""""""""""""""""""""""converter for date  """""""""""""""""""""""""""""""""""""""""""""""""""""""

DATA: lv_timestamp TYPE string,
      lv_millis    TYPE int8,
      lv_seconds   TYPE int8,
      lv_days      TYPE i,
      lv_date      TYPE d.

FIND FIRST OCCURRENCE OF REGEX '\d+' IN lv_ack_date
     MATCH OFFSET DATA(lv_off)
     MATCH LENGTH DATA(lv_len).

IF sy-subrc = 0.

  lv_timestamp = lv_ack_date+lv_off(lv_len).

  lv_millis = CONV int8( lv_timestamp ).


  lv_seconds = lv_millis / 1000.


  lv_days = lv_seconds DIV 86400.


  lv_date = '19700101'.


  lv_date = cl_abap_context_info=>get_system_date( ) -
            cl_abap_context_info=>get_system_date( ) +
            lv_date + lv_days.

  lv_ack_date = |{ lv_date+6(2) }-{ lv_date+4(2) }-{ lv_date(4) }|.

ENDIF.


    SELECT SINGLE billingdocumenttype FROM i_billingdocument   WITH PRIVILEGED ACCESS
    WHERE division = @ls_entity-division
    AND billingdocumenttype = @ls_entity-billdoctype
    INTO @DATA(lv_anme).


    IF lv_anme = 'G2'.

      ls_head-formname = 'Credit Memo'.
    ELSEIF lv_anme = 'L2'.
      ls_head-formname = 'Debit  Memo'.
    ELSEIF lv_anme = 'F2'.
*   ls_head-formname = ''
      ls_head-formname = 'Tax Invoice'.
    ENDIF.


    SELECT SINGLE
      FROM i_billingdocument
      FIELDS billingdocument,
             creationdate AS invoicedate,
             totalnetamount,
             totaltaxamount,
             salesorganization,
             \_customerpaymentterms\_text[ language = 'E' ]-customerpaymenttermsname
      WHERE billingdocument = @lv_billingdoc
    INTO @DATA(ls_invoicedetails).
    IF sy-subrc IS INITIAL.
    ENDIF.




    SELECT SINGLE salesorganization,
                  addressid,
                  CompanyCode

            FROM i_salesorganization
            WHERE salesorganization = @ls_invoicedetails-salesorganization
            INTO @DATA(ls_sorg).



select single companycodeparametervalue
from I_AddlCompanyCodeInformation
where CompanyCode = @ls_sorg-CompanyCode
into @data(lv_cin) .



    SELECT SINGLE salesorganizationname,
                  salesorganization

            FROM i_salesorganizationtext
            WHERE salesorganization = @ls_invoicedetails-salesorganization
            INTO @DATA(ls_sorgtext).


    SELECT SINGLE floor,
                  roomnumber,
                  building,
                  country,
                  region,
                  streetname,
                  streetprefixname1,
                  streetprefixname2,
                  housenumber,
                  streetsuffixname1,
                  streetsuffixname2,
                  districtname,
                  cityname,
                  postalcode
      FROM i_addrorgnamepostaladdress
      WITH PRIVILEGED ACCESS
      WHERE addressid = @ls_sorg-addressid
    INTO @DATA(wa_soadd).


    DATA lv_plantadd TYPE string.

    CONCATENATE wa_soadd-floor wa_soadd-roomnumber  wa_soadd-building wa_soadd-streetname wa_soadd-streetprefixname1
                wa_soadd-streetprefixname2 INTO lv_plantadd SEPARATED BY ''.

    "Billing Document - Sales/Purchase/Delivery Documents

    SELECT
      FROM i_billingdocumentitem
      FIELDS billingdocument,
             billingdocumentitem,
             plant,
             salesdocument       AS soponumber,
             salesdocumentitem   AS soponumberitem,
             referencesddocument AS deliverydoc,
             referencesddocumentitem AS deliverydocitem
      WHERE billingdocument = @lv_billingdoc
    INTO TABLE @DATA(lt_billsalesdoc).


    IF sy-subrc IS INITIAL.
      DATA(lv_soponumber) = VALUE vbeln( lt_billsalesdoc[ 1 ]-soponumber OPTIONAL ).
      DATA(lv_soponumber_item) = VALUE #( lt_billsalesdoc[ 1 ]-soponumberitem OPTIONAL ).
      DATA(lv_deliverynumber) = VALUE #( lt_billsalesdoc[ 1 ]-deliverydoc OPTIONAL ).
    ENDIF.

    READ TABLE lt_billsalesdoc INTO DATA(wa_bitem) INDEX 1.

    SELECT SINGLE plant ,
                  businessplace
               FROM i_plant
               WHERE plant = @wa_bitem-plant
               INTO @DATA(ls_plant).

    SELECT SINGLE in_gstidentificationnumber ,
                  businessplace,
                  businessplacedescription
               FROM i_businessplace
               WHERE businessplace = @ls_plant-businessplace
                     and CompanyCode  = @ls_sorg-CompanyCode
               INTO @DATA(ls_bplace).

    DATA lv_formtype(10).

    IF ls_entity-division = '11' OR ls_entity-division = '12' OR ls_entity-division = '13' OR ls_entity-division = '14' OR ls_entity-division = '03'
    OR ls_entity-division = '15' OR ls_entity-division = '16' OR ls_entity-division = '19'
       .
      lv_formtype = 'service'.
    ELSEIF  ls_entity-division = '17' . " OR  ls_entity-division = '0'.
      lv_formtype = 'scrap'.
    ELSEIF  ls_entity-division = '18'. "OR ls_entity-division = '03'.
      lv_formtype = 'stock'.
    ENDIF.

*------------  Bridge Sales & Track Invoice ------------*


    IF ls_entity-billdoctype = 'F2'
    OR ls_entity-billdoctype = 'L2'
    OR ls_entity-billdoctype = 'G2'.

**      IF lv_formtype = 'service'.

      "Sold to Party
      SELECT SINGLE
          FROM i_billingdocumentpartner WITH PRIVILEGED ACCESS AS a
          LEFT JOIN  i_billingdocument AS b ON a~billingdocument = b~billingdocument

          FIELDS a~customer
          WHERE b~billingdocument = @lv_billingdoc
            AND partnerfunction = 'AG'
      INTO @ls_customer-shiptocustomer .

      SELECT SINGLE
          FROM i_billingdocumentpartner
          FIELDS customer
          WHERE billingdocument = @lv_billingdoc
            AND partnerfunction = 'RE'
      INTO @ls_customer-billtocustomer .


**      ENDIF.

      DATA(lv_salesdoc) = lv_soponumber.


      "LOA details
      SELECT SINGLE
        FROM i_salesdocument
        FIELDS purchaseorderbycustomer   AS loaordno,
               customerpurchaseorderdate AS loaorddate
        WHERE salesdocument = @lv_salesdoc
      INTO @DATA(ls_loadetails).
      IF sy-subrc IS INITIAL.
      ENDIF.

      "Sales Item Text details
      READ ENTITIES OF i_salesordertp FORWARDING PRIVILEGED
        ENTITY salesorderitem
        BY \_itemtext
        ALL FIELDS
        WITH VALUE #( FOR item IN lt_billsalesdoc
                      ( %key-salesorder     = item-soponumber
                        %key-salesorderitem = item-soponumberitem ) )
      RESULT DATA(lt_salesorditemtext)
      FAILED DATA(ls_failed_itemtext)
      REPORTED DATA(ls_reported_itemtext).

      "Sales Header Text
      READ ENTITIES OF i_salesordertp FORWARDING PRIVILEGED
        ENTITY salesorder
        BY \_text
        ALL FIELDS
        WITH VALUE #( ( %key-salesorder = lv_soponumber ) )
      RESULT DATA(lt_salesordhdrtext)
      FAILED DATA(ls_failed_hdrtext)
      REPORTED DATA(ls_reported_hdrtext).

      DATA(lv_referenceno) = VALUE #( lt_salesordhdrtext[ language   = 'E'
                                                          longtextid = 'TX01' ]-longtext OPTIONAL ).


*------------ Bridge STO Invoice ------------*
    ELSEIF ls_entity-billdoctype = 'F8' OR
           ls_entity-billdoctype = 'JSTO' OR
           ls_entity-billdoctype = 'L2' OR
           ls_entity-billdoctype = 'G2'.

      lv_formname = 'Bridge-STO'.

      DATA(lv_purdoc) = lv_soponumber.
      DATA(lv_purdocitem) = lv_soponumber_item.


      "Ship to address for STO
      SELECT SINGLE storagelocation, plant
        FROM i_purchaseorderitemapi01
        WHERE purchaseorder = @lv_purdoc
        AND purchaseorderitem = @lv_purdocitem
      INTO @DATA(ls_storeloc).
      IF sy-subrc = 0.

        SELECT SINGLE addressid
          FROM i_storagelocationaddress
          WHERE storagelocation = @ls_storeloc-storagelocation
            AND plant = @ls_storeloc-plant
        INTO @DATA(lv_storeaddr).

        SELECT SINGLE country,
                      region,
                      streetname,
                      streetprefixname1,
                      streetprefixname2,
                      housenumber,
                      streetsuffixname1,
                      streetsuffixname2,
                      districtname,
                      cityname,
                      postalcode,
                      addressid
          FROM i_addrorgnamepostaladdress
          WITH PRIVILEGED ACCESS
          WHERE addressid = @lv_storeaddr
        INTO @DATA(wa_toaddr).


*        SELECT SINGLE streetname, streetprefixname1, streetprefixname2, housenumber, streetsuffixname1,
*               streetsuffixname2,districtname,cityname,postalcode,region ,country
*               FROM i_addrorgnamepostaladdress WITH PRIVILEGED ACCESS
*               WHERE addressid = @waa
*                INTO @DATA(wa_recaddr).

        SELECT SINGLE regionname
          FROM i_regiontext
          WHERE country = @wa_toaddr-country
            AND region = @wa_toaddr-region
            AND language = @sy-langu
        INTO @DATA(lv_sh_addr_state).

        DATA(lv_sh_addr1) = |{ wa_toaddr-streetprefixname1 } { wa_toaddr-streetprefixname2 }|.
        DATA(lv_sh_addr2) = |{ wa_toaddr-streetname }|.
        DATA(lv_sh_addr3) = |{ wa_toaddr-cityname } { wa_toaddr-postalcode }|.
        DATA(lv_sh_addr4) = |{ wa_toaddr-country }|.
        DATA(lv_state) = lv_sh_addr_state.

        IF lv_sh_addr1 CO ' '.
          CONDENSE lv_sh_addr1.
        ENDIF.

        IF lv_sh_addr2 CO ' '.
          CONDENSE lv_sh_addr2.
        ENDIF.

        IF lv_sh_addr3 CO ' '.
          CONDENSE lv_sh_addr3.
        ENDIF.

        IF lv_sh_addr4 CO ' '.
          CONDENSE lv_sh_addr4.
        ENDIF.

      ENDIF.



conCATENATE   wa_soadd-StreetPrefixName1  wa_soadd-StreetPrefixName2 into data(ne)  sePARATED BY ',' .
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


      "LOA details - Order Number
      SELECT SINGLE
        FROM i_purchaseordernotetp_2
        FIELDS plainlongtext
        WHERE purchaseorder  = @lv_purdoc
          AND textobjecttype = 'F01'
          AND language = 'E'
      INTO @ls_loadetails-loaordno.
      IF sy-subrc IS INITIAL.
      ENDIF.

      "LOA details - Order Date
      SELECT SINGLE
        FROM i_purchaseorderapi01
        FIELDS creationdate
        WHERE purchaseorder = @lv_purdoc
      INTO @ls_loadetails-loaorddate.
      IF sy-subrc IS INITIAL.
      ENDIF.

      "Purchase Item Text details
      SELECT SINGLE
        FROM i_purchaseordernotetp_2
        FIELDS plainlongtext
        WHERE purchaseorder  = @lv_purdoc
          AND textobjecttype = 'F02'
          AND language = 'E'
       INTO @DATA(lv_po_text).
      IF sy-subrc IS INITIAL.
      ENDIF.


      "Purchase Order Header Text - Reference No
      SELECT SINGLE
        FROM i_purchaseordernotetp_2
        FIELDS plainlongtext
        WHERE purchaseorder  = @lv_purdoc
          AND textobjecttype = 'F26'
          AND language = 'E'
       INTO @lv_referenceno.
      IF sy-subrc IS INITIAL.
      ENDIF.

    ENDIF.


    "Customer Address details
    SELECT
      FROM i_customer AS _cust
      LEFT OUTER JOIN i_regiontext AS _state ON _cust~region = _state~region
                                            AND _state~language = @sy-langu
                                            AND _state~country = 'IN'
*    left oUTER join  I_Customer_to_BusinessPartner   as c on  _cust~Customer = c~Customer
*   left outer join  I_businesspartneraddress       as   b on       _cust~Customer = b~BusinessPartner
      FIELDS _cust~customer          AS customer,
             _cust~addressid         AS addressid,
             _cust~bpcustomername    AS customername,
            _cust~bpaddrstreetname  AS streetname,
             _cust~bpaddrcityname    AS cityname,
             _cust~postalcode        AS postalcode,
             _state~regionname AS state,
             taxnumber3        AS gstin




       WHERE _cust~customer = @ls_customer-shiptocustomer OR
             _cust~customer = @ls_customer-billtocustomer
    INTO TABLE @DATA(lt_addressdetails).
    IF sy-subrc IS INITIAL.
    ENDIF.

reAD TABLE lt_addressdetails into data(waaa) index 1 .


SELECT SINGLE streetname, streetprefixname1, streetprefixname2, housenumber, streetsuffixname1,
               streetsuffixname2,districtname,cityname,postalcode,region ,country
               FROM i_addrorgnamepostaladdress WITH PRIVILEGED ACCESS
               WHERE addressid = @waaa-addressid INTO @DATA(wa_recaddr1).






    DATA: ls_deliverychallandetails TYPE c LENGTH 20.
    CONDENSE lv_plantadd.
    ls_head-companyadd = VALUE #( companyname   = ls_sorgtext-salesorganizationname
                                  plantaddress1 = lv_plantadd
                                  plantaddress2 = ''
                                  plantaddress3 = ''
                                  gstin         = ls_bplace-in_gstidentificationnumber
                                  statename     = ls_bplace-businessplacedescription
                                  companyemail  = '' ).

    IF ls_entity-billdoctype = 'F8' OR ls_entity-billdoctype = 'JSTO'  .  "Bridge STO
      ls_head-shiptoadd = VALUE #( shiptoname      = ''            "VALUE #( lt_AddressDetails[ Customer = ls_Customer-ShipToCustomer ]-CustomerName OPTIONAL )
                                   shiptoaddress1  = lv_sh_addr1
                                   shiptoaddress2  = lv_sh_addr2
                                   shiptoaddress3  = lv_sh_addr3
                                   shiptoaddress4  = lv_sh_addr4
                                   shiptogstin     = VALUE #( lt_addressdetails[ customer = ls_customer-shiptocustomer ]-gstin OPTIONAL )
                                   shiptostatename = VALUE #( lt_addressdetails[ customer = ls_customer-shiptocustomer ]-state OPTIONAL ) ).

    ELSEIF ls_entity-billdoctype = 'G2' OR ls_entity-billdoctype = 'L2'  OR ls_entity-billdoctype = 'F2'.  "Sales & Track

      ls_head-shiptoadd = VALUE #( shiptoname      = VALUE #( lt_addressdetails[ customer = ls_customer-shiptocustomer ]-customername OPTIONAL )
                                   shiptoaddress1  = VALUE #( lt_addressdetails[ customer = ls_customer-shiptocustomer ]-streetname OPTIONAL )
*                                   shiptoaddress2  = VALUE #( lt_addressdetails[ customer = ls_customer-shiptocustomer ]- OPTIONAL )
                                   shiptoaddress3  = VALUE #( lt_addressdetails[ customer = ls_customer-shiptocustomer ]-postalcode OPTIONAL )
                                   shiptoaddress4  = ''
                                   shiptogstin     = VALUE #( lt_addressdetails[ customer = ls_customer-shiptocustomer ]-gstin OPTIONAL )
                                   shiptostatename = VALUE #( lt_addressdetails[ customer = ls_customer-shiptocustomer ]-state OPTIONAL ) ).

    ENDIF.

    ls_head-billtoadd = VALUE #( billtoname      = VALUE #( lt_addressdetails[ customer = ls_customer-billtocustomer ]-customername OPTIONAL )
                                 billtoaddress1  = VALUE #( lt_addressdetails[ customer = ls_customer-billtocustomer ]-streetname OPTIONAL )
                                 billtoaddress2  = VALUE #( lt_addressdetails[ customer = ls_customer-billtocustomer ]-cityname OPTIONAL )
                                 billtoaddress3  = VALUE #( lt_addressdetails[ customer = ls_customer-billtocustomer ]-postalcode OPTIONAL )
                                 billtoaddress4  = ''
                                 biillgstin      = VALUE #( lt_addressdetails[ customer = ls_customer-billtocustomer ]-gstin OPTIONAL )
                                 billstatename   = VALUE #( lt_addressdetails[ customer = ls_customer-billtocustomer ]-state OPTIONAL ) ).

    ls_head-invdet    = VALUE #( invoiceno       = |{ ls_invoicedetails-billingdocument ALPHA = OUT }|
                                 invoicedate     = COND #( WHEN ls_invoicedetails-invoicedate = '00000000' THEN '' ELSE ls_invoicedetails-invoicedate )
                                 delchallanno    = '' "ls_DeliveryChallanDetails-deliverychallanno
                                 delchallandate  = COND #( WHEN ls_deliverychallandetails = '00000000' THEN '' ELSE ls_deliverychallandetails )
                                 payterm         = ls_invoicedetails-customerpaymenttermsname
                                 referenceno     = lv_referenceno
                                 loaordno        = ls_loadetails-loaordno
                                 loaorddate      = COND #( WHEN ls_loadetails-loaorddate = '00000000' THEN '' ELSE ls_loadetails-loaorddate )
                                 transportname   = ''"ls_DeliveryChallanDetails-transportername
                                 grno            = ''"ls_DeliveryChallanDetails-rrgrno
                                 grdate          = COND #( WHEN ls_deliverychallandetails = '00000000' THEN '' ELSE ls_deliverychallandetails )
                                 vehicleno       = ''" ls_DeliveryChallanDetails-vehicleno
                                 destination     = COND #( WHEN ls_entity-billdoctype = 'F8' OR ls_entity-billdoctype = 'JSTO'
                                                             THEN wa_toaddr-cityname
                                                           ELSE VALUE #( lt_addressdetails[ customer = ls_customer-shiptocustomer ]-cityname OPTIONAL ) )
                                 ).

***------------------------------------- Item Details -------------------------------------***
    "Billing Document Item Details
   SELECT
     FROM   i_billingdocumentitem WITH PRIVILEGED ACCESS AS a
      LEFT  JOIN zsd_billing_qat_sum_cds AS c ON c~billingdocument = a~billingdocument
*                                                and a~BillingDocumentItem = c~BillingDocumentItem

     LEFT JOIN zsd_tax_inv_cds_amt2  AS B ON B~BillingDocument = A~BillingDocument
                                             and a~BillingDocumentItem = b~BillingDocumentItem
*      lefT jOIN ZSD_Tax_invoice_count_cds as bb on bb~BillingDocument = b~BillingDocument

      FIELDS a~billingdocument,
             a~BillingDocumentItem,
             a~billingdocumentitemtext,
             a~salesdocument,
*     a~BillingDocumentItem,
*count( * ) as text_line ,
             c~linietm as text_line,
             a~plant,
             a~product,
             a~\_producttext[ language = 'E' ]-productname AS productname,
              c~BillingQuantity   AS billingquantity,
             a~BillingQuantityUnit as  billingquantityunit,
              c~netamount         AS netamount,
              c~amt              AS conditionratevalue,
             c~conditionrate,
             B~conditionrate1,
*             c~cond_amt,
*             b~ConditionType,
            c~ConditionTypeName,
             c~ConditionQuantityUnit
*             c~conditionrate1

      WHERE a~billingdocument = @lv_billingdoc



    INTO TABLE @DATA(lt_billdocitem).
    IF sy-subrc IS INITIAL.
      SORT lt_billdocitem BY BillingDocumentItem.
    DELETE ADJACENT DUPLICATES FROM lt_billdocitem COMPARING BillingDocumentItemText.
    ENDIF.





    SELECT
      FROM i_billingdocumentitemprcgelmnt WITH PRIVILEGED ACCESS AS A
      LEFT JOIN I_ConditionTypeText  AS B ON  A~ConditionType = B~ConditionType
      FIELDS A~billingdocument,
             A~billingdocumentitem,
             A~pricingprocedurestep,
         A~pricingprocedurecounter,
             A~conditiontype,
*             \_pricingconditiontype\_text_2[ language = 'E' ]-conditiontypename AS conditiontypename,
            B~ConditionTypeName AS conditiontypename,
             CAST( A~conditionbasequantity AS DEC( 15,2 ) ) AS conditionbasequantity,
             CASE
               WHEN A~conditionquantityunit IS NOT INITIAL
                 THEN A~conditionquantityunit
               ELSE A~conditionrateratiounit
             END AS conditionquantityunit,
             CASE
               WHEN A~conditionrateamount IS NOT INITIAL
                 THEN CAST( A~conditionrateamount AS DEC( 15,2 ) )
               ELSE CAST( A~conditionrateratio AS DEC( 15,2 ) )
             END AS conditionrate,
             A~conditionamount  AS conditionamount
      WHERE A~billingdocument = @lv_billingdoc
      and A~ConditionIsManuallyChanged  <> 'X'


    INTO TABLE @DATA(lt_billdocitemcond).
    IF sy-subrc IS INITIAL.
      SORT lt_billdocitemcond BY billingdocument billingdocumentitem ConditionType conditiontypename.
      DELETE ADJACENT DUPLICATES FROM lt_billdocitemcond cOMPARING  BillingDocument ConditionType conditiontypename .
    ENDIF.


SELECT FROM @lt_billdocitemcond AS a
FIELDS a~billingdocument  , a~conditiontype,
a~conditionrate,
a~conditiontypename,
conditionquantityunit,
 SUM( a~conditionamount ) AS conditionamount
GROUP BY
a~billingdocument,
a~conditiontype,
a~conditionrate,
a~conditiontypename,
a~conditionquantityunit
INTO TABLE @DATA(it_conditions).


    SELECT
      FROM i_productplantintltrd AS _hsn
      INNER JOIN i_billingdocumentitem AS _item
        ON _item~product = _hsn~product
       AND _item~plant   = _hsn~plant
      FIELDS _hsn~product,
             _hsn~plant,
             consumptiontaxctrlcode AS hsncode
      WHERE _item~billingdocument = @lv_billingdoc
    INTO TABLE @DATA(lt_hsncode).

    DATA(lv_totalamt) = CONV string( ls_invoicedetails-totalnetamount + ls_invoicedetails-totaltaxamount ).
    CONDENSE lv_totalamt.

***------------------------------------- XML Preparation -------------------------------------***
    DATA: lv_conamtjoig TYPE i_billingdocument-totalnetamount,
          lv_conamtjosg TYPE i_billingdocument-totalnetamount,
          lv_conamtjocg TYPE i_billingdocument-totalnetamount.

    DATA: lv_slno TYPE i.

    lv_template = 'TAX_INVOICE/TAX_INVOICE'.

*-------------------------  Service Tax Invoice -------------------------*
    IF lv_formtype = 'service'.

      lv_xml =
         |<form1>| &&
         |  <MainPage1>| &&
         |    <HEADER>| &&
         |      <FormName>{ ls_head-formname }</FormName>| &&
         |      <HeaderDetails>| &&
         |        <e-invoice>| &&
         |            <QR>{  ssb_image1  }</QR>| &&
         |            <IRNNo>{ lv_irn }</IRNNo>| &&
         |            <ACKNo>{ lv_ack_no }</ACKNo>| &&
         |            <ACKDate>{ lv_ack_date }</ACKDate>| &&

         |        </e-invoice>| &&
         |        <HeadAddress>| &&
         |          <CompanyDetails>| &&
         |            <CompanyName>{ ls_head-companyadd-companyname }</CompanyName>| &&
         |            <PlantAddress1>{ ls_head-companyadd-plantaddress1 }</PlantAddress1>| &&
         |                            <psotal>{ wa_soadd-CityName },{ wa_soadd-PostalCode }</psotal>                                                                    | &&
         |            <PlantAddress2>{ ls_head-companyadd-plantaddress2 }</PlantAddress2>| &&
         |            <PlantAddress3>{ ls_head-companyadd-plantaddress3 }</PlantAddress3>| &&
         |            <GSTIN>{ ls_head-companyadd-gstin }</GSTIN>| &&
         |             <CIN>{ lv_cin }</CIN>                                                |  &&
         |            <StateName>{ ls_head-companyadd-statename }</StateName>| &&
         |            <CompanyEmail>{ ls_head-companyadd-companyemail }</CompanyEmail>| &&
         |          </CompanyDetails>| &&


         |          <ShipToDetails>| &&
         |            <ShipToName>{ ls_head-shiptoadd-shiptoname }</ShipToName>| &&
         |            <ShipToAddress1>{ ls_head-shiptoadd-shiptoaddress1 }</ShipToAddress1>| &&
         |            <ShipToAddress2>{ wa_recaddr1-StreetPrefixName1 },{ wa_recaddr1-StreetPrefixName2 }</ShipToAddress2>| &&
         |            <ShipToAddress3>{ ls_head-shiptoadd-shiptoaddress3 }</ShipToAddress3>| &&
         |            <ShipToAddress4>{ ls_head-shiptoadd-shiptoaddress4 }</ShipToAddress4>| &&
         |            <ShipToGSTIN>{ ls_head-shiptoadd-shiptogstin }</ShipToGSTIN>| &&
         |            <ShipToStateName>{ ls_head-shiptoadd-shiptostatename }</ShipToStateName>| &&
         |          </ShipToDetails>| &&



         |          <BillToDetails>| &&
         |            <BillToName>{ ls_head-billtoadd-billtoname }</BillToName>| &&
         |            <BillToAddress1>{ ls_head-billtoadd-billtoaddress1 }</BillToAddress1>| &&
*         |            <BillToAddress2>{ ls_head-billtoadd-billtoaddress2 }</BillToAddress2>| &&
          |            <BillToAddress2>{ wa_recaddr1-StreetPrefixName1 },{ wa_recaddr1-StreetPrefixName2 }</BillToAddress2>| &&
         |            <BillToAddress3>{ ls_head-billtoadd-billtoaddress3 }</BillToAddress3>| &&
         |            <BillToAddress4>{ ls_head-billtoadd-billtoaddress4 }</BillToAddress4>| &&
         |            <BiillGSTIN>{ ls_head-billtoadd-biillgstin }</BiillGSTIN>| &&
         |            <BillStateName>{ ls_head-billtoadd-billstatename }</BillStateName>| &&
         |          </BillToDetails>| &&
         |        </HeadAddress>| &&
         |        <InvoiceDetails>| &&
         |          <InvoiceNoSFrm><InvoiceNo>{ lv_billingdoc }</InvoiceNo></InvoiceNoSFrm>| &&
         |          <InvoiceDateSFrm><InvoiceDate>{ ls_head-invdet-invoicedate }</InvoiceDate></InvoiceDateSFrm>| &&
         |          <DelChallanNoSFrm><DelChallanNo>{ ls_head-invdet-delchallanno }</DelChallanNo></DelChallanNoSFrm>| &&
         |          <DelChallanDateSFrm><DelChallanDate>{ ls_head-invdet-delchallandate }</DelChallanDate></DelChallanDateSFrm>| &&
         |          <PayTermSFrm><PayTerm>{ ls_head-invdet-payterm }</PayTerm></PayTermSFrm>| &&
         |          <ReferenceNoSFrm><ReferenceNo>{ ls_head-invdet-referenceno }</ReferenceNo></ReferenceNoSFrm>| &&
         |          <LOAOrdNoSFrm><LOAOrdNo>{ ls_head-invdet-loaordno }</LOAOrdNo></LOAOrdNoSFrm>| &&
         |          <LOAOrdDateSFrm><LOAOrdDate>{ ls_head-invdet-loaorddate }</LOAOrdDate></LOAOrdDateSFrm>| &&
         |          <TransportNameSFrm><TransportName>{ ls_head-invdet-transportname }</TransportName></TransportNameSFrm>| &&
         |          <GRNoSFrm><GRNo>{ ls_head-invdet-grno }</GRNo></GRNoSFrm>| &&
         |          <GRDateSFrm><GRDate>{ ls_head-invdet-grdate }</GRDate></GRDateSFrm>| &&
         |          <VehicleNoSFrm><VehicleNo>{ ls_head-invdet-vehicleno }</VehicleNo></VehicleNoSFrm>| &&
         |          <DestinationSFrm><Destination>{ ls_head-invdet-destination }</Destination></DestinationSFrm>| &&
         |        </InvoiceDetails>| &&
         |      </HeaderDetails>| &&
         |    </HEADER>|.

      lv_xml = lv_xml &&
         |<ITEM>| &&
         |  <ITEM_MAIN>| &&
         |    <HEADER/>| &&
         |    <ITEM_BODY>| &&
         |      <ITEM_TABLE_FORM>|.

      LOOP AT lt_billdocitem INTO DATA(ls_item).
      conCATENATE    ls_item-text_line ls_item-BillingDocumentItemText into data(lv_item) sEPARATED BY ' ' .
        lv_slno = lv_slno + 1.
        DATA(lv_hsncode)  = CONV string( VALUE #( lt_hsncode[ plant = ls_item-plant product = ls_item-product ]-hsncode OPTIONAL ) ).
        DATA(lv_itemtext) = CONV string( VALUE #( lt_salesorditemtext[ salesorder = ls_item-salesdocument
                                                                       language   = 'E'
                                                                       longtextid = '0001' ]-longtext OPTIONAL ) ).

        lv_xml = lv_xml &&
           |        <ITEM_TABLE>| &&
           |          <MATERIAL_DETAILS>| &&
           |            <SLNo>{ lv_slno }</SLNo>| &&
           |            <MaterialDescFrm>| &&
           |              <MaterialDesc>{ lv_item }</MaterialDesc>| &&
           |              <MaterialText>{ lv_itemtext }</MaterialText>| &&
           |            </MaterialDescFrm>| &&
           |            <HSN>{ lv_hsncode }</HSN>| &&
           |            <Quantity>{ ls_item-billingquantity }</Quantity>| &&
*           |            <Rate></Rate>| &&
              |            <Rate>{ ls_item-conditionrate1 }</Rate>| &&
           |            <Per>{ ls_item-billingquantityunit }</Per>| &&
           |            <Amount>{ ls_item-netamount }</Amount>| &&

           |          </MATERIAL_DETAILS>|.





        LOOP AT it_conditions INTO DATA(ls_itemcond)
             WHERE billingdocument = ls_item-billingdocument
               AND conditiontype  <> 'ZMSP'
               AND conditiontype  <> 'ZHRM'
               AND conditiontype  <> 'ZMTP'.
*               AND ConditionType <> 'JOSG'.




          DATA(lv_condtype) = CONV string( ls_itemcond-conditiontypename ).
          DATA(lv_condrate) = CONV string( ls_itemcond-conditionrate ).
          DATA(lv_condper)  = CONV string( ls_itemcond-conditionquantityunit ).
          DATA(lv_condamt)  = CONV string( ls_itemcond-conditionamount ).




          lv_xml = lv_xml &&
              |          <MATERIAL_COND>| &&
              |            <SLNo></SLNo>| &&
              |            <CondText>{ lv_condtype  }</CondText>| &&
              |            <HSN></HSN>| &&
              |            <CondQty></CondQty>| &&
              |            <CondRate>{ ls_itemcond-conditionrate }</CondRate>| &&
              |            <CondPer>{ COND string( WHEN ls_entity-bsalesflag = 'X' THEN '' ELSE lv_condper ) }</CondPer>| &&
              |            <CondAmt>{ lv_condamt }</CondAmt>| &&
              |          </MATERIAL_COND>|.
          CLEAR:  lv_condrate, lv_condper, lv_condamt.
        ENDLOOP.

        lv_xml = lv_xml &&
           |        </ITEM_TABLE>|.

      ENDLOOP.
      CLEAR lv_slno.

      lv_xml = lv_xml &&
         |      </ITEM_TABLE_FORM>| &&
         |    </ITEM_BODY>| &&
         |    <TOTAL_AMT>| &&
         |      <TotalAmountValue>{ lv_totalamt }</TotalAmountValue>| &&
         |    </TOTAL_AMT>| &&
         |  </ITEM_MAIN>|.

      lv_xml = lv_xml &&
         |  <AmtInWords>| &&
         |    <AmtText/>| &&
         |    <AmtValue>| &&
         |      <AmtInWordsValue/>| &&
         |    </AmtValue>| &&
         |  </AmtInWords>| &&
         |</ITEM>|.


      lv_xml = lv_xml &&
         |<ITEM_HSN>| &&
         |  <ITEM>| &&
         |    <HEADER1/>| &&
         |    <HEADER2/>|.

      DATA: lv_totaltaxablevalue   TYPE i_billingdocument-totalnetamount,
            lv_totaltaxamountvalue TYPE i_billingdocument-totalnetamount.

      LOOP AT lt_billdocitem INTO DATA(ls_itemhsn).

        DATA(lv_hsncode1)     = CONV string( VALUE #( lt_hsncode[ plant = ls_itemhsn-plant product = ls_itemhsn-product ]-hsncode OPTIONAL ) ).

        DATA(lv_TaxableValue) = CONV String( VALUE #( lt_BillDocItemCond[ BillingDocument = ls_ItemHSN-BillingDocument
                                                                          ConditionType       = 'ZMSP' ]-ConditionAmount OPTIONAL ) +
                                             VALUE #( lt_BillDocItemCond[ BillingDocument = ls_ItemHSN-BillingDocument
                                                                          ConditionType       = 'ZHRM' ]-ConditionAmount OPTIONAL ) +
                                             VALUE #( lt_BillDocItemCond[ BillingDocument  = ls_ItemHSN-BillingDocument
                                                                          ConditionType       = 'ZMTP' ]-ConditionAmount OPTIONAL ) ).

*        DATA(lv_taxablevalue) = ls_itemhsn-netamount.

        DATA(lv_taxrate)      = CONV string( VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn-billingdocument
                                                                          conditiontype       = 'JOIG' ]-conditionrate OPTIONAL ) +
                                             VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn-billingdocument
                                                                          conditiontype       = 'JOCG' ]-conditionrate OPTIONAL ) +
                                             VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn-billingdocument
                                                                          conditiontype       = 'JOSG' ]-conditionrate OPTIONAL ) ) &&
                                CONV string( VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn-billingdocument
                                                                          conditiontype       = 'JOIG' ]-conditionquantityunit OPTIONAL ) &&
                                             VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn-billingdocument
                                                                          conditiontype       = 'JOCG' ]-conditionquantityunit OPTIONAL ) ).

        DATA(lv_taxamt)       = CONV string( VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn-billingdocument
                                                                          conditiontype       = 'JOIG' ]-conditionamount OPTIONAL ) +
                                             VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn-billingdocument
                                                                          conditiontype       = 'JOSG' ]-conditionamount OPTIONAL ) +
                                             VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn-billingdocument
                                                                          conditiontype       = 'JOCG' ]-conditionamount OPTIONAL ) ).



        lv_totaltaxablevalue   = lv_totaltaxablevalue   + lv_taxablevalue.
*        lv_totaltaxamountvalue = lv_totaltaxamountvalue + lv_taxamt.
          lv_totaltaxamountvalue =  lv_taxamt.
*            lv_totaltaxamountvalue  = ls_item-netamount .


        lv_xml = lv_xml &&
           |    <BODY>| &&
           |      <HSN>{ lv_hsncode1 }</HSN>| &&
           |      <TaxableValue>{ ls_item-netamount }</TaxableValue>| &&
           |      <Rate>{ lv_taxrate }</Rate>| &&
           |      <AmountValue>{ lv_taxamt }</AmountValue>| &&
           |      <TaxAmountValue>{ lv_taxamt }</TaxAmountValue>| &&
           |    </BODY>|.

        CLEAR: lv_hsncode1, lv_taxablevalue, lv_taxrate, lv_taxamt.
      ENDLOOP.

      ls_footer_det = VALUE #( companyname = 'for Transvolt Mobility Private Limited'
                               companypan  = '' ).

      lv_xml = lv_xml &&
         |    <TOTALAMT>| &&
         |      <TotalTaxableValue>{ ls_item-netamount } </TotalTaxableValue>| &&
         |      <RateText/>| &&
*         |      <TotalAmountValue>{ lv_totaltaxamountvalue }</TotalAmountValue>| &&
         | <TotalAmountValue>{ lv_totaltaxamountvalue } </TotalAmountValue>| &&
         |      <TotalTaxAmountValue>{ lv_totaltaxamountvalue }</TotalTaxAmountValue>| &&
         |    </TOTALAMT>| &&
         |  </ITEM>| &&
         |</ITEM_HSN>|.

      lv_xml = lv_xml &&
         |<Footer>| &&
         |  <TaxAmtInWords>| &&
         |    <TaxAmtInWordsValue/>| &&
         |  </TaxAmtInWords>| &&
         |  <CompanyPANfrm>| &&
         |    <Space/>| &&
         |    <CompanyPAN>| &&
         |      <CompanyPAN>{ ls_footer_det-companypan }</CompanyPAN>| &&
         |    </CompanyPAN>| &&
         |  </CompanyPANfrm>| &&

         |  <SigntaureFrm>| &&
         |    <CompanyName>{ ls_footer_det-companyname }</CompanyName>| &&

         |    <Space/>| &&
         |  </SigntaureFrm>| &&
         |</Footer>|.

      lv_xml = lv_xml &&
         |</MainPage1>| &&
         |</form1>|.




*-----------------------------  Bridge STO Invoice -----------------------------*
*      IF  ls_entity-division = '17'.
       ELSEIF lv_formtype = 'scrap'.

      lv_template = 'TAX_INVOICE/TAX_INVOICE'.

      lv_xml =
         |<form1>| &&
         |  <MainPage1>| &&
         |    <HEADER>| &&
         |      <FormName>{ ls_head-formname }</FormName>| &&
         |      <HeaderDetails>| &&
         |        <e-invoice>| &&
         |            <QR></QR>| &&
         |            <IRNNo></IRNNo>| &&
         |            <ACKNo></ACKNo>| &&
         |            <ACKDate></ACKDate>| &&
         |        </e-invoice>| &&
         |        <HeadAddress>| &&
         |          <CompanyDetails>| &&
         |            <CompanyName>{ ls_head-companyadd-companyname }</CompanyName>| &&
         |            <PlantAddress1>{ ls_head-companyadd-plantaddress1 }</PlantAddress1>| &&
         |            <psotal>{ wa_soadd-CityName },{ wa_soadd-PostalCode }</psotal>| &&
         |            <PlantAddress2>{ ls_head-companyadd-plantaddress2 }</PlantAddress2>| &&
         |            <PlantAddress3>{ ls_head-companyadd-plantaddress3 }</PlantAddress3>| &&
         |            <GSTIN>{ ls_head-companyadd-gstin }</GSTIN>| &&
         |            <CIN>{ lv_cin }</CIN>| &&
         |            <StateName>{ ls_head-companyadd-statename }</StateName>| &&
         |            <CompanyEmail>{ ls_head-companyadd-companyemail }</CompanyEmail>| &&
         |          </CompanyDetails>| &&
         |          <ShipToDetails>| &&
         |            <ShipToName>{ ls_head-shiptoadd-shiptoname }</ShipToName>| &&
         |            <ShipToAddress1>{ ls_head-shiptoadd-shiptoaddress1 }</ShipToAddress1>| &&
         |            <ShipToAddress2>{ wa_recaddr1-StreetPrefixName1 },{ wa_recaddr1-StreetPrefixName2 }</ShipToAddress2>| &&
         |            <ShipToAddress3>{ ls_head-shiptoadd-shiptoaddress3 }</ShipToAddress3>| &&
         |            <ShipToAddress4>{ ls_head-shiptoadd-shiptoaddress4 }</ShipToAddress4>| &&
         |            <ShipToGSTIN>{ ls_head-shiptoadd-shiptogstin }</ShipToGSTIN>| &&
         |            <ShipToStateName>{ ls_head-shiptoadd-shiptostatename }</ShipToStateName>| &&
         |          </ShipToDetails>| &&
         |          <BillToDetails>| &&
         |            <BillToName>{ ls_head-billtoadd-billtoname }</BillToName>| &&
         |            <BillToAddress1>{ ls_head-billtoadd-billtoaddress1 }</BillToAddress1>| &&
         |            <BillToAddress2>{ wa_recaddr1-StreetPrefixName1 },{ wa_recaddr1-StreetPrefixName2 }</BillToAddress2>| &&
         |            <BillToAddress3>{ ls_head-billtoadd-billtoaddress3 }</BillToAddress3>| &&
         |            <BillToAddress4>{ ls_head-billtoadd-billtoaddress4 }</BillToAddress4>| &&
         |            <BiillGSTIN>{ ls_head-billtoadd-biillgstin }</BiillGSTIN>| &&
         |            <BillStateName>{ ls_head-billtoadd-billstatename }</BillStateName>| &&
         |          </BillToDetails>| &&
         |        </HeadAddress>| &&
         |        <InvoiceDetails>| &&
         |          <InvoiceNoSFrm><InvoiceNo>{ lv_billingdoc }</InvoiceNo></InvoiceNoSFrm>| &&
         |          <InvoiceDateSFrm><InvoiceDate>{ ls_head-invdet-invoicedate }</InvoiceDate></InvoiceDateSFrm>| &&
         |          <DelChallanNoSFrm><DelChallanNo>{ ls_head-invdet-delchallanno }</DelChallanNo></DelChallanNoSFrm>| &&
         |          <DelChallanDateSFrm><DelChallanDate>{ ls_head-invdet-delchallandate }</DelChallanDate></DelChallanDateSFrm>| &&
         |          <PayTermSFrm><PayTerm>{ ls_head-invdet-payterm }</PayTerm></PayTermSFrm>| &&
         |          <ReferenceNoSFrm><ReferenceNo>{ ls_head-invdet-referenceno }</ReferenceNo></ReferenceNoSFrm>| &&
         |          <LOAOrdNoSFrm><LOAOrdNo>{ ls_head-invdet-loaordno }</LOAOrdNo></LOAOrdNoSFrm>| &&
         |          <LOAOrdDateSFrm><LOAOrdDate>{ ls_head-invdet-loaorddate }</LOAOrdDate></LOAOrdDateSFrm>| &&
         |          <TransportNameSFrm><TransportName>{ ls_head-invdet-transportname }</TransportName></TransportNameSFrm>| &&
         |          <GRNoSFrm><GRNo>{ ls_head-invdet-grno }</GRNo></GRNoSFrm>| &&
         |          <GRDateSFrm><GRDate>{ ls_head-invdet-grdate }</GRDate></GRDateSFrm>| &&
         |          <VehicleNoSFrm><VehicleNo>{ ls_head-invdet-vehicleno }</VehicleNo></VehicleNoSFrm>| &&
         |          <DestinationSFrm><Destination>{ ls_head-invdet-destination }</Destination></DestinationSFrm>| &&
         |        </InvoiceDetails>| &&
         |      </HeaderDetails>| &&
         |    </HEADER>|.

      lv_xml = lv_xml &&
         |<ITEM>| &&
         |  <ITEM_MAIN>| &&
         |    <HEADER/>| &&
         |    <ITEM_BODY>| &&
         |      <ITEM_TABLE_FORM>|.

      LOOP AT lt_billdocitem INTO DATA(ls_item_scrap).
        CONCATENATE ls_item_scrap-text_line ls_item_scrap-billingdocumentitemtext
          INTO DATA(lv_item_scrap) SEPARATED BY ' '.
        lv_slno = lv_slno + 1.
        DATA(lv_hsncode_scrap) = CONV string( VALUE #(
          lt_hsncode[ plant = ls_item_scrap-plant product = ls_item_scrap-product ]-hsncode OPTIONAL ) ).
        DATA(lv_itemtext_scrap) = CONV string( VALUE #(
          lt_salesorditemtext[ salesorder = ls_item_scrap-salesdocument
                               language   = 'E'
                               longtextid = '0001' ]-longtext OPTIONAL ) ).

        lv_xml = lv_xml &&
           |        <ITEM_TABLE>| &&
           |          <MATERIAL_DETAILS>| &&
           |            <SLNo>{ lv_slno }</SLNo>| &&
           |            <MaterialDescFrm>| &&
           |              <MaterialDesc>{ lv_item_scrap }</MaterialDesc>| &&
           |              <MaterialText>{ lv_itemtext_scrap }</MaterialText>| &&
           |            </MaterialDescFrm>| &&
           |            <HSN>{ lv_hsncode_scrap }</HSN>| &&
           |            <Quantity>{ ls_item_scrap-billingquantity }</Quantity>| &&
           |            <Rate>{ ls_item_scrap-conditionrate1 }</Rate>| &&
           |            <Per>{ ls_item_scrap-billingquantityunit }</Per>| &&
           |            <Amount>{ ls_item_scrap-netamount }</Amount>| &&
           |          </MATERIAL_DETAILS>|.

        LOOP AT it_conditions INTO DATA(ls_cond_scrap)
             WHERE billingdocument = ls_item_scrap-billingdocument
               AND conditiontype  <> 'ZMSP'
               AND conditiontype  <> 'ZHRM'
               AND conditiontype  <> 'ZMTP'.

          lv_xml = lv_xml &&
              |          <MATERIAL_COND>| &&
              |            <SLNo></SLNo>| &&
              |            <CondText>{ ls_cond_scrap-conditiontypename }</CondText>| &&
              |            <HSN></HSN>| &&
              |            <CondQty></CondQty>| &&
              |            <CondRate>{ ls_cond_scrap-conditionrate }</CondRate>| &&
              |            <CondPer>{ COND string( WHEN ls_entity-bsalesflag = 'X' THEN '' ELSE ls_cond_scrap-conditionquantityunit ) }</CondPer>| &&
              |            <CondAmt>{ ls_cond_scrap-conditionamount }</CondAmt>| &&
              |          </MATERIAL_COND>|.
        ENDLOOP.

        lv_xml = lv_xml && |        </ITEM_TABLE>|.
      ENDLOOP.
      CLEAR lv_slno.

      lv_xml = lv_xml &&
         |      </ITEM_TABLE_FORM>| &&
         |    </ITEM_BODY>| &&
         |    <TOTAL_AMT>| &&
         |      <TotalAmountValue>{ lv_totalamt }</TotalAmountValue>| &&
         |    </TOTAL_AMT>| &&
         |  </ITEM_MAIN>|.

      lv_xml = lv_xml &&
         |  <AmtInWords>| &&
         |    <AmtText/>| &&
         |    <AmtValue>| &&
         |      <AmtInWordsValue/>| &&
         |    </AmtValue>| &&
         |  </AmtInWords>| &&
         |</ITEM>|.

      lv_xml = lv_xml &&
         |<ITEM_HSN>| &&
         |  <ITEM>| &&
         |    <HEADER1/>| &&
         |    <HEADER2/>|.

      DATA: lv_totaltaxablevalue_s   TYPE i_billingdocument-totalnetamount,
            lv_totaltaxamountvalue_s TYPE i_billingdocument-totalnetamount.

      CLEAR: lv_conamtjoig, lv_conamtjosg, lv_conamtjocg.

      LOOP AT lt_billdocitem INTO DATA(ls_itemhsn_scrap).


        DATA(lv_hsncode_scrap1) = CONV string( VALUE #(
          lt_hsncode[ plant = ls_itemhsn_scrap-plant product = ls_itemhsn_scrap-product ]-hsncode OPTIONAL ) ).

        DATA(lv_taxablevalue_scrap) = CONV string(
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'ZMSP' ]-conditionamount OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'ZHRM' ]-conditionamount OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'ZMTP' ]-conditionamount OPTIONAL )
                                        ).

*        DATA(lv_taxrate_scrap) = CONV string(
*          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
*                                       conditiontype   = 'JOIG' ]-conditionrate OPTIONAL ) +
*          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
*                                       conditiontype   = 'JOCG' ]-conditionrate OPTIONAL ) +
*          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
*                                       conditiontype   = 'JOSG' ]-conditionrate OPTIONAL )
*                                        ).


       DATA(lv_taxrate_scrap_dec) =
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'JOIG' ]-conditionrate OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'JOCG' ]-conditionrate OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'JOSG' ]-conditionrate OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'JTC1' ]-conditionrate OPTIONAL ).
        DATA(lv_taxrate_scrap) = |{ lv_taxrate_scrap_dec }|.
        CONDENSE lv_taxrate_scrap.

        DATA(lv_taxamt_scrap) = CONV string(
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'JOIG' ]-conditionamount OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'JOSG' ]-conditionamount OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'JOCG' ]-conditionamount OPTIONAL ) +
               VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_scrap-billingdocument
                                       conditiontype   = 'JTC1' ]-conditionamount OPTIONAL )                          ).

        lv_totaltaxablevalue_s = lv_totaltaxablevalue_s + ls_itemhsn_scrap-netamount.
        lv_totaltaxamountvalue_s = lv_taxamt_scrap.



        lv_xml = lv_xml &&
           |    <BODY>| &&
           |      <HSN>{ lv_hsncode_scrap1 }</HSN>| &&
           |      <TaxableValue>{ ls_itemhsn_scrap-netamount }</TaxableValue>| &&
           |      <Rate>{ lv_taxrate_scrap }</Rate>| &&
           |      <AmountValue>{ lv_taxamt_scrap }</AmountValue>| &&
           |      <TaxAmountValue>{ lv_taxamt_scrap }</TaxAmountValue>| &&
           |    </BODY>|.

        CLEAR: lv_hsncode_scrap1, lv_taxablevalue_scrap, lv_taxrate_scrap, lv_taxamt_scrap.
      ENDLOOP.

           ls_footer_det = VALUE #( companyname = 'for Transvolt Mobility Private Limited'
                               companypan  = '' ).

      lv_xml = lv_xml &&
         |    <TOTALAMT>| &&
*         |      <TotalTaxableValue>{ lv_totaltaxablevalue_s }</TotalTaxableValue>| &&
         |      <TotalTaxableValue>{  ls_itemhsn_scrap-netamount }</TotalTaxableValue>| &&
         |      <RateText/>| &&
         |      <TotalAmountValue>{ lv_totaltaxamountvalue_s }</TotalAmountValue>| &&
         |      <TotalTaxAmountValue>{ lv_totaltaxamountvalue_s }</TotalTaxAmountValue>| &&
         |    </TOTALAMT>| &&
         |  </ITEM>| &&
         |</ITEM_HSN>|.

      lv_xml = lv_xml &&
         |<Footer>| &&
         |  <TaxAmtInWords>| &&
         |    <TaxAmtInWordsValue/>| &&
         |  </TaxAmtInWords>| &&
         |  <CompanyPANfrm>| &&
         |    <Space/>| &&
         |    <CompanyPAN>| &&
         |      <CompanyPAN>{ ls_footer_det-companypan }</CompanyPAN>| &&
         |    </CompanyPAN>| &&
         |  </CompanyPANfrm>| &&
         |  <SigntaureFrm>| &&
         |    <CompanyName>{ ls_footer_det-companyname }</CompanyName>| &&
         |    <Space/>| &&
         |  </SigntaureFrm>| &&
         |</Footer>|.

      lv_xml = lv_xml &&
         |</MainPage1>| &&
         |</form1>|.





*      ELSEIF ls_entity-division = '18'.

     ELSEIF lv_formtype = 'stock'.

      lv_template = 'TAX_INVOICE/TAX_INVOICE'.

      lv_xml =
         |<form1>| &&
         |  <MainPage1>| &&
         |    <HEADER>| &&
         |      <FormName>{ ls_head-formname }</FormName>| &&
         |      <HeaderDetails>| &&
         |        <e-invoice>| &&
         |            <QR></QR>| &&
         |            <IRNNo></IRNNo>| &&
         |            <ACKNo></ACKNo>| &&
         |            <ACKDate></ACKDate>| &&
         |        </e-invoice>| &&
         |        <HeadAddress>| &&
         |          <CompanyDetails>| &&
         |            <CompanyName>{ ls_head-companyadd-companyname }</CompanyName>| &&
         |            <PlantAddress1>{ ls_head-companyadd-plantaddress1 }</PlantAddress1>| &&
         |            <psotal>{ wa_soadd-CityName },{ wa_soadd-PostalCode }</psotal>| &&
         |            <PlantAddress2>{ ls_head-companyadd-plantaddress2 }</PlantAddress2>| &&
         |            <PlantAddress3>{ ls_head-companyadd-plantaddress3 }</PlantAddress3>| &&
         |            <GSTIN>{ ls_head-companyadd-gstin }</GSTIN>| &&
         |            <CIN>{ lv_cin }</CIN>| &&
         |            <StateName>{ ls_head-companyadd-statename }</StateName>| &&
         |            <CompanyEmail>{ ls_head-companyadd-companyemail }</CompanyEmail>| &&
         |          </CompanyDetails>| &&
         |          <ShipToDetails>| &&
         |            <ShipToName>{ ls_head-shiptoadd-shiptoname }</ShipToName>| &&
         |            <ShipToAddress1>{ ls_head-shiptoadd-shiptoaddress1 }</ShipToAddress1>| &&
         |            <ShipToAddress2>{ wa_recaddr1-StreetPrefixName1 },{ wa_recaddr1-StreetPrefixName2 }</ShipToAddress2>| &&
         |            <ShipToAddress3>{ ls_head-shiptoadd-shiptoaddress3 }</ShipToAddress3>| &&
         |            <ShipToAddress4>{ ls_head-shiptoadd-shiptoaddress4 }</ShipToAddress4>| &&
         |            <ShipToGSTIN>{ ls_head-shiptoadd-shiptogstin }</ShipToGSTIN>| &&
         |            <ShipToStateName>{ ls_head-shiptoadd-shiptostatename }</ShipToStateName>| &&
         |          </ShipToDetails>| &&
         |          <BillToDetails>| &&
         |            <BillToName>{ ls_head-billtoadd-billtoname }</BillToName>| &&
         |            <BillToAddress1>{ ls_head-billtoadd-billtoaddress1 }</BillToAddress1>| &&
         |            <BillToAddress2>{ wa_recaddr1-StreetPrefixName1 },{ wa_recaddr1-StreetPrefixName2 }</BillToAddress2>| &&
         |            <BillToAddress3>{ ls_head-billtoadd-billtoaddress3 }</BillToAddress3>| &&
         |            <BillToAddress4>{ ls_head-billtoadd-billtoaddress4 }</BillToAddress4>| &&
         |            <BiillGSTIN>{ ls_head-billtoadd-biillgstin }</BiillGSTIN>| &&
         |            <BillStateName>{ ls_head-billtoadd-billstatename }</BillStateName>| &&
         |          </BillToDetails>| &&
         |        </HeadAddress>| &&
         |        <InvoiceDetails>| &&
         |          <InvoiceNoSFrm><InvoiceNo>{ lv_billingdoc }</InvoiceNo></InvoiceNoSFrm>| &&
         |          <InvoiceDateSFrm><InvoiceDate>{ ls_head-invdet-invoicedate }</InvoiceDate></InvoiceDateSFrm>| &&
         |          <DelChallanNoSFrm><DelChallanNo>{ ls_head-invdet-delchallanno }</DelChallanNo></DelChallanNoSFrm>| &&
         |          <DelChallanDateSFrm><DelChallanDate>{ ls_head-invdet-delchallandate }</DelChallanDate></DelChallanDateSFrm>| &&
         |          <PayTermSFrm><PayTerm>{ ls_head-invdet-payterm }</PayTerm></PayTermSFrm>| &&
         |          <ReferenceNoSFrm><ReferenceNo>{ ls_head-invdet-referenceno }</ReferenceNo></ReferenceNoSFrm>| &&
         |          <LOAOrdNoSFrm><LOAOrdNo>{ ls_head-invdet-loaordno }</LOAOrdNo></LOAOrdNoSFrm>| &&
         |          <LOAOrdDateSFrm><LOAOrdDate>{ ls_head-invdet-loaorddate }</LOAOrdDate></LOAOrdDateSFrm>| &&
         |          <TransportNameSFrm><TransportName>{ ls_head-invdet-transportname }</TransportName></TransportNameSFrm>| &&
         |          <GRNoSFrm><GRNo>{ ls_head-invdet-grno }</GRNo></GRNoSFrm>| &&
         |          <GRDateSFrm><GRDate>{ ls_head-invdet-grdate }</GRDate></GRDateSFrm>| &&
         |          <VehicleNoSFrm><VehicleNo>{ ls_head-invdet-vehicleno }</VehicleNo></VehicleNoSFrm>| &&
         |          <DestinationSFrm><Destination>{ ls_head-invdet-destination }</Destination></DestinationSFrm>| &&
         |        </InvoiceDetails>| &&
         |      </HeaderDetails>| &&
         |    </HEADER>|.

      lv_xml = lv_xml &&
         |<ITEM>| &&
         |  <ITEM_MAIN>| &&
         |    <HEADER/>| &&
         |    <ITEM_BODY>| &&
         |      <ITEM_TABLE_FORM>|.

      LOOP AT lt_billdocitem INTO DATA(ls_item_stock).
        CONCATENATE ls_item_stock-text_line ls_item_stock-billingdocumentitemtext
          INTO DATA(lv_item_stock) SEPARATED BY ' '.
        lv_slno = lv_slno + 1.
        DATA(lv_hsncode_stock) = CONV string( VALUE #(
          lt_hsncode[ plant = ls_item_stock-plant product = ls_item_stock-product ]-hsncode OPTIONAL ) ).
        DATA(lv_itemtext_stock) = CONV string( VALUE #(
          lt_salesorditemtext[ salesorder = ls_item_stock-salesdocument
                               language   = 'E'
                               longtextid = '0001' ]-longtext OPTIONAL ) ).

        lv_xml = lv_xml &&
           |        <ITEM_TABLE>| &&
           |          <MATERIAL_DETAILS>| &&
           |            <SLNo>{ lv_slno }</SLNo>| &&
           |            <MaterialDescFrm>| &&
           |              <MaterialDesc>{ lv_item_stock }</MaterialDesc>| &&
           |              <MaterialText>{ lv_itemtext_stock }</MaterialText>| &&
           |            </MaterialDescFrm>| &&
           |            <HSN>{ lv_hsncode_stock }</HSN>| &&
           |            <Quantity>{ ls_item_stock-billingquantity }</Quantity>| &&
           |            <Rate>{ ls_item_stock-conditionrate1 }</Rate>| &&
           |            <Per>{ ls_item_stock-billingquantityunit }</Per>| &&
           |            <Amount>{ ls_item_stock-netamount }</Amount>| &&
           |          </MATERIAL_DETAILS>|.

        LOOP AT it_conditions INTO DATA(ls_cond_stock)
             WHERE billingdocument = ls_item_stock-billingdocument
               AND conditiontype  <> 'ZMSP'
               AND conditiontype  <> 'ZHRM'
               AND conditiontype  <> 'ZMTP'.

          lv_xml = lv_xml &&
              |          <MATERIAL_COND>| &&
              |            <SLNo></SLNo>| &&
              |            <CondText>{ ls_cond_stock-conditiontypename }</CondText>| &&
              |            <HSN></HSN>| &&
              |            <CondQty></CondQty>| &&
              |            <CondRate>{ ls_cond_stock-conditionrate }</CondRate>| &&
              |            <CondPer>{ COND string( WHEN ls_entity-bsalesflag = 'X' THEN '' ELSE ls_cond_stock-conditionquantityunit ) }</CondPer>| &&
              |            <CondAmt>{ ls_cond_stock-conditionamount }</CondAmt>| &&
              |          </MATERIAL_COND>|.
        ENDLOOP.

        lv_xml = lv_xml && |        </ITEM_TABLE>|.
      ENDLOOP.
      CLEAR lv_slno.

      lv_xml = lv_xml &&
         |      </ITEM_TABLE_FORM>| &&
         |    </ITEM_BODY>| &&
         |    <TOTAL_AMT>| &&
         |      <TotalAmountValue>{ lv_totalamt }</TotalAmountValue>| &&
         |    </TOTAL_AMT>| &&
         |  </ITEM_MAIN>|.

      lv_xml = lv_xml &&
         |  <AmtInWords>| &&
         |    <AmtText/>| &&
         |    <AmtValue>| &&
         |      <AmtInWordsValue/>| &&
         |    </AmtValue>| &&
         |  </AmtInWords>| &&
         |</ITEM>|.

      lv_xml = lv_xml &&
         |<ITEM_HSN>| &&
         |  <ITEM>| &&
         |    <HEADER1/>| &&
         |    <HEADER2/>|.

      DATA: lv_totaltaxablevalue_k   TYPE i_billingdocument-totalnetamount,
            lv_totaltaxamountvalue_k TYPE i_billingdocument-totalnetamount.

      CLEAR: lv_conamtjoig, lv_conamtjosg, lv_conamtjocg.

      LOOP AT lt_billdocitem INTO DATA(ls_itemhsn_stock).

        DATA(lv_hsncode_stock1) = CONV string( VALUE #(
          lt_hsncode[ plant = ls_itemhsn_stock-plant product = ls_itemhsn_stock-product ]-hsncode OPTIONAL ) ).

        DATA(lv_taxablevalue_stock) = CONV string(
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_stock-billingdocument
                                       conditiontype   = 'ZMSP' ]-conditionamount OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_stock-billingdocument
                                       conditiontype   = 'ZHRM' ]-conditionamount OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_stock-billingdocument
                                       conditiontype   = 'ZMTP' ]-conditionamount OPTIONAL ) ).

        DATA(lv_taxrate_stock) = CONV string(
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_stock-billingdocument
                                       conditiontype   = 'JOIG' ]-conditionrate OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_stock-billingdocument
                                       conditiontype   = 'JOCG' ]-conditionrate OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_stock-billingdocument
                                       conditiontype   = 'JOSG' ]-conditionrate OPTIONAL ) ).

        DATA(lv_taxamt_stock) = CONV string(
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_stock-billingdocument
                                       conditiontype   = 'JOIG' ]-conditionamount OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_stock-billingdocument
                                       conditiontype   = 'JOSG' ]-conditionamount OPTIONAL ) +
          VALUE #( lt_billdocitemcond[ billingdocument = ls_itemhsn_stock-billingdocument
                                       conditiontype   = 'JOCG' ]-conditionamount OPTIONAL ) ).

        lv_totaltaxablevalue_k = lv_totaltaxablevalue_k + ls_itemhsn_stock-netamount.
        lv_totaltaxamountvalue_k = lv_taxamt_stock.

        lv_xml = lv_xml &&
           |    <BODY>| &&
           |      <HSN>{ lv_hsncode_stock1 }</HSN>| &&
           |      <TaxableValue>{ ls_itemhsn_stock-netamount }</TaxableValue>| &&
           |      <Rate>{ lv_taxrate_stock }</Rate>| &&
           |      <AmountValue>{ lv_taxamt_stock }</AmountValue>| &&
           |      <TaxAmountValue>{ lv_taxamt_stock }</TaxAmountValue>| &&
           |    </BODY>|.

        CLEAR: lv_hsncode_stock1, lv_taxablevalue_stock, lv_taxrate_stock, lv_taxamt_stock.
      ENDLOOP.

  ls_footer_det = VALUE #( companyname = 'for Transvolt Mobility Private Limited'
                               companypan  = '' ).
.

      lv_xml = lv_xml &&
         |    <TOTALAMT>| &&
         |      <TotalTaxableValue>{ lv_totaltaxablevalue_k }</TotalTaxableValue>| &&
         |      <RateText/>| &&
         |      <TotalAmountValue>{ lv_totaltaxamountvalue_k }</TotalAmountValue>| &&
         |      <TotalTaxAmountValue>{ lv_totaltaxamountvalue_k }</TotalTaxAmountValue>| &&
         |    </TOTALAMT>| &&
         |  </ITEM>| &&
         |</ITEM_HSN>|.

      lv_xml = lv_xml &&
         |<Footer>| &&
         |  <TaxAmtInWords>| &&
         |    <TaxAmtInWordsValue/>| &&
         |  </TaxAmtInWords>| &&
         |  <CompanyPANfrm>| &&
         |    <Space/>| &&
         |    <CompanyPAN>| &&
         |      <CompanyPAN>{ ls_footer_det-companypan }</CompanyPAN>| &&
         |    </CompanyPAN>| &&
         |  </CompanyPANfrm>| &&
         |  <SigntaureFrm>| &&
         |    <CompanyName>{ ls_footer_det-companyname }</CompanyName>| &&
         |    <Space/>| &&
         |  </SigntaureFrm>| &&
         |</Footer>|.



      lv_xml = lv_xml &&
         |</MainPage1>| &&
         |</form1>|.

    ENDIF.


    REPLACE ALL OCCURRENCES OF '&' IN lv_xml WITH 'and'.

    CALL METHOD zmm_adobe_print1=>getpdf(
      EXPORTING
        xmldata  = lv_xml
        template = lv_template
      RECEIVING
        result   = DATA(lv_pdf) ).

    IF lv_pdf IS NOT INITIAL.
      APPEND VALUE zsdt_taxinv_prnt( client        = sy-mandt
                                     bill_doc      = ls_entity-billdoc
                                     form_name     = lv_formname
                                     file_contents = lv_pdf
                                     sto_qty           = ls_entity-stoqty
                                     sto_unit      = ls_entity-stounit ) TO lhc_buffer=>mt_buffer.
    ENDIF.
  ENDMETHOD.

  METHOD update.
  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.


  METHOD get_xml_tag_value.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zsd_tax_invoice_print DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zsd_tax_invoice_print IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    DATA: lt_taxinvprintdata TYPE STANDARD TABLE OF zsdt_taxinv_prnt.

    IF lhc_buffer=>mt_buffer IS NOT INITIAL.
      lt_taxinvprintdata = lhc_buffer=>mt_buffer.
      MODIFY zsdt_taxinv_prnt FROM TABLE @lt_taxinvprintdata.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
