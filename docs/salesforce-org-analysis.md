# Salesforce Org Analysis

Generated from the metadata available under `force-app/main/default/objects`.

## Account

- Label: Account
- Fields selected by the DAO: 46
- Required fields enforced by the Service: Name

| Field | Type | Reference |
| --- | --- | --- |
| AccountNumber |  |  |
| AccountSource | Picklist |  |
| Active__c | Picklist |  |
| AnnualRevenue |  |  |
| BillingAddress |  |  |
| ChannelProgramLevelName |  |  |
| ChannelProgramName |  |  |
| CleanStatus |  |  |
| CustomerPriority__c | Picklist |  |
| DandbCompanyId | Lookup |  |
| Description |  |  |
| DunsNumber |  |  |
| Fax |  |  |
| Industry | Picklist |  |
| IsCustomerPortal |  |  |
| IsPartner |  |  |
| Jigsaw |  |  |
| NaicsCode |  |  |
| NaicsDesc |  |  |
| Name |  |  |
| NumberOfEmployees |  |  |
| NumberofLocations__c | Number |  |
| OperatingHoursId | Lookup |  |
| OwnerId | Lookup |  |
| Ownership | Picklist |  |
| ParentId | Hierarchy |  |
| Phone |  |  |
| Rating | Picklist |  |
| SLAExpirationDate__c | Date |  |
| SLASerialNumber__c | Text |  |
| SLA__c | Picklist |  |
| ShippingAddress |  |  |
| Sic |  |  |
| SicDesc |  |  |
| Site |  |  |
| TickerSymbol |  |  |
| Tier |  |  |
| Tradestyle |  |  |
| Type | Picklist |  |
| UpsellOpportunity__c | Picklist |  |
| Website |  |  |
| YearStarted |  |  |

## Bundle_Feature__c

- Label: Bundle Feature
- Fields selected by the DAO: 8
- Required fields enforced by the Service: Sort_Order__c, Name

| Field | Type | Reference |
| --- | --- | --- |
| Name | Name | |
| Help_Text__c | LongTextArea |  |
| Max_Options__c | Number |  |
| Min_Options__c | Number |  |
| Product__c | Lookup | Product2 |
| Sort_Order__c | Number |  |

## Bundle_Option__c

- Label: Bundle Option
- Fields selected by the DAO: 16
- Required fields enforced by the Service: Option_Type__c, Sort_Order__c

| Field | Type | Reference |
| --- | --- | --- |
| Name | Name | |
| Bundle_Product__c | Lookup | Product2 |
| Default_Quantity__c | Number |  |
| Feature__c | Lookup | Bundle_Feature__c |
| Is_Required__c | Checkbox |  |
| Is_Selected__c | Checkbox |  |
| Max_Quantity__c | Number |  |
| Min_Quantity__c | Number |  |
| Option_Product__c | Lookup | Product2 |
| Option_Type__c | Picklist |  |
| Quantity_Editable__c | Checkbox |  |
| Sort_Order__c | Number |  |

## Bundle_Rule_Assignment__c

- Label: Bundle Rule Assignment
- Fields selected by the DAO: 7
- Required fields enforced by the Service: Product_Rule__c, Bundle_Product__c

| Field | Type | Reference |
| --- | --- | --- |
| Name | Name | |
| Bundle_Product__c | Lookup | Product2 |
| Is_Active__c | Checkbox |  |
| Product_Rule__c | Lookup | Product_Rule__c |

## Location

- Label: Location
- Fields selected by the DAO: 36
- Required fields enforced by the Service: Country_Code__c, Name

| Field | Type | Reference |
| --- | --- | --- |
| CloseDate |  |  |
| ConstructionEndDate |  |  |
| ConstructionStartDate |  |  |
| Country_Code__c | Picklist |  |
| Description |  |  |
| DrivingDirections |  |  |
| EarliestPickupTimeOffset |  |  |
| Email |  |  |
| ExternalReference |  |  |
| Fax |  |  |
| IsEligibleForPickup |  |  |
| IsInventoryLocation |  |  |
| IsMobile |  |  |
| LatestPickupTimeOffset |  |  |
| Location |  |  |
| LocationLevel |  |  |
| LocationType | Picklist |  |
| LogoId | Lookup |  |
| Mobile |  |  |
| Name |  |  |
| OpenDate |  |  |
| OwnerId | Lookup |  |
| ParentLocationId | Hierarchy |  |
| Phone |  |  |
| PickupProcessingTime |  |  |
| PickupProcessingTimeUnit |  |  |
| PossessionDate |  |  |
| RemodelEndDate |  |  |
| RemodelStartDate |  |  |
| RootLocationId | Lookup |  |
| ShouldSyncWithOci |  |  |
| Site_Access__c | Picklist |  |
| TimeZone |  |  |
| VisitorAddressId | Lookup |  |

