public inherited sharing class PricebookService {
    public enum PricingMethod {
        Pricebook,
        VolumePricing
    }

    public class PricingException extends Exception {}

    public static PricingResponse calculateByPricebook(Id productId, Id pricebookId, Integer quantity, Decimal discount) {
        try {
            validateDiscount(discount);
            validateQuantity(quantity);

            PricebookEntry entry = PricebookEntryDAO.getByProductAndPricebook(productId, pricebookId);
            if (entry == null) {
                return PricingResponse.error('Pricebook entry not found for product');
            }

            Decimal listPrice = entry.UnitPrice;
            Decimal netPrice = listPrice * (1 - discount / 100).setScale(2);
            Decimal totalPrice = (netPrice * quantity).setScale(2);

            PricingResponse response = new PricingResponse();
            response.productId = productId;
            response.listPrice = listPrice;
            response.netPrice = netPrice;
            response.totalPrice = totalPrice;
            response.discount = discount;
            response.quantity = quantity;
            response.pricingMethod = PricingMethod.Pricebook.name();
            return response;
        } catch (Exception e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    public static PricingResponse calculateByVolumePricing(Id productId, Id pricebookId, Integer quantity, Decimal discount) {
        try {
            validateDiscount(discount);
            validateQuantity(quantity);

            Volume_Pricing_Schedule__c schedule = VolumePricingScheduleDAO.getActiveByProductAndPricebook(productId, pricebookId);
            
            if (schedule == null) {
                return PricingResponse.error('Volume pricing schedule not found for product');
            }

            List<Volume_Pricing_Tier__c> tiers = schedule.Volume_Pricing_Tiers__r;
            if (tiers == null || tiers.isEmpty()) {
                return PricingResponse.error('No volume pricing tiers defined');
            }

            Volume_Pricing_Tier__c matchedTier = findMatchedTier(tiers, quantity);

            if (matchedTier == null) {
                return PricingResponse.error('No matching tier for quantity: ' + quantity);
            }

            Decimal listPrice = matchedTier.Price__c.setScale(2);
            Decimal netPrice = listPrice * (1 - discount / 100);
            Decimal totalPrice;
            String method;

            if (schedule.Pricing_Type__c == 'Block') {
                method = 'Block';
                totalPrice = netPrice.setScale(2);
            } else {
                method = 'Tiered';
                totalPrice = (netPrice * quantity).setScale(2);
            }

            PricingResponse response = new PricingResponse();
            response.productId = productId;
            response.listPrice = listPrice;
            response.netPrice = netPrice.setScale(2);
            response.totalPrice = totalPrice;
            response.discount = discount;
            response.quantity = quantity;
            response.pricingMethod = method;
            return response;
        } catch (Exception e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    private static Volume_Pricing_Tier__c findMatchedTier(List<Volume_Pricing_Tier__c> tiers, Integer quantity) {
        Decimal qty = Decimal.valueOf(quantity);
        for (Volume_Pricing_Tier__c tier : tiers) {
            if (tier.Lower_Bound__c != null && tier.Upper_Bound__c != null &&
                qty >= tier.Lower_Bound__c && qty < tier.Upper_Bound__c) {
                return tier;
            }
        }
        return null;
    }

    public static List<PricingResponse> calculatePrices(List<Map<String, Object>> lineItems, PricingMethod pricingMethod, Id pricebookId) {
        List<PricingResponse> responses = new List<PricingResponse>();

        for (Map<String, Object> item : lineItems) {
            Id productId = (Id) item.get('productId');
            Integer quantity = toInteger(item.get('quantity'));
            Decimal discount = toDecimal(item.get('discount'));

            PricingResponse response = pricingMethod == PricingMethod.Pricebook
                ? calculateByPricebook(productId, pricebookId, quantity, discount)
                : calculateByVolumePricing(productId, pricebookId, quantity, discount);
            responses.add(response);
        }

        return responses;
    }

    private static Integer toInteger(Object value) {
        if (value == null) return 1;
        if (value instanceof Integer) return (Integer) value;
        if (value instanceof Decimal) return ((Decimal) value).intValue();
        return Integer.valueOf(String.valueOf(value));
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) return 0;
        if (value instanceof Decimal) return (Decimal) value;
        if (value instanceof Integer) return Decimal.valueOf((Integer) value);
        return Decimal.valueOf(String.valueOf(value));
    }

    private static void validateDiscount(Decimal discount) {
        if (discount == null || discount < 0 || discount > 100) {
            throw new PricingException('Discount must be between 0 and 100');
        }
    }

    private static void validateQuantity(Integer quantity) {
        if (quantity == null || quantity < 1) {
            throw new PricingException('Quantity must be at least 1');
        }
    }
}