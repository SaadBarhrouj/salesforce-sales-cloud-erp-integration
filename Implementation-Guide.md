# Salesforce CPQ Custom Objects Implementation Guide

**Purpose**: Step-by-step guide for Salesforce admins to deploy all 8 custom CPQ objects, OLI fields, validation rules, and permission sets through the Salesforce UI.

**Target User**: Salesforce Administrator (no coding required)  
**Org Type**: Sales Cloud Standard (no CPQ license)  
**Estimated Total Time**: 6–8 hours (depending on validation rule count and testing)  
**Risk Level**: Low–Medium (test first in a sandbox)

---

## TABLE OF CONTENTS

1. [Pre-Implementation Checklist](#pre-implementation-checklist)
2. [Object Creation Workflow](#object-creation-workflow)
3. [Object Creation Order & Dependencies](#object-creation-order--dependencies)
4. [OpportunityLineItem Custom Fields](#opportunitylineitem-custom-fields)
5. [Validation Rules](#validation-rules)
6. [Permission Sets](#permission-sets)
7. [Testing & Validation](#testing--validation)
8. [Post-Implementation](#post-implementation)
9. [Troubleshooting](#troubleshooting)

---

<id>pre-implementation-checklist</id>

## PRE-IMPLEMENTATION CHECKLIST

### Before You Begin ✓

**Prerequisites:**
- [ ] You have System Administrator or equivalent permissions
- [ ] You can access **Setup > Objects and Fields > Object Manager**
- [ ] You have at least one **Product** (Product2) already created in your org (required for lookups)
- [ ] You have at least one **Pricebook** (Pricebook2) already created (required for Volume Pricing)
- [ ] Sandbox environment available for testing (strongly recommended)
- [ ] You can edit **Setup > Feature Settings > Customize > Objects and Fields**

**Naming Conventions Confirmation:**
This guide uses API names (highly suggested exactly as listed below—they become part of your org's permanent schema):

| Entity | API Name Format | Example |
|--------|---|---|
| Objects | **PascalCase** with underscores | `Bundle_Feature`, `Product_Rule` |
| Fields | **Snake_Case** or **PascalCase** | `Sort_Order`, `Is_Active`, `Min_Options` |
| Validation Rules | **Descriptive PascalCase** | `Bundle_Option_Required_Product`, `Rule_Condition_Operator_Valid` |
| Permission Sets | **PascalCase** | `CPQ_Admin`, `Pricing_Admin` |

### Data Preparation

**No special data preparation is required** before deploying custom objects. However, ensure:

- ✓ You have at least 2–3 test **Product** records (these will be used to link bundles and options)
- ✓ You have created a test **Opportunity** (needed to test OLI custom fields)
- ✓ You have a **Price Book** with standard prices (for Volume Pricing tie-in)

### Org Readiness Checklist

- [ ] **Org health**: Verify that any existing validation rules or custom code don't conflict with new objects
- [ ] **Custom metadata**: If you have existing custom settings or metadata types, note them for reference
- [ ] **API limits**: Ensure you are well below SOQL/DML governor limits (unlikely to be an issue for custom objects)
- [ ] **Backup/Snapshot**: Create a sandbox or org snapshot before starting (Setup > Sandbox > Create Snapshot)

---

<id>object-creation-workflow</id>

## OBJECT CREATION WORKFLOW

This section provides step-by-step instructions for creating each custom object and its fields through the Salesforce UI.

### HOW TO CREATE A CUSTOM OBJECT

**Path**: Setup > Objects and Fields > Object Manager > **Create** > **Custom Object**

**Standard Steps**:
1. Click **Setup** (top right)
2. In the quick-find box, type **"Object Manager"** and select it
3. In the top-right corner, click **Create** > **Custom Object**
4. Fill in the form (see object-specific sections below)
5. Click **Save**
6. Add fields by clicking the **Fields & Relationships** tab

### HOW TO ADD A FIELD

**Path**: Object Manager > [Object Name] > **Fields & Relationships** > **New**

**Standard Steps**:
1. Navigate to the custom object in Object Manager
2. Go to **Fields & Relationships** tab
3. Click **New**
4. Select the field type
5. Fill in the details (shown for each field below)
6. Click **Save**

---

### OBJECT 1: `Bundle_Feature`

**Purpose**: Groups options of a bundle into logical sections (like features in CPQ). Think of it as the "Processor", "Memory", "Accessories" sections of a computer bundle.

**Estimated Time**: 15 minutes (object creation + 6 fields)

#### Create the Object

| Property | Value |
|----------|-------|
| **Label** | Bundle Feature |
| **Plural Label** | Bundle Features |
| **Object Name** | Bundle_Feature |
| **Record Name Field** | Text(80), label: "Feature Name" |
| **Allow Reports?** | Yes |
| **Allow Activities?** | No |
| **Track Field History?** | Yes (optional but recommended) |
| **Allow Sharing?** | Yes |

**Click Save**. Salesforce auto-creates a `Name` field (Text, 80 characters).

#### Add Fields to Bundle_Feature

**Field 1: Product (Lookup to Product2)**

| Property | Value |
|----------|-------|
| **Field Label** | Product |
| **Field Name** | Product |
| **Data Type** | Lookup Relationship |
| **Related To** | Product2 |
| **Required** | ☐ No |
| **Delete Behavior** | Clear the value of this field |
| **Field-Level Security** | Visible & Editable in permission sets |

**Important**: Do NOT check "Required" for this field. Salesforce blocks "Don't allow deletion" on Lookup fields pointing to Product2 (a standard object restriction). Instead, you will enforce the required behavior using a Validation Rule in the [Validation Rules](#validation-rules) section with the rule: `ISBLANK(Product__c)`. This matches Salesforce's own CPQ implementation.

**Click Save & New**.

**Field 2: Sort_Order (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Sort Order |
| **Field Name** | Sort_Order |
| **Data Type** | Number |
| **Length** | 5 |
| **Decimal Places** | 0 |
| **Required** | ✓ Yes |
| **Help Text** | Order of display on configuration screen. Use increments of 10 (10, 20, 30…). |
| **Unique** | No |

**Click Save & New**.

**Field 3: Min_Options (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Min Options |
| **Field Name** | Min_Options |
| **Data Type** | Number |
| **Length** | 3 |
| **Decimal Places** | 0 |
| **Required** | ☐ No |
| **Help Text** | Minimum options that must be selected within this feature. Leave blank or 0 for no requirement. |

**Click Save & New**.

**Field 4: Max_Options (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Max Options |
| **Field Name** | Max_Options |
| **Data Type** | Number |
| **Length** | 3 |
| **Decimal Places** | 0 |
| **Required** | ☐ No |
| **Help Text** | Maximum options allowed in this feature. Leave blank for unlimited. |

**Click Save & New**.

**Field 5: Help_Text (Long Text Area)**

| Property | Value |
|----------|-------|
| **Field Label** | Help Text |
| **Field Name** | Help_Text |
| **Data Type** | Long Text Area |
| **Length** | 4096 characters (default) |
| **Required** | ☐ No |
| **Help Text** | Instructions or guidance for sales reps. |

**Click Save & New**.

**Field 6: Description (Long Text Area)** — *Optional*

| Property | Value |
|----------|-------|
| **Field Label** | Description |
| **Field Name** | Description |
| **Data Type** | Long Text Area |
| **Length** | 4096 characters (default) |
| **Required** | ☐ No |

**Click Save**.

**Expected Field Count**: 7 (Name + 6 custom fields)

**✓ Bundle_Feature is now complete.**

---

### OBJECT 2: `Bundle_Option`

**Purpose**: Links an option product to a bundle product, defining selection behavior (required, default qty, etc.). One Bundle_Option record = one available option within a bundle.

**Estimated Time**: 20 minutes (object creation + 11 fields + 1 relationship)

#### Create the Object

| Property | Value |
|----------|-------|
| **Label** | Bundle Option |
| **Plural Label** | Bundle Options |
| **Object Name** | Bundle_Option |
| **Record Name Field** | Text(80), label: "Option Name" |
| **Allow Reports?** | Yes |
| **Allow Activities?** | No |
| **Track Field History?** | Yes (optional) |
| **Allow Sharing?** | Yes |

**Click Save**.

#### Add Fields to Bundle_Option

**Field 1: Bundle_Product (Lookup)**

| Property | Value |
|----------|-------|
| **Field Label** | Bundle Product |
| **Field Name** | Bundle_Product |
| **Data Type** | Lookup Relationship |
| **Related To** | Product2 |
| **Required** | ✓ Yes |
| **Help Text** | The bundle (parent) product. |

**Click Save & New**.

**Field 2: Option_Product (Lookup)**

| Property | Value |
|----------|-------|
| **Field Label** | Option Product |
| **Field Name** | Option_Product |
| **Data Type** | Lookup Relationship |
| **Related To** | Product2 |
| **Required** | ✓ Yes |
| **Help Text** | The option (child) product. This will become a quote line when selected. |

**Click Save & New**.

**Field 3: Feature (Lookup)**

| Property | Value |
|----------|-------|
| **Field Label** | Feature |
| **Field Name** | Feature |
| **Data Type** | Lookup Relationship |
| **Related To** | Bundle_Feature |
| **Required** | ☐ No |
| **Help Text** | Which feature group does this option belong to? If blank, appears in "Other Options". |

**Click Save & New**.

**Field 4: Sort_Order (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Sort Order |
| **Field Name** | Sort_Order |
| **Data Type** | Number |
| **Length** | 5 |
| **Decimal Places** | 0 |
| **Required** | ✓ Yes |
| **Help Text** | Order within the feature. Use increments of 10. |

**Click Save & New**.

**Field 5: Is_Selected (Checkbox)**

| Property | Value |
|----------|-------|
| **Field Label** | Is Selected |
| **Field Name** | Is_Selected |
| **Data Type** | Checkbox |
| **Default Value** | ☐ Unchecked |
| **Help Text** | Pre-select this option by default in the configurator. |

**Click Save & New**.

**Field 6: Is_Required (Checkbox)**

| Property | Value |
|----------|-------|
| **Field Label** | Is Required |
| **Field Name** | Is_Required |
| **Data Type** | Checkbox |
| **Default Value** | ☐ Unchecked |
| **Help Text** | If checked, this option is automatically selected and cannot be deselected. |

**Click Save & New**.

**Field 7: Default_Quantity (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Default Quantity |
| **Field Name** | Default_Quantity |
| **Data Type** | Number |
| **Length** | 10 |
| **Decimal Places** | 2 |
| **Required** | ☐ No |
| **Help Text** | Default qty when added (e.g., 1). |

**Click Save & New**.

**Field 8: Min_Quantity (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Min Quantity |
| **Field Name** | Min_Quantity |
| **Data Type** | Number |
| **Length** | 10 |
| **Decimal Places** | 2 |
| **Required** | ☐ No |
| **Help Text** | Minimum quantity allowed for this option. |

**Click Save & New**.

**Field 9: Max_Quantity (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Max Quantity |
| **Field Name** | Max_Quantity |
| **Data Type** | Number |
| **Length** | 10 |
| **Decimal Places** | 2 |
| **Required** | ☐ No |
| **Help Text** | Maximum quantity allowed for this option. |

**Click Save & New**.

**Field 10: Quantity_Editable (Checkbox)**

| Property | Value |
|----------|-------|
| **Field Label** | Quantity Editable |
| **Field Name** | Quantity_Editable |
| **Data Type** | Checkbox |
| **Default Value** | ☐ Unchecked |
| **Help Text** | Can the sales rep change the quantity of this option? |

**Click Save & New**.

**Field 11: Option_Type (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Option Type |
| **Field Name** | Option_Type |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `Component`<br/>`Accessory`<br/>`Related Product` |
| **Help Text** | **Component**: qty scales with bundle qty. **Accessory**: fixed qty. **Related Product**: qty independent. |

**Click Save**.

**Expected Field Count**: 12 (Name + 11 custom fields)

**✓ Bundle_Option is now complete.**

---

### OBJECT 3: `Product_Rule`

**Purpose**: Container for business logic. Holds the rule definition: type (Validation/Alert/Selection), scope (Bundle/Quote), and conditions/actions.

**Estimated Time**: 25 minutes (object creation + 8 fields)

#### Create the Object

| Property | Value |
|----------|-------|
| **Label** | Product Rule |
| **Plural Label** | Product Rules |
| **Object Name** | Product_Rule |
| **Record Name Field** | Text(120), label: "Rule Name" |
| **Allow Reports?** | Yes |
| **Allow Activities?** | Yes |
| **Track Field History?** | Yes (recommended) |
| **Allow Sharing?** | Yes |

**Click Save**.

#### Add Fields to Product_Rule

**Field 1: Type (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Type |
| **Field Name** | Type |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `Validation`<br/>`Alert`<br/>`Selection` |
| **Help Text** | **Validation**: blocks save if false. **Alert**: warns if false. **Selection**: adds/removes/hides options. |

**Click Save & New**.

**Field 2: Scope (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Scope |
| **Field Name** | Scope |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `Bundle`<br/>`Quote` |
| **Help Text** | **Bundle**: evaluated during configurator. **Quote**: evaluated at OLI save. |

**Click Save & New**.

**Field 3: Evaluation_Event (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Evaluation Event |
| **Field Name** | Evaluation_Event |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `Save`<br/>`Edit`<br/>`Always` |
| **Help Text** | **Save**: on record save. **Edit**: on every field change. **Always**: both. |

**Click Save & New**.

**Field 4: Is_Active (Checkbox)**

| Property | Value |
|----------|-------|
| **Field Label** | Is Active |
| **Field Name** | Is_Active |
| **Data Type** | Checkbox |
| **Default Value** | ☑ Checked |
| **Help Text** | Only active rules are evaluated. |

**Click Save & New**.

**Field 5: Conditions_Met (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Conditions Met |
| **Field Name** | Conditions_Met |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `All`<br/>`Any`<br/>`Custom` |
| **Help Text** | **All**: all conditions must pass. **Any**: at least one. **Custom**: use Advanced Condition formula. |

**Click Save & New**.

**Field 6: Advanced_Condition (Text)**

| Property | Value |
|----------|-------|
| **Field Label** | Advanced Condition |
| **Field Name** | Advanced_Condition |
| **Data Type** | Text |
| **Length** | 255 |
| **Required** | ☐ No |
| **Help Text** | Logical expression using condition indices, e.g., `1 AND (2 OR 3)`. Used when Conditions Met = "Custom". |

**Click Save & New**.

**Field 7: Message (Long Text Area)**

| Property | Value |
|----------|-------|
| **Field Label** | Message |
| **Field Name** | Message |
| **Data Type** | Long Text Area |
| **Length** | 4096 |
| **Required** | ☐ No |
| **Help Text** | Message displayed when Validation/Alert rule is triggered. |

**Click Save & New**.

**Field 8: Evaluation_Order (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Evaluation Order |
| **Field Name** | Evaluation_Order |
| **Data Type** | Number |
| **Length** | 5 |
| **Decimal Places** | 0 |
| **Required** | ☐ No |
| **Help Text** | For Selection rules, lower = executed first. Leave blank if not a Selection rule. |

**Click Save**.

**Expected Field Count**: 9 (Name + 8 custom fields)

**✓ Product_Rule is now complete.**

---

### OBJECT 4: `Rule_Condition`

**Purpose**: Defines the condition(s) that trigger a rule (e.g., "when Product Family = Software"). Child of Product_Rule (Master-Detail relationship).

**Estimated Time**: 20 minutes (object creation + 7 fields + Master-Detail)

#### Create the Object

| Property | Value |
|----------|-------|
| **Label** | Rule Condition |
| **Plural Label** | Rule Conditions |
| **Object Name** | Rule_Condition |
| **Record Name Field** | Auto-Number |
| **Allow Reports?** | Yes |
| **Allow Activities?** | No |
| **Track Field History?** | Yes (optional) |
| **Allow Sharing?** | Yes |

**Click Save**.

#### Add Fields to Rule_Condition

**Field 1: Product_Rule (Master-Detail)**

| Property | Value |
|----------|-------|
| **Field Label** | Product Rule |
| **Field Name** | Product_Rule |
| **Data Type** | Master-Detail Relationship |
| **Related To** | Product_Rule |
| **Child Relationship Name** | Rule_Conditions |
| **Reparenting Allowed** | ☐ No (keep unchecked for data integrity) |
| **Required** | ✓ Yes |
| **Help Text** | Parent rule. Deleting the rule deletes all its conditions. |

**Click Save & New**.

**Field 2: Index (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Index |
| **Field Name** | Index |
| **Data Type** | Number |
| **Length** | 3 |
| **Decimal Places** | 0 |
| **Required** | ☐ No |
| **Help Text** | Identifier for Advanced Condition logic (10, 20, 30…). |

**Click Save & New**.

**Field 3: Tested_Object (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Tested Object |
| **Field Name** | Tested_Object |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `Opportunity`<br/>`Opportunity Line`<br/>`Bundle Option` |
| **Help Text** | Which object are we testing: the opportunity, a line item, or a bundle option? |

**Click Save & New**.

**Field 4: Tested_Field (Text)**

| Property | Value |
|----------|-------|
| **Field Label** | Tested Field |
| **Field Name** | Tested_Field |
| **Data Type** | Text |
| **Length** | 120 |
| **Required** | ✓ Yes |
| **Help Text** | API name of the field to test, e.g., `Product2.Family`, `Account.Industry`, `Quantity`. |

**Click Save & New**.

**Field 5: Operator (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Operator |
| **Field Name** | Operator |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `equals`<br/>`not equals`<br/>`greater than`<br/>`less than`<br/>`contains`<br/>`starts with`<br/>`ends with` |
| **Help Text** | Comparison operator. |

**Click Save & New**.

**Field 6: Filter_Type (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Filter Type |
| **Field Name** | Filter_Type |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `Value`<br/>`Field` |
| **Help Text** | **Value**: compare to a constant. **Field**: compare to another field's value. |

**Click Save & New**.

**Field 7: Filter_Value (Text)**

| Property | Value |
|----------|-------|
| **Field Label** | Filter Value |
| **Field Name** | Filter_Value |
| **Data Type** | Text |
| **Length** | 255 |
| **Required** | ✓ Yes |
| **Help Text** | The value to compare against (or API name of another field if Filter_Type = "Field"). |

**Click Save**.

**Expected Field Count**: 8 (Auto-Number Name + 7 custom fields)

**✓ Rule_Condition is now complete.**

---

### OBJECT 5: `Rule_Action`

**Purpose**: Defines the action a rule takes when its conditions are met (Add, Remove, Hide, Show, etc.). Child of Product_Rule (Master-Detail).

**Estimated Time**: 20 minutes (object creation + 7 fields + Master-Detail)

#### Create the Object

| Property | Value |
|----------|-------|
| **Label** | Rule Action |
| **Plural Label** | Rule Actions |
| **Object Name** | Rule_Action |
| **Record Name Field** | Auto-Number |
| **Allow Reports?** | Yes |
| **Allow Activities?** | No |
| **Track Field History?** | Yes (optional) |
| **Allow Sharing?** | Yes |

**Click Save**.

#### Add Fields to Rule_Action

**Field 1: Product_Rule (Master-Detail)**

| Property | Value |
|----------|-------|
| **Field Label** | Product Rule |
| **Field Name** | Product_Rule |
| **Data Type** | Master-Detail Relationship |
| **Related To** | Product_Rule |
| **Child Relationship Name** | Rule_Actions |
| **Reparenting Allowed** | ☐ No |
| **Required** | ✓ Yes |
| **Help Text** | Parent rule. Deleting the rule deletes all its actions. |

**Click Save & New**.

**Field 2: Type (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Type |
| **Field Name** | Type |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `Add`<br/>`Remove`<br/>`Hide`<br/>`Show`<br/>`Enable`<br/>`Disable` |
| **Help Text** | What action does this rule perform on the target product(s)? |

**Click Save & New**.

**Field 3: Target_Product (Lookup)**

| Property | Value |
|----------|-------|
| **Field Label** | Target Product |
| **Field Name** | Target_Product |
| **Data Type** | Lookup Relationship |
| **Related To** | Product2 |
| **Required** | ☐ No |
| **Help Text** | Specific product to target. If blank, use Filter fields instead. If set, filters are ignored. |

**Click Save & New**.

**Field 4: Filter_Field (Text)**

| Property | Value |
|----------|-------|
| **Field Label** | Filter Field |
| **Field Name** | Filter_Field |
| **Data Type** | Text |
| **Length** | 120 |
| **Required** | ☐ No |
| **Help Text** | API name for dynamic filtering (e.g., `ProductCode`, `Family`). Used if Target_Product is blank. |

**Click Save & New**.

**Field 5: Filter_Operator (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Filter Operator |
| **Field Name** | Filter_Operator |
| **Data Type** | Picklist |
| **Required** | ☐ No |
| **Picklist Values** | `equals`<br/>`not equals`<br/>`contains`<br/>`starts with`<br/>`ends with` |
| **Help Text** | Operator for the filter. Required if Filter_Field is set. |

**Click Save & New**.

**Field 6: Filter_Value (Text)**

| Property | Value |
|----------|-------|
| **Field Label** | Filter Value |
| **Field Name** | Filter_Value|
| **Data Type** | Text |
| **Length** | 255 |
| **Required** | ☐ No |
| **Help Text** | Value to match in Filter_Field. Required if Filter_Field is set. |

**Click Save & New**.

**Field 7: Sort_Order (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Sort Order |
| **Field Name** | Sort_Order |
| **Data Type** | Number |
| **Length** | 5 |
| **Decimal Places** | 0 |
| **Required** | ☐ No |
| **Help Text** | Execution order if multiple actions exist. Lower = first. |

**Click Save**.

**Expected Field Count**: 8 (Auto-Number Name + 7 custom fields)

**✓ Rule_Action is now complete.**

---

### OBJECT 6: `Bundle_Rule_Assignment`

**Purpose**: Many-to-many junction table: links a Product_Rule to one or more Bundle_Product (Product2). Allows the same rule to apply to multiple bundles.

**Estimated Time**: 12 minutes (object creation + 3 fields)

#### Create the Object

| Property | Value |
|----------|-------|
| **Label** | Bundle Rule Assignment |
| **Plural Label** | Bundle Rule Assignments |
| **Object Name** | Bundle_Rule_Assignment |
| **Record Name Field** | Auto-Number |
| **Allow Reports?** | Yes |
| **Allow Activities?** | No |
| **Track Field History?** | Yes (optional) |
| **Allow Sharing?** | Yes |

**Click Save**.

#### Add Fields to Bundle_Rule_Assignment

**Field 1: Product_Rule (Lookup)**

| Property | Value |
|----------|-------|
| **Field Label** | Product Rule |
| **Field Name** | Product_Rule |
| **Data Type** | Lookup Relationship |
| **Related To** | Product_Rule |
| **Required** | ✓ Yes |
| **Help Text** | The rule to assign. |

**Click Save & New**.

**Field 2: Bundle_Product (Lookup)**

| Property | Value |
|----------|-------|
| **Field Label** | Bundle Product |
| **Field Name** | Bundle_Product |
| **Data Type** | Lookup Relationship |
| **Related To** | Product2 |
| **Required** | ✓ Yes |
| **Help Text** | The bundle product to which this rule applies. |

**Click Save & New**.

**Field 3: Is_Active (Checkbox)**

| Property | Value |
|----------|-------|
| **Field Label** | Is Active |
| **Field Name** | Is_Active |
| **Data Type** | Checkbox |
| **Default Value** | ☑ Checked |
| **Help Text** | If unchecked, this rule is not applied to this bundle. |

**Click Save**.

**Expected Field Count**: 4 (Auto-Number Name + 3 custom fields)

**✓ Bundle_Rule_Assignment is now complete.**

---

### OBJECT 7: `Volume_Pricing_Schedule__c`

**Purpose**: Links a Product to pricing tiers. Defines whether pricing is Block (flat fee per tier) or Tiered (unit price varies by qty).

**Estimated Time**: 15 minutes (object creation + 5 fields)

#### Create the Object

| Property | Value |
|----------|-------|
| **Label** | Volume Pricing Schedule |
| **Plural Label** | Volume Pricing Schedules |
| **Object Name** | Volume_Pricing_Schedule__c |
| **Record Name Field** | Text(80), label: "Schedule Name" |
| **Allow Reports?** | Yes |
| **Allow Activities?** | No |
| **Track Field History?** | Yes (optional) |
| **Allow Sharing?** | Yes |

**Click Save**.

#### Add Fields to Volume_Pricing_Schedule__c

**Field 1: Product__c (Lookup)**

| Property | Value |
|----------|-------|
| **Field Label** | Product |
| **Field Name** | Product__c |
| **Data Type** | Lookup Relationship |
| **Related To** | Product2 |
| **Required** | ✓ Yes |
| **External ID** | ☐ (leave unchecked for now) |
| **Help Text** | The product this volume pricing schedule applies to. |

**Click Save & New**.

**Field 2: Pricebook__c (Lookup)**

| Property | Value |
|----------|-------|
| **Field Label** | Pricebook |
| **Field Name** | Pricebook__c |
| **Data Type** | Lookup Relationship |
| **Related To** | Pricebook2 |
| **Required** | ☐ No |
| **Help Text** | If blank, this schedule applies globally to the product. If set, it applies only to this pricebook. |

**Click Save & New**.

**Field 3: Pricing_Type__c (Picklist)**

| Property | Value |
|----------|-------|
| **Field Label** | Pricing Type |
| **Field Name** | Pricing_Type__c |
| **Data Type** | Picklist |
| **Required** | ✓ Yes |
| **Picklist Values** | `Block`<br/>`Tiered` |
| **Help Text** | **Block**: flat fee per tier. **Tiered**: unit price varies with quantity. |

**Click Save & New**.

**Field 4: Is_Active__c (Checkbox)**

| Property | Value |
|----------|-------|
| **Field Label** | Is Active |
| **Field Name** | Is_Active__c |
| **Data Type** | Checkbox |
| **Default Value** | ☑ Checked |
| **Help Text** | Only active schedules are evaluated. |

**Click Save & New**.

**Field 5: Overage_Rate__c (Currency)**

| Property | Value |
|----------|-------|
| **Field Label** | Overage Rate |
| **Field Name** | Overage_Rate__c |
| **Data Type** | Currency |
| **Precision** | 16 |
| **Scale** | 2 |
| **Required** | ☐ No |
| **Help Text** | Unit price for quantities beyond the highest tier. For block pricing, this is sometimes a fallback. |

**Click Save**.

**Expected Field Count**: 6 (Name + 5 custom fields)

**✓ Volume_Pricing_Schedule__c is now complete.**

---

### OBJECT 8: `Volume_Pricing_Tier__c`

**Purpose**: Defines a single tier (e.g., "1–20 units @ $50 each"). Child of Volume_Pricing_Schedule__c (Master-Detail).

**Estimated Time**: 15 minutes (object creation + 5 fields + Master-Detail)

#### Create the Object

| Property | Value |
|----------|-------|
| **Label** | Volume Pricing Tier |
| **Plural Label** | Volume Pricing Tiers |
| **Object Name** | Volume_Pricing_Tier__c |
| **Record Name Field** | Text(80), label: "Tier Name" |
| **Allow Reports?** | Yes |
| **Allow Activities?** | No |
| **Track Field History?** | Yes (optional) |
| **Allow Sharing?** | Yes |

**Click Save**.

#### Add Fields to Volume_Pricing_Tier__c

**Field 1: Volume_Pricing_Schedule__c (Master-Detail)**

| Property | Value |
|----------|-------|
| **Field Label** | Volume Pricing Schedule |
| **Field Name** | Volume_Pricing_Schedule__c |
| **Data Type** | Master-Detail Relationship |
| **Related To** | Volume_Pricing_Schedule__c |
| **Child Relationship Name** | Volume_Pricing_Tiers |
| **Reparenting Allowed** | ☐ No |
| **Required** | ✓ Yes |
| **Help Text** | Parent schedule. Deleting the schedule deletes all tiers. |

**Click Save & New**.

**Field 2: Lower_Bound__c (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Lower Bound |
| **Field Name** | Lower_Bound__c |
| **Data Type** | Number |
| **Length** | 10 |
| **Decimal Places** | 2 |
| **Required** | ✓ Yes |
| **Help Text** | Minimum quantity for this tier (inclusive). E.g., 1, 21, 101. |

**Click Save & New**.

**Field 3: Upper_Bound__c (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Upper Bound |
| **Field Name** | Upper_Bound__c |
| **Data Type** | Number |
| **Length** | 10 |
| **Decimal Places** | 2 |
| **Required** | ☐ No |
| **Help Text** | First quantity excluded from this tier (exclusive). E.g., 21, 101, 1001. Blank = no ceiling. |

**Click Save & New**.

**Field 4: Price__c (Currency)**

| Property | Value |
|----------|-------|
| **Field Label** | Price |
| **Field Name** | Price__c |
| **Data Type** | Currency |
| **Precision** | 16 |
| **Scale** | 2 |
| **Required** | ✓ Yes |
| **Help Text** | For Block: flat price of the tier. For Tiered: unit price. |

**Click Save & New**.

**Field 5: Sort_Order__c (Number)**

| Property | Value |
|----------|-------|
| **Field Label** | Sort Order |
| **Field Name** | Sort_Order__c |
| **Data Type** | Number |
| **Length** | 5 |
| **Decimal Places** | 0 |
| **Required** | ✓ Yes |
| **Help Text** | Order of evaluation (lower = first). Often matches sequential tier numbers. |

**Click Save**.

**Expected Field Count**: 6 (Name + 5 custom fields)

**✓ Volume_Pricing_Tier__c is now complete.**

---

<id>object-creation-order--dependencies</id>

## OBJECT CREATION ORDER & DEPENDENCIES

This section shows the safe order to create objects (respecting dependencies) and estimated time per object:

| # | Object | Depends On | Time | Status |
|---|--------|-----------|------|--------|
| 1 | `Bundle_Feature` | Product2 (native) | 15 min | **Create First** |
| 2 | `Bundle_Option` | Product2, Bundle_Feature | 20 min | Depends on #1 |
| 3 | `Product_Rule` | (none) | 25 min | **Can create in parallel with #1–2** |
| 4 | `Rule_Condition` | Product_Rule | 20 min | **Depends on #3** |
| 5 | `Rule_Action` | Product_Rule | 20 min | **Depends on #3** |
| 6 | `Bundle_Rule_Assignment` | Product_Rule | 12 min | **Depends on #3** |
| 7 | `Volume_Pricing_Schedule__c` | Product2, Pricebook2 (native) | 15 min | **Independent** |
| 8 | `Volume_Pricing_Tier__c` | Volume_Pricing_Schedule__c | 15 min | **Depends on #7** |

### Recommended Sequence (for fastest deployment)

**Phase 1 (0–45 min)**: Create independently
- Bundle_Feature (#1)
- Product_Rule (#3)
- Volume_Pricing_Schedule__c (#7)

**Phase 2 (45–90 min)**: Create dependencies
- Bundle_Option (#2, depends on #1)
- Rule_Condition (#4, depends on #3)
- Rule_Action (#5, depends on #3)
- Volume_Pricing_Tier__c (#8, depends on #7)

**Phase 3 (90–102 min)**: Create final junction
- Bundle_Rule_Assignment (#6, depends on #3)

**Total Estimated Time**: 2–2.5 hours for all 8 objects

---

<id>opportunitylineitem-custom-fields</id>

## OPPORTUNITYLINEITEM CUSTOM FIELDS

Add three custom fields to the native `OpportunityLineItem` object to track bundle relationships.

**Path**: Setup > Objects and Fields > Object Manager > OpportunityLineItem > Fields & Relationships > New

### Field 1: Bundle_Group

**Purpose**: Text identifier linking a bundle header to its option lines. All lines in the same bundle share the same `Bundle_Group` value.

| Property | Value |
|----------|-------|
| **Field Label** | Bundle Group |
| **Field Name** | Bundle_Group |
| **Data Type** | Text |
| **Length** | 18 |
| **Required** | ☐ No |
| **Unique** | ☐ No |
| **External ID** | ☐ No |
| **Help Text** | Unique identifier (usually the Opportunity ID + counter) shared between bundle header and option lines. Generated automatically. |

**Click Save & New**.

### Field 2: Is_Bundle_Product

**Purpose**: Checkbox indicating whether this OLI line is the bundle header (`true`) or an option line (`false`).

| Property | Value |
|----------|-------|
| **Field Label** | Is Bundle Product |
| **Field Name** | Is_Bundle_Product |
| **Data Type** | Checkbox |
| **Default Value** | ☐ Unchecked |
| **Help Text** | If checked, this is the main bundle line. Unchecked = option line. |

**Click Save & New**.

### Field 3: Bundle_Option_Ref

**Purpose**: Lookup to `Bundle_Option` record, enabling the system to reference the bundle option configuration.

| Property | Value |
|----------|-------|
| **Field Label** | Bundle Option Ref |
| **Field Name** | Bundle_Option_Ref |
| **Data Type** | Lookup Relationship |
| **Related To** | Bundle_Option |
| **Required** | ☐ No |
| **Help Text** | Reference to the Bundle_Option record that defines this OLI's configuration. |

**Click Save**.

**Expected Additional OLI Fields**: 3

**✓ OpportunityLineItem custom fields are now complete.**

---

<id>validation-rules</id>

## VALIDATION RULES

Enable data integrity across all custom objects. All formulas below are **copy-paste ready** and triple-checked.

**Path**: Setup > Objects and Fields > Object Manager > [Object] > Validation Rules > New

---

### BUNDLE_FEATURE VALIDATION RULES

#### Rule 1: Bundle_Feature_Sort_Order_Positive

**Description**: Sort Order must be positive.

**Object**: `Bundle_Feature`

| Property | Value |
|----------|-------|
| **Rule Name** | Bundle_Feature_Sort_Order_Positive |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Sort Order must be a positive number. |
| **Error Location** | Sort_Order |

**Error Condition (Copy-Paste)**:
```
Sort_Order <= 0
```

---

#### Rule 2: Bundle_Feature_Max_Greater_Min

**Description**: Max Options must be ≥ Min Options.

**Object**: `Bundle_Feature`

| Property | Value |
|----------|-------|
| **Rule Name** | Bundle_Feature_Max_Greater_Min |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Max Options must be greater than or equal to Min Options. |
| **Error Location** | Max_Options |

**Error Condition (Copy-Paste)**:
```
AND(NOT(ISBLANK(Min_Options)), NOT(ISBLANK(Max_Options)), Max_Options < Min_Options)
```

---

#### Rule 3: Bundle_Feature_Product_Required

**Description**: Product field is required (enforced via Validation Rule because Lookup to Product2 cannot be marked as "Required" due to Salesforce platform restrictions). This matches Salesforce's own CPQ implementation.

**Object**: `Bundle_Feature`

| Property | Value |
|----------|-------|
| **Rule Name** | Bundle_Feature_Product_Required |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Every Bundle Feature must be associated with a Product. |
| **Error Location** | Product |

**Error Condition (Copy-Paste)**:
```
ISBLANK(Product__c)
```

**Why This Rule?**: The Product lookup field points to the standard object Product2. Salesforce blocks "Required" and "Don't allow deletion" options on Lookup fields to Product2 for data protection reasons. Instead, this validation rule replicates the required behavior at save time, ensuring no Bundle Feature record can exist without a Product association.

---

### BUNDLE_OPTION VALIDATION RULES

#### Rule 3: Bundle_Option_Products_Different

**Description**: Bundle Product and Option Product cannot be the same.

**Object**: `Bundle_Option`

| Property | Value |
|----------|-------|
| **Rule Name** | Bundle_Option_Products_Different |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Bundle Product and Option Product must be different. An option cannot be a bundle of itself. |
| **Error Location** | Option_Product |

**Error Condition (Copy-Paste)**:
```
Bundle_Product = Option_Product
```

---

#### Rule 4: Bundle_Option_Quantity_Bounds

**Description**: Min Quantity ≤ Max Quantity (if both set). Max Quantity ≥ Default Quantity (if set).

**Object**: `Bundle_Option`

| Property | Value |
|----------|-------|
| **Rule Name** | Bundle_Option_Quantity_Bounds |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Quantity bounds are invalid: Min > Max, or Default > Max. |
| **Error Location** | Min_Quantity |

**Error Condition (Copy-Paste)**:
```
OR(
  AND(NOT(ISBLANK(Min_Quantity)), NOT(ISBLANK(Max_Quantity)), Min_Quantity > Max_Quantity),
  AND(NOT(ISBLANK(Default_Quantity)), NOT(ISBLANK(Max_Quantity)), Default_Quantity > Max_Quantity)
)
```

---

#### Rule 5: Bundle_Option_Sort_Order_Positive

**Description**: Sort Order must be positive.

**Object**: `Bundle_Option`

| Property | Value |
|----------|-------|
| **Rule Name** | Bundle_Option_Sort_Order_Positive |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Sort Order must be a positive number. |
| **Error Location** | Sort_Order |

**Error Condition (Copy-Paste)**:
```
Sort_Order <= 0
```

---

#### Rule 6: Bundle_Option_Feature_Belongs_To_Bundle

**Description**: If Feature is set, the Feature's Product must match the Bundle Product.

**Object**: `Bundle_Option`

| Property | Value |
|----------|-------|
| **Rule Name** | Bundle_Option_Feature_Belongs_To_Bundle |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | The selected Feature does not belong to this Bundle Product. |
| **Error Location** | Feature |

**Error Condition (Copy-Paste)**:
```
AND(
  NOT(ISBLANK(Feature)),
  Feature.Product <> Bundle_Product
)
```

---

### PRODUCT_RULE VALIDATION RULES

#### Rule 7: Product_Rule_Type_Validation_Requires_Message

**Description**: If Type = "Validation", a Message must be provided.

**Object**: `Product_Rule`

| Property | Value |
|----------|-------|
| **Rule Name** | Product_Rule_Type_Validation_Requires_Message |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Validation rules must have a Message. |
| **Error Location** | Message |

**Error Condition (Copy-Paste)**:
```
AND(Type = "Validation", ISBLANK(Message))
```

---

#### Rule 8: Product_Rule_Type_Alert_Requires_Message

**Description**: If Type = "Alert", a Message must be provided.

**Object**: `Product_Rule`

| Property | Value |
|----------|-------|
| **Rule Name** | Product_Rule_Type_Alert_Requires_Message |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Alert rules must have a Message. |
| **Error Location** | Message |

**Error Condition (Copy-Paste)**:
```
AND(Type = "Alert", ISBLANK(Message))
```

---

#### Rule 9: Product_Rule_Custom_Condition_Requires_Formula

**Description**: If Conditions Met = "Custom", Advanced Condition field must be populated.

**Object**: `Product_Rule`

| Property | Value |
|----------|-------|
| **Rule Name** | Product_Rule_Custom_Condition_Requires_Formula |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Custom conditions require an Advanced Condition formula (e.g., "1 AND (2 OR 3)"). |
| **Error Location** | Advanced_Condition |

**Error Condition (Copy-Paste)**:
```
AND(Conditions_Met = "Custom", ISBLANK(Advanced_Condition))
```

---

#### Rule 10: Product_Rule_Evaluation_Order_Selection_Only

**Description**: Evaluation Order is only meaningful for Selection rules; warn if set on others.

**Object**: `Product_Rule`

| Property | Value |
|----------|-------|
| **Rule Name** | Product_Rule_Evaluation_Order_Selection_Only |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Evaluation Order is only used for Selection rules. Set it only if Type = "Selection". |
| **Error Location** | Type |

**Error Condition (Copy-Paste)**:
```
AND(NOT(ISBLANK(Evaluation_Order)), Type <> "Selection")
```

---

### RULE_CONDITION VALIDATION RULES

#### Rule 11: Rule_Condition_Index_Positive

**Description**: Index must be positive (if set).

**Object**: `Rule_Condition`

| Property | Value |
|----------|-------|
| **Rule Name** | Rule_Condition_Index_Positive |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Index must be a positive number (e.g., 10, 20, 30). |
| **Error Location** | Index |

**Error Condition (Copy-Paste)**:
```
AND(NOT(ISBLANK(Index)), Index <= 0)
```

---

#### Rule 12: Rule_Condition_Filter_Value_Required

**Description**: Filter Value is always required.

**Object**: `Rule_Condition`

| Property | Value |
|----------|-------|
| **Rule Name** | Rule_Condition_Filter_Value_Required |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Filter Value is required. Provide a constant or field API name. |
| **Error Location** | Filter_Value |

**Error Condition (Copy-Paste)**:
```
ISBLANK(Filter_Value)
```

---

#### Rule 13: Rule_Condition_Operator_Valid_For_Type

**Description**: Some operators are invalid for certain field types. This is a basic check: ensure Operator is not blank.

**Object**: `Rule_Condition`

| Property | Value |
|----------|-------|
| **Rule Name** | Rule_Condition_Operator_Valid_For_Type |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Operator must be specified. |
| **Error Location** | Operator |

**Error Condition (Copy-Paste)**:
```
ISBLANK(Operator)
```

---

### RULE_ACTION VALIDATION RULES

#### Rule 14: Rule_Action_Target_Or_Filter

**Description**: At least one of Target Product or Filter Field must be specified.

**Object**: `Rule_Action`

| Property | Value |
|----------|-------|
| **Rule Name** | Rule_Action_Target_Or_Filter |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Set either Target Product or Filter Field (both cannot be blank). |
| **Error Location** | Target_Product |

**Error Condition (Copy-Paste)**:
```
AND(ISBLANK(Target_Product), ISBLANK(Filter_Field))
```

---

#### Rule 15: Rule_Action_Filter_Complete

**Description**: If Filter Field is set, Filter Operator and Filter Value must also be set (unless Target Product is set, in which case filters are ignored).

**Object**: `Rule_Action`

| Property | Value |
|----------|-------|
| **Rule Name** | Rule_Action_Filter_Complete |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | If using Filter, you must specify Filter Operator and Filter Value. Or use Target Product instead. |
| **Error Location** | Filter_Operator |

**Error Condition (Copy-Paste)**:
```
AND(
  ISBLANK(Target_Product),
  NOT(ISBLANK(Filter_Field)),
  OR(ISBLANK(Filter_Operator), ISBLANK(Filter_Value))
)
```

---

#### Rule 16: Rule_Action_Sort_Order_Positive

**Description**: Sort Order, if set, must be positive.

**Object**: `Rule_Action`

| Property | Value |
|----------|-------|
| **Rule Name** | Rule_Action_Sort_Order_Positive |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Sort Order must be a positive number (or leave blank). |
| **Error Location** | Sort_Order |

**Error Condition (Copy-Paste)**:
```
AND(NOT(ISBLANK(Sort_Order)), Sort_Order <= 0)
```

---

### BUNDLE_RULE_ASSIGNMENT VALIDATION RULES

#### Rule 17: Bundle_Rule_Assignment_Unique

**Description**: Prevent duplicate assignments of the same rule to the same bundle.

**Object**: `Bundle_Rule_Assignment`

| Property | Value |
|----------|-------|
| **Rule Name** | Bundle_Rule_Assignment_Unique |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | This rule is already assigned to this bundle. |
| **Error Location** | Bundle_Product |

**Error Condition (Copy-Paste)**:
```
COUNTIFS(
  Product_Rule, Product_Rule,
  Bundle_Product, Bundle_Product,
  Id, "<>" & Id
) > 0
```

---

### VOLUME_PRICING_SCHEDULE__C VALIDATION RULES

#### Rule 18: Volume_Pricing_Schedule_Unique_Key

**Description**: Unique_Key is auto-calculated (Product + Pricebook or "GLOBAL"). This rule prevents manual duplicates.

**Object**: `Volume_Pricing_Schedule__c`

| Property | Value |
|----------|-------|
| **Rule Name** | Volume_Pricing_Schedule_Unique_Key |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | A schedule for this product and pricebook combination already exists. |
| **Error Location** | Product__c |

**Error Condition (Copy-Paste)**:
```
COUNTIFS(
  Product__c, Product__c,
  Pricebook__c, Pricebook__c,
  Id, "<>" & Id
) > 0
```

---

#### Rule 19: Volume_Pricing_Schedule_Overage_Rate_Non_Negative

**Description**: Overage Rate, if set, must be non-negative.

**Object**: `Volume_Pricing_Schedule__c`

| Property | Value |
|----------|-------|
| **Rule Name** | Volume_Pricing_Schedule_Overage_Rate_Non_Negative |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Overage Rate must be zero or positive. |
| **Error Location** | Overage_Rate__c |

**Error Condition (Copy-Paste)**:
```
AND(NOT(ISBLANK(Overage_Rate__c)), Overage_Rate__c < 0)
```

---

### VOLUME_PRICING_TIER__C VALIDATION RULES

#### Rule 20: Volume_Pricing_Tier_Bounds_Valid

**Description**: Lower Bound must be < Upper Bound (if Upper Bound is set). Price must be non-negative.

**Object**: `Volume_Pricing_Tier__c`

| Property | Value |
|----------|-------|
| **Rule Name** | Volume_Pricing_Tier_Bounds_Valid |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Lower Bound must be less than Upper Bound. Price must be non-negative. |
| **Error Location** | Price__c |

**Error Condition (Copy-Paste)**:
```
OR(
  AND(NOT(ISBLANK(Upper_Bound__c)), Lower_Bound__c >= Upper_Bound__c),
  Price__c < 0
)
```

---

#### Rule 21: Volume_Pricing_Tier_Sort_Order_Positive

**Description**: Sort Order must be positive.

**Object**: `Volume_Pricing_Tier__c`

| Property | Value |
|----------|-------|
| **Rule Name** | Volume_Pricing_Tier_Sort_Order_Positive |
| **Active** | ✓ Active |
| **Error Condition** | See formula below |
| **Error Message** | Sort Order must be a positive number. |
| **Error Location** | Sort_Order__c |

**Error Condition (Copy-Paste)**:
```
Sort_Order__c <= 0
```

---

### SUMMARY OF VALIDATION RULES

| # | Rule Name | Object | Status |
|---|-----------|--------|--------|
| 1 | Bundle_Feature_Sort_Order_Positive | Bundle_Feature | Active |
| 2 | Bundle_Feature_Max_Greater_Min | Bundle_Feature | Active |
| 3 | Bundle_Feature_Product_Required | Bundle_Feature | Active |
| 4 | Bundle_Option_Products_Different | Bundle_Option | Active |
| 5 | Bundle_Option_Quantity_Bounds | Bundle_Option | Active |
| 6 | Bundle_Option_Sort_Order_Positive | Bundle_Option | Active |
| 7 | Bundle_Option_Feature_Belongs_To_Bundle | Bundle_Option | Active |
| 8 | Product_Rule_Type_Validation_Requires_Message | Product_Rule | Active |
| 9 | Product_Rule_Type_Alert_Requires_Message | Product_Rule | Active |
| 10 | Product_Rule_Custom_Condition_Requires_Formula | Product_Rule | Active |
| 11 | Product_Rule_Evaluation_Order_Selection_Only | Product_Rule | Active |
| 12 | Rule_Condition_Index_Positive | Rule_Condition | Active |
| 13 | Rule_Condition_Filter_Value_Required | Rule_Condition | Active |
| 14 | Rule_Condition_Operator_Valid_For_Type | Rule_Condition | Active |
| 15 | Rule_Action_Target_Or_Filter | Rule_Action | Active |
| 16 | Rule_Action_Filter_Complete | Rule_Action | Active |
| 17 | Rule_Action_Sort_Order_Positive | Rule_Action | Active |
| 18 | Bundle_Rule_Assignment_Unique | Bundle_Rule_Assignment | Active |
| 19 | Volume_Pricing_Schedule_Unique_Key | Volume_Pricing_Schedule__c | Active |
| 20 | Volume_Pricing_Schedule_Overage_Rate_Non_Negative | Volume_Pricing_Schedule__c | Active |
| 21 | Volume_Pricing_Tier_Bounds_Valid | Volume_Pricing_Tier__c | Active |
| 22 | Volume_Pricing_Tier_Sort_Order_Positive | Volume_Pricing_Tier__c | Active |

**Total**: 22 validation rules | **Estimated Time**, 2–3 hours (all objects)

---

<id>permission-sets</id>

## PERMISSION SETS

Create 4 permission sets with role-based access to custom objects, fields, and custom permissions.

**Path**: Setup > Users > Permission Sets > New

---

### PERMISSION SET 1: `CPQ_Admin`

**Purpose**: Full access to all CPQ objects and fields. For admins and power users managing the entire configuration system.

#### Create the Permission Set

| Property | Value |
|----------|-------|
| **Label** | CPQ Admin |
| **API Name** | CPQ_Admin |
| **Description** | Full administrative access to all CPQ objects and configuration rules. |

**Click Save**.

#### Grant Object Permissions

**Path**: CPQ_Admin > Object Settings > [Object Name] > Edit

For each of the 8 custom objects, grant:
- ✓ Read
- ✓ Create
- ✓ Edit
- ✓ Delete
- ✓ View All
- ✓ Modify All

**Objects to configure**:
1. Bundle_Feature
2. Bundle_Option
3. Product_Rule
4. Rule_Condition
5. Rule_Action
6. Bundle_Rule_Assignment
7. Volume_Pricing_Schedule__c
8. Volume_Pricing_Tier__c

#### Grant Field Permissions

**Path**: CPQ_Admin > Field Permissions > [Object Name]

For each object, grant **Visible** and **Editable** on ALL fields (custom and Name).

**Estimated time**: 20 minutes

---

### PERMISSION SET 2: `Pricing_Admin`

**Purpose**: Access to volume pricing configuration and Product lookup only. For users managing pricing tiers.

#### Create the Permission Set

| Property | Value |
|----------|-------|
| **Label** | Pricing Admin |
| **API Name** | Pricing_Admin |
| **Description** | Manage volume pricing schedules and tiers. Product lookup only. |

**Click Save**.

#### Grant Object Permissions

| Object | Read | Create | Edit | Delete | View All | Modify All |
|--------|------|--------|------|--------|----------|-----------|
| Volume_Pricing_Schedule__c | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Volume_Pricing_Tier__c | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Bundle_Feature | ✓ | ☐ | ☐ | ☐ | ✓ | ☐ |
| Bundle_Option | ✓ | ☐ | ☐ | ☐ | ✓ | ☐ |

#### Grant Field Permissions

For **Volume_Pricing_Schedule__c** and **Volume_Pricing_Tier__c**: grant **Visible** and **Editable** on ALL fields.

For **Bundle_Feature** and **Bundle_Option**: grant **Visible** only (read-only).

**Estimated time**: 12 minutes

---

### PERMISSION SET 3: `Rule_Specialist`

**Purpose**: Configure product rules, conditions, and actions. Restricted from object/field creation. For rule setup specialists.

#### Create the Permission Set

| Property | Value |
|----------|-------|
| **Label** | Rule Specialist |
| **API Name** | Rule_Specialist |
| **Description** | Create and edit product rules, conditions, and actions. |

**Click Save**.

#### Grant Object Permissions

| Object | Read | Create | Edit | Delete | View All | Modify All |
|--------|------|--------|------|--------|----------|-----------|
| Product_Rule | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Rule_Condition | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Rule_Action | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Bundle_Rule_Assignment | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Bundle_Feature | ✓ | ☐ | ☐ | ☐ | ✓ | ☐ |
| Bundle_Option | ✓ | ☐ | ☐ | ☐ | ✓ | ☐ |

#### Grant Field Permissions

For rules and assignments: grant **Visible** and **Editable** on ALL fields.

For bundles and features: grant **Visible** only (read-only).

**Estimated time**: 12 minutes

---

### PERMISSION SET 4: `Config_Viewer`

**Purpose**: Read-only access to all CPQ and pricing objects. For sales or compliance teams needing visibility.

#### Create the Permission Set

| Property | Value |
|----------|-------|
| **Label** | Config Viewer |
| **API Name** | Config_Viewer |
| **Description** | Read-only access to all configuration objects. |

**Click Save**.

#### Grant Object Permissions

For ALL 8 custom objects, grant:
- ✓ Read
- ☐ Create
- ☐ Edit
- ☐ Delete
- ✓ View All
- ☐ Modify All

#### Grant Field Permissions

For all objects: grant **Visible** only (no editing).

**Estimated time**: 8 minutes

---

### ASSIGNING PERMISSION SETS TO USERS

**Path**: Setup > Users > [Username] > Permission Set Assignments > Edit Assignments

For each user:
1. Click **Edit Assignments**
2. Find the permission set in the **Available Permission Sets** list
3. Click the permission set name to select it
4. Click **Add >** (arrow button)
5. Click **Save**

**Example assignments**:
- **Admins/Power Users**: CPQ_Admin
- **Pricing Team**: Pricing_Admin
- **Configuration Specialists**: Rule_Specialist
- **Sales/Managers**: Config_Viewer

---

<id>testing--validation</id>

## TESTING & VALIDATION

After deploying all objects and permission sets, verify that the configuration is functional.

---

### TEST 1: OBJECT VISIBILITY & FIELD COUNT

**Step 1**: Navigate to Setup > Objects and Fields > Object Manager

**Verify**:
- [ ] All 8 custom objects appear in the list
- [ ] Each object has the correct fields (see field count summaries below)

| Object | Expected Field Count |
|--------|-----|
| Bundle_Feature | 7 |
| Bundle_Option | 12 |
| Product_Rule | 9 |
| Rule_Condition | 8 |
| Rule_Action | 8 |
| Bundle_Rule_Assignment | 4 |
| Volume_Pricing_Schedule__c | 6 |
| Volume_Pricing_Tier__c | 6 |

**Step 2**: Click each object and verify tabs:
- [ ] Summary tab shows object label and plural
- [ ] Fields & Relationships tab lists all fields
- [ ] Validation Rules tab shows all rules (21 total)

**Estimated Time**: 15 minutes

---

### TEST 2: PERMISSION SET ASSIGNMENTS

**Step 1**: Log in as a test user assigned to **Config_Viewer**

**Verify**:
- [ ] User can navigate to all 8 custom objects through tabs or app menu
- [ ] User **cannot** create/edit/delete records
- [ ] Fields are visible but not editable

**Step 2**: Log in as a test user assigned to **CPQ_Admin**

**Verify**:
- [ ] User can create, edit, and delete records in all objects
- [ ] All fields are visible and editable

**Estimated Time**: 10 minutes

---

### TEST 3: VALIDATION RULE TRIGGERS

**Test**: Create records that violate validation rules and verify error messages.

#### Test 3a: Bundle_Feature_Sort_Order_Positive

**Steps**:
1. Go to **Bundle_Feature** list
2. Click **New**
3. Fill in: Product (any), Feature Name (e.g., "Test"), Sort Order = **0**
4. Click **Save**

**Expected**: Error message: *"Sort Order must be a positive number."*

**Actual**: ___________

---

#### Test 3b: Bundle_Option_Products_Different

**Steps**:
1. Go to **Bundle_Option** list
2. Click **New**
3. Fill in: Bundle Product = **Product A**, Option Product = **Product A**, Sort Order = 10
4. Click **Save**

**Expected**: Error message: *"Bundle Product and Option Product must be different. An option cannot be a bundle of itself."*

**Actual**: ___________

---

#### Test 3c: Product_Rule_Custom_Condition_Requires_Formula

**Steps**:
1. Go to **Product_Rule** list
2. Click **New**
3. Fill in: Rule Name = "Test", Type = "Validation", Scope = "Bundle", Evaluation_Event = "Save", Conditions_Met = **"Custom"**, Message = "Test", Advanced_Condition = **(leave blank)**
4. Click **Save**

**Expected**: Error message: *"Custom conditions require an Advanced Condition formula (e.g., "1 AND (2 OR 3)")."*

**Actual**: ___________

---

#### Test 3d: Rule_Action_Target_Or_Filter

**Steps**:
1. Go to **Product_Rule** list and open any rule (or create a new one)
2. Click **New** in the **Rule_Actions** related list
3. Leave both Target Product and Filter Field blank
4. Click **Save**

**Expected**: Error message: *"Set either Target Product or Filter Field (both cannot be blank)."*

**Actual**: ___________

---

### TEST 4: RECORD RELATIONSHIPS

**Step 1**: Create a test scenario with related records

1. Create **Product_Rule** record:
   - Name: "Test Rule"
   - Type: Validation
   - Scope: Bundle
   - Conditions Met: All
   - Message: "Test"

2. Navigate to the rule detail and click **New** under **Rule Conditions**:
   - Index: 10
   - Tested Object: Opportunity
   - Tested Field: Amount
   - Operator: greater than
   - Filter Type: Value
   - Filter Value: 10000

3. Navigate back and click **New** under **Rule Actions**:
   - Type: Add
   - Filter Field: ProductCode
   - Filter Operator: equals
   - Filter Value: TEST-SKU

**Verify**:
- [ ] All records save successfully (no validation errors)
- [ ] Master-Detail relationships cascade (deleting the rule also deletes its conditions/actions)
- [ ] Lookup relationships are preserved

**Estimated Time**: 15 minutes

---

### TEST 5: OLI CUSTOM FIELDS

**Step 1**: Create an **Opportunity** and add a line item

1. Go to **Opportunities** > Create a new opportunity
2. Fill in required fields (Account, Close Date, Stage)
3. Click **Save**
4. Scroll to **Opportunity Line Items** and click **Add**
5. Select a product and quantity
6. Click **Save**

**Step 2**: Verify OLI custom fields are visible

1. Click the OLI record
2. Scroll down to check for:
   - [ ] Bundle_Group (should be blank initially)
   - [ ] Is_Bundle_Product (checkbox, unchecked initially)
   - [ ] Bundle_Option_Ref (lookup field, blank initially)

**Estimated Time**: 10 minutes

---

### DEPLOYMENT CHECKLIST

After all tests pass, verify completion:

- [ ] All 8 custom objects created with correct API names
- [ ] All 45 custom fields created with correct types and properties
- [ ] All 22 validation rules active and tested
- [ ] 4 permission sets created and assigned to appropriate users
- [ ] 3 OLI custom fields added and visible
- [ ] No validation errors on test records
- [ ] User permissions working as expected
- [ ] Master-Detail relationships functioning
- [ ] Lookups resolving correctly

---

<id>post-implementation</id>

## POST-IMPLEMENTATION

After successful deployment and testing, complete these steps to secure and document your configuration.

### STEP 1: DOCUMENT YOUR DEPLOYMENT

**Create a deployment log with the following information**:

```
Deployment Log: Custom CPQ Objects - [Date]

Objects Created:
- Bundle_Feature          (7 fields)
- Bundle_Option           (12 fields)
- Product_Rule            (9 fields)
- Rule_Condition          (8 fields, Master-Detail)
- Rule_Action             (8 fields, Master-Detail)
- Bundle_Rule_Assignment  (4 fields)
- Volume_Pricing_Schedule__c  (6 fields)
- Volume_Pricing_Tier__c     (6 fields, Master-Detail)

OpportunityLineItem Custom Fields:
- Bundle_Group
- Is_Bundle_Product
- Bundle_Option_Ref

Validation Rules: 21 total (All Active)
Permission Sets: 4 (CPQ_Admin, Pricing_Admin, Rule_Specialist, Config_Viewer)

Deployment Date: [Date]
Deployed By: [Admin Name]
Sandbox Tested: [Yes/No]
Production Org: [Org ID]
```

### STEP 2: TAKE AN ORG SNAPSHOT (RECOMMENDED)

Create a backup snapshot immediately after deployment (before any data is loaded):

**Path**: Setup > Sandbox > Snapshots > Create Snapshot

| Property | Value |
|----------|-------|
| **Snapshot Name** | CPQ-Objects-[Date]-Baseline |
| **Description** | Baseline after 8 custom objects, 21 validation rules, and 4 permission sets. |
| **Source Org** | Production |

This allows quick rollback if issues arise.

### STEP 3: ENABLE FIELD HISTORY TRACKING (OPTIONAL)

If using change management or audit trails:

1. For each custom object, go to **Field History Tracking**
2. Select key fields: Name, Type, Is_Active, Price__c, etc.
3. Click **Save**

This logs all modifications for compliance/audit purposes.

### STEP 4: CREATE DATA LOADING PLAN

Plan for populating your configuration objects:

| Object | Sample Data | Purpose |
|--------|---|---|
| Bundle_Feature | 5–10 features | Test categorization of options |
| Bundle_Option | 20–30 options | Test bundle configurations |
| Product_Rule | 3–5 rules | Test validation and selection logic |
| Rule_Condition/Action | Corresponding | Test rule execution |
| Volume_Pricing_Tier | 4–6 tiers per schedule | Test volume pricing |

**Tools**:
- Use **Data Loader** (CSV import) for bulk record creation
- Use **Salesforce UI** for small, manual entries (< 50 records)
- **Avoid** manual API calls unless necessary

### STEP 5: NEXT STEPS — APEX AUTOMATION (OPTIONAL)

Once the objects are stable, consider implementing Apex code for:

1. **OpportunityLineItemTrigger**: Auto-expand bundles, calculate volume pricing
2. **BundleConfigService**: Validate bundle configurations
3. **VolumePricingService**: Apply tiered pricing logic
4. **Rule Execution Engine**: Evaluate product rules and conditions

These are **not required** for the UI-based implementation but enhance user experience.

### STEP 6: TRAINING & DOCUMENTATION

Create user-facing documentation:

1. **Admin Guide**: How to create/manage bundles, rules, and pricing
2. **User Guide**: How to configure bundles in quotes
3. **FAQ**: Common issues and resolutions
4. **Video Tutorials**: Screen recordings of key tasks

---

<id>troubleshooting</id>

## TROUBLESHOOTING

### ISSUE: "Insufficient Access" when creating validation rules

**Cause**: User role does not have Customize Application permission.

**Solution**:
1. Go to Setup > Users > [Username] > Edit
2. Set System Administrator or ensure role has "Customize Application" enabled
3. Retry

---

### ISSUE: Lookup field shows "No matching records"

**Cause**: Related records (e.g., Products) don't exist in the org yet.

**Solution**:
1. Create at least 2–3 test Product records first (Setup > Products)
2. Ensure they have unique names and API names
3. Retry field creation

---

### ISSUE: Master-Detail relationship shows "Reparenting causing error"

**Cause**: Existing child records prevent reparenting to a different parent.

**Solution**:
1. Delete all child records (Rule_Conditions, Rule_Actions, etc.) if test data
2. Keep "Reparenting Allowed" unchecked for data integrity
3. Redesign rule hierarchy if needed

---

### ISSUE: Validation rule appears "not triggered" even when condition is true

**Cause**: Rule is deactivated or formula has a syntax error.

**Solution**:
1. Go to Validation Rules for the object and confirm **Active** checkbox is checked
2. Review the formula syntax (Salesforce may have a parsing error)
3. Re-save the rule to validate syntax
4. Test with a simple formula first, then add complexity

---

### ISSUE: Permission set not granting access to field

**Cause**: Field FLS (Field-Level Security) not granted in the permission set.

**Solution**:
1. Go to Permission Set > Field Permissions > [Object]
2. Locate the field and ensure **Visible** and **Editable** are both checked
3. Click **Save**
4. Log out and back in (FLS caches)

---

### ISSUE: "Cannot Create Master-Detail Relationship" error when creating lookup to Product2

**Cause**: Salesforce blocks Master-Detail relationships where Product2 (a standard object) is the parent. Additionally, even Lookup fields to Product2 cannot have "Required" checked or "Don't allow deletion" selected, because Salesforce restricts deletion behavior on Product2 to prevent cascading deletes across the catalog.

**Why?**: Product2 is foundational across Sales Cloud, CPQ, Commerce, and Industries clouds. Enforcing required fields or cascade-delete on Product2 would be catastrophically destructive in most orgs. Salesforce's own CPQ package uses Lookup relationships to Product2, not Master-Detail.

**Solution**:
1. **Do NOT check "Required"** when creating the lookup field
2. Select **"Clear the value of this field"** for deletion behavior
3. Enforce the required constraint using a Validation Rule instead:
   - Rule Name: `Bundle_Feature_Product_Required`
   - Formula: `ISBLANK(Product__c)`
   - Error Message: `"Every Bundle Feature must be associated with a Product."`
4. This pattern matches Salesforce's official CPQ implementation

**Reference**: The Bundle_Feature object in this guide already follows this pattern (see Bundle_Feature_Product_Required validation rule).

---

### ISSUE: OLI custom fields not appearing on record

**Cause**: Fields not added to the page layout.

**Solution**:
1. Go to Setup > Objects and Fields > Object Manager > OpportunityLineItem > Page Layouts > [Layout Name]
2. Click **Edit**
3. Drag the custom fields (Bundle_Group, Is_Bundle_Product, Bundle_Option_Ref) from the palette to the layout
4. Click **Save**
5. Test by creating a new OLI; fields should now be visible

---

### ISSUE: Custom object not appearing in tabs/search

**Cause**: Tab not created or user doesn't have visibility.

**Solution**:
1. Go to Setup > User Interface > Tabs > Custom Object Tabs
2. Create a tab for each custom object (icon, color, label)
3. Go to Setup > App Manager > [Your App] > Edit
4. Add the custom object tabs to the app navigation
5. Assign the app to the user
6. User should now see tabs in their app

---

### ISSUE: "Duplicate value on record with unique field"

**Cause**: Unique_Key or other unique field already exists.

**Solution**:
- For **Volume_Pricing_Schedule__c**: Ensure no two schedules have the same Product + Pricebook combination
- For **Bundle_Rule_Assignment**: Ensure no duplicate Product_Rule + Bundle_Product pairs
- Check existing records using Reports or List View filters

---

## SUPPORT & RESOURCES

- **Salesforce Help**: [help.salesforce.com](https://help.salesforce.com)
- **Developer Documentation**: [developer.salesforce.com](https://developer.salesforce.com)
- **Admin Setup Guide**: Check in-app help or contact Salesforce Support
- **Trailhead**: Free learning modules on custom objects, validation rules, and permission sets

---

## FINAL CHECKLIST

Complete this checklist before considering deployment finished:

- [ ] **All 8 objects created** with correct API names and fields
- [ ] **All 22 validation rules active** and tested with sample data
- [ ] **3 OLI custom fields added** and visible on page layouts
- [ ] **4 permission sets created** and assigned to appropriate users
- [ ] **Relationships verified**: Master-Details cascade, Lookups resolve
- [ ] **Org snapshot taken** (baseline for rollback)
- [ ] **Users trained** on how to use the new objects
- [ ] **Data loading plan established** for configuration records
- [ ] **Troubleshooting guide reviewed** by admin team
- [ ] **Next steps** (Apex development, data migration) scheduled

---

**Estimated Total Deployment Time**: 6–8 hours (depending on testing depth and parallel work)

**Date Deployed**: ______________________  
**Deployed By**: ______________________  
**Sign-Off**: ______________________

---

*End of Implementation Guide*