## Opportunity

- Label: Opportunity
- Fields selected by the DAO: 37
- Required fields enforced by the Service: Name, StageName, CloseDate, AccountId

| Field | Type | Reference |
| --- | --- | --- |
| AccountId | Lookup |  |
| Amount |  |  |
| CampaignId | Lookup |  |
| CloseDate |  |  |
| ContractId | Lookup |  |
| CurrentGenerators__c | Text |  |
| Default_Agency__c | Lookup | Location |
| DeliveryInstallationStatus__c | Picklist |  |
| Delivery_Site__c | Lookup | Location |
| Description |  |  |
| ExpectedRevenue |  |  |
| IqScore |  |  |
| IsPrivate |  |  |
| Is_Transport_Required__c | Checkbox |  |
| LeadSource | Picklist |  |
| MainCompetitors__c | Text |  |
| Name |  |  |
| NextStep |  |  |
| Offer_Type__c | Picklist |  |
| OrderNumber__c | Text |  |
| OwnerId | Lookup |  |
| Pricebook2Id | Lookup |  |
| Probability |  |  |
| StageName | Picklist |  |
| TotalOpportunityQuantity |  |  |
| Total_Transport_Cost__c | Summary |  |
| TrackingNumber__c | Text |  |
| Transport_Urgency__c | Picklist |  |
| Type | Picklist |  |

## OpportunityLineItem

- Label: OpportunityLineItem
- Fields selected by the DAO: 28
- Required fields enforced by the Service: OpportunityId, PricebookEntryId, Quantity, UnitPrice

| Field | Type | Reference |
| --- | --- | --- |
| Bundle_Group__c | Text |  |
| Delivery_Date__c | Date |  |
| Departure_Agency__c | Lookup | Location |
| Description |  |  |
| Discount |  |  |
| Is_Bundle_Product__c | Checkbox |  |
| ListPrice |  |  |
| Name |  |  |
| OpportunityId | Lookup |  |
| Pickup_Date__c | Date |  |
| Product2Id | Lookup |  |
| ProductCode |  |  |
| Quantity |  |  |
| Rental_End_Date__c | Date |  |
| Rental_Start_Date__c | Date |  |
| ServiceDate |  |  |
| Subtotal |  |  |
| TotalPrice |  |  |
| Trip_Delivery__c | Lookup | Trip__c |
| Trip_Pickup__c | Lookup | Trip__c |
| UnitPrice |  |  |
| PricebookEntryId | Standard | |

## Product2

- Label: Product2
- Fields selected by the DAO: 14
- Required fields enforced by the Service: Name

| Field | Type | Reference |
| --- | --- | --- |
| Description |  |  |
| DisplayUrl |  |  |
| ExternalDataSourceId | Lookup |  |
| ExternalId |  |  |
| Family | Picklist |  |
| IsActive |  |  |
| Name |  |  |
| ProductCode |  |  |
| QuantityUnitOfMeasure | Picklist |  |
| SellerId | Lookup |  |
| SourceProductId | Lookup |  |
| StockKeepingUnit |  |  |
| Unit_Weight_Kg__c | Number |  |

## ProductCatalog

- Label: ProductCatalog
- Fields selected by the DAO: 4
- Required fields enforced by the Service: Name

| Field | Type | Reference |
| --- | --- | --- |
| Name |  |  |
| OwnerId | Lookup |  |

## ProductCategory

- Label: ProductCategory
- Fields selected by the DAO: 8
- Required fields enforced by the Service: CatalogId, Name

| Field | Type | Reference |
| --- | --- | --- |
| CatalogId | MasterDetail |  |
| Description |  |  |
| IsNavigational |  |  |
| Name |  |  |
| ParentCategoryId | Hierarchy |  |
| SortOrder |  |  |

## ProductCategoryProduct

- Label: ProductCategoryProduct
- Fields selected by the DAO: 6
- Required fields enforced by the Service: ProductCategoryId, ProductId

