/**
 * CPQ Configurator – Mock Data Module
 * Comprehensive JSON structures simulating the Salesforce database.
 * Phase 2: Replace with @AuraEnabled Apex calls.
 */

/* ─── Accounts ─── */
export const ACCOUNTS = [
    { Id: 'acc-001', Name: 'Acme Corporation',    Industry: 'Technology',    Active__c: 'Yes', CustomerPriority__c: 'High',   NumberofLocations__c: 12 },
    { Id: 'acc-002', Name: 'Global Industries',   Industry: 'Manufacturing', Active__c: 'Yes', CustomerPriority__c: 'Medium', NumberofLocations__c: 5 },
    { Id: 'acc-003', Name: 'Summit Enterprises',  Industry: 'Finance',       Active__c: 'Yes', CustomerPriority__c: 'High',   NumberofLocations__c: 20 },
    { Id: 'acc-004', Name: 'Pinnacle Solutions',   Industry: 'Consulting',    Active__c: 'Yes', CustomerPriority__c: 'Low',    NumberofLocations__c: 3 }
];

/* ─── Contacts ─── */
export const CONTACTS = [
    { Id: 'con-001', FirstName: 'John',    LastName: 'Smith',    Email: 'john.smith@acme.com',          AccountId: 'acc-001', Title: 'CTO' },
    { Id: 'con-002', FirstName: 'Jane',    LastName: 'Doe',      Email: 'jane.doe@acme.com',            AccountId: 'acc-001', Title: 'Procurement Manager' },
    { Id: 'con-003', FirstName: 'Michael', LastName: 'Johnson',  Email: 'mjohnson@globalind.com',       AccountId: 'acc-002', Title: 'IT Director' },
    { Id: 'con-004', FirstName: 'Sarah',   LastName: 'Williams', Email: 'swilliams@summit.com',         AccountId: 'acc-003', Title: 'VP Operations' },
    { Id: 'con-005', FirstName: 'Robert',  LastName: 'Brown',    Email: 'rbrown@pinnacle.com',          AccountId: 'acc-004', Title: 'Office Manager' }
];

/* ─── Catalogs ─── */
export const CATALOGS = [
    { Id: 'catalog-001', Name: 'Sales Catalog' },
    { Id: 'catalog-002', Name: 'Rental Catalog' }
];

/* ─── Categories (hierarchical via ParentCategoryId) ─── */
export const CATEGORIES = [
    // Sales Catalog
    { Id: 'catg-001', Name: 'Computers',       CatalogId: 'catalog-001', ParentCategoryId: null,       SortOrder: 1, IsNavigational: true },
    { Id: 'catg-002', Name: 'Laptops',          CatalogId: 'catalog-001', ParentCategoryId: 'catg-001', SortOrder: 1, IsNavigational: true },
    { Id: 'catg-003', Name: 'Desktops',         CatalogId: 'catalog-001', ParentCategoryId: 'catg-001', SortOrder: 2, IsNavigational: true },
    { Id: 'catg-004', Name: 'Printers',         CatalogId: 'catalog-001', ParentCategoryId: null,       SortOrder: 2, IsNavigational: true },
    { Id: 'catg-005', Name: 'LaserJet',         CatalogId: 'catalog-001', ParentCategoryId: 'catg-004', SortOrder: 1, IsNavigational: true },
    { Id: 'catg-006', Name: 'Copy Machines',    CatalogId: 'catalog-001', ParentCategoryId: 'catg-004', SortOrder: 2, IsNavigational: true },
    { Id: 'catg-007', Name: 'Office Supplies',  CatalogId: 'catalog-001', ParentCategoryId: null,       SortOrder: 3, IsNavigational: true },
    { Id: 'catg-008', Name: 'Software',         CatalogId: 'catalog-001', ParentCategoryId: null,       SortOrder: 4, IsNavigational: true },
    { Id: 'catg-009', Name: 'Warranties',       CatalogId: 'catalog-001', ParentCategoryId: null,       SortOrder: 5, IsNavigational: true },
    // Rental Catalog
    { Id: 'catg-101', Name: 'Rental Equipment', CatalogId: 'catalog-002', ParentCategoryId: null,       SortOrder: 1, IsNavigational: true },
    { Id: 'catg-102', Name: 'Laptops',          CatalogId: 'catalog-002', ParentCategoryId: 'catg-101', SortOrder: 1, IsNavigational: true },
    { Id: 'catg-103', Name: 'Printers',         CatalogId: 'catalog-002', ParentCategoryId: 'catg-101', SortOrder: 2, IsNavigational: true }
];

