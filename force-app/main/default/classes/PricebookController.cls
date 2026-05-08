/**
 * @description Controller for pricing calculations.
 */
public inherited sharing class PricebookController {
    private static final String PRICEBOOK_METHOD = 'Pricebook';
    private static final String VOLUME_PRICING_METHOD = 'VolumePricing';

    /**
     * @description Calculates line prices for the provided line items.
     * Catches all exceptions and returns error responses so the LWC always receives a list.
     * @param lineItems Line item payloads containing product, quantity, and discount.
     * @param offerType Catalog or offer identifier used to determine pricing mode.
     * @param pricebookId Pricebook used for standard pricing lookups.
     * @return List of calculated pricing responses.
     */
    @AuraEnabled(cacheable=false)
    public static List<PricingResponse> calculateLinePrices(List<Map<String, Object>> lineItems, Object offerType, Id pricebookId) {
        try {
            if (lineItems == null || lineItems.isEmpty()) {
                return new List<PricingResponse>();
            }
            String pricingMethod = getPricingMethod(offerType);
            return PricebookService.calculatePrices(lineItems, pricingMethod, pricebookId);
        } catch (Exception e) {
            List<PricingResponse> errors = new List<PricingResponse>();
            for (Integer i = 0; i < lineItems.size(); i++) {
                errors.add(PricingResponse.error(e.getMessage()));
            }
            return errors;
        }
    }

    /**
     * @description Resolves the pricing method from the supplied offer type.
     * Catalogs in Volume_Pricing_Catalog_Names use day-bracketed Volume Pricing
     * (service dates required); everything else falls back to standard Pricebook.
     * @param offerType Catalog identifier.
     * @return The pricing method name.
     */
    private static String getPricingMethod(Object offerType) {
        if (offerType == null) {
            return PRICEBOOK_METHOD;
        }
        String offerTypeStr = String.valueOf(offerType);
        if (String.isBlank(offerTypeStr)) {
            return PRICEBOOK_METHOD;
        }

        ProductCatalog catalog = ProductCatalogDAO.getById(offerTypeStr);
        if (catalog == null) {
            return PRICEBOOK_METHOD;
        }

        if (catalogNameIn(catalog.Name, Label.Volume_Pricing_Catalog_Names)) {
            return VOLUME_PRICING_METHOD;
        }
        return PRICEBOOK_METHOD;
    }

    /**
     * @description Returns true if `name` matches any comma-separated entry in `csv`.
     * @param name The catalog name to test.
     * @param csv The comma-separated catalog name list (Custom Label value).
     * @return Whether the name appears in the list.
     */
    private static Boolean catalogNameIn(String name, String csv) {
        if (String.isBlank(csv) || String.isBlank(name)) {
            return false;
        }
        for (String token : csv.split(',')) {
            if (token.trim().equalsIgnoreCase(name)) {
                return true;
            }
        }
        return false;
    }
}