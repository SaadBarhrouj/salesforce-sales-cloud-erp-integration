public inherited sharing class PricebookController {
    @AuraEnabled(cacheable=false)
    public static PricingResponse calculateLinePrice(Id productId, Id pricebookId, Integer quantity, Decimal discount, Object offerType) {
        try {
            PricebookService.PricingMethod pricingMethod = getPricingMethod(offerType);
            if (pricingMethod == PricebookService.PricingMethod.Pricebook) {
                return PricebookService.calculateByPricebook(productId, pricebookId, quantity, discount);
            } else {
                return PricebookService.calculateByVolumePricing(productId, pricebookId, quantity, discount);
            }
        } catch (Exception e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<PricingResponse> calculateLinePrices(List<Map<String, Object>> lineItems, Object offerType, Id pricebookId) {
        try {
            if (lineItems == null || lineItems.isEmpty()) {
                return new List<PricingResponse>();
            }
            PricebookService.PricingMethod pricingMethod = getPricingMethod(offerType);
            return PricebookService.calculatePrices(lineItems, pricingMethod, pricebookId);
        } catch (Exception e) {
            List<PricingResponse> errors = new List<PricingResponse>();
            for (Integer i = 0; i < lineItems.size(); i++) {
                errors.add(PricingResponse.error(e.getMessage()));
            }
            return errors;
        }
    }

    private static PricebookService.PricingMethod getPricingMethod(Object offerType) {
        if (offerType == null) {
            return PricebookService.PricingMethod.Pricebook;
        }

        String offerTypeStr = String.valueOf(offerType);
        if (String.isBlank(offerTypeStr)) {
            return PricebookService.PricingMethod.Pricebook;
        }

        List<String> volumeCatalogs = Label.Volume_Pricing_Catalog_Names.split(',');

        ProductCatalog catalog = ProductCatalogDAO.getById(offerTypeStr);
        if (catalog == null || String.isBlank(catalog.Name)) {
            return PricebookService.PricingMethod.Pricebook;
        }

        if (matchesCatalog(catalog.Name, volumeCatalogs)) return PricebookService.PricingMethod.VolumePricing;
        return PricebookService.PricingMethod.Pricebook;
    }

    private static Boolean matchesCatalog(String value, List<String> catalogs) {
        if (String.isBlank(value) || catalogs == null || catalogs.isEmpty()) return false;
        String normalized = value.trim();
        for (String catalog : catalogs) {
            if (normalized.containsIgnoreCase(catalog.trim())) return true;
        }
        return false;
    }
}