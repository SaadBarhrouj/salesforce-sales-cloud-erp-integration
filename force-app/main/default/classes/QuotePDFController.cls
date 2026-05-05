/**
 * @description Visualforce controller extension for the Quote PDF page.
 * Exposes the QuotePDFData assembled by QuoteService to the VF page.
 * Uses the Quote standard controller as the primary record context.
 */
public with sharing class QuotePDFController {

    private final Quote quote;
    public QuoteService.QuotePDFData pdfData { get; private set; }
    public Boolean hasLineItems { get; private set; }
    public Boolean hasTrips { get; private set; }
    public Boolean hasVolumePricing { get; private set; }
    public Boolean hasTransport { get; private set; }

    /**
     * @description Constructor accepting the standard controller.
     * @param controller The Quote standard controller.
     */
    public QuotePDFController(ApexPages.StandardController controller) {
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
            System.debug(LoggingLevel.ERROR, 'QuotePDFController failed: ' + e.getMessage());
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
     */
    public String getQuoteNumber() {
        return pdfData?.quote?.QuoteNumber;
    }

    /**
     * @description Gets the formatted expiration date.
     */
    public String getExpirationDateFormatted() {
        if (pdfData?.quote?.ExpirationDate == null) {
            return '—';
        }
        return pdfData.quote.ExpirationDate.format();
    }

    /**
     * @description Gets the Account Name.
     */
    public String getAccountName() {
        return pdfData?.quote?.Account?.Name;
    }

    /**
     * @description Gets the Contact Name.
     */
    public String getContactName() {
        return pdfData?.quote?.Contact?.Name;
    }

    /**
     * @description Gets the Contact Email.
     */
    public String getContactEmail() {
        return pdfData?.quote?.Contact?.Email;
    }

    /**
     * @description Gets the Contact Phone.
     */
    public String getContactPhone() {
        return pdfData?.quote?.Contact?.Phone;
    }

    /**
     * @description Gets the Account Phone.
     */
    public String getAccountPhone() {
        return pdfData?.quote?.Account?.Phone;
    }

    /**
     * @description Gets formatted line items subtotal.
     */
    public String getLineItemsSubtotal() {
        return formatCurrency(pdfData?.lineItemsSubtotal);
    }

    /**
     * @description Gets formatted transport total.
     */
    public String getTransportTotal() {
        return formatCurrency(pdfData?.transportTotal);
    }

    /**
     * @description Gets formatted grand total.
     */
    public String getGrandTotal() {
        return formatCurrency(pdfData?.grandTotal);
    }

    /**
     * @description Returns whether the transport section should be displayed.
     */
    public Boolean getShowTransportSection() {
        return hasTransport && hasTrips;
    }
}