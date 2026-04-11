public inherited sharing class PricebookController {
    private static final String PRICEBOOK_METHOD = 'Pricebook';
    private static final String VOLUME_PRICING_METHOD = 'VolumePricing';

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