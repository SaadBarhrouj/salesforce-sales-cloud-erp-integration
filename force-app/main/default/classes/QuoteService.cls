/**
 * @description Service layer for Quote PDF data assembly.
 * Queries all data needed for the quote PDF and returns it as structured wrapper objects.
 */
public inherited sharing class QuoteService {

    /** Wrapper holding all data required to render the Quote PDF. */
    public class QuotePDFData {
        /** @description The Quote record with related Account, Contact, and Opportunity. */
        public Quote quote { get; set; }
        /** @description The list of line item rows for the PDF. */
        public List<LineItemRow> lineItems { get; set; }
        /** @description The subtotal of all line items. */
        public Decimal lineItemsSubtotal { get; set; }
        /** @description The list of trip rows for transport costs. */
        public List<TripRow> trips { get; set; }
        /** @description The total transport cost. */
        public Decimal transportTotal { get; set; }
        /** @description The grand total (line items + transport). */
        public Decimal grandTotal { get; set; }
        /** @description Whether transport is required for this quote. */
        public Boolean hasTransport { get; set; }
        /** @description Whether any line item has volume pricing. */
        public Boolean hasVolumePricing { get; set; }
    }

    /** Wrapper representing a single line item row in the PDF. */
    public class LineItemRow {
        /** @description The line number on the quote. */
        public Integer lineNumber { get; set; }
        /** @description The product name. */
        public String productName { get; set; }
        /** @description The product family. */
        public String productFamily { get; set; }
        /** @description The quantity ordered. */
        public Decimal quantity { get; set; }
        /** @description The unit price. */
        public Decimal unitPrice { get; set; }
        /** @description The discount percentage. */
        public Decimal discount { get; set; }
        /** @description The total price for this line. */
        public Decimal totalPrice { get; set; }
        /** @description Whether this item is a bundle. */
        public Boolean isBundle { get; set; }
        /** @description The rental start date. */
        public Date rentalStartDate { get; set; }
        /** @description The rental end date. */
        public Date rentalEndDate { get; set; }
        /** @description The Product2 ID. */
        public Id product2Id { get; set; }
        /** @description The volume pricing tiers for this product. */
        public List<VolumePricingRow> volumePricingTiers { get; set; }
    }

    /** Wrapper representing a volume pricing schedule row. */
    public class VolumePricingRow {
        /** @description The product name. */
        public String productName { get; set; }
        /** @description The pricing type (e.g. Tiered, Flat). */
        public String pricingType { get; set; }
        /** @description The overage rate. */
        public Decimal overageRate { get; set; }
        /** @description The list of pricing tiers. */
        public List<VolumePricingTierRow> tiers { get; set; }
    }

    /** Wrapper representing a single volume pricing tier. */
    public class VolumePricingTierRow {
        /** @description The lower bound quantity. */
        public Decimal lowerBound { get; set; }
        /** @description The upper bound quantity. */
        public Decimal upperBound { get; set; }
        /** @description The price for this tier. */
        public Decimal price { get; set; }
    }

    /** Wrapper representing a trip row for transport costs. */
    public class TripRow {
        /** @description The trip direction. */
        public String direction { get; set; }
        /** @description The distance in kilometers. */
        public Decimal distanceKm { get; set; }
        /** @description The total weight in kilograms. */
        public Decimal totalWeightKg { get; set; }
        /** @description The truck type. */
        public String truckType { get; set; }
        /** @description The final price for this trip. */
        public Decimal finalPrice { get; set; }
    }

    /**
     * @description Builds all data required for the Quote PDF.
     * @param quoteId The ID of the Quote to build data for.
     * @return QuotePDFData containing all PDF rendering data.
     */
    public static QuotePDFData buildQuotePDFData(Id quoteId) {
        if (quoteId == null) {
            throw new QuoteException('Quote ID is required.');
        }

        Quote quote = QuoteDAO.getQuoteWithRelations(quoteId);
        if (quote == null) {
            throw new QuoteException('Quote not found.');
        }

        QuotePDFData data = new QuotePDFData();
        data.quote = quote;

        List<QuoteLineItem> qlis = QuoteDAO.getLineItemsByQuoteId(quoteId);

        Set<Id> productIds = new Set<Id>();
        for (QuoteLineItem qli : qlis) {
            productIds.add(qli.Product2Id);
        }

        Id pricebookId = quote.Opportunity != null
            ? quote.Opportunity.Pricebook2Id : null;

        Map<Id, Volume_Pricing_Schedule__c> scheduleByProduct = new Map<Id, Volume_Pricing_Schedule__c>();
        for (Volume_Pricing_Schedule__c schedule : [
            SELECT Id, Product__c, Pricing_Type__c, Overage_Rate__c,
                (SELECT Id, Lower_Bound__c, Upper_Bound__c, Price__c, Sort_Order__c
                 FROM Volume_Pricing_Tiers__r
                 ORDER BY Sort_Order__c ASC)
            FROM Volume_Pricing_Schedule__c
            WHERE Product__c IN :productIds
            AND Is_Active__c = true
            AND (Pricebook__c = :pricebookId OR Pricebook__c = null)
            ORDER BY Pricebook__c DESC NULLS LAST
        ]) {
            if (!scheduleByProduct.containsKey(schedule.Product__c)) {
                scheduleByProduct.put(schedule.Product__c, schedule);
            }
        }

        List<LineItemRow> rows = new List<LineItemRow>();
        Decimal subtotal = 0;
        Boolean hasAnyVolumePricing = false;

        for (QuoteLineItem qli : qlis) {
            LineItemRow row = new LineItemRow();
            row.lineNumber = qli.LineNumber != null ? Integer.valueOf(qli.LineNumber) : null;
            row.productName = qli.Product2.Name;
            row.productFamily = qli.Product2.Family;
            row.quantity = qli.Quantity;
            row.unitPrice = qli.UnitPrice;
            row.discount = qli.Discount;
            row.totalPrice = qli.TotalPrice;
            row.isBundle = qli.Is_Bundle__c;
            row.product2Id = qli.Product2Id;
            row.rentalStartDate = qli.OpportunityLineItem != null
                ? qli.OpportunityLineItem.Rental_Start_Date__c : null;
            row.rentalEndDate = qli.OpportunityLineItem != null
                ? qli.OpportunityLineItem.Rental_End_Date__c : null;

            if (row.totalPrice != null) {
                subtotal += row.totalPrice;
            }

            Volume_Pricing_Schedule__c schedule = scheduleByProduct.get(qli.Product2Id);

            if (schedule != null) {
                hasAnyVolumePricing = true;
                VolumePricingRow vpRow = new VolumePricingRow();
                vpRow.productName = qli.Product2.Name;
                vpRow.pricingType = schedule.Pricing_Type__c;
                vpRow.overageRate = schedule.Overage_Rate__c;
                vpRow.tiers = new List<VolumePricingTierRow>();

                if (schedule.Volume_Pricing_Tiers__r != null) {
                    for (Volume_Pricing_Tier__c tier : schedule.Volume_Pricing_Tiers__r) {
                        VolumePricingTierRow tierRow = new VolumePricingTierRow();
                        tierRow.lowerBound = tier.Lower_Bound__c;
                        tierRow.upperBound = tier.Upper_Bound__c;
                        tierRow.price = tier.Price__c;
                        vpRow.tiers.add(tierRow);
                    }
                }
                row.volumePricingTiers = new List<VolumePricingRow>{ vpRow };
            }

            rows.add(row);
        }

        data.lineItems = rows;
        data.lineItemsSubtotal = subtotal;
        data.hasVolumePricing = hasAnyVolumePricing;

        data.hasTransport = quote.Opportunity != null
            && quote.Opportunity.Is_Transport_Required__c == true;

        if (data.hasTransport) {
            Id oppId = quote.OpportunityId;
            List<Trip__c> allTrips = TripDAO.getTripsByOpportunity(oppId);
            List<TripRow> tripRows = new List<TripRow>();
            Decimal transportTotal = 0;

            for (Trip__c trip : allTrips) {
                if (trip.Status__c == 'Cancelled') {
                    continue;
                }
                TripRow tripRow = new TripRow();
                tripRow.direction = trip.Direction__c;
                tripRow.distanceKm = trip.Distance_Km__c;
                tripRow.totalWeightKg = trip.Total_Weight_Kg__c;
                tripRow.truckType = trip.Truck_Type__c;
                tripRow.finalPrice = trip.Final_Price__c != null ? trip.Final_Price__c : 0;
                tripRows.add(tripRow);

                if (trip.Final_Price__c != null) {
                    transportTotal += trip.Final_Price__c;
                }
            }

            data.trips = tripRows;
            data.transportTotal = transportTotal;
        } else {
            data.trips = new List<TripRow>();
            data.transportTotal = 0;
        }

        data.grandTotal = data.lineItemsSubtotal + data.transportTotal;

        return data;
    }
}