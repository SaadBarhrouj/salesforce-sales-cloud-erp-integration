/**
 * @description Service layer for Quote PDF data assembly.
 * Queries all data needed for the quote PDF and returns it as structured wrapper objects.
 */
public inherited sharing class QuoteService {

    public class QuotePDFData {
        public Quote quote { get; set; }
        public List<LineItemRow> lineItems { get; set; }
        public Decimal lineItemsSubtotal { get; set; }
        public List<TripRow> trips { get; set; }
        public Decimal transportTotal { get; set; }
        public Decimal grandTotal { get; set; }
        public Boolean hasTransport { get; set; }
        public Boolean hasVolumePricing { get; set; }
    }

    public class LineItemRow {
        public Integer lineNumber { get; set; }
        public String productName { get; set; }
        public String productFamily { get; set; }
        public Decimal quantity { get; set; }
        public Decimal unitPrice { get; set; }
        public Decimal discount { get; set; }
        public Decimal totalPrice { get; set; }
        public Boolean isBundle { get; set; }
        public Date rentalStartDate { get; set; }
        public Date rentalEndDate { get; set; }
        public Id product2Id { get; set; }
        public List<VolumePricingRow> volumePricingTiers { get; set; }
    }

    public class VolumePricingRow {
        public String productName { get; set; }
        public String pricingType { get; set; }
        public Decimal overageRate { get; set; }
        public List<VolumePricingTierRow> tiers { get; set; }
    }

    public class VolumePricingTierRow {
        public Decimal lowerBound { get; set; }
        public Decimal upperBound { get; set; }
        public Decimal price { get; set; }
    }

    public class TripRow {
        public String direction { get; set; }
        public Decimal distanceKm { get; set; }
        public Decimal totalWeightKg { get; set; }
        public String truckType { get; set; }
        public Decimal finalPrice { get; set; }
    }

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

        Map<Id, Product2> productMap = Product2DAO.getByIds(productIds);

        Id pricebookId = quote.Opportunity != null
            ? quote.Opportunity.Pricebook2Id : null;

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

            List<Volume_Pricing_Schedule__c> schedules = [
                SELECT Id, Product__c, Pricing_Type__c, Overage_Rate__c,
                    (SELECT Id, Lower_Bound__c, Upper_Bound__c, Price__c, Sort_Order__c
                     FROM Volume_Pricing_Tiers__r
                     ORDER BY Sort_Order__c ASC)
                FROM Volume_Pricing_Schedule__c
                WHERE Product__c = :qli.Product2Id
                AND Is_Active__c = true
                AND (Pricebook__c = :pricebookId OR Pricebook__c = null)
                ORDER BY Pricebook__c DESC NULLS LAST
                LIMIT 1
            ];

            if (!schedules.isEmpty()) {
                hasAnyVolumePricing = true;
                Volume_Pricing_Schedule__c schedule = schedules[0];
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