/* ─── Products ─── */
export const PRODUCTS = [
    /* ── Bundles ─────────────────────────────────────── */
    { Id: 'prod-001', Name: '15" Laptop',         ProductCode: 'LAPTOP15',         Family: 'Hardware',   IsActive: true, IsBundle: true,  Description: '15-inch professional laptop – fully configurable.',          UnitPrice: 1500.00, Unit_Weight_Kg__c: 2.5  },
    { Id: 'prod-002', Name: 'Desktop Computer',    ProductCode: 'DESKTOP01',        Family: 'Hardware',   IsActive: true, IsBundle: true,  Description: 'Tower desktop workstation – fully configurable.',            UnitPrice: 2000.00, Unit_Weight_Kg__c: 8.0  },
    { Id: 'prod-003', Name: 'Copy Machine',        ProductCode: 'COPYMACHINE',      Family: 'Hardware',   IsActive: true, IsBundle: true,  Description: 'Professional high-volume copy machine with add-on modules.', UnitPrice: 3500.00, Unit_Weight_Kg__c: 45.0 },
    { Id: 'prod-004', Name: 'LaserJet Printer',    ProductCode: 'LJ-PRINTER',       Family: 'Hardware',   IsActive: true, IsBundle: true,  Description: 'Business-class LaserJet printer bundle.',                    UnitPrice: 275.00,  Unit_Weight_Kg__c: 12.0 },

    /* ── Standalone / Option Products ─────────────── */
    // Processors
    { Id: 'prod-cpu22', Name: 'CPU 2.2GHz i7',                ProductCode: 'CPU22GHZI7',        Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 125.00,  Unit_Weight_Kg__c: 0.1 },
    { Id: 'prod-cpu25', Name: 'CPU 2.5GHz i7',                ProductCode: 'CPU25GHZI7',        Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 100.00,  Unit_Weight_Kg__c: 0.1 },
    { Id: 'prod-cpu28', Name: 'CPU 2.8GHz i7',                ProductCode: 'CPU28GHZI7',        Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 250.00,  Unit_Weight_Kg__c: 0.1 },
    { Id: 'prod-cpu34', Name: 'CPU 3.4GHz i7',                ProductCode: 'CPU34GHZI7',        Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 350.00,  Unit_Weight_Kg__c: 0.1 },
    { Id: 'prod-cpu38', Name: 'CPU 3.8GHz i7',                ProductCode: 'CPU38GHZI7',        Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 475.00,  Unit_Weight_Kg__c: 0.1 },
    // RAM
    { Id: 'prod-ram8',   Name: 'RAM 8GB',                     ProductCode: 'RAM8GB',            Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 75.00,   Unit_Weight_Kg__c: 0.05 },
    { Id: 'prod-ram16',  Name: 'RAM 16GB',                    ProductCode: 'RAM16GB',           Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 125.00,  Unit_Weight_Kg__c: 0.05 },
    { Id: 'prod-ram32',  Name: 'RAM 32GB',                    ProductCode: 'RAM32GB',           Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 225.00,  Unit_Weight_Kg__c: 0.05 },
    // Storage
    { Id: 'prod-ssd256', Name: 'SSD Hard Drive 256GB',        ProductCode: 'SSD256',            Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 60.00,   Unit_Weight_Kg__c: 0.05 },
    { Id: 'prod-ssd512', Name: 'SSD Hard Drive 512GB',        ProductCode: 'SSD512',            Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 100.00,  Unit_Weight_Kg__c: 0.05 },
    { Id: 'prod-ssd1tb', Name: 'SSD Hard Drive 1TB',          ProductCode: 'SSD1TB',            Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 180.00,  Unit_Weight_Kg__c: 0.05 },
    // Input Devices
    { Id: 'prod-kb01',   Name: 'Wireless Keyboard',           ProductCode: 'WLKB01',            Family: 'Accessory',  IsActive: true, IsBundle: false, UnitPrice: 45.00,   Unit_Weight_Kg__c: 0.3  },
    { Id: 'prod-mouse01',Name: 'Wireless Mouse',              ProductCode: 'WLMOUSE01',         Family: 'Accessory',  IsActive: true, IsBundle: false, UnitPrice: 30.00,   Unit_Weight_Kg__c: 0.1  },
    { Id: 'prod-stylus', Name: 'Stylus Pen',                  ProductCode: 'STYLUS01',          Family: 'Accessory',  IsActive: true, IsBundle: false, UnitPrice: 55.00,   Unit_Weight_Kg__c: 0.05 },
    // Output Devices
    { Id: 'prod-mon24',  Name: '24" Monitor',                 ProductCode: 'MON24',             Family: 'Accessory',  IsActive: true, IsBundle: false, UnitPrice: 350.00,  Unit_Weight_Kg__c: 4.5  },
    { Id: 'prod-mon27',  Name: '27" Monitor',                 ProductCode: 'MON27',             Family: 'Accessory',  IsActive: true, IsBundle: false, UnitPrice: 500.00,  Unit_Weight_Kg__c: 5.5  },
    // Cables
    { Id: 'prod-hdmi',   Name: 'HDMI Cable 2m',               ProductCode: 'HDMI2M',            Family: 'Accessory',  IsActive: true, IsBundle: false, UnitPrice: 15.00,   Unit_Weight_Kg__c: 0.1  },
    { Id: 'prod-usbc',   Name: 'USB-C Cable',                 ProductCode: 'USBC01',            Family: 'Accessory',  IsActive: true, IsBundle: false, UnitPrice: 20.00,   Unit_Weight_Kg__c: 0.05 },
    { Id: 'prod-dp',     Name: 'DisplayPort Cable 1.5m',      ProductCode: 'DP15M',             Family: 'Accessory',  IsActive: true, IsBundle: false, UnitPrice: 18.00,   Unit_Weight_Kg__c: 0.1  },
    // Printer consumables
    { Id: 'prod-toner',     Name: 'LaserJet Toner Cartridge', ProductCode: 'LJ-TONER',          Family: 'Consumable', IsActive: true, IsBundle: false, UnitPrice: 125.00,  Unit_Weight_Kg__c: 0.5  },
    { Id: 'prod-maintkit',  Name: 'LaserJet Maintenance Kit', ProductCode: 'LJ-MAINTKIT',       Family: 'Consumable', IsActive: true, IsBundle: false, UnitPrice: 20.00,   Unit_Weight_Kg__c: 1.0  },
    { Id: 'prod-papera4',   Name: 'LaserJet Paper A4',        ProductCode: 'LJ-PAPERA4',        Family: 'Consumable', IsActive: true, IsBundle: false, UnitPrice: 10.00,   Unit_Weight_Kg__c: 2.5  },
    { Id: 'prod-paperlt',   Name: 'LaserJet Paper Letter',    ProductCode: 'LJ-PAPERLETTER',    Family: 'Consumable', IsActive: true, IsBundle: false, UnitPrice: 10.00,   Unit_Weight_Kg__c: 2.5  },
    // Copy-machine options
    { Id: 'prod-copybind',  Name: 'Copy Binding Module',              ProductCode: 'COPYBINDINGMODULE',  Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 350.00,  Unit_Weight_Kg__c: 5.0  },
    { Id: 'prod-hitoner',   Name: 'High Capacity Toner Cartridge',    ProductCode: 'HIGHCAPACITYTONER',  Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 250.00,  Unit_Weight_Kg__c: 1.0  },
    { Id: 'prod-copypaper', Name: 'Copy Paper Letter',                ProductCode: 'COPYPAPERLETTER',    Family: 'Consumable', IsActive: true, IsBundle: false, UnitPrice: 85.00,   Unit_Weight_Kg__c: 2.5  },
    { Id: 'prod-copytray',  Name: 'Extra Paper Tray',                 ProductCode: 'COPYEXTRATRAY',     Family: 'Component',  IsActive: true, IsBundle: false, UnitPrice: 150.00,  Unit_Weight_Kg__c: 3.0  },
    // Software
    { Id: 'prod-office',    Name: 'Microsoft Office 365',     ProductCode: 'MS-OFFICE365',       Family: 'Software',   IsActive: true, IsBundle: false, UnitPrice: 10.00,   Unit_Weight_Kg__c: 0   },
    { Id: 'prod-antivirus', Name: 'Enterprise Antivirus',     ProductCode: 'ENT-AV01',           Family: 'Software',   IsActive: true, IsBundle: false, UnitPrice: 35.00,   Unit_Weight_Kg__c: 0   },
    // Warranty
    { Id: 'prod-warranty',  Name: 'Loss and Damage Warranty', ProductCode: 'LD-NTY',             Family: 'Support',    IsActive: true, IsBundle: false, UnitPrice: 0.00,    Unit_Weight_Kg__c: 0   },
    { Id: 'prod-extwty',    Name: 'Extended Warranty 3-Year', ProductCode: 'EXT-WTY-3Y',         Family: 'Support',    IsActive: true, IsBundle: false, UnitPrice: 199.00,  Unit_Weight_Kg__c: 0   }
];

