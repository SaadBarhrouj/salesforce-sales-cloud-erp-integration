// Seeds demo data so the Sales Reports folder + Sales Performance dashboard populate.
// Safe to run multiple times (records are timestamp-suffixed).

Integer stamp = Math.mod(Datetime.now().getTime(), 1000000).intValue();

// 1) Accounts
List<Account> accts = new List<Account>();
for (Integer i = 1; i <= 5; i++) {
    accts.add(new Account(Name = 'Demo Account ' + stamp + '-' + i));
}
insert accts;

// 1b) Locations to satisfy "Default Agency required when transport required" validation
List<String> ccVals = new List<String>();
for (Schema.PicklistEntry pe : Schema.Location.Country_Code__c.getDescribe().getPicklistValues()) {
    if (pe.isActive()) { ccVals.add(pe.getValue()); }
}
String cc = ccVals.isEmpty() ? 'MA' : ccVals[0];
List<Schema.Location> agencies = new List<Schema.Location>{
    new Schema.Location(Name = 'Demo Agency ' + stamp + '-1', Country_Code__c = cc, LocationType = 'Warehouse'),
    new Schema.Location(Name = 'Demo Agency ' + stamp + '-2', Country_Code__c = cc, LocationType = 'Warehouse')
};
insert agencies;
List<Schema.Location> sites = new List<Schema.Location>{
    new Schema.Location(Name = 'Demo Site ' + stamp + '-1', Country_Code__c = cc, LocationType = 'Site'),
    new Schema.Location(Name = 'Demo Site ' + stamp + '-2', Country_Code__c = cc, LocationType = 'Site')
};
insert sites;

// 2) Product Catalogs drive Opportunity.Offer_Type__c (REUSE existing only — never create)
List<ProductCatalog> catalogs = [SELECT Id, Name FROM ProductCatalog ORDER BY Name LIMIT 50];
if (catalogs.isEmpty()) {
    throw new System.IllegalArgumentException('No ProductCatalog (offer types) exist to assign. Create offer types in the app, not in a seed script.');
}

// 3) Standard pricebook + two products with entries (needed for Quote line items)
Pricebook2 stdPb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
if (!stdPb.IsActive) { stdPb.IsActive = true; update stdPb; }

List<Product2> prods = new List<Product2>{
    new Product2(Name = 'Demo Product A ' + stamp, ProductCode = 'DEMOA-' + stamp, IsActive = true),
    new Product2(Name = 'Demo Product B ' + stamp, ProductCode = 'DEMOB-' + stamp, IsActive = true)
};
insert prods;

List<PricebookEntry> pbes = new List<PricebookEntry>{
    new PricebookEntry(Pricebook2Id = stdPb.Id, Product2Id = prods[0].Id, UnitPrice = 1000, IsActive = true),
    new PricebookEntry(Pricebook2Id = stdPb.Id, Product2Id = prods[1].Id, UnitPrice = 1500, IsActive = true)
};
insert pbes;

// 4) Read org picklist + stage values at runtime (robust against org config)
List<String> urgVals = new List<String>();
for (Schema.PicklistEntry pe : Opportunity.Transport_Urgency__c.getDescribe().getPicklistValues()) {
    if (pe.isActive()) urgVals.add(pe.getValue());
}

List<String> openStages = new List<String>();
String wonStage, lostStage;
for (OpportunityStage s : [SELECT MasterLabel, IsWon, IsClosed FROM OpportunityStage WHERE IsActive = true ORDER BY SortOrder]) {
    if (s.IsClosed && s.IsWon && wonStage == null) { wonStage = s.MasterLabel; }
    else if (s.IsClosed && !s.IsWon && lostStage == null) { lostStage = s.MasterLabel; }
    else if (!s.IsClosed) { openStages.add(s.MasterLabel); }
}
if (openStages.isEmpty()) { openStages.add('Prospecting'); }

// 5) Opportunities spread across stages / months / offer types / transport flags
List<Opportunity> opps = new List<Opportunity>();
Integer total = 24;
for (Integer i = 0; i < total; i++) {
    Integer bucket = Math.mod(i, 6);
    String stage;
    if (bucket < 4) { stage = openStages[Math.mod(i, openStages.size())]; }
    else if (bucket == 4) { stage = wonStage != null ? wonStage : openStages[0]; }
    else { stage = lostStage != null ? lostStage : openStages[0]; }

    Boolean transp = Math.mod(i, 2) == 0;
    Opportunity o = new Opportunity(
        Name = 'Demo Opp ' + stamp + '-' + (i + 1),
        AccountId = accts[Math.mod(i, accts.size())].Id,
        StageName = stage,
        CloseDate = Date.today().addMonths(Math.mod(i, 7) - 2).addDays(Math.mod(i * 3, 25)),
        Amount = 5000 + (i * 3500),
        Pricebook2Id = stdPb.Id,
        Offer_Type__c = catalogs[Math.mod(i, catalogs.size())].Id,
        Is_Transport_Required__c = transp
    );
    if (transp) {
        o.Default_Agency__c = agencies[Math.mod(i, agencies.size())].Id;
        o.Delivery_Site__c = sites[Math.mod(i, sites.size())].Id;
        if (!urgVals.isEmpty()) {
            o.Transport_Urgency__c = urgVals[Math.mod(i, urgVals.size())];
        }
    }
    opps.add(o);
}
insert opps;

// 6) Quotes (with line items) across every Status value
List<String> statuses = new List<String>{
    'Draft', 'Needs Review', 'In Review', 'Approved', 'Rejected', 'Presented', 'Accepted', 'Denied'
};
List<Quote> quotes = new List<Quote>();
for (Integer i = 0; i < statuses.size(); i++) {
    quotes.add(new Quote(
        Name = 'Demo Quote ' + stamp + '-' + (i + 1),
        OpportunityId = opps[i].Id,
        Pricebook2Id = stdPb.Id,
        Status = statuses[i],
        ExpirationDate = Date.today().addDays(10 + i)
    ));
}
insert quotes;

List<QuoteLineItem> qlis = new List<QuoteLineItem>();
for (Integer i = 0; i < quotes.size(); i++) {
    qlis.add(new QuoteLineItem(
        QuoteId = quotes[i].Id,
        PricebookEntryId = pbes[0].Id,
        Quantity = 1 + Math.mod(i, 5),
        UnitPrice = 1000 + (i * 100),
        Discount = Math.mod(i, 3) == 0 ? 10 : 0
    ));
    if (Math.mod(i, 2) == 0) {
        qlis.add(new QuoteLineItem(
            QuoteId = quotes[i].Id,
            PricebookEntryId = pbes[1].Id,
            Quantity = 2,
            UnitPrice = 1500
        ));
    }
}
insert qlis;

System.debug(LoggingLevel.ERROR, 'SEEDED => Accounts=' + accts.size()
    + ' Opportunities=' + opps.size()
    + ' Quotes=' + quotes.size()
    + ' QuoteLineItems=' + qlis.size());
