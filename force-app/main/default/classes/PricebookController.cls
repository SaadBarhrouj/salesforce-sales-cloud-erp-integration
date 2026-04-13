/**
 * @description Controller for pricing calculations.
 */
public inherited sharing class PricebookController {
    private static final String PRICEBOOK_METHOD = 'Pricebook';
    private static final String VOLUME_PRICING_METHOD = 'VolumePricing';

    /**
     * @description Calculates line prices for the provided line items.
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

        List<String> volumePricingCatalogs = Label.Volume_Pricing_Catalog_Names.split(',');

        ProductCatalog catalog = ProductCatalogDAO.getById(offerTypeStr);

        for (String volumePricingCatalog : volumePricingCatalogs) {
            if (catalog != null && catalog.Name == volumePricingCatalog.trim()) {
                return VOLUME_PRICING_METHOD;
            }
        }
        return PRICEBOOK_METHOD;
    }
}