/* ─── Product ↔ Category Junctions ─── */
export const PRODUCT_CATEGORY_PRODUCTS = [
    // Laptops
    { Id: 'pcp-001', ProductId: 'prod-001', ProductCategoryId: 'catg-002', IsPrimaryCategory: true },
    // Desktops
    { Id: 'pcp-002', ProductId: 'prod-002', ProductCategoryId: 'catg-003', IsPrimaryCategory: true },
    // LaserJet
    { Id: 'pcp-003', ProductId: 'prod-004', ProductCategoryId: 'catg-005', IsPrimaryCategory: true },
    // Copy Machines
    { Id: 'pcp-004', ProductId: 'prod-003', ProductCategoryId: 'catg-006', IsPrimaryCategory: true },
    // Software
    { Id: 'pcp-005', ProductId: 'prod-office',    ProductCategoryId: 'catg-008', IsPrimaryCategory: true },
    { Id: 'pcp-006', ProductId: 'prod-antivirus', ProductCategoryId: 'catg-008', IsPrimaryCategory: true },
    // Consumables → Office Supplies
    { Id: 'pcp-007', ProductId: 'prod-toner',    ProductCategoryId: 'catg-007', IsPrimaryCategory: true },
    { Id: 'pcp-008', ProductId: 'prod-maintkit', ProductCategoryId: 'catg-007', IsPrimaryCategory: true },
    { Id: 'pcp-009', ProductId: 'prod-papera4',  ProductCategoryId: 'catg-007', IsPrimaryCategory: true },
    { Id: 'pcp-010', ProductId: 'prod-paperlt',  ProductCategoryId: 'catg-007', IsPrimaryCategory: true },
    // Warranty
    { Id: 'pcp-011', ProductId: 'prod-warranty', ProductCategoryId: 'catg-009', IsPrimaryCategory: true },
    { Id: 'pcp-012', ProductId: 'prod-extwty',   ProductCategoryId: 'catg-009', IsPrimaryCategory: true },
    // Rental
    { Id: 'pcp-101', ProductId: 'prod-001', ProductCategoryId: 'catg-102', IsPrimaryCategory: false },
    { Id: 'pcp-102', ProductId: 'prod-004', ProductCategoryId: 'catg-103', IsPrimaryCategory: false }
];

