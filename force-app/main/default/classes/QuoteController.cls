/**
 * @description Visualforce controller extension for the Quote PDF page.
 * Exposes the QuotePDFData assembled by QuoteService to the VF page.
 * Uses the Quote standard controller as the primary record context.
 */
public with sharing class QuoteController {

    private final Quote quote;
    /** @description The PDF data assembled by QuoteService for the VF page. */
    public QuoteService.QuotePDFData pdfData { get; private set; }
    /** @description Whether the quote has line items. */
    public Boolean hasLineItems { get; private set; }
    /** @description Whether the quote has trips. */
    public Boolean hasTrips { get; private set; }
    /** @description Whether the quote has volume pricing. */
    public Boolean hasVolumePricing { get; private set; }
    /** @description Whether the quote has transport. */
    public Boolean hasTransport { get; private set; }
    /** @description Test hook to bypass getContentAsPDF in test context. */
    @TestVisible
    private static Blob mockPdfBlob = null;

    /**
     * @description Constructor accepting the standard controller.
     * @param controller The Quote standard controller.
     */
    public QuoteController(ApexPages.StandardController controller) {
        this.quote = (Quote) controller.getRecord();
        loadData();
    }

    /**
     * @description Loads all data needed for the PDF via QuoteService.
     */
    private void loadData() {
        try {
            pdfData = QuoteService.buildQuotePDFData(quote.Id);
            hasLineItems = pdfData.lineItems != null && !pdfData.lineItems.isEmpty();
            hasTrips = pdfData.trips != null && !pdfData.trips.isEmpty();
            hasVolumePricing = pdfData.hasVolumePricing;
            hasTransport = pdfData.hasTransport;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'QuoteController failed: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Failed to generate quote PDF: ' + e.getMessage()
            ));
        }
    }

    /**
     * @description Formats a Decimal value as a currency string for display.
     * @param value The Decimal value to format.
     * @return Formatted currency string like "$1,234.56".
     */
    public String formatCurrency(Decimal value) {
        if (value == null) {
            return '$0.00';
        }
        return '$' + value.setScale(2).format();
    }

    /**
     * @description Formats a Decimal as a percentage string for display.
     * @param value The Decimal value to format.
     * @return Formatted percentage string like "10.00%".
     */
    public String formatPercent(Decimal value) {
        if (value == null) {
            return '0%';
        }
        return value.stripTrailingZeros().format() + '%';
    }

    /**
     * @description Formats a Date for display, returning '—' if null.
     * @param d The Date to format.
     * @return Formatted date string or '—'.
     */
    public String formatDate(Date d) {
        if (d == null) {
            return '—';
        }
        return d.format();
    }

    /**
     * @description Formats a tier range string like "0 - 300" or "300+".
     * @param lower The lower bound.
     * @param upper The upper bound (null means unlimited).
     * @return Formatted range string.
     */
    public String formatTierRange(Decimal lower, Decimal upper) {
        String lowerStr = lower != null ? lower.setScale(0).format() : '0';
        if (upper == null) {
            return lowerStr + '+';
        }
        return lowerStr + ' - ' + upper.setScale(0).format();
    }

    /**
     * @description Gets the Quote Number for the header.
     * @return The quote number string.
     */
    public String getQuoteNumber() {
        return pdfData?.quote?.QuoteNumber;
    }

    /**
     * @description Gets the formatted expiration date.
     * @return The formatted expiration date string.
     */
    public String getExpirationDateFormatted() {
        if (pdfData?.quote?.ExpirationDate == null) {
            return '—';
        }
        return pdfData.quote.ExpirationDate.format();
    }

    /**
     * @description Gets the Account Name.
     * @return The account name string.
     */
    public String getAccountName() {
        return pdfData?.quote?.Account?.Name;
    }

    /**
     * @description Gets the Contact Name.
     * @return The contact name string.
     */
    public String getContactName() {
        return pdfData?.quote?.Contact?.Name;
    }

    /**
     * @description Gets the Contact Email.
     * @return The contact email string.
     */
    public String getContactEmail() {
        return pdfData?.quote?.Contact?.Email;
    }

    /**
     * @description Gets the Contact Phone.
     * @return The contact phone string.
     */
    public String getContactPhone() {
        return pdfData?.quote?.Contact?.Phone;
    }

    /**
     * @description Gets the Account Phone.
     * @return The account phone string.
     */
    public String getAccountPhone() {
        return pdfData?.quote?.Account?.Phone;
    }

    /**
     * @description Gets formatted line items subtotal.
     * @return The formatted subtotal string.
     */
    public String getLineItemsSubtotal() {
        return formatCurrency(pdfData?.lineItemsSubtotal);
    }

    /**
     * @description Gets formatted transport total.
     * @return The formatted transport total string.
     */
    public String getTransportTotal() {
        return formatCurrency(pdfData?.transportTotal);
    }

    /**
     * @description Gets formatted grand total.
     * @return The formatted grand total string.
     */
    public String getGrandTotal() {
        return formatCurrency(pdfData?.grandTotal);
    }

    /**
     * @description Returns whether the transport section should be displayed.
     * @return True if transport section should be shown.
     */
    public Boolean getShowTransportSection() {
        return hasTransport && hasTrips;
    }

    // ── @AuraEnabled methods for the Quote PDF Preview LWC Quick Action ──

    /**
     * @description Generates the PDF and saves it as a QuoteDocument on the Quote.
     * Callout (getContentAsPDF) runs before DML (insert), so synchronous is safe.
     * The QuoteDocument Name is auto-generated by Salesforce (includes version).
     * @param quoteId The ID of the Quote to save the PDF for.
     * @return The auto-generated name of the created QuoteDocument.
     */
    @AuraEnabled
    public static String savePDF(String quoteId) {
        if (quoteId == null) {
            throw new QuoteException('Quote ID is required.');
        }

        if ([SELECT COUNT() FROM Quote WHERE Id = :quoteId] == 0) {
            throw new QuoteException('Quote not found.');
        }

        PageReference pdfPage = Page.QuotePDF;
        pdfPage.getParameters().put('id', quoteId);
        Blob pdfBlob = mockPdfBlob != null ? mockPdfBlob : pdfPage.getContentAsPDF();

        QuoteDocument qd = new QuoteDocument();
        qd.QuoteId = quoteId;
        qd.Document = pdfBlob;
        insert qd;

        QuoteDocument inserted = [
            SELECT Name FROM QuoteDocument WHERE Id = :qd.Id
        ];
        return inserted.Name;
    }
}