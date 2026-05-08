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
            Date startDate = toDate(item.get('serviceStartDate'));
            Date endDate = toDate(item.get('serviceEndDate'));

            PricingResponse response = pricingMethod == VOLUME_PRICING_METHOD
                ? calculateByVolumePricing(productId, pricebookId, quantity, discount, startDate, endDate)
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
        } catch (PricebookException e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    /**
     * @description Calculates price using day-bracketed Volume Pricing tiers.
     * The tier whose Lower_Bound/Upper_Bound contains the inclusive day count is selected.
     * The tier price is interpreted as the per-day rate at that bracket.
     *
     * Tiered: total = tierPrice (per day) * qty * days * (1 - discount%)
     * Block:  total = tierPrice (per day) * days * (1 - discount%)  -- qty-agnostic
     *
     * @param productId Product Id with an active schedule.
     * @param pricebookId Pricebook Id for lookup.
     * @param quantity Quantity (multiplied for Tiered, ignored for Block).
     * @param discount Discount percentage to apply.
     * @param startDate Service start date (inclusive); required.
     * @param endDate Service end date (inclusive); required.
     * @return PricingResponse with tiered or block pricing result.
     */
    public static PricingResponse calculateByVolumePricing(
        Id productId, Id pricebookId, Integer quantity, Decimal discount, Date startDate, Date endDate
    ) {
        try {
            validateDiscount(discount);
            validateQuantity(quantity);
            Integer days = validateAndComputeDays(startDate, endDate);

            Volume_Pricing_Schedule__c schedule = VolumePricingScheduleDAO.getActiveByProductAndPricebook(productId, pricebookId);

            if (schedule == null) {
                return PricingResponse.error('Volume pricing schedule not found for product');
            }

            List<Volume_Pricing_Tier__c> tiers = schedule.Volume_Pricing_Tiers__r;
            if (tiers == null || tiers.isEmpty()) {
                return PricingResponse.error('No volume pricing tiers defined');
            }

            Volume_Pricing_Tier__c matchedTier = findMatchedTier(tiers, days);

            Decimal dailyRate;
            String method;

            if (matchedTier != null) {
                dailyRate = matchedTier.Price__c.setScale(2);
            } else if (schedule.Overage_Rate__c != null) {
                dailyRate = schedule.Overage_Rate__c.setScale(2);
            } else {
                return PricingResponse.error('No matching tier for service days: ' + days);
            }

            Decimal listPrice = (dailyRate * days).setScale(2);
            Decimal netPrice = (listPrice * (1 - discount / 100)).setScale(2);
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
            response.dailyRate = dailyRate;
            response.serviceDays = days;
            response.serviceStartDate = startDate;
            response.serviceEndDate = endDate;
            return response;
        } catch (PricebookException e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    /**
     * @description Validates service dates and returns the inclusive day count.
     * @param startDate The service start date.
     * @param endDate The service end date.
     * @return Inclusive day count (end - start + 1).
     * @throws PricebookException if dates are missing or end < start.
     */
    private static Integer validateAndComputeDays(Date startDate, Date endDate) {
        if (startDate == null || endDate == null) {
            throw new PricebookException('Service Start Date and End Date are required.');
        }
        if (endDate < startDate) {
            throw new PricebookException('Service End Date must be on or after Service Start Date.');
        }
        return startDate.daysBetween(endDate) + 1;
    }

    /**
     * @description Converts an Object value to a Date.
     * @param value The value to convert (Date instance or ISO date string).
     * @return The Date value, or null on failure.
     */
    private static Date toDate(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Date) {
            return (Date) value;
        }
        try {
            return Date.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * @description Finds the matching volume pricing tier whose day-bracket
     * (Lower_Bound__c .. Upper_Bound__c) contains the given inclusive day count.
     * @param tiers List of Volume_Pricing_Tier__c records to search.
     * @param days The inclusive service day count.
     * @return The matched tier, or null if no tier matches.
     */
    private static Volume_Pricing_Tier__c findMatchedTier(List<Volume_Pricing_Tier__c> tiers, Integer days) {
        Decimal value = Decimal.valueOf(days);
        for (Volume_Pricing_Tier__c tier : tiers) {
            if (tier.Lower_Bound__c != null && value >= tier.Lower_Bound__c) {
                if (tier.Upper_Bound__c == null || value <= tier.Upper_Bound__c) {
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