/* ─── Bundle Features (tabs inside configurator) ─── */
export const BUNDLE_FEATURES = [
    // 15" Laptop features
    { Id: 'feat-l-proc',  Product__c: 'prod-001', Name: 'Processor',          Min_Options__c: 1, Max_Options__c: 1, Sort_Order__c: 10, Help_Text__c: 'Select one processor for the laptop.' },
    { Id: 'feat-l-mem',   Product__c: 'prod-001', Name: 'Memory',             Min_Options__c: 1, Max_Options__c: 1, Sort_Order__c: 20, Help_Text__c: 'Select RAM capacity.' },
    { Id: 'feat-l-stor',  Product__c: 'prod-001', Name: 'Storage',            Min_Options__c: 1, Max_Options__c: 1, Sort_Order__c: 30, Help_Text__c: 'Select hard drive.' },
    { Id: 'feat-l-inp',   Product__c: 'prod-001', Name: 'Input Devices',      Min_Options__c: 0, Max_Options__c: 3, Sort_Order__c: 40, Help_Text__c: 'Add input peripherals.' },
    { Id: 'feat-l-out',   Product__c: 'prod-001', Name: 'Output Devices',     Min_Options__c: 0, Max_Options__c: 2, Sort_Order__c: 50, Help_Text__c: 'Add monitors or displays.' },
    { Id: 'feat-l-cab',   Product__c: 'prod-001', Name: 'Cables & Adapters',  Min_Options__c: 0, Max_Options__c: 5, Sort_Order__c: 60, Help_Text__c: 'Add cables.' },

    // Desktop Computer features
    { Id: 'feat-d-proc',  Product__c: 'prod-002', Name: 'Processor',          Min_Options__c: 1, Max_Options__c: 1, Sort_Order__c: 10, Help_Text__c: 'Select one processor.' },
    { Id: 'feat-d-mem',   Product__c: 'prod-002', Name: 'Memory',             Min_Options__c: 1, Max_Options__c: 1, Sort_Order__c: 20, Help_Text__c: 'Select RAM capacity.' },
    { Id: 'feat-d-stor',  Product__c: 'prod-002', Name: 'Storage',            Min_Options__c: 1, Max_Options__c: 2, Sort_Order__c: 30, Help_Text__c: 'Select up to two drives.' },
    { Id: 'feat-d-inp',   Product__c: 'prod-002', Name: 'Input Devices',      Min_Options__c: 0, Max_Options__c: 3, Sort_Order__c: 40, Help_Text__c: 'Add peripherals.' },
    { Id: 'feat-d-out',   Product__c: 'prod-002', Name: 'Output Devices',     Min_Options__c: 0, Max_Options__c: 3, Sort_Order__c: 50, Help_Text__c: 'Add monitors.' },
    { Id: 'feat-d-cab',   Product__c: 'prod-002', Name: 'Cables & Adapters',  Min_Options__c: 0, Max_Options__c: 5, Sort_Order__c: 60, Help_Text__c: 'Add cables.' },

    // Copy Machine features
    { Id: 'feat-c-opts',  Product__c: 'prod-003', Name: 'Other Options',      Min_Options__c: 0, Max_Options__c: 5, Sort_Order__c: 10, Help_Text__c: 'Select accessories for the copy machine.' },

    // LaserJet Printer features
    { Id: 'feat-p-cons',  Product__c: 'prod-004', Name: 'Consumables',        Min_Options__c: 0, Max_Options__c: 5, Sort_Order__c: 10, Help_Text__c: 'Add toner, paper, maintenance kits.' },
    { Id: 'feat-p-sw',    Product__c: 'prod-004', Name: 'Software',           Min_Options__c: 0, Max_Options__c: 2, Sort_Order__c: 20, Help_Text__c: 'Add driver or management software.' }
];

