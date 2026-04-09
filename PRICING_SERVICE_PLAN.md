# Pricing Service Implementation Plan

## Overview
Build a robust pricing calculation service for the CPQ Line Editor (Step 3) that supports multiple offer types (Sale, Rental, Services) with tiered pricing, volume discounts, and comprehensive error handling.

## Business Requirements

### Offer Types & Pricing Sources
1. **Sale Catalog** (Offer Type: Sale)
   - Pricing Source: `PricebookEntry` in "Sale" Pricebook
   - Method: Standard fixed unit price
   - Example: Product A @ $100/unit

2. **Rental and Services Catalog** (Offer Type: Rental and Services)
   - Pricing Source: `Volume_Pricing_Schedule__c` + `Volume_Pricing_Tier__c` in "Rental and Services" Pricebook
   - Method: Tiered or Block pricing based on quantity ranges
   - Example: Product B @ $50/unit for qty 1-10, $45/unit for qty 11-20

### Key Constraints
- **Pricebook Selection**: LWC provides `pricebookId` directly (no server-side catalog lookup needed)
- **Volume Tier Matching**: Match quantity within exact range (qty ≥ lowerBound AND qty ≤ upperBound)
- **Discount Validation**: Ensure discount is 0-100% range
- **Decimal Precision**: All calculations use Decimal(16,2)
- **Error Handling**: Throw exceptions for missing pricing data (fail fast)
- **Caching**: Use `@cacheable` for repeated pricing lookups within batch operations

## Technical Architecture

### ClassesStructure (Domain-Driven Design)

```
PricingService Layer (Business Logic)
├─ PricebookService

│  ─ Logic: "Sale" vs "Rental and Services" pricing selection

DAO Layer (Data Access)
├─ PricebookEntryDAO
│  ├─ @cacheable getByProductAndPricebook(productId, pricebookId)
│
└─ VolumePricingScheduleDAO
   ├─ @cacheable getWithTiersByProductAndPricebook(productId, pricebookId)

Controller Layer (LWC Integration)
└─ PricebookController


Response Model
└─ PricingResponse (Wrapper)


## Pricing Calculation Logic

### For Sale Offer Type:
1. Fetch `PricebookEntry.UnitPrice` for the product in "Sale" pricebook
2. Validate discount (0-100%)
3. Calculate: `netPrice = unitPrice * (1 - discount/100)`
4. Calculate: `totalPrice = netPrice * quantity`
5. Return: `PricingResponse` with validated prices

### For Rental/Services Offer Type:
1. Fetch `Volume_Pricing_Schedule__c` for the product
2. Find matching `Volume_Pricing_Tier__c` where `quantity >= lowerBound AND quantity <= upperBound`
3. Extract tier price, determine if Tiered or Block pricing
4. Calculate: `netPrice = tierPrice * (1 - discount/100)` (if Tiered); or use tier price directly (if Block)
5. Calculate: `totalPrice = netPrice * quantity`
6. Return: `PricingResponse` with pricing method info

### Discount Application:
- Validate: `0 <= discount <= 100`
- Throw exception if out of range
- Formula: `netPrice = unitPrice * (1 - discount/100)`
- Precision: Round to 2 decimals

## Exception Handling Strategy

| Scenario | Action |
|----------|--------|
| Product not found | Throw exception (fail fast) |
| PricebookEntry missing | Throw exception in service |
| Volume_Pricing_Schedule not found | Throw exception in service |
| No matching tier for quantity | Throw exception (qty out of valid range) |
| Discount validation fails | Throw exception in service |
| Any service exception | Controller catches, wraps in `AuraHandledException` |

## LWC Integration (Line Editor)

### Data Flow:
1. **User edits row** (qty or discount change)
2. **Debounce 500ms** (wait for user to stop typing)
3. **Batch collect edits** (if multiple rows edited)
4. **Call controller method**: `calculateLinePricesBatch(List<Map>)`
5. **Service calculates** (Sale or Rental pricing)
6. **Return PricingResponse** with prices + errors
7. **Update UI** (show prices or toast error)

## File Checklist (To Create)

- [ ] `PricingResponse.cls` - Wrapper
- [ ] `PricebookEntryDAO.cls` - Query PricebookEntry
- [ ] `VolumePricingScheduleDAO.cls` - Query Volume tiers
- [ ] `PricebookService.cls` - Core pricing logic
- [ ] `PricebookController.cls` - Expose to LWC

## Naming Conventions (Established Patterns)

- DAO Classes: `{Object}DAO.cls` (e.g., `PricebookEntryDAO`)
- Service Classes: `{Object}Service.cls` (e.g., `PricebookService`)
- Controller Classes: `{Object}Controller.cls` (e.g., `PricebookController`)
- Wrappers: `{Purpose}Response.cls` (e.g., `PricingResponse`)
- Exceptions: Reuse `BundleOptionException` or `Product2Exception` (generic handling)
- Methods: `camelCase`, `@AuraEnabled` for LWC, `@cacheable` for repeated queries

## Known Constraints & Assumptions

1. **ProductCatalog is NOT queried in service** - LWC provides pricebookId directly
2. **Volume_Pricing_Schedule is currently empty**
3. **Discount validation is light** (0-100% range only; max discount limits handled by LWC UI)
4. **Batch operations** assume max 100 line items per batch (Apex governor limit safety)
5. **Caching scope** is request-level (@cacheable) to support batch operations
6. **Precision** is Decimal(16,2) for all monetary values (matches Salesforce standard)

## Implementation Priority

| Phase | Task |
|-------|------|
| 1 | Create `PricingResponse` wrapper + exceptions |
| 2 | Create `PricebookEntryDAO` + `VolumePricingScheduleDAO` |
| 3 | Create `PricebookService` with core calculation logic |
| 4 | Create `PricebookController` with @AuraEnabled methods |
| 6 | Integrate with Line Editor LWC |

---

**Status**: Ready for implementation ✓
