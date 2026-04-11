public inherited sharing class PricebookService {
    public class PricingException extends Exception {}

    public static PricingResponse calculateSalePrice(Id productId, Id pricebookId, Integer quantity, Decimal discount) {
        try {
            validateDiscount(discount);
            validateQuantity(quantity);

            PricebookEntry entry = PricebookEntryDAO.getByProductAndPricebook(productId, pricebookId);
            if (entry == null) {
                return PricingResponse.error('Pricebook entry not found for product in sale pricebook');
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
            response.pricingMethod = 'Standard';
            return response;
        } catch (Exception e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    public static PricingResponse calculateRentalServicesPrice(Id productId, Id pricebookId, Integer quantity, Decimal discount) {
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

            Volume_Pricing_Tier__c matchedTier = null;

            for (Volume_Pricing_Tier__c tier : tiers) {
                Decimal qty = Decimal.valueOf(quantity);
                if (qty >= tier.Lower_Bound__c && qty <= tier.Upper_Bound__c) {
                    matchedTier = tier;
                    break;
                }
            }

            if (matchedTier == null) {
                return PricingResponse.error('No matching tier for quantity: ' + quantity);
            }

            Decimal listPrice;
            Decimal netPrice;
            Decimal totalPrice;
            String pricingMethod;

            String pricingType = schedule.Pricing_Type__c;
            
            if (pricingType == 'Block') {
                pricingMethod = 'Block';
                listPrice = matchedTier.Price__c.setScale(2);
                netPrice = listPrice * (1 - discount / 100);
                totalPrice = netPrice.setScale(2);
                netPrice = netPrice.setScale(2);
            } else {
                pricingMethod = 'Tiered';
                listPrice = matchedTier.Price__c.setScale(2);
                netPrice = listPrice * (1 - discount / 100);
                totalPrice = (netPrice * quantity).setScale(2);
                netPrice = netPrice.setScale(2);
            }

            PricingResponse response = new PricingResponse();
            response.productId = productId;
            response.listPrice = listPrice;
            response.netPrice = netPrice;
            response.totalPrice = totalPrice;
            response.discount = discount;
            response.quantity = quantity;
            response.pricingMethod = pricingMethod;
            return response;
        } catch (Exception e) {
            return PricingResponse.error(e.getMessage());
        }
    }

    public static List<PricingResponse> calculatePrices(List<Map<String, Object>> lineItems, String pricingType, Id pricebookId) {
        List<PricingResponse> responses = new List<PricingResponse>();

        for (Map<String, Object> item : lineItems) {
            Id productId = (Id) item.get('productId');
            Object qtyObj = item.get('quantity');
            Integer quantity;

            if (qtyObj instanceof Integer) {
                quantity = (Integer) qtyObj;
            } else if (qtyObj instanceof Decimal) {
                quantity = ((Decimal) qtyObj).intValue();
            } else if (qtyObj != null) {
                quantity = Integer.valueOf(qtyObj);
            } else {
                quantity = 1;
            }

            Object discObj = item.get('discount');
            Decimal discount;

            if (discObj instanceof Decimal) {
                discount = (Decimal) discObj;
            } else if (discObj != null) {
                discount = Decimal.valueOf(String.valueOf(discObj));
            } else {
                discount = 0;
            }

            PricingResponse response;
            if (pricingType == 'Sale') {
                response = calculateSalePrice(productId, pricebookId, quantity, discount);
            } else {
                response = calculateRentalServicesPrice(productId, pricebookId, quantity, discount);
            }
            responses.add(response);
        }

        return responses;
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