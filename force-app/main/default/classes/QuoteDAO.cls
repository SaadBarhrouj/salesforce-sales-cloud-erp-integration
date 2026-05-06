/**
 * @description Data access layer for Quote and QuoteLineItem records.
 * Provides SOQL queries for Quote PDF data assembly.
 * Reuses existing DAOs for related object queries.
 */
public inherited sharing class QuoteDAO {

    /**
     * @description Retrieves a Quote with its related Account, Contact, and Opportunity.
     * @param quoteId The Quote ID.
     * @return Quote record with parent relationships populated.
     */
    public static Quote getQuoteWithRelations(Id quoteId) {
        if (quoteId == null) {
            return null;
        }
        List<Quote> quotes = [
            SELECT Id, QuoteNumber, Name, ExpirationDate,
                   AccountId, Account.Name, Account.Phone,
                   ContactId, Contact.Name, Contact.Email, Contact.Phone,
                   OpportunityId, Opportunity.Is_Transport_Required__c,
                   Opportunity.Total_Transport_Cost__c,
                   Opportunity.Transport_Urgency__c,
                   Opportunity.Delivery_Site__c, Opportunity.Delivery_Site__r.Name,
                   Opportunity.Default_Agency__c, Opportunity.Default_Agency__r.Name,
                   Opportunity.Pricebook2Id
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
        return quotes.isEmpty() ? null : quotes[0];
    }

    /**
     * @description Retrieves all QuoteLineItems for a Quote with Product2 name
     * and the related OpportunityLineItem rental date fields.
     * @param quoteId The Quote ID.
     * @return List of QuoteLineItem records.
     */
    public static List<QuoteLineItem> getLineItemsByQuoteId(Id quoteId) {
        if (quoteId == null) {
            return new List<QuoteLineItem>();
        }
        return [
            SELECT Id, QuoteId, Product2Id, Product2.Name, Product2.Family,
                   Quantity, UnitPrice, ListPrice, Discount, TotalPrice,
                   LineNumber, Description, Is_Bundle__c,
                   OpportunityLineItemId,
                   OpportunityLineItem.Rental_Start_Date__c,
                   OpportunityLineItem.Rental_End_Date__c
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
            ORDER BY LineNumber ASC, Id ASC
        ];
    }
}