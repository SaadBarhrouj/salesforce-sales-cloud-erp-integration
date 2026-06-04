// Bulk, diverse demo data for the Sales Reports + Sales Performance dashboard.
// Uses weighted randomization for realistic distributions. Additive & re-runnable.

Integer stamp = Math.mod(Datetime.now().getTime(), 1000000).intValue();
Integer OPP_COUNT = 72;
Integer QUOTE_COUNT = 40;

// ── Accounts ──────────────────────────────────────────────
List<Account> accts = new List<Account>();
for (Integer i = 1; i <= 10; i++) { accts.add(new Account(Name = 'Demo Account ' + stamp + '-' + i)); }
insert accts;

// ── Locations (Warehouse agencies + delivery Sites) ───────
List<String> ccVals = new List<String>();
for (Schema.PicklistEntry pe : Schema.Location.Country_Code__c.getDescribe().getPicklistValues()) {
    if (pe.isActive()) { ccVals.add(pe.getValue()); }
}
String cc = ccVals.isEmpty() ? 'MA' : ccVals[0];
List<Schema.Location> agencies = new List<Schema.Location>();
for (Integer i = 1; i <= 3; i++) {
    agencies.add(new Schema.Location(Name = 'Demo Agency ' + stamp + '-' + i, Country_Code__c = cc, LocationType = 'Warehouse'));
}
insert agencies;
List<Schema.Location> sites = new List<Schema.Location>();
for (Integer i = 1; i <= 4; i++) {
    sites.add(new Schema.Location(Name = 'Demo Site ' + stamp + '-' + i, Country_Code__c = cc, LocationType = 'Site'));
}
insert sites;

// ── Product Catalogs drive Offer Type (REUSE existing only — never create) ──
List<ProductCatalog> catalogs = [SELECT Id FROM ProductCatalog ORDER BY Name LIMIT 50];
if (catalogs.isEmpty()) {
    throw new System.IllegalArgumentException('No ProductCatalog (offer types) exist to assign. Create offer types in the app, not in a seed script.');
}

// ── Pricebook + products + entries (for quote line items) ──
Pricebook2 stdPb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
if (!stdPb.IsActive) { stdPb.IsActive = true; update stdPb; }
List<Product2> prods = new List<Product2>();
for (Integer i = 1; i <= 4; i++) { prods.add(new Product2(Name = 'Demo Product ' + stamp + '-' + i, ProductCode = 'DEMO-' + stamp + '-' + i, IsActive = true)); }
insert prods;
List<PricebookEntry> pbes = new List<PricebookEntry>();
for (Integer i = 0; i < prods.size(); i++) {
    pbes.add(new PricebookEntry(Pricebook2Id = stdPb.Id, Product2Id = prods[i].Id, UnitPrice = 500 + (i * 750), IsActive = true));
}
insert pbes;

// ── Runtime picklist + stage values ───────────────────────
List<String> urgVals = new List<String>();
for (Schema.PicklistEntry pe : Opportunity.Transport_Urgency__c.getDescribe().getPicklistValues()) {
    if (pe.isActive()) { urgVals.add(pe.getValue()); }
}
List<String> openStages = new List<String>();
String wonStage, lostStage;
for (OpportunityStage s : [SELECT MasterLabel, IsWon, IsClosed FROM OpportunityStage WHERE IsActive = true ORDER BY SortOrder]) {
    if (s.IsClosed && s.IsWon) { if (wonStage == null) { wonStage = s.MasterLabel; } }
    else if (s.IsClosed && !s.IsWon) { if (lostStage == null) { lostStage = s.MasterLabel; } }
    else { openStages.add(s.MasterLabel); }
}
if (openStages.isEmpty()) { openStages.add('Prospecting'); }

// Weighted stage bag (open-heavy pipeline, some won/lost)
List<String> stageBag = new List<String>();
for (String st : openStages) { for (Integer k = 0; k < 3; k++) { stageBag.add(st); } }
if (wonStage != null) { for (Integer k = 0; k < 4; k++) { stageBag.add(wonStage); } }
if (lostStage != null) { for (Integer k = 0; k < 2; k++) { stageBag.add(lostStage); } }

// ── Opportunities ─────────────────────────────────────────
List<Opportunity> opps = new List<Opportunity>();
for (Integer i = 0; i < OPP_COUNT; i++) {
    String stage = stageBag[(Integer)(Math.random() * stageBag.size())];
    Double r = Math.random();
    Integer amt = (Integer)(2000 + (r * r) * 248000);
    amt = (amt / 500) * 500;
    Boolean transp = Math.random() < 0.4;
    Opportunity o = new Opportunity(
        Name = 'Demo Opp ' + stamp + '-' + (i + 1),
        AccountId = accts[(Integer)(Math.random() * accts.size())].Id,
        StageName = stage,
        CloseDate = Date.today().addDays((Integer)(Math.random() * 390) - 90),
        Amount = amt,
        Pricebook2Id = stdPb.Id,
        Offer_Type__c = catalogs[(Integer)(Math.random() * catalogs.size())].Id,
        Is_Transport_Required__c = transp
    );
    if (transp) {
        o.Default_Agency__c = agencies[(Integer)(Math.random() * agencies.size())].Id;
        o.Delivery_Site__c = sites[(Integer)(Math.random() * sites.size())].Id;
        if (!urgVals.isEmpty()) { o.Transport_Urgency__c = urgVals[(Integer)(Math.random() * urgVals.size())]; }
    }
    opps.add(o);
}
insert opps;

// ── Quotes following a realistic funnel ───────────────────
List<String> statusBag = new List<String>();
Map<String, Integer> statusWeights = new Map<String, Integer>{
    'Draft' => 6, 'Needs Review' => 3, 'In Review' => 3, 'Approved' => 4,
    'Presented' => 6, 'Accepted' => 4, 'Rejected' => 3, 'Denied' => 4
};
for (String st : statusWeights.keySet()) { for (Integer k = 0; k < statusWeights.get(st); k++) { statusBag.add(st); } }

List<Quote> quotes = new List<Quote>();
for (Integer i = 0; i < QUOTE_COUNT; i++) {
    quotes.add(new Quote(
        Name = 'Demo Quote ' + stamp + '-' + (i + 1),
        OpportunityId = opps[(Integer)(Math.random() * opps.size())].Id,
        Pricebook2Id = stdPb.Id,
        Status = statusBag[(Integer)(Math.random() * statusBag.size())],
        ExpirationDate = Date.today().addDays(5 + (Integer)(Math.random() * 40))
    ));
}
insert quotes;

// ── Quote line items (1-3 per quote, varied product/qty/discount) ──
List<Decimal> discountChoices = new List<Decimal>{ 0, 0, 5, 10, 15, 20 };
List<QuoteLineItem> qlis = new List<QuoteLineItem>();
for (Quote q : quotes) {
    Integer lines = 1 + (Integer)(Math.random() * 3);
    for (Integer L = 0; L < lines; L++) {
        PricebookEntry pbe = pbes[(Integer)(Math.random() * pbes.size())];
        qlis.add(new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1 + (Integer)(Math.random() * 10),
            UnitPrice = (pbe.UnitPrice * (0.9 + Math.random() * 0.3)).setScale(2),
            Discount = discountChoices[(Integer)(Math.random() * discountChoices.size())]
        ));
    }
}
insert qlis;

System.debug(LoggingLevel.ERROR, 'BULK SEEDED => Accounts=' + accts.size()
    + ' Opportunities=' + opps.size()
    + ' Quotes=' + quotes.size()
    + ' QuoteLineItems=' + qlis.size());