/* ─── Bundle Options (rows inside feature tabs) ─── */
export const BUNDLE_OPTIONS = [
    /* ── 15" Laptop → Processor (single select) ── */
    { Id: 'opt-l-cpu22', Feature__c: 'feat-l-proc', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-cpu22', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 10 },
    { Id: 'opt-l-cpu25', Feature__c: 'feat-l-proc', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-cpu25', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 20 },
    { Id: 'opt-l-cpu28', Feature__c: 'feat-l-proc', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-cpu28', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 30 },

    /* ── 15" Laptop → Memory (single select) ── */
    { Id: 'opt-l-ram8',  Feature__c: 'feat-l-mem', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-ram8',  Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 10 },
    { Id: 'opt-l-ram16', Feature__c: 'feat-l-mem', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-ram16', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 20 },
    { Id: 'opt-l-ram32', Feature__c: 'feat-l-mem', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-ram32', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 30 },

    /* ── 15" Laptop → Storage (single select) ── */
    { Id: 'opt-l-ssd256', Feature__c: 'feat-l-stor', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-ssd256', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 10 },
    { Id: 'opt-l-ssd512', Feature__c: 'feat-l-stor', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-ssd512', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 20 },
    { Id: 'opt-l-ssd1tb', Feature__c: 'feat-l-stor', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-ssd1tb', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 30 },

    /* ── 15" Laptop → Input Devices (multi select) ── */
    { Id: 'opt-l-kb',    Feature__c: 'feat-l-inp', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-kb01',    Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 2, Quantity_Editable__c: true,  Sort_Order__c: 10 },
    { Id: 'opt-l-mouse', Feature__c: 'feat-l-inp', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-mouse01', Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 2, Quantity_Editable__c: true,  Sort_Order__c: 20 },
    { Id: 'opt-l-styl',  Feature__c: 'feat-l-inp', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-stylus',  Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 30 },

    /* ── 15" Laptop → Output Devices (multi select) ── */
    { Id: 'opt-l-mon24', Feature__c: 'feat-l-out', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-mon24', Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 2, Quantity_Editable__c: true,  Sort_Order__c: 10 },
    { Id: 'opt-l-mon27', Feature__c: 'feat-l-out', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-mon27', Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 2, Quantity_Editable__c: true,  Sort_Order__c: 20 },

    /* ── 15" Laptop → Cables (multi select) ── */
    { Id: 'opt-l-hdmi', Feature__c: 'feat-l-cab', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-hdmi', Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 3, Quantity_Editable__c: true,  Sort_Order__c: 10 },
    { Id: 'opt-l-usbc', Feature__c: 'feat-l-cab', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-usbc', Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 3, Quantity_Editable__c: true,  Sort_Order__c: 20 },
    { Id: 'opt-l-dp',   Feature__c: 'feat-l-cab', Bundle_Product__c: 'prod-001', Option_Product__c: 'prod-dp',   Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 3, Quantity_Editable__c: true,  Sort_Order__c: 30 },

    /* ── Desktop Computer → Processor (single select) ── */
    { Id: 'opt-d-cpu28', Feature__c: 'feat-d-proc', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-cpu28', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 10 },
    { Id: 'opt-d-cpu34', Feature__c: 'feat-d-proc', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-cpu34', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 20 },
    { Id: 'opt-d-cpu38', Feature__c: 'feat-d-proc', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-cpu38', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 30 },

    /* ── Desktop Computer → Memory (single select) ── */
    { Id: 'opt-d-ram8',  Feature__c: 'feat-d-mem', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-ram8',  Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 10 },
    { Id: 'opt-d-ram16', Feature__c: 'feat-d-mem', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-ram16', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 20 },
    { Id: 'opt-d-ram32', Feature__c: 'feat-d-mem', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-ram32', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 30 },

    /* ── Desktop Computer → Storage (multi select max 2) ── */
    { Id: 'opt-d-ssd256', Feature__c: 'feat-d-stor', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-ssd256', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 10 },
    { Id: 'opt-d-ssd512', Feature__c: 'feat-d-stor', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-ssd512', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 20 },
    { Id: 'opt-d-ssd1tb', Feature__c: 'feat-d-stor', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-ssd1tb', Option_Type__c: 'Component', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 30 },

    /* ── Desktop → Input / Output / Cables (same products, different feature refs) ── */
    { Id: 'opt-d-kb',    Feature__c: 'feat-d-inp', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-kb01',    Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 2, Quantity_Editable__c: true, Sort_Order__c: 10 },
    { Id: 'opt-d-mouse', Feature__c: 'feat-d-inp', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-mouse01', Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 2, Quantity_Editable__c: true, Sort_Order__c: 20 },
    { Id: 'opt-d-mon24', Feature__c: 'feat-d-out', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-mon24',   Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 2, Quantity_Editable__c: true, Sort_Order__c: 10 },
    { Id: 'opt-d-mon27', Feature__c: 'feat-d-out', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-mon27',   Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 2, Quantity_Editable__c: true, Sort_Order__c: 20 },
    { Id: 'opt-d-hdmi',  Feature__c: 'feat-d-cab', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-hdmi',    Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 3, Quantity_Editable__c: true, Sort_Order__c: 10 },
    { Id: 'opt-d-dp',    Feature__c: 'feat-d-cab', Bundle_Product__c: 'prod-002', Option_Product__c: 'prod-dp',      Option_Type__c: 'Accessory', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 3, Quantity_Editable__c: true, Sort_Order__c: 20 },

    /* ── Copy Machine → Other Options (multi select) ── */
    { Id: 'opt-c-bind',   Feature__c: 'feat-c-opts', Bundle_Product__c: 'prod-003', Option_Product__c: 'prod-copybind',  Option_Type__c: 'Component',  Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 10 },
    { Id: 'opt-c-toner',  Feature__c: 'feat-c-opts', Bundle_Product__c: 'prod-003', Option_Product__c: 'prod-hitoner',   Option_Type__c: 'Component',  Is_Required__c: true,  Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 3, Quantity_Editable__c: true,  Sort_Order__c: 20 },
    { Id: 'opt-c-paper',  Feature__c: 'feat-c-opts', Bundle_Product__c: 'prod-003', Option_Product__c: 'prod-copypaper', Option_Type__c: 'Consumable',  Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 5, Min_Quantity__c: 1, Max_Quantity__c: 20, Quantity_Editable__c: true, Sort_Order__c: 30 },
    { Id: 'opt-c-tray',   Feature__c: 'feat-c-opts', Bundle_Product__c: 'prod-003', Option_Product__c: 'prod-copytray', Option_Type__c: 'Accessory',   Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 3, Quantity_Editable__c: true,  Sort_Order__c: 40 },

    /* ── LaserJet Printer → Consumables (multi select) ── */
    { Id: 'opt-p-toner',  Feature__c: 'feat-p-cons', Bundle_Product__c: 'prod-004', Option_Product__c: 'prod-toner',    Option_Type__c: 'Consumable', Is_Required__c: true,  Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 5, Quantity_Editable__c: true,  Sort_Order__c: 10 },
    { Id: 'opt-p-maint',  Feature__c: 'feat-p-cons', Bundle_Product__c: 'prod-004', Option_Product__c: 'prod-maintkit', Option_Type__c: 'Consumable', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 3, Quantity_Editable__c: true,  Sort_Order__c: 20 },
    { Id: 'opt-p-pa4',    Feature__c: 'feat-p-cons', Bundle_Product__c: 'prod-004', Option_Product__c: 'prod-papera4',  Option_Type__c: 'Consumable', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 10, Quantity_Editable__c: true, Sort_Order__c: 30 },
    { Id: 'opt-p-plt',    Feature__c: 'feat-p-cons', Bundle_Product__c: 'prod-004', Option_Product__c: 'prod-paperlt',  Option_Type__c: 'Consumable', Is_Required__c: false, Is_Selected__c: true,  Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 10, Quantity_Editable__c: true, Sort_Order__c: 40 },
    /* ── LaserJet Printer → Software (multi select) ── */
    { Id: 'opt-p-office', Feature__c: 'feat-p-sw',   Bundle_Product__c: 'prod-004', Option_Product__c: 'prod-office',    Option_Type__c: 'Related Product', Is_Required__c: false, Is_Selected__c: false, Default_Quantity__c: 1, Min_Quantity__c: 1, Max_Quantity__c: 1, Quantity_Editable__c: false, Sort_Order__c: 10 }
];

/* ─── Volume Pricing Schedules ─── */
export const VOLUME_PRICING_SCHEDULES = [
    { Id: 'vps-001', Product__c: 'prod-copypaper', Pricebook__c: null, Pricing_Type__c: 'Tiered', Is_Active__c: true, Overage_Rate__c: 80.00 }
];

/* ─── Volume Pricing Tiers ─── */
export const VOLUME_PRICING_TIERS = [
    { Id: 'vpt-001', Volume_Pricing_Schedule__c: 'vps-001', Lower_Bound__c: 1,  Upper_Bound__c: 5,   Price__c: 85.00, Sort_Order__c: 10 },
    { Id: 'vpt-002', Volume_Pricing_Schedule__c: 'vps-001', Lower_Bound__c: 6,  Upper_Bound__c: 15,  Price__c: 75.00, Sort_Order__c: 20 },
    { Id: 'vpt-003', Volume_Pricing_Schedule__c: 'vps-001', Lower_Bound__c: 16, Upper_Bound__c: 50,  Price__c: 65.00, Sort_Order__c: 30 }
];

/* ─── Product Rules ─── */
export const PRODUCT_RULES = [
    {
        Id: 'rule-001',
        Name: 'High-end CPU requires 16GB+ RAM',
        Type__c: 'Validation',
        Scope__c: 'Bundle',
        Evaluation_Event__c: 'Save',
        Conditions_Met__c: 'All',
        Advanced_Condition__c: null,
        Message__c: 'A CPU 3.4GHz or higher requires at least 16GB RAM.',
        Evaluation_Order__c: 10,
        Is_Active__c: true
    },
    {
        Id: 'rule-002',
        Name: 'Auto-add toner with printer',
        Type__c: 'Selection',
        Scope__c: 'Bundle',
        Evaluation_Event__c: 'Always',
        Conditions_Met__c: 'All',
        Advanced_Condition__c: null,
        Message__c: null,
        Evaluation_Order__c: 20,
        Is_Active__c: true
    }
];

/* ─── Rule Conditions ─── */
export const RULE_CONDITIONS = [
    { Id: 'rc-001', Product_Rule__c: 'rule-001', Tested_Object__c: 'Bundle_Option__c', Tested_Field__c: 'Option_Product__c.ProductCode', Operator__c: 'equals',       Filter_Type__c: 'Value', Filter_Value__c: 'CPU34GHZI7', Index__c: 1 },
    { Id: 'rc-002', Product_Rule__c: 'rule-002', Tested_Object__c: 'Product2',         Tested_Field__c: 'Family',                        Operator__c: 'equals',       Filter_Type__c: 'Value', Filter_Value__c: 'Hardware',    Index__c: 1 }
];

/* ─── Rule Actions ─── */
export const RULE_ACTIONS = [
    { Id: 'ra-001', Product_Rule__c: 'rule-002', Type__c: 'Add', Target_Product__c: 'prod-toner', Filter_Field__c: null, Filter_Operator__c: null, Filter_Value__c: null, Sort_Order__c: 10 }
];

/* ─── Bundle Rule Assignments ─── */
export const BUNDLE_RULE_ASSIGNMENTS = [
    { Id: 'bra-001', Bundle_Product__c: 'prod-002', Product_Rule__c: 'rule-001', Is_Active__c: true },
    { Id: 'bra-002', Bundle_Product__c: 'prod-004', Product_Rule__c: 'rule-002', Is_Active__c: true }
];

/* ─── Locations (for Logistics step) ─── */
export const LOCATIONS = [
    { Id: 'loc-001', Name: 'Paris Main Depot',     City: 'Paris',      Country: 'France',  IsActive: true, Type: 'Warehouse' },
    { Id: 'loc-002', Name: 'Lyon Agency',          City: 'Lyon',       Country: 'France',  IsActive: true, Type: 'Agency' },
    { Id: 'loc-003', Name: 'Marseille Office',     City: 'Marseille',  Country: 'France',  IsActive: true, Type: 'Office' },
    { Id: 'loc-004', Name: 'Brussels Warehouse',   City: 'Brussels',   Country: 'Belgium', IsActive: true, Type: 'Warehouse' },
    { Id: 'loc-005', Name: 'Client Site – Acme',   City: 'Nice',       Country: 'France',  IsActive: true, Type: 'Client Site' }
];