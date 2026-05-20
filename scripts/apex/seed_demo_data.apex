// LOXFORCE — Demo seed data (all-or-none, idempotent). LOXAM SKUs.
Savepoint sp = Database.setSavepoint();
try {

    // 1. CATALOGS
    List<ProductCatalog> catalogs = new List<ProductCatalog>{
        new ProductCatalog(Name='Sales'),
        new ProductCatalog(Name='Rental and Services')
    };
    Map<String, Id> catalogByName = new Map<String, Id>();
    Set<String> catalogNames = new Set<String>{'Sales','Rental and Services'};
    for (ProductCatalog c : [SELECT Id, Name FROM ProductCatalog WHERE Name IN :catalogNames]) catalogByName.put(c.Name, c.Id);
    for (ProductCatalog c : catalogs) if (catalogByName.containsKey(c.Name)) c.Id = catalogByName.get(c.Name);
    upsert catalogs;
    for (ProductCatalog c : catalogs) catalogByName.put(c.Name, c.Id);
    Id catSales = catalogByName.get('Sales');
    Id catRentalSvc = catalogByName.get('Rental and Services');

    // 2. CATEGORIES (parents first, then children). Natural key: CatalogId + Name.
    List<ProductCategory> parentCategories = new List<ProductCategory>{
        new ProductCategory(CatalogId=catRentalSvc, Name='Transport et Manutention',      IsNavigational=true, SortOrder=1),
        new ProductCategory(CatalogId=catRentalSvc, Name='Terrassement et Routes',        IsNavigational=true, SortOrder=2),
        new ProductCategory(CatalogId=catRentalSvc, Name='Gros Oeuvre et Demolition',     IsNavigational=true, SortOrder=3),
        new ProductCategory(CatalogId=catRentalSvc, Name='Energie Electrique et Fluides', IsNavigational=true, SortOrder=4)
    };
    Map<String, Id> categoryByKey = new Map<String, Id>();
    Set<Id> catalogIdSet = new Set<Id>{catSales, catRentalSvc};
    for (ProductCategory pc : [SELECT Id, CatalogId, Name FROM ProductCategory WHERE CatalogId IN :catalogIdSet]) categoryByKey.put(String.valueOf(pc.CatalogId)+'|'+pc.Name, pc.Id);
    for (ProductCategory pc : parentCategories) { String k=String.valueOf(pc.CatalogId)+'|'+pc.Name; if (categoryByKey.containsKey(k)) pc.Id=categoryByKey.get(k); }
    upsert parentCategories;
    for (ProductCategory pc : parentCategories) categoryByKey.put(String.valueOf(pc.CatalogId)+'|'+pc.Name, pc.Id);

    Id parentTRANSPORT  = categoryByKey.get(String.valueOf(catRentalSvc)+'|Transport et Manutention');
    Id parentEARTHWORKS = categoryByKey.get(String.valueOf(catRentalSvc)+'|Terrassement et Routes');

    List<ProductCategory> childCategories = new List<ProductCategory>{
        new ProductCategory(CatalogId=catRentalSvc, Name='Fourgon et Pick-up',   ParentCategoryId=parentTRANSPORT,  IsNavigational=true, SortOrder=1),
        new ProductCategory(CatalogId=catRentalSvc, Name='Camion-Benne',         ParentCategoryId=parentTRANSPORT,  IsNavigational=true, SortOrder=2),
        new ProductCategory(CatalogId=catRentalSvc, Name='Chariot Telescopique', ParentCategoryId=parentTRANSPORT,  IsNavigational=true, SortOrder=3),
        new ProductCategory(CatalogId=catRentalSvc, Name='Minipelle',            ParentCategoryId=parentEARTHWORKS, IsNavigational=true, SortOrder=1),
        new ProductCategory(CatalogId=catRentalSvc, Name='Rouleau Vibrant',      ParentCategoryId=parentEARTHWORKS, IsNavigational=true, SortOrder=2)
    };
    for (ProductCategory pc : childCategories) { String k=String.valueOf(pc.CatalogId)+'|'+pc.Name; if (categoryByKey.containsKey(k)) pc.Id=categoryByKey.get(k); }
    upsert childCategories;
    for (ProductCategory pc : childCategories) categoryByKey.put(String.valueOf(pc.CatalogId)+'|'+pc.Name, pc.Id);

    List<ProductCategory> categories = new List<ProductCategory>();
    categories.addAll(parentCategories);
    categories.addAll(childCategories);
    Map<String, Id> categoryByCode = new Map<String, Id>();
    for (ProductCategory pc : categories) categoryByCode.put(pc.Name, pc.Id);

    // 3. PRODUCTS (LOXAM SKUs)
    // Family: 'Equipment' for physical items (included in BinSolver packing) / 'Service' for intangibles (excluded).
    // Picklist constraint: Product2Family standardValueSet allows None / Equipment / Service only.
    // Sub-categorization (Vehicle / Lifting / Power ...) is encoded via ProductCategoryProduct, not Family.
    // Dimensions (Width_cm__c / Height_cm__c / Depth_cm__c / Unit_Weight_Kg__c) are REQUIRED by BinSolver:
    // TripService.buildItemsFromCPQ skips items where w or h is null. Bundles themselves don't need dims (only their leaf options do).
    List<Product2> products = new List<Product2>{
        new Product2(ProductCode='052-5000',   Name='Chariot Telescopique', Family='Equipment', Type='Bundle', IsActive=true),
        new Product2(ProductCode='079-8000',    Name='Camion-Benne',         Family='Equipment', Type='Bundle', IsActive=true),
        new Product2(ProductCode='057-5000', Name='Minipelle',            Family='Equipment', Type='Bundle', IsActive=true),
        new Product2(ProductCode='079-0025', Name='Fourgon Diesel 3 m3',        Family='Equipment', IsActive=true, Width_cm__c=180, Height_cm__c=200, Depth_cm__c=450, Unit_Weight_Kg__c=1800),
        new Product2(ProductCode='079-0030', Name='Fourgon Diesel 9 m3',        Family='Equipment', IsActive=true, Width_cm__c=200, Height_cm__c=250, Depth_cm__c=600, Unit_Weight_Kg__c=2500),
        new Product2(ProductCode='079-0035', Name='Fourgon 7 places 12 m3',     Family='Equipment', IsActive=true, Width_cm__c=210, Height_cm__c=260, Depth_cm__c=650, Unit_Weight_Kg__c=2800),
        new Product2(ProductCode='079-8041', Name='Camion-Benne Electrique',    Family='Equipment', IsActive=true, Width_cm__c=220, Height_cm__c=280, Depth_cm__c=700, Unit_Weight_Kg__c=3500),
        new Product2(ProductCode='079-0041', Name='Camion-Benne Diesel 3,5 t',  Family='Equipment', IsActive=true, Width_cm__c=220, Height_cm__c=280, Depth_cm__c=700, Unit_Weight_Kg__c=3500),
        new Product2(ProductCode='052-5021', Name='Chariot Telescopique 2t/4m',    Family='Equipment', IsActive=true, Width_cm__c=220, Height_cm__c=200, Depth_cm__c=500, Unit_Weight_Kg__c=4500),
        new Product2(ProductCode='052-5024', Name='Chariot Telescopique 2,5t/6m',  Family='Equipment', IsActive=true, Width_cm__c=230, Height_cm__c=210, Depth_cm__c=550, Unit_Weight_Kg__c=5500),
        new Product2(ProductCode='052-5033', Name='Chariot Telescopique 3,5t/12m', Family='Equipment', IsActive=true, Width_cm__c=240, Height_cm__c=220, Depth_cm__c=700, Unit_Weight_Kg__c=7500),
        new Product2(ProductCode='057-5001', Name='Minipelle 1 t Diesel',     Family='Equipment', IsActive=true, Width_cm__c=90,  Height_cm__c=220, Depth_cm__c=250, Unit_Weight_Kg__c=1100),
        new Product2(ProductCode='057-5004', Name='Minipelle 2,7 t Diesel',   Family='Equipment', IsActive=true, Width_cm__c=140, Height_cm__c=240, Depth_cm__c=320, Unit_Weight_Kg__c=2700),
        new Product2(ProductCode='057-5008', Name='Minipelle 8,2 t Diesel',   Family='Equipment', IsActive=true, Width_cm__c=220, Height_cm__c=270, Depth_cm__c=500, Unit_Weight_Kg__c=8200),
        new Product2(ProductCode='024-0030', Name='Rouleau Vibrant VM1',      Family='Equipment', IsActive=true, Width_cm__c=80,  Height_cm__c=90,  Depth_cm__c=130, Unit_Weight_Kg__c=250),
        new Product2(ProductCode='024-0041', Name='Rouleau Vibrant VM3',      Family='Equipment', IsActive=true, Width_cm__c=130, Height_cm__c=130, Depth_cm__c=240, Unit_Weight_Kg__c=1500),
        new Product2(ProductCode='010-0014', Name='Betonniere Electrique 90 L', Family='Equipment', IsActive=true, Width_cm__c=60, Height_cm__c=130, Depth_cm__c=120, Unit_Weight_Kg__c=65),
        new Product2(ProductCode='010-0031', Name='Betonniere Thermique 280 L', Family='Equipment', IsActive=true, Width_cm__c=80, Height_cm__c=150, Depth_cm__c=150, Unit_Weight_Kg__c=180),
        new Product2(ProductCode='002-0007', Name='Brise-Beton Electrique 13 kg',Family='Equipment', IsActive=true, Width_cm__c=30, Height_cm__c=80, Depth_cm__c=30, Unit_Weight_Kg__c=13),
        new Product2(ProductCode='002-0026', Name='Brise-Beton Electrique 30 kg',Family='Equipment', IsActive=true, Width_cm__c=35, Height_cm__c=90, Depth_cm__c=35, Unit_Weight_Kg__c=30),
        new Product2(ProductCode='030-0001', Name='Groupe Electrogene 5 kVA Essence',  Family='Equipment', IsActive=true, Width_cm__c=60, Height_cm__c=70, Depth_cm__c=80,  Unit_Weight_Kg__c=80),
        new Product2(ProductCode='030-0032', Name='Groupe Electrogene 6,5 kVA Diesel', Family='Equipment', IsActive=true, Width_cm__c=70, Height_cm__c=80, Depth_cm__c=100, Unit_Weight_Kg__c=150),
        new Product2(ProductCode='080-0010', Name='Tour d\'Eclairage LED 9m',          Family='Equipment', IsActive=true, Width_cm__c=100, Height_cm__c=250, Depth_cm__c=100, Unit_Weight_Kg__c=220),
        new Product2(ProductCode='060-0011', Name='Sangle de Levage 5t',               Family='Equipment', IsActive=true, Width_cm__c=20,  Height_cm__c=10,  Depth_cm__c=200, Unit_Weight_Kg__c=5)
    };
    Map<String, Id> productByCode = new Map<String, Id>();
    Set<String> productCodes = new Set<String>();
    for (Product2 p : products) productCodes.add(p.ProductCode);
    for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :productCodes]) productByCode.put(p.ProductCode, p.Id);
    for (Product2 p : products) if (productByCode.containsKey(p.ProductCode)) p.Id = productByCode.get(p.ProductCode);
    upsert products;
    for (Product2 p : products) productByCode.put(p.ProductCode, p.Id);
    Set<Id> prodIdSet = new Set<Id>(productByCode.values());

    // 3b. PRICEBOOK ENTRIES (Standard Pricebook, daily EUR rate)
    Id stdPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
    Map<String, Decimal> priceByCode = new Map<String, Decimal>{
        '052-5000'=>320.00, '079-8000'=>200.00, '057-5000'=>190.00,
        '079-0025'=>90.00, '079-0030'=>130.00, '079-0035'=>150.00,
        '079-8041'=>220.00, '079-0041'=>160.00,
        '052-5021'=>280.00, '052-5024'=>320.00, '052-5033'=>420.00,
        '057-5001'=>110.00, '057-5004'=>180.00, '057-5008'=>290.00,
        '024-0030'=>240.00, '024-0041'=>380.00,
        '010-0014'=>30.00, '010-0031'=>65.00,
        '002-0007'=>45.00, '002-0026'=>65.00,
        '030-0001'=>50.00, '030-0032'=>85.00,
        '080-0010'=>70.00, '060-0011'=>15.00
    };
    List<PricebookEntry> pbes = new List<PricebookEntry>();
    for (String code : priceByCode.keySet()) {
        pbes.add(new PricebookEntry(Pricebook2Id=stdPbId, Product2Id=productByCode.get(code), UnitPrice=priceByCode.get(code), IsActive=true));
    }
    Map<String, Id> pbeByKey = new Map<String, Id>();
    for (PricebookEntry pe : [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :stdPbId AND Product2Id IN :prodIdSet]) pbeByKey.put(String.valueOf(pe.Pricebook2Id)+'|'+String.valueOf(pe.Product2Id), pe.Id);
    for (PricebookEntry pe : pbes) { String k=String.valueOf(pe.Pricebook2Id)+'|'+String.valueOf(pe.Product2Id); if (pbeByKey.containsKey(k)) pe.Id=pbeByKey.get(k); }
    upsert pbes;

    // 3c. CUSTOM PRICEBOOKS + entries (same UnitPrice as Standard, segmented by catalog)
    List<Pricebook2> pricebooks = new List<Pricebook2>{
        new Pricebook2(Name='Sales',              IsActive=true, Description='Outright purchase price list'),
        new Pricebook2(Name='Rental and Services', IsActive=true, Description='Equipment rental and services price list')
    };
    Map<String, Id> pbByName = new Map<String, Id>();
    Set<String> pbNames = new Set<String>{'Sales','Rental and Services'};
    for (Pricebook2 pb : [SELECT Id, Name FROM Pricebook2 WHERE Name IN :pbNames]) pbByName.put(pb.Name, pb.Id);
    for (Pricebook2 pb : pricebooks) if (pbByName.containsKey(pb.Name)) pb.Id = pbByName.get(pb.Name);
    upsert pricebooks;
    for (Pricebook2 pb : pricebooks) pbByName.put(pb.Name, pb.Id);
    Id pbSales = pbByName.get('Sales');
    Id pbRental = pbByName.get('Rental and Services');

    List<PricebookEntry> customPbes = new List<PricebookEntry>();
    for (String code : priceByCode.keySet()) {
        Id prodId = productByCode.get(code);
        Decimal price = priceByCode.get(code);
        customPbes.add(new PricebookEntry(Pricebook2Id=pbSales,  Product2Id=prodId, UnitPrice=price, IsActive=true));
        customPbes.add(new PricebookEntry(Pricebook2Id=pbRental, Product2Id=prodId, UnitPrice=price, IsActive=true));
    }
    Set<Id> customPbIds = new Set<Id>{pbSales, pbRental};
    Map<String, Id> customPbeByKey = new Map<String, Id>();
    for (PricebookEntry pe : [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id IN :customPbIds AND Product2Id IN :prodIdSet]) customPbeByKey.put(String.valueOf(pe.Pricebook2Id)+'|'+String.valueOf(pe.Product2Id), pe.Id);
    for (PricebookEntry pe : customPbes) { String k=String.valueOf(pe.Pricebook2Id)+'|'+String.valueOf(pe.Product2Id); if (customPbeByKey.containsKey(k)) pe.Id=customPbeByKey.get(k); }
    upsert customPbes;

    // 4. PRODUCT-CATEGORY LINKS (each bundle mapped to its host category so it appears in the catalog UI)
    Map<String, String> productToCategoryCode = new Map<String, String>{
        '079-0025'=>'Fourgon et Pick-up', '079-0030'=>'Fourgon et Pick-up', '079-0035'=>'Fourgon et Pick-up',
        '079-8041'=>'Camion-Benne', '079-0041'=>'Camion-Benne',
        '052-5021'=>'Chariot Telescopique', '052-5024'=>'Chariot Telescopique', '052-5033'=>'Chariot Telescopique',
        '057-5001'=>'Minipelle', '057-5004'=>'Minipelle', '057-5008'=>'Minipelle',
        '024-0030'=>'Rouleau Vibrant', '024-0041'=>'Rouleau Vibrant',
        '010-0014'=>'Gros Oeuvre et Demolition', '010-0031'=>'Gros Oeuvre et Demolition', '002-0007'=>'Gros Oeuvre et Demolition', '002-0026'=>'Gros Oeuvre et Demolition',
        '030-0001'=>'Energie Electrique et Fluides', '030-0032'=>'Energie Electrique et Fluides',
        '080-0010'=>'Energie Electrique et Fluides', '060-0011'=>'Transport et Manutention',
        '052-5000'=>'Chariot Telescopique', '079-8000'=>'Camion-Benne', '057-5000'=>'Minipelle'
    };
    List<ProductCategoryProduct> pcps = new List<ProductCategoryProduct>();
    for (String code : productToCategoryCode.keySet()) pcps.add(new ProductCategoryProduct(ProductCategoryId=categoryByCode.get(productToCategoryCode.get(code)), ProductId=productByCode.get(code)));
    Set<Id> catIdSet = new Set<Id>(categoryByCode.values());
    Map<String, Id> pcpByKey = new Map<String, Id>();
    for (ProductCategoryProduct x : [SELECT Id, ProductCategoryId, ProductId FROM ProductCategoryProduct WHERE ProductCategoryId IN :catIdSet AND ProductId IN :prodIdSet]) pcpByKey.put(String.valueOf(x.ProductCategoryId)+'|'+String.valueOf(x.ProductId), x.Id);
    for (ProductCategoryProduct x : pcps) { String k=String.valueOf(x.ProductCategoryId)+'|'+String.valueOf(x.ProductId); if (pcpByKey.containsKey(k)) x.Id=pcpByKey.get(k); }
    upsert pcps;

    // 5. BUNDLE FEATURES (each bundle = 1 configurable machine: required base model + optional attachments + complementary energy + accessories)
    List<Bundle_Feature__c> features = new List<Bundle_Feature__c>{
        // 052-5000: telescopic forklift configurable
        new Bundle_Feature__c(Product__c=productByCode.get('052-5000'),   Name='Modele de Base',         Min_Options__c=1, Max_Options__c=1, Sort_Order__c=1),
        new Bundle_Feature__c(Product__c=productByCode.get('052-5000'),   Name='Energie d\'Appoint',     Min_Options__c=0, Max_Options__c=1, Sort_Order__c=2),
        new Bundle_Feature__c(Product__c=productByCode.get('052-5000'),   Name='Accessoires de Levage',  Min_Options__c=0, Max_Options__c=2, Sort_Order__c=3),
        // 079-8000: dump truck configurable
        new Bundle_Feature__c(Product__c=productByCode.get('079-8000'),    Name='Modele de Base',         Min_Options__c=1, Max_Options__c=1, Sort_Order__c=1),
        new Bundle_Feature__c(Product__c=productByCode.get('079-8000'),    Name='Energie d\'Appoint',     Min_Options__c=0, Max_Options__c=1, Sort_Order__c=2),
        new Bundle_Feature__c(Product__c=productByCode.get('079-8000'),    Name='Eclairage de Chantier',  Min_Options__c=0, Max_Options__c=2, Sort_Order__c=3),
        // 057-5000: excavator configurable
        new Bundle_Feature__c(Product__c=productByCode.get('057-5000'), Name='Modele de Base',         Min_Options__c=1, Max_Options__c=1, Sort_Order__c=1),
        new Bundle_Feature__c(Product__c=productByCode.get('057-5000'), Name='Outils de Demolition',   Min_Options__c=0, Max_Options__c=1, Sort_Order__c=2),
        new Bundle_Feature__c(Product__c=productByCode.get('057-5000'), Name='Energie d\'Appoint',     Min_Options__c=0, Max_Options__c=1, Sort_Order__c=3)
    };
    Map<String, Id> featureByKey = new Map<String, Id>();
    for (Bundle_Feature__c f : [SELECT Id, Product__c, Name FROM Bundle_Feature__c WHERE Product__c IN :prodIdSet]) featureByKey.put(String.valueOf(f.Product__c)+'|'+f.Name, f.Id);
    for (Bundle_Feature__c f : features) { String k=String.valueOf(f.Product__c)+'|'+f.Name; if (featureByKey.containsKey(k)) f.Id=featureByKey.get(k); }
    upsert features;
    for (Bundle_Feature__c f : features) featureByKey.put(String.valueOf(f.Product__c)+'|'+f.Name, f.Id);

    Id fCH_M=featureByKey.get(String.valueOf(productByCode.get('052-5000'))+'|Modele de Base');
    Id fCH_E=featureByKey.get(String.valueOf(productByCode.get('052-5000'))+'|Energie d\'Appoint');
    Id fCH_A=featureByKey.get(String.valueOf(productByCode.get('052-5000'))+'|Accessoires de Levage');
    Id fCA_M=featureByKey.get(String.valueOf(productByCode.get('079-8000'))+'|Modele de Base');
    Id fCA_E=featureByKey.get(String.valueOf(productByCode.get('079-8000'))+'|Energie d\'Appoint');
    Id fCA_L=featureByKey.get(String.valueOf(productByCode.get('079-8000'))+'|Eclairage de Chantier');
    Id fMP_M=featureByKey.get(String.valueOf(productByCode.get('057-5000'))+'|Modele de Base');
    Id fMP_D=featureByKey.get(String.valueOf(productByCode.get('057-5000'))+'|Outils de Demolition');
    Id fMP_E=featureByKey.get(String.valueOf(productByCode.get('057-5000'))+'|Energie d\'Appoint');

    // 6. BUNDLE OPTIONS
    //  - Component: base model (qty scales with bundle qty)
    //  - Related Product: complementary energy (independent qty)
    //  - Accessory: small add-on (fixed qty)
    List<Bundle_Option__c> options = new List<Bundle_Option__c>{
        // 052-5000 (Chariot Telescopique)
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('052-5000'),   Feature__c=fCH_M, Option_Product__c=productByCode.get('052-5021'), Option_Type__c='Component',       Is_Selected__c=true, Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=1, Sort_Order__c=1),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('052-5000'),   Feature__c=fCH_M, Option_Product__c=productByCode.get('052-5024'), Option_Type__c='Component',       Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=1, Sort_Order__c=2),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('052-5000'),   Feature__c=fCH_M, Option_Product__c=productByCode.get('052-5033'), Option_Type__c='Component',       Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=1, Sort_Order__c=3),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('052-5000'),   Feature__c=fCH_E, Option_Product__c=productByCode.get('030-0001'), Option_Type__c='Related Product', Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=2, Sort_Order__c=1),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('052-5000'),   Feature__c=fCH_E, Option_Product__c=productByCode.get('030-0032'), Option_Type__c='Related Product', Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=2, Sort_Order__c=2),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('052-5000'),   Feature__c=fCH_A, Option_Product__c=productByCode.get('060-0011'), Option_Type__c='Accessory',       Default_Quantity__c=2, Min_Quantity__c=1, Max_Quantity__c=10, Sort_Order__c=1),
        // 079-8000 (Camion-Benne)
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('079-8000'),    Feature__c=fCA_M, Option_Product__c=productByCode.get('079-0041'), Option_Type__c='Component',       Is_Selected__c=true, Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=1, Sort_Order__c=1),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('079-8000'),    Feature__c=fCA_M, Option_Product__c=productByCode.get('079-8041'), Option_Type__c='Component',       Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=1, Sort_Order__c=2),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('079-8000'),    Feature__c=fCA_E, Option_Product__c=productByCode.get('030-0001'), Option_Type__c='Related Product', Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=2, Sort_Order__c=1),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('079-8000'),    Feature__c=fCA_E, Option_Product__c=productByCode.get('030-0032'), Option_Type__c='Related Product', Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=2, Sort_Order__c=2),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('079-8000'),    Feature__c=fCA_L, Option_Product__c=productByCode.get('080-0010'), Option_Type__c='Accessory',       Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=4, Sort_Order__c=1),
        // 057-5000 (Minipelle)
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('057-5000'), Feature__c=fMP_M, Option_Product__c=productByCode.get('057-5004'), Option_Type__c='Component',       Is_Selected__c=true, Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=1, Sort_Order__c=1),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('057-5000'), Feature__c=fMP_M, Option_Product__c=productByCode.get('057-5001'), Option_Type__c='Component',       Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=1, Sort_Order__c=2),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('057-5000'), Feature__c=fMP_M, Option_Product__c=productByCode.get('057-5008'), Option_Type__c='Component',       Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=1, Sort_Order__c=3),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('057-5000'), Feature__c=fMP_D, Option_Product__c=productByCode.get('002-0007'), Option_Type__c='Accessory',       Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=3, Sort_Order__c=1),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('057-5000'), Feature__c=fMP_D, Option_Product__c=productByCode.get('002-0026'), Option_Type__c='Accessory',       Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=2, Sort_Order__c=2),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('057-5000'), Feature__c=fMP_E, Option_Product__c=productByCode.get('030-0001'), Option_Type__c='Related Product', Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=2, Sort_Order__c=1),
        new Bundle_Option__c(Bundle_Product__c=productByCode.get('057-5000'), Feature__c=fMP_E, Option_Product__c=productByCode.get('030-0032'), Option_Type__c='Related Product', Default_Quantity__c=1, Min_Quantity__c=1, Max_Quantity__c=2, Sort_Order__c=2)
    };
    Set<Id> featureIdSet = new Set<Id>(featureByKey.values());
    Map<String, Id> optionByKey = new Map<String, Id>();
    for (Bundle_Option__c o : [SELECT Id, Feature__c, Option_Product__c FROM Bundle_Option__c WHERE Feature__c IN :featureIdSet]) optionByKey.put(String.valueOf(o.Feature__c)+'|'+String.valueOf(o.Option_Product__c), o.Id);
    for (Bundle_Option__c o : options) { String k=String.valueOf(o.Feature__c)+'|'+String.valueOf(o.Option_Product__c); if (optionByKey.containsKey(k)) o.Id=optionByKey.get(k); }
    upsert options;

    // 7. VOLUME PRICING SCHEDULES (one per product, Tiered)
    Map<String, Decimal> overageByCode = new Map<String, Decimal>();
    for (String code : priceByCode.keySet()) overageByCode.put(code, (priceByCode.get(code) * 0.80).setScale(2));

    List<Volume_Pricing_Schedule__c> schedules = new List<Volume_Pricing_Schedule__c>();
    Set<String> schedNames = new Set<String>();
    for (String code : productByCode.keySet()) {
        String sname = code + ' Pricing Schedule';
        schedNames.add(sname);
        schedules.add(new Volume_Pricing_Schedule__c(Name=sname, Product__c=productByCode.get(code), Pricing_Type__c='Tiered', Is_Active__c=true, Overage_Rate__c=overageByCode.get(code)));
    }
    Map<String, Id> schedByName = new Map<String, Id>();
    for (Volume_Pricing_Schedule__c s : [SELECT Id, Name FROM Volume_Pricing_Schedule__c WHERE Name IN :schedNames]) schedByName.put(s.Name, s.Id);
    for (Volume_Pricing_Schedule__c s : schedules) if (schedByName.containsKey(s.Name)) s.Id = schedByName.get(s.Name);
    upsert schedules;
    for (Volume_Pricing_Schedule__c s : schedules) schedByName.put(s.Name, s.Id);

    // 8. VOLUME PRICING TIERS (3 day-count tiers per product)
    List<Volume_Pricing_Tier__c> tiers = new List<Volume_Pricing_Tier__c>();
    for (String code : productByCode.keySet()) {
        Decimal p = priceByCode.get(code);
        Id sId = schedByName.get(code + ' Pricing Schedule');
        tiers.add(new Volume_Pricing_Tier__c(Volume_Pricing_Schedule__c=sId, Name=code+' tier 1', Lower_Bound__c=1, Upper_Bound__c=2,    Price__c=p,                            Sort_Order__c=1));
        tiers.add(new Volume_Pricing_Tier__c(Volume_Pricing_Schedule__c=sId, Name=code+' tier 2', Lower_Bound__c=3, Upper_Bound__c=6,    Price__c=(p * 0.90).setScale(2),       Sort_Order__c=2));
        tiers.add(new Volume_Pricing_Tier__c(Volume_Pricing_Schedule__c=sId, Name=code+' tier 3', Lower_Bound__c=7, Upper_Bound__c=null, Price__c=(p * 0.80).setScale(2),       Sort_Order__c=3));
    }
    Set<Id> schedIdSet = new Set<Id>(schedByName.values());
    Map<String, Id> tierByKey = new Map<String, Id>();
    for (Volume_Pricing_Tier__c t : [SELECT Id, Volume_Pricing_Schedule__c, Lower_Bound__c FROM Volume_Pricing_Tier__c WHERE Volume_Pricing_Schedule__c IN :schedIdSet]) tierByKey.put(String.valueOf(t.Volume_Pricing_Schedule__c)+'|'+String.valueOf(t.Lower_Bound__c), t.Id);
    for (Volume_Pricing_Tier__c t : tiers) { String k=String.valueOf(t.Volume_Pricing_Schedule__c)+'|'+String.valueOf(t.Lower_Bound__c); if (tierByKey.containsKey(k)) t.Id=tierByKey.get(k); }
    upsert tiers;

    // 9. ACCOUNTS
    List<Account> accounts = new List<Account>{
        new Account(Name='BTP Atlas SARL',             Type='Customer - Direct',  Industry='Construction', BillingCity='Casablanca', BillingCountry='Morocco', Phone='+212 522 000 001', Website='btp-atlas.ma'),
        new Account(Name='Constructions Mediterranee', Type='Customer - Direct',  Industry='Construction', BillingCity='Marseille',  BillingCountry='France',  Phone='+33 4 91 00 00 02', Website='constructions-mediterranee.fr'),
        new Account(Name='Iberian Works SL',           Type='Customer - Channel', Industry='Engineering',  BillingCity='Barcelona',  BillingCountry='Spain',   Phone='+34 93 000 00 03', Website='iberian-works.es')
    };
    Map<String, Id> accByName = new Map<String, Id>();
    Set<String> accNames = new Set<String>();
    for (Account a : accounts) accNames.add(a.Name);
    for (Account a : [SELECT Id, Name FROM Account WHERE Name IN :accNames]) accByName.put(a.Name, a.Id);
    for (Account a : accounts) if (accByName.containsKey(a.Name)) a.Id = accByName.get(a.Name);
    upsert accounts;
    for (Account a : accounts) accByName.put(a.Name, a.Id);

    // 10. CONTACTS
    List<Contact> contacts = new List<Contact>{
        new Contact(AccountId=accByName.get('BTP Atlas SARL'),             FirstName='Youssef', LastName='Amrani',  Title='Site Manager',        Email='y.amrani@btp-atlas.ma',                       Phone='+212 661 000 001'),
        new Contact(AccountId=accByName.get('BTP Atlas SARL'),             FirstName='Sara',    LastName='Bennani', Title='Procurement Manager', Email='s.bennani@btp-atlas.ma',                      Phone='+212 661 000 002'),
        new Contact(AccountId=accByName.get('Constructions Mediterranee'), FirstName='Marc',    LastName='Dubois',  Title='Project Director',    Email='marc.dubois@constructions-mediterranee.fr',   Phone='+33 6 10 00 00 01'),
        new Contact(AccountId=accByName.get('Constructions Mediterranee'), FirstName='Claire',  LastName='Laurent', Title='CFO',                 Email='claire.laurent@constructions-mediterranee.fr',Phone='+33 6 10 00 00 02'),
        new Contact(AccountId=accByName.get('Iberian Works SL'),           FirstName='Carlos',  LastName='Ruiz',    Title='Equipment Manager',   Email='carlos.ruiz@iberian-works.es',                Phone='+34 600 000 001')
    };
    Map<String, Id> contactByEmail = new Map<String, Id>();
    Set<String> emails = new Set<String>();
    for (Contact c : contacts) emails.add(c.Email);
    for (Contact c : [SELECT Id, Email FROM Contact WHERE Email IN :emails]) contactByEmail.put(c.Email, c.Id);
    for (Contact c : contacts) if (contactByEmail.containsKey(c.Email)) c.Id = contactByEmail.get(c.Email);
    upsert contacts;

    System.debug('SEED OK: catalogs='+catalogs.size()+' categories='+categories.size()+' products='+products.size()+' stdPbe='+pbes.size()+' pricebooks='+pricebooks.size()+' customPbe='+customPbes.size()+' pcps='+pcps.size()+' features='+features.size()+' options='+options.size()+' scheds='+schedules.size()+' tiers='+tiers.size()+' accounts='+accounts.size()+' contacts='+contacts.size());

} catch (Exception e) {
    Database.rollback(sp);
    System.debug(LoggingLevel.ERROR, 'SEED ROLLBACK: '+e.getTypeName()+': '+e.getMessage());
    System.debug(LoggingLevel.ERROR, e.getStackTraceString());
    throw e;
}
