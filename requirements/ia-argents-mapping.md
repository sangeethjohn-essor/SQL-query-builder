# Requirements: ia-argents-mapping

- **source_file:** `ia-argents-mapping.xlsx`
- **sheet:** IA Field Mapping
- **flow:** outbound_and_inbound
- **three_pl:** argents
- **source_outbound:** DWH.PROD.FACT_FINANCE_ARGENTS_OUTBOUND_SHIPMENT
- **source_inbound:** DWH.PROD.FACT_FINANCE_ARGENTS_INBOUND_SHIPMENT

## Field mappings

### unique_id

- **level:** Header
- **required:** Yes
- **rule:** UUID
- **comments:** This has to be unique per transaction.

### external_id

- **level:** Header
- **required:** Yes
- **rule:** UUID
- **comments:** This has to be unique per transaction.

### memo

- **level:** Header
- **required:** Yes
- **rule:** We should use the ID & EXTERNALID Columns - EXTERNAL ID needs to be the text after the '-'
- **example:** Oubound '6ebd3289-221b-4fea-b581-1434b6265c3f' has an [ExternalID] of 'OC1402-TOES05126' and ID of '6ebd3289-221b-4fea-b581-1434b6265c3f'  
    
  Result >> TOES05126 // 6ebd3289-221b-4fea-b581-1434b6265c3f

### subsidiary_internal_id

- **level:** Header
- **required:** Yes
- **rule:** We will use the [VENDOR] value associated with the outbound shipment to look up in the `NETSUITE.NETSUITE.NETSUITE_SUBSIDIARIES` table.
- **example:** For example, outbound '6ebd3289-221b-4fea-b581-1434b6265c3f' has "BOKA" as Customer. We will use the following query to get the subsidiary internal ID.  
    
  (Essor (uc3)) = Karaka LLC & (Boka) = BOKA LLC )  
    
  Result >> BOKA LLC = INTERNAL ID 113

### location_internal_id

- **level:** Header
- **required:** Yes
- **rule:** We will use the [WAREHOUSE] and [VENDOR] values associated with the outbound shipment to look up in the `NETSUITE.NETSUITE.NETSUITE_LOCATIONS` table.
- **example:** For example, outbound '6ebd3289-221b-4fea-b581-1434b6265c3f' has "BOKA LLC" as Vendor and "Elgin IL" as Facility. (We only need to take the location not the State) e.g. 'Elgin'  
    
  SELECT LOCATION_INT_ID, LOCATION_NAME, LOCATION_SUBSIDIARY_NAME  
  FROM NETSUITE.NETSUITE.NETSUITE_LOCATIONS  
  WHERE LOCATION_NAME ILIKE '%Elgin%' AND LOCATION_SUBSIDIARY_NAME LIKE 'BOKA LLC';  
    
  >> Result: 2863 (Argents Elgin-US-BOK)
- **comments:** Adjustment Location

### account_id

- **level:** Header
- **required:** Yes
- **rule:** This depends on the Order Type we categorise this into:  
    
  Work Order: 134000 Manual Adjustments 1693  
  Samples: 524500 Essor Samples 3323  
  Disposals: 518110 Other Disposals 2872

### date

- **level:** Header
- **required:** Yes
- **rule:** [SHIPPEDDATE] from Argents
- **example:** For example, outbound '6ebd3289-221b-4fea-b581-1434b6265c3f' has a Shipped date of 26th June

### geography_id

- **level:** Header
- **required:** Yes
- **rule:** We will use the [SHIPPINGADDRESSCOUNTRYTWOLETTERCODE] value to look up in the `NETSUITE.NETSUITE.NETSUITE_GEOGRAPHIES` table.
- **example:** For example, outbound '6ebd3289-221b-4fea-b581-1434b6265c3f' has a Country code of US

### sales_channel_id

- **level:** Header
- **required:** Yes
- **rule:** Always use Amazon Seller Central  
    
  Internal ID 1

### Class_id

- **level:** Header
- **required:** Yes
- **rule:** We will take the first 3 letters from the result of sku_internal_id

### Department_id

- **level:** Header
- **required:** Yes
- **rule:** Always Supply Chain 21100 - Internal ID 12

### sku_internal_id

- **level:** Line
- **required:** Yes
- **rule:** We will use the [LINEITEMSKU] value to look up in the `NETSUITE.NETSUITE.NETSUITE_ITEMS` table.
- **example:** For example, outbound '6ebd3289-221b-4fea-b581-1434b6265c3f' contains the following [LINEITEMSKU] values:  
    
  BOK-FGS-W002-02-AA1US  
  BOK-FGS-P002-01-AB1US  
    
  SELECT DISTINCT SKU, ITEM_ID  
  FROM NETSUITE.NETSUITE.NETSUITE_ITEMS  
  WHERE SKU IN ('BOK-FGS-W002-02-AA1US',  
  'BOK-FGS-P002-01-AB1US  
  ) AND ALIAS_MARKET_COUNTRY = 'US';  
    
  Result: BOK-FGS-P002-01-AB1US 39484  
  BOK-FGS-W002-02-AA1US 39551

### quantity

- **level:** Line
- **required:** Yes
- **rule:** We will use [LINEITEMQUANTITY] values.
- **comments:** Can be posititive or negative

### line_location_internal_id

- **level:** Line
- **required:** Yes
- **rule:** We will use the [WAREHOUSE] and [VENDOR] values associated with the outbound shipment to look up in the `NETSUITE.NETSUITE.NETSUITE_LOCATIONS` table.
- **example:** For example, outbound '6ebd3289-221b-4fea-b581-1434b6265c3f' has "BOKA LLC" as Vendor and "Elgin IL" as Facility. (We only need to take the location not the State) e.g. 'Elgin'  
    
  SELECT LOCATION_INT_ID, LOCATION_NAME, LOCATION_SUBSIDIARY_NAME  
  FROM NETSUITE.NETSUITE.NETSUITE_LOCATIONS  
  WHERE LOCATION_NAME ILIKE '%Elgin%' AND LOCATION_SUBSIDIARY_NAME LIKE 'BOKA LLC';  
    
  >> Result: 2863 (Argents Elgin-US-BOK)

### line_department_id

- **level:** Line
- **required:** Yes
- **rule:** Always Supply Chain 21100 - Internal ID 12

### line_class_id

- **level:** Line
- **required:** Yes
- **rule:** We will take the first 3 letters from the result of sku_internal_id

### line_sales_channel_id

- **level:** Line
- **required:** Yes
- **rule:** Always use Amazon Seller Central  
    
  Internal ID 1

### line_geography_id

- **level:** Line
- **required:** Yes
- **rule:** We will use the [SHIPPINGADDRESSCOUNTRYTWOLETTERCODE] value to look up in the `NETSUITE.NETSUITE.NETSUITE_GEOGRAPHIES` table.
- **example:** For example, outbound '6ebd3289-221b-4fea-b581-1434b6265c3f' has a Country code of US

## Required output columns

| Column | Level |
|--------|-------|
| unique_id | Header |
| external_id | Header |
| memo | Header |
| subsidiary_internal_id | Header |
| location_internal_id | Header |
| account_id | Header |
| date | Header |
| geography_id | Header |
| sales_channel_id | Header |
| Class_id | Header |
| Department_id | Header |
| sku_internal_id | Line |
| quantity | Line |
| line_location_internal_id | Line |
| line_department_id | Line |
| line_class_id | Line |
| line_sales_channel_id | Line |
| line_geography_id | Line |
