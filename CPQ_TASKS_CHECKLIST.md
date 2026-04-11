# CPQ Line Editor & Configuration — Task Checklist

---

## 1. Subtotal Alignment
**Requirement:** The subtotal in `cpqStepLineEditor.html` (lines 203-213) is currently a `slds-box slds-theme_shade` div that spans the full table width below it. It must be aligned with the **Total column** (the rightmost numeric column) and rendered without section/box **outside** the table, positioned directly under the total columns.

**Context:** 
- File: `force-app/main/default/lwc/cpqStepLineEditor/cpqStepLineEditor.html`
- Currently rendered as full-width footer div below table
- Need to align with the rightmost `Total` column in the table grid

---

## 2. Remove Table Action Icon
**Requirement:** The "Actions" column header (`cpqStepLineEditor.html:63-65`) and the per-row action button with `utility:down` icon (`cpqStepLineEditor.html:190-196`) must be removed from the line editor table.

**Context:**
- File: `force-app/main/default/lwc/cpqStepLineEditor/cpqStepLineEditor.html`
- Column header defined in COLUMNS constant (`cpqStepLineEditor.js:7-15`)
- Per-row action button renders the down-arrow icon

---

## 3. Save Line Items on Parent cpqConfigurator
**Requirement:** When the `saveLines` step action is clicked in `cpqStickyHeader` (which dispatches `headeraction` → `handleHeaderAction`), the line items must be persisted onto the parent `cpqConfigurator`'s state (`selectedProducts` / change the name of the `quoteState` to line items).

**Context:**
- File: `force-app/main/default/lwc/cpqConfigurator/cpqConfigurator.js`
- Step actions defined in `cpqConstants.js` - currently uses `DEFAULT_STEP_ACTIONS` with `save`
- Parent's `_triggerSave()` only shows a toast, does not persist line items
- Line editor (`cpqStepLineEditor.js`) does not explicitly save lines back to parent

---

## 4. Loading State from First Load
**Requirement:** The `isLoading` spinner (`cpqStepLineEditor.html:4-6`) and the loading guard in the parent (`cpqConfigurator.js:62-63`) must show from the **initial component mount**, before the table data is prepared and rendered.

**Context:**
- File: `force-app/main/default/lwc/cpqStepLineEditor/cpqStepLineEditor.js`
- `isLoading` tracked property (line 23) is currently set to `true` only during pricing calculation
- Spinner currently conditionally rendered based on this property
- Need to initialize `isLoading` as `true` and set to `false` only after data is prepared

---

## 5. Bug: Selected Options Not Passed When No Bundle Selected on Sidebar
**Requirement:** When the user enters the Configure step (Step 2) but **never clicks any bundle** on the sidebar, `handleItemSelect` and `handleBundleConfigSaved` are never triggered. This means each bundle's `selectedOptions` (from default checkbox/radio states) are never captured into `selectedProducts`. When the user proceeds to the Line Editor (Step 3), line items arrive with missing/stale option data because the bundle configuration was never persisted.

**Context:**
- File: `force-app/main/default/lwc/cpqConfigurator/cpqConfigurator.js`
- `_loadConfigureSidebar()` (lines 499-527) maps bundles to sidebar items
- `handleItemSelect` (line 545) saves current bundle config only when **switching** bundles
- If user never clicks any bundle, `handleBundleConfigSaved()` is never called
- Result: Line editor receives items with missing/stale option data

---

## Related Files

| File | Description |
|-----|-------------|
| `force-app/main/default/lwc/cpqConfigurator/cpqConfigurator.js` | Parent wizard - handles step navigation, state management |
| `force-app/main/default/lwc/cpqConfigurator/cpqConfigurator.html` | Parent template - two-column layout |
| `force-app/main/default/lwc/cpqStepLineEditor/cpqStepLineEditor.js` | Line editor (Step 3) - tree-grid table, pricing |
| `force-app/main/default/lwc/cpqStepLineEditor/cpqStepLineEditor.html` | Line editor template |
| `force-app/main/default/lwc/cpqStepBundleConfig/cpqStepBundleConfig.js` | Bundle config (Step 2) - feature/option selection |
| `force-app/main/default/lwc/cpqStickyHeader/cpqStickyHeader.js` | Header - renders step actions |
| `force-app/main/default/lwc/cpqConstants/cpqConstants.js` | Step definitions, constants |
| `force-app/main/default/lwc/cpqCollapsibleSidebar/cpqCollapsibleSidebar.js` | Sidebar component |