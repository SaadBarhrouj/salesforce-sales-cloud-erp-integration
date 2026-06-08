// Populate Product2 bin-packing dimensions on existing UAT products, keyed by ProductCode.
// Values are taken verbatim from scripts/apex/seed_demo_data.apex (no fabricated data).
Map<String, List<Decimal>> dimsByCode = new Map<String, List<Decimal>>{
    // ProductCode => { Width_cm__c, Height_cm__c, Depth_cm__c, Unit_Weight_Kg__c }
    '079-0025' => new List<Decimal>{ 180, 200, 450, 1800 },
    '079-0030' => new List<Decimal>{ 200, 250, 600, 2500 },
    '079-0035' => new List<Decimal>{ 210, 260, 650, 2800 },
    '079-8041' => new List<Decimal>{ 220, 280, 700, 3500 },
    '079-0041' => new List<Decimal>{ 220, 280, 700, 3500 },
    '052-5021' => new List<Decimal>{ 220, 200, 500, 4500 },
    '052-5024' => new List<Decimal>{ 230, 210, 550, 5500 },
    '052-5033' => new List<Decimal>{ 240, 220, 700, 7500 },
    '057-5001' => new List<Decimal>{ 90,  220, 250, 1100 },
    '057-5004' => new List<Decimal>{ 140, 240, 320, 2700 },
    '057-5008' => new List<Decimal>{ 220, 270, 500, 8200 },
    '024-0030' => new List<Decimal>{ 80,  90,  130, 250 },
    '024-0041' => new List<Decimal>{ 130, 130, 240, 1500 },
    '010-0014' => new List<Decimal>{ 60,  130, 120, 65 },
    '010-0031' => new List<Decimal>{ 80,  150, 150, 180 },
    '002-0007' => new List<Decimal>{ 30,  80,  30,  13 },
    '002-0026' => new List<Decimal>{ 35,  90,  35,  30 },
    '030-0001' => new List<Decimal>{ 60,  70,  80,  80 },
    '030-0032' => new List<Decimal>{ 70,  80,  100, 150 }
};

List<Product2> toUpdate = new List<Product2>();
for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :dimsByCode.keySet()]) {
    List<Decimal> d = dimsByCode.get(p.ProductCode);
    p.Width_cm__c = d[0];
    p.Height_cm__c = d[1];
    p.Depth_cm__c = d[2];
    p.Unit_Weight_Kg__c = d[3];
    toUpdate.add(p);
}

update toUpdate;
System.debug('Updated dimensions on ' + toUpdate.size() + ' products.');
