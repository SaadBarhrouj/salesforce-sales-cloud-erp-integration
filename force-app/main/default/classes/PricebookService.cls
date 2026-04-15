/**
 * @description Service class for calculating product and bundle pricing.
 * It supports standard Pricebook pricing and Volume-based pricing logic.
 */
public inherited sharing class PricebookService {
    private static final String PRICEBOOK_METHOD = 'Pricebook';
    private static final String VOLUME_PRICING_METHOD = 'VolumePricing';  
      
    /**
     * @description Calculates pricing for multiple line items based on a pricing method.
     * @param lineItems List of line items with productId, quantity, and discount.
     * @param pricingMethod Either 'Pricebook' or 'VolumePricing'.
     * @param pricebookId The Pricebook to use for lookups.
     * @return List of PricingResponse objects with calculated values.
     */
    public static List<PricingResponse> calculatePrices(List<Map<String, Object>> lineItems, String pricingMethod, Id pricebookId) {
        List<PricingResponse> responses = new List<PricingResponse>();

        for (Map<String, Object> item : lineItems) {
            Id productId = (Id) item.get('productId');
            Integer quantity = toInteger(item.get('quantity'));
            Decimal discount = toDecimal(item.get('discount'));

            PricingResponse response = pricingMethod == VOLUME_PRICING_METHOD
                ? calculateByVolumePricing(productId, pricebookId, quantity, discount)
                : calculateByPricebook(productId, pricebookId, quantity, discount);

            responses.add(response);
        }

        return responses;
    }


    /**
     * @description Calculates price using standard Pricebook Entry.
     * @param productId Product Id to look up.
     * @param pricebookId Pricebook Id to look up.
     * @param quantity Quantity to multiply.
     * @param discount Discount percentage to apply.
     * @return PricingResponse with calculated prices.
     */
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
            response.pricingMethod = PRICEBOOK_METHOD;
            return response;
        } catch (Exception e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    /**
     * @description Calculates price using Volume Pricing Schedules and Tiers.
     * @param productId Product Id with an active schedule.
     * @param pricebookId Pricebook Id for lookup.
     * @param quantity Quantity to determine the tier.
     * @param discount Discount percentage to apply.
     * @return PricingResponse with tiered or block pricing result.
     */
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

            Decimal listPrice;
            String method;

            if (matchedTier != null) {
                listPrice = matchedTier.Price__c.setScale(2);
            } else if (schedule.Overage_Rate__c != null) {
                listPrice = schedule.Overage_Rate__c.setScale(2);
            } else {
                return PricingResponse.error('No matching tier for quantity: ' + quantity);
            }

            Decimal netPrice = listPrice * (1 - discount / 100).setScale(2);
            Decimal totalPrice;

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
            response.netPrice = netPrice;
            response.totalPrice = totalPrice;
            response.discount = discount;
            response.quantity = quantity;
            response.pricingMethod = method;
            return response;
        } catch (Exception e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    /**
     * @description Finds the matching volume pricing tier for a given quantity.
     * @param tiers List of Volume_Pricing_Tier__c records to search.
     * @param quantity The quantity to match against tier bounds.
     * @return The matched tier, or null if no tier matches.
     */
    private static Volume_Pricing_Tier__c findMatchedTier(List<Volume_Pricing_Tier__c> tiers, Integer quantity) {
        Decimal qty = Decimal.valueOf(quantity);
        for (Volume_Pricing_Tier__c tier : tiers) {
            if (tier.Lower_Bound__c != null && qty >= tier.Lower_Bound__c) {
                if (tier.Upper_Bound__c == null || qty <= tier.Upper_Bound__c) {
                    return tier;
                }
            }
        }
        return null;
    }
    
    /**
     * @description Converts an Object value to an Integer, defaulting to 1.
     * @param value The object to convert to an Integer.
     * @return The Integer value, or 1 if conversion fails.
     */
    private static Integer toInteger(Object value) {
        if (value == null) {
            return 1;
        }
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Decimal) {
            return ((Decimal) value).intValue();
        }
        return Integer.valueOf(String.valueOf(value));
    }

    /**
     * @description Converts an Object value to a Decimal, defaulting to 0.
     * @param value The object to convert to a Decimal.
     * @return The Decimal value, or 0 if conversion fails.
     */
    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return 0;
        }
        if (value instanceof Decimal) {
            return (Decimal) value;
        }
        if (value instanceof Integer) {
            return Decimal.valueOf((Integer) value);
        }
        return Decimal.valueOf(String.valueOf(value));
    }

    /**
     * @description Validates that the discount is between 0 and 100.
     * @param discount The discount percentage to validate.
     * @throws PricebookException if discount is null, negative, or exceeds 100.
     */
    private static void validateDiscount(Decimal discount) {
        if (discount == null || discount < 0 || discount > 100) {
            throw new PricebookException('Discount must be between 0 and 100');
        }
    }

    /**
     * @description Validates that the quantity is at least 1.
     * @param quantity The quantity to validate.
     * @throws PricebookException if quantity is null or less than 1.
     */
    private static void validateQuantity(Integer quantity) {
        if (quantity == null || quantity < 1) {
            throw new PricebookException('Quantity must be at least 1');
        }
    }
}