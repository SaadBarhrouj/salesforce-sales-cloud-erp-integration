public inherited sharing class PricebookController {
    @AuraEnabled(cacheable=false)
    public static PricingResponse calculateLinePrice(Id productId, Id pricebookId, Integer quantity, Decimal discount, Object offerType) {
        try {
            String pricingType = getPricingType(offerType);
            if (pricingType == 'Sale') {
                return PricebookService.calculateSalePrice(productId, pricebookId, quantity, discount);
            } else {
                return PricebookService.calculateRentalServicesPrice(productId, pricebookId, quantity, discount);
            }
        } catch (Exception e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<PricingResponse> calculateLinePricesBatch(List<Map<String, Object>> lineItems, Object offerType, Id pricebookId) {
        try {
            if (lineItems == null || lineItems.isEmpty()) {
                return new List<PricingResponse>();
            }
            String pricingType = getPricingType(offerType);
            return PricebookService.calculatePricesBatch(lineItems, pricingType, pricebookId);
        } catch (Exception e) {
            List<PricingResponse> errors = new List<PricingResponse>();
            for (Integer i = 0; i < lineItems.size(); i++) {
                errors.add(PricingResponse.error(e.getMessage()));
            }
            return errors;
        }
    }

    private static String getPricingType(Object offerType) {
        if (offerType == null) {
            return 'Sale';
        }
        
        String offerTypeStr = String.valueOf(offerType);
        
        if (offerTypeStr.length() >= 15 && offerTypeStr.length() <= 18) {
            try {
                Id offerTypeId = offerTypeStr;
                if (offerTypeId != null) {
                    List<ProductCatalog> catalogs = [
                        SELECT Name 
                        FROM ProductCatalog 
                        WHERE Id = :offerTypeId 
                        LIMIT 1
                    ];
                    
                    if (!catalogs.isEmpty() && catalogs[0].Name != null && catalogs[0].Name.containsIgnoreCase('Sale')) {
                        return 'Sale';
                    }
                }
            } catch (Exception e) {
                if (offerTypeStr.equalsIgnoreCase('Sale')) {
                    return 'Sale';
                }
                return 'Rental';
            }
        }
        
        if (offerTypeStr.equalsIgnoreCase('Sale')) {
            return 'Sale';
        }
        
        return 'Rental';
    }
}