| Field | Type | Reference |
| --- | --- | --- |
| IsPrimaryCategory |  |  |
| ProductCategoryId | MasterDetail |  |
| ProductId | Lookup |  |

## Product_Rule__c

- Label: Product Rule
- Fields selected by the DAO: 10
- Required fields enforced by the Service: Conditions_Met__c, Evaluation_Event__c, Scope__c, Type__c, Name

| Field | Type | Reference |
| --- | --- | --- |
| Name | Name | |
| Advanced_Condition__c | Text |  |
| Conditions_Met__c | Picklist |  |
| Evaluation_Event__c | Picklist |  |
| Evaluation_Order__c | Number |  |
| Is_Active__c | Checkbox |  |
| Message__c | LongTextArea |  |
| Scope__c | Picklist |  |
| Type__c | Picklist |  |

## Rule_Action__c

- Label: Rule Action
- Fields selected by the DAO: 11
- Required fields enforced by the Service: Product_Rule__c, Type__c

| Field | Type | Reference |
| --- | --- | --- |
| Name | Name | |
| Filter_Field__c | Text |  |
| Filter_Operator__c | Picklist |  |
| Filter_Value__c | Text |  |
| Product_Rule__c | MasterDetail | Product_Rule__c |
| Sort_Order__c | Number |  |
| Target_Product__c | Lookup | Product2 |
| Type__c | Picklist |  |

## Rule_Condition__c

- Label: Rule Condition
- Fields selected by the DAO: 10
- Required fields enforced by the Service: Filter_Type__c, Filter_Value__c, Operator__c, Product_Rule__c, Tested_Field__c, Tested_Object__c

| Field | Type | Reference |
| --- | --- | --- |
| Name | Name | |
| Filter_Type__c | Picklist |  |
| Filter_Value__c | Text |  |
| Index__c | Number |  |
| Operator__c | Picklist |  |
| Product_Rule__c | MasterDetail | Product_Rule__c |
| Tested_Field__c | Text |  |
| Tested_Object__c | Picklist |  |

## Trip__c

- Label: Trip
- Fields selected by the DAO: 24
- Required fields enforced by the Service: Country_Code__c, Direction__c, Opportunity__c, Status__c, Trip_Date__c, Trip_Key__c

| Field | Type | Reference |
| --- | --- | --- |
| Name | Name | |
| Calculation_Detail__c | LongTextArea |  |
| Country_Code__c | Text |  |
| Departure_Location__c | Lookup | Location |
| Destination_Location__c | Lookup | Location |
| Direction__c | Picklist |  |
| Distance_Km__c | Number |  |
| Final_Price__c | Currency |  |
| Is_Price_Overridden__c | Checkbox |  |
| Opportunity__c | MasterDetail | Opportunity |
| Override_Reason__c | Text |  |
| Price_Before_Conversion__c | Currency |  |
| Rate_Currency__c | Text |  |
| Status__c | Picklist |  |
| System_Price__c | Currency |  |
| Total_Weight_Kg__c | Number |  |
| Transport_Zone__c | Text |  |
| Trip_Date__c | Date |  |
| Trip_Key__c | Text |  |
| Truck_Type__c | Text |  |

## Volume_Pricing_Schedule__c

- Label: Volume Pricing Schedule
- Fields selected by the DAO: 9
- Required fields enforced by the Service: Pricing_Type__c, Name, Product__c

| Field | Type | Reference |
| --- | --- | --- |
| Name | Name | |
| Is_Active__c | Checkbox |  |
| Overage_Rate__c | Currency |  |
| Pricebook__c | Lookup | Pricebook2 |
| Pricing_Type__c | Picklist |  |
| Product__c | Lookup | Product2 |

## Volume_Pricing_Tier__c

- Label: Volume Pricing Tier
- Fields selected by the DAO: 8
- Required fields enforced by the Service: Lower_Bound__c, Price__c, Sort_Order__c, Volume_Pricing_Schedule__c, Name

| Field | Type | Reference |
| --- | --- | --- |
| Name | Name | |
| Lower_Bound__c | Number |  |
| Price__c | Currency |  |
| Sort_Order__c | Number |  |
| Upper_Bound__c | Number |  |
| Volume_Pricing_Schedule__c | MasterDetail | Volume_Pricing_Schedule__c |
