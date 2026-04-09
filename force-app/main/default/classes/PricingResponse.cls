public class PricingResponse {
    @AuraEnabled public Boolean success;
    @AuraEnabled public String errorMessage;
    @AuraEnabled public String productId;
    @AuraEnabled public Decimal listPrice;
    @AuraEnabled public Decimal netPrice;
    @AuraEnabled public Decimal totalPrice;
    @AuraEnabled public Decimal discount;
    @AuraEnabled public Integer quantity;
    @AuraEnabled public String pricingMethod;

    public PricingResponse() {
        this.success = true;
        this.pricingMethod = 'Standard';
    }

    public PricingResponse(Boolean success, String errorMessage) {
        this.success = success;
        this.errorMessage = errorMessage;
    }

    public static PricingResponse error(String message) {
        return new PricingResponse(false, message);
    }
}