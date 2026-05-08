/**
 * @description Response wrapper for pricing calculations.
 */
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
    @AuraEnabled public Decimal dailyRate;
    @AuraEnabled public Integer serviceDays;
    @AuraEnabled public Date serviceStartDate;
    @AuraEnabled public Date serviceEndDate;

    /**
     * @description Creates a successful pricing response with default values.
     */
    public PricingResponse() {
        this.success = true;
        this.pricingMethod = 'Standard';
    }

    /**
     * @description Creates a pricing response with the provided success state and error message.
     * @param success Whether the calculation succeeded.
     * @param errorMessage Error message, when applicable.
     */
    public PricingResponse(Boolean success, String errorMessage) {
        this.success = success;
        this.errorMessage = errorMessage;
    }

    /**
     * @description Builds a failed pricing response.
     * @param message Error message to expose.
     * @return Failed PricingResponse instance.
     */
    public static PricingResponse error(String message) {
        return new PricingResponse(false, message);
    }
}