// LOXFORCE — Product Rules demo seed (clean wipe-and-recreate, savepoint-wrapped).
//
// Modeled on Salesforce CPQ Trailhead patterns (Home Security Console, Telecommuter
// Workstation, Home Automation Hub modules) adapted to the LOXAM construction-rental catalog:
//
//   Selection rules — mirror the "Outlets ↔ Electrical Installation" pattern: when a
//                     specific base option is picked, the engine automatically
//                     adds/hides a related option.
//   Validation rule — mirror "Prevent Missing Microphones": block save when a
//                     business-critical threshold is breached.
//   Alert rule      — mirror "Window Sensor Warning": warn when the configuration is
//                     legal but probably wrong.
//
// All Product_Rule__c records are wiped and recreated each run so the demo data
// stays canonical with no leftover rules.
Savepoint sp = Database.setSavepoint();
try {

    // --- 1. Look up the products the rules reference --------------------------------
    Map<String, Id> productByCode = new Map<String, Id>();
    Set<String> codes = new Set<String>{
        '052-5000','052-5033','060-0011',
        '057-5000','057-5001','002-0026',
        '079-8000','079-8041','030-0032'
    };
    for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :codes]) {
        productByCode.put(p.ProductCode, p.Id);
    }
    for (String c : codes) {
        if (!productByCode.containsKey(c)) {
            throw new System.IllegalArgumentException('Missing product '+c+' — run seed_demo_data.apex first.');
        }
    }

    // --- 2. Wipe any existing rules so the demo data is canonical -------------------
    // Bundle_Rule_Assignment__c is a lookup with Restrict on Product_Rule__c, so it
    // must go first. Rule_Condition__c and Rule_Action__c are master-detail children
    // of Product_Rule__c and cascade automatically.
    delete [SELECT Id FROM Bundle_Rule_Assignment__c];
    delete [SELECT Id FROM Product_Rule__c];

    // --- 3. Rules ------------------------------------------------------------------
    Product_Rule__c rRequireStrap = new Product_Rule__c(
        Name='Require Heavy-Duty Lifting Strap',
        Type__c='Selection', Conditions_Met__c='All', Evaluation_Event__c='Edit', Is_Active__c=true,
        Message__c='The 3.5 t / 12 m telehandler must be paired with a 5 t-rated lifting strap.');
    Product_Rule__c rHideDieselBackup = new Product_Rule__c(
        Name='Hide Diesel Backup for Electric Truck',
        Type__c='Selection', Conditions_Met__c='All', Evaluation_Event__c='Edit', Is_Active__c=true,
        Message__c='Electric dump trucks operate on zero-emission sites — diesel gensets are not allowed.');
    Product_Rule__c rHideHeavyBreaker = new Product_Rule__c(
        Name='Hide Heavy Breaker for 1 t Excavator',
        Type__c='Selection', Conditions_Met__c='All', Evaluation_Event__c='Edit', Is_Active__c=true,
        Message__c='The 1 t mini-excavator cannot supply the hydraulic flow required by the 30 kg breaker.');
    Product_Rule__c rBlockElectricDieselMix = new Product_Rule__c(
        Name='Block Electric Truck with Diesel Generator',
        Type__c='Validation', Conditions_Met__c='All', Evaluation_Event__c='Save', Is_Active__c=true,
        Message__c='Quote contains both an electric dump truck and a diesel generator. Electric trucks deploy only on zero-emission sites — remove the diesel generator or switch to a diesel truck.');
    // Custom-conditions example. The formula (1 AND 2 AND 3) OR (1 AND 4) reuses
    // condition 1 across two OR-arms — not expressible as All (too narrow: requires
    // all four) or Any (too noisy: fires on any single one). Doesn't shadow the
    // Selection rules because it tests bundle presence on the quote, not bundle
    // internals.
    Product_Rule__c rFlagMultiTrade = new Product_Rule__c(
        Name='Flag Multi-Trade Job-Site Quote',
        Type__c='Alert', Conditions_Met__c='Custom', Evaluation_Event__c='Save', Is_Active__c=true,
        Advanced_Condition__c='(1 AND 2 AND 3) OR (1 AND 4)',
        Message__c='Multi-trade or large-scale job-site pattern detected. Confirm fleet pricing has been negotiated and that delivery logistics are coordinated with the rental manager.');
    Product_Rule__c rWarnFleetSize = new Product_Rule__c(
        Name='Flag Fleet-Size Bundle Order',
        Type__c='Alert', Conditions_Met__c='All', Evaluation_Event__c='Save', Is_Active__c=true,
        Message__c='A bundle line carries quantity 4 or more. Fleet-size orders should be priced against the fleet rate card — confirm with the rental manager.');

    List<Product_Rule__c> rules = new List<Product_Rule__c>{
        rRequireStrap, rHideDieselBackup, rHideHeavyBreaker, rBlockElectricDieselMix, rFlagMultiTrade, rWarnFleetSize
    };
    insert rules;

    // --- 4. Conditions -------------------------------------------------------------
    List<Rule_Condition__c> conditions = new List<Rule_Condition__c>{
        // Selection: trigger when the 3.5 t / 12 m telehandler is the selected base
        new Rule_Condition__c(Product_Rule__c=rRequireStrap.Id,
            Tested_Object__c='Bundle Option', Tested_Field__c='Option_Product__r.ProductCode',
            Operator__c='equals', Filter_Type__c='Value', Filter_Value__c='052-5033', Index__c=1),
        // Selection: trigger when the electric truck is the selected base
        new Rule_Condition__c(Product_Rule__c=rHideDieselBackup.Id,
            Tested_Object__c='Bundle Option', Tested_Field__c='Option_Product__r.ProductCode',
            Operator__c='equals', Filter_Type__c='Value', Filter_Value__c='079-8041', Index__c=1),
        // Selection: trigger when the 1 t mini-excavator is the selected base
        new Rule_Condition__c(Product_Rule__c=rHideHeavyBreaker.Id,
            Tested_Object__c='Bundle Option', Tested_Field__c='Option_Product__r.ProductCode',
            Operator__c='equals', Filter_Type__c='Value', Filter_Value__c='057-5001', Index__c=1),
        // Validation (All): cross-line check — electric truck AND diesel genset both on the quote
        new Rule_Condition__c(Product_Rule__c=rBlockElectricDieselMix.Id,
            Tested_Object__c='Opportunity Line', Tested_Field__c='ProductCode',
            Operator__c='equals', Filter_Type__c='Value', Filter_Value__c='079-8041', Index__c=1),
        new Rule_Condition__c(Product_Rule__c=rBlockElectricDieselMix.Id,
            Tested_Object__c='Opportunity Line', Tested_Field__c='ProductCode',
            Operator__c='equals', Filter_Type__c='Value', Filter_Value__c='030-0032', Index__c=2),
        // Alert (Custom: (1 AND 2 AND 3) OR (1 AND 4))
        //   1: telehandler bundle on quote (052-5000)
        //   2: dump-truck bundle on quote (079-8000)
        //   3: mini-excavator bundle on quote (057-5000)
        //   4: any line with quantity > 3 (fleet-sized order)
        // Fires when all three bundle types are on the quote (multi-trade site) OR
        // when the telehandler is paired with a fleet-sized order.
        new Rule_Condition__c(Product_Rule__c=rFlagMultiTrade.Id,
            Tested_Object__c='Opportunity Line', Tested_Field__c='ProductCode',
            Operator__c='equals', Filter_Type__c='Value', Filter_Value__c='052-5000', Index__c=1),
        new Rule_Condition__c(Product_Rule__c=rFlagMultiTrade.Id,
            Tested_Object__c='Opportunity Line', Tested_Field__c='ProductCode',
            Operator__c='equals', Filter_Type__c='Value', Filter_Value__c='079-8000', Index__c=2),
        new Rule_Condition__c(Product_Rule__c=rFlagMultiTrade.Id,
            Tested_Object__c='Opportunity Line', Tested_Field__c='ProductCode',
            Operator__c='equals', Filter_Type__c='Value', Filter_Value__c='057-5000', Index__c=3),
        new Rule_Condition__c(Product_Rule__c=rFlagMultiTrade.Id,
            Tested_Object__c='Opportunity Line', Tested_Field__c='Quantity',
            Operator__c='greater than', Filter_Type__c='Value', Filter_Value__c='3', Index__c=4),
        // Alert: any bundle line with quantity >= 4 (fleet size)
        new Rule_Condition__c(Product_Rule__c=rWarnFleetSize.Id,
            Tested_Object__c='Opportunity Line', Tested_Field__c='IsBundle',
            Operator__c='equals', Filter_Type__c='Value', Filter_Value__c='true', Index__c=1),
        new Rule_Condition__c(Product_Rule__c=rWarnFleetSize.Id,
            Tested_Object__c='Opportunity Line', Tested_Field__c='Quantity',
            Operator__c='greater than', Filter_Type__c='Value', Filter_Value__c='3', Index__c=2)
    };
    insert conditions;

    // --- 5. Actions (Selection rules only) -----------------------------------------
    List<Rule_Action__c> actions = new List<Rule_Action__c>{
        new Rule_Action__c(Product_Rule__c=rRequireStrap.Id,     Type__c='Add',  Target_Product__c=productByCode.get('060-0011'), Sort_Order__c=1),
        new Rule_Action__c(Product_Rule__c=rHideDieselBackup.Id, Type__c='Hide', Target_Product__c=productByCode.get('030-0032'), Sort_Order__c=1),
        new Rule_Action__c(Product_Rule__c=rHideHeavyBreaker.Id, Type__c='Hide', Target_Product__c=productByCode.get('002-0026'), Sort_Order__c=1)
    };
    insert actions;

    // --- 6. Assignments (Selection rules to their host bundles) --------------------
    List<Bundle_Rule_Assignment__c> assignments = new List<Bundle_Rule_Assignment__c>{
        new Bundle_Rule_Assignment__c(Bundle_Product__c=productByCode.get('052-5000'), Product_Rule__c=rRequireStrap.Id,     Is_Active__c=true),
        new Bundle_Rule_Assignment__c(Bundle_Product__c=productByCode.get('079-8000'), Product_Rule__c=rHideDieselBackup.Id, Is_Active__c=true),
        new Bundle_Rule_Assignment__c(Bundle_Product__c=productByCode.get('057-5000'), Product_Rule__c=rHideHeavyBreaker.Id, Is_Active__c=true)
    };
    insert assignments;

    System.debug('SEED RULES OK: rules='+rules.size()+' conditions='+conditions.size()+' actions='+actions.size()+' assignments='+assignments.size());

} catch (Exception e) {
    Database.rollback(sp);
    System.debug(LoggingLevel.ERROR, 'SEED RULES ROLLBACK: '+e.getTypeName()+': '+e.getMessage());
    System.debug(LoggingLevel.ERROR, e.getStackTraceString());
    throw e;
}
