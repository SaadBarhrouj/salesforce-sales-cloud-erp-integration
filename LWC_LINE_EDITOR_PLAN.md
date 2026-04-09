# Line Editor Step (Step 3) - LWC User Stories

## Display & Navigation

- **As a** sales rep, **I want** to see all quote line items in a clean table format **so that** I can quickly review the quote contents
- **As a** sales rep, **I want** to expand bundle products to see nested options **so that** I understand what's included in each bundle
- **As a** sales rep, **I want** bundle items collapsed by default **so that** I have an uncluttered view of the top-level products

## Line Item Editing

- **As a** sales rep, **I want** to edit Quantity directly in the table column **so that** I can quickly adjust quantities without leaving the table
- **As a** sales rep, **I want** to edit Discount % directly in the table column **so that** I can apply discounts inline
- **As a** sales rep, **I want** to see Net Price and Total recalculate immediately after editing **so that** I see the impact of my changes right away

## Pricing Calculations

- **As a** sales rep, **I want** pricing to recalculate after I stop typing **so that** the system doesn't overload with requests on every keystroke
- **As a** sales rep, **I want** multiple pricing edits to batch together before sending to the server **so that** the system handles them efficiently
- **As a** sales rep, **I want** to see the correct Net Price and Total Price after my edits **so that** I know the final cost of each line item

## Validation & Errors

- **As a** sales rep, **I want** to see an error message if my discount or quantity is invalid **so that** I know what to fix
- **As a** sales rep, **I want** invalid rows highlighted visually in the table **so that** I can spot problems quickly
- **As a** sales rep, **I want** to be blocked from proceeding to the next step if there are errors **so that** I don't accidentally submit a broken quote

## Bulk Operations

- **As a** sales rep, **I want** to apply a discount to all line items at once **so that** I don't need to edit each row individually
- **As a** sales rep, **I want** to refresh all pricing from the server **so that** I can get updated prices if they change
- **As a** sales rep, **I want** to validate that all rows are correct before moving to the next step **so that** I know my quote is ready

## Data Persistence

- **As a** sales rep, **I want** my edits to be saved as I make them **so that** I don't lose work if I navigate away
- **As a** sales rep, **I want** a fresh load of data when I return to this step **so that** I see the latest server data
- **As a** sales rep, **I want** to abandon my changes if I navigate away **so that** I can start over if needed

## Data Model

### Table Display
```
#  │ Product            │ Qty │ List Price │ Disc % │ Net Price │ Total
────┼────────────────────┼─────┼────────────┼────────┼───────────┼─────────
1  │ Product A          │ 5   │ $100.00    │ 10     │ $90.00    │ $450.00
   ├─ Option 1          │ -   │ $50.00     │ -      │ $50.00    │ $100.00
   └─ Option 2          │ -   │ $75.00     │ -      │ $75.00    │ $225.00
2  │ Product B          │ 10  │ $200.00    │ 5      │ $190.00   │ $1,900.00
```

### Column Specifications

| Column | Editable | Notes |
|--------|----------|-------|
| # | No | Line item counter (1, 2, 3...) |
| Product | No | Product name |
| Qty | **Yes** | User edits quantity |
| List Price | No | Base price (read-only) |
| Disc % | **Yes** | User edits discount (0-100 range) |
| Net Price | No | Auto-calculated: List Price × (1 - Disc/100) |
| Total | No | Auto-calculated: Net Price × Qty |


### Bundle Behavior
- Parent products show as expandable rows with expand/collapse icon
- Bundle options show as child rows indented below parent
- Use tree-grid component to handle parent-child relationships
- Child rows are read-only for selection but editable in pricing columns
- Bundle defaults to collapsed state

## Pricing Calculation Flow

### When User Changes Quantity or Discount
1. User edits value in table cell
2. Component captures the change
3. Component waits 500ms (debounce) while user might make more edits
4. After 500ms idle time, batch all pending changes
5. Send batch request to Apex controller with changed line items
6. Receive response with calculated prices
7. Update table with new Net Price and Total values
8. Show error toast if calculation fails
9. Highlight row red if there's an error

### Batch Limits
- Debounce wait time: 500ms
- Single Apex call for all batched changes

## Error Handling

### Error Display
- Show toast notification with error message
- Mark invalid rows with red highlighting
- Prevent user from proceeding to next step until errors fixed

### Common Errors
- Discount outside 0-100% range
- Quantity below minimum or above maximum allowed
- Pricing calculation failure
- Missing pricing data from server

## Component Inputs & Outputs

### Receives from Parent
- Array of line items (selectedProducts)
- Pricebook ID (pricebookId)
- Offer type - Sale or Rental and Services (offerType)

### Does for Parent
- Refreshes all line pricing when requested
- Validates all rows before allowing next step
- Returns current line state with prices
- Applies bulk discount to all rows
- Fires events when lines change or errors occur

## Component Files

```
cpqStepLineEditor/
├─ cpqStepLineEditor.js       (Logic, event handlers, Apex calls)
├─ cpqStepLineEditor.html     (Tree-grid table template)
├─ cpqStepLineEditor.css      (Styling)
└─ cpqStepLineEditor.js-meta.xml (Metadata)
```

## UI/UX Design

- **Layout**: Desktop optimized, high-density table format
- **Currency**: Show with $ symbol and 2 decimal places
- **Loading**: Show spinner while server calculates prices
- **Errors**: Red background on invalid rows, toast notification
- **Design System**: Follow Salesforce Lightning Design System

## Constraints

1. All edits happen in table columns only (no separate detail panel)
2. Bundle options (children) are read-only
3. Only one bundle can be expanded at a time
4. Discount must be between 0-100%
6. Data loads fresh each time component mounts
7. Component state NOT persisted across navigation

---

**Status**: User stories & requirements complete ✓

