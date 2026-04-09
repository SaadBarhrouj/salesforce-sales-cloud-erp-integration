/**
 * CPQ Configurator – Shared Constants Module
 * Centralizes all enumerations, step definitions, labels, and reusable SLDS tokens.
 */

/* ─── Wizard Steps ─── */
const DEFAULT_STEP_ACTIONS = [
    { name: 'back', label: 'Back', variant: 'neutral' },
    { name: 'save', label: 'Save', variant: 'neutral' },
    { name: 'next', label: 'Next', variant: 'brand' }
];

const CONFIGURE_STEP_ACTIONS = [
    { name: 'applyRules', label: 'Apply Rules', variant: 'neutral', isStandalone: true },
    { name: 'back', label: 'Back', variant: 'neutral' },
    { name: 'next', label: 'Save', variant: 'brand' }
];

const DEFAULT_GLOBAL_ACTIONS = [
    { name: 'settings', label: 'List View Controls', variant: 'border-filled', iconName: 'utility:settings', isMenu: true },
    { name: 'refresh', label: 'Refresh List', variant: 'border-filled', iconName: 'utility:refresh' }
];

const CONFIGURE_GLOBAL_ACTIONS = [
    { name: 'refresh', label: 'Refresh Bundle', iconName: 'utility:refresh', variant: 'border-filled' },
    {
        name: 'organize', label: 'Organize Features', iconName: 'utility:table', variant: 'border-filled', isMenu: true,
        menuItems: [
            { name: 'groupBySection', label: 'Group by Section', iconName: 'utility:section' },
            { name: 'groupByTab', label: 'Group by Tab', iconName: 'utility:tabset' }
        ]
    },
    {
        name: 'configGroup', isGroup: true, items: [
            { name: 'resetConfig', label: 'Reset Configuration', iconName: 'utility:clear', variant: 'border-filled' },
            { name: 'toggleFilters', label: 'Filters', iconName: 'utility:filterList', variant: 'border-filled', dynamicProperty: 'highlightIfFiltersOpen' }

        ]
    }
];

export const STEPS = Object.freeze({
    SELECTION: {
        number: 1, key: 'selection', label: 'Product Selection', icon: 'standard:product', subtitle: 'Select and configure products',
        header: {
            showSearch: true,
            searchPlaceholder: 'Search products...',
            stepActions: [
                { name: 'cancel', label: 'Cancel', variant: 'neutral' },
                { name: 'select', label: 'Select', variant: 'brand', dynamicProperty: 'disableIfCartEmpty' }
            ],
            globalActions: [
                { name: 'refresh', label: 'Refresh Catalog', iconName: 'utility:refresh' },
                {
                    name: 'changeView', label: 'Change View', iconName: 'utility:table', isMenu: true, variant: 'border-filled',
                    menuItems: [
                        { name: 'viewTable', label: 'Table View', iconName: 'utility:table' },
                        { name: 'viewCards', label: 'Card View', iconName: 'utility:rows' }
                    ]
                },
                {
                    name: 'selectionGroup', isGroup: true, items: [
                        { name: 'clearSelection', label: 'Clear Selection', iconName: 'utility:clear', variant: 'border-filled' },
                        { name: 'toggleFilters', label: 'Filters', iconName: 'utility:filterList', variant: 'border-filled', dynamicProperty: 'highlightIfFiltersOpen' }
                    ]
                }
            ]
        }
    },
    CONFIGURE: {
        number: 2, key: 'configure', label: 'Configure Products', icon: 'standard:custom', subtitle: 'Configure bundles and options',
        header: { showSearch: false, searchPlaceholder: 'Search...', stepActions: CONFIGURE_STEP_ACTIONS, globalActions: CONFIGURE_GLOBAL_ACTIONS }
    },
    LINE_EDITOR: {
        number: 3, key: 'lineEditor', label: 'Line Editor', icon: 'standard:order_item', subtitle: 'Review and adjust line items',
        header: { 
            showSearch: false, 
            searchPlaceholder: 'Search...', 
            stepActions: DEFAULT_STEP_ACTIONS, 
            globalActions: []  // No sidebar in line editor
        }
    },
    LOGISTICS: {
        number: 4, key: 'logistics', label: 'Logistics', icon: 'standard:shipment', subtitle: 'Delivery options',
        header: { showSearch: false, searchPlaceholder: 'Search...', stepActions: DEFAULT_STEP_ACTIONS, globalActions: DEFAULT_GLOBAL_ACTIONS }
    },
    REVIEW: {
        number: 5, key: 'review', label: 'Review & Save', icon: 'standard:task', subtitle: 'Verify everything before saving',
        header: { showSearch: false, searchPlaceholder: 'Search...', stepActions: DEFAULT_STEP_ACTIONS, globalActions: DEFAULT_GLOBAL_ACTIONS }
    }
});

export const STEP_LIST = Object.freeze(
    Object.values(STEPS).sort((a, b) => a.number - b.number)
);

/* ─── Option Types (Bundle_Option__c.Option_Type__c) ─── */
export const OPTION_TYPES = Object.freeze({
    COMPONENT:       'Component',
    ACCESSORY:       'Accessory',
    RELATED_PRODUCT: 'Related Product'
});

/* ─── Product Rule Types ─── */
export const RULE_TYPES = Object.freeze({
    VALIDATION: 'Validation',
    ALERT:      'Alert',
    SELECTION:  'Selection'
});

export const RULE_SCOPES = Object.freeze({
    BUNDLE: 'Bundle',
    QUOTE:  'Quote'
});

export const RULE_EVAL_EVENTS = Object.freeze({
    SAVE:   'Save',
    EDIT:   'Edit',
    ALWAYS: 'Always'
});

export const TOAST_DURATION = 4000;

export const RULE_ACTION_TYPES = Object.freeze({
    ADD:    'Add',
    REMOVE: 'Remove',
    HIDE:   'Hide',
    SHOW:   'Show'
});

/* ─── Volume Pricing Types ─── */
export const PRICING_TYPES = Object.freeze({
    BLOCK:  'Block',
    TIERED: 'Tiered'
});

/* ─── Transport Urgency ─── */
export const URGENCY_OPTIONS = Object.freeze([
    { label: 'Standard', value: 'Standard' },
    { label: 'Express',  value: 'Express' },
    { label: 'Urgent',   value: 'Urgent' }
]);

/* ─── User-Facing Messages ─── */
export const MESSAGES = Object.freeze({
    REQUIRED_FIELD:   'This field is required.',
    MIN_OPTIONS:      'At least {0} option(s) must be selected in "{1}".',
    MAX_OPTIONS:      'No more than {0} option(s) allowed in "{1}".',
    SAVE_SUCCESS:     'Quote saved successfully.',
    SAVE_ERROR:       'An error occurred while saving the quote.',
    CALCULATE_OK:     'Prices recalculated.',
    NO_PRODUCTS:      'Add at least one product before proceeding.',
    CONFIRM_REMOVE:   'Remove "{0}" from the quote?',
    NOT_CONFIGURED:   'One or more bundles have not been configured.',
    LOGISTICS_INCOMPLETE: 'Please complete all required logistics fields.'
});

/* ─── Feature Selection Mode (derived from min/max) ─── */
export const SELECTION_MODES = Object.freeze({
    SINGLE_REQUIRED: 'single-required',   // min=1, max=1
    SINGLE_OPTIONAL: 'single-optional',   // min=0, max=1
    MULTI_REQUIRED:  'multi-required',    // min>=1, max>1
    MULTI_OPTIONAL:  'multi-optional'     // min=0, max>1 or no max
});

/* ─── Custom Event Names ─── */
export const EVENTS = Object.freeze({
    STEP_CHANGE:       'stepchange',
    INIT_COMPLETE:     'initcomplete',
    PRODUCT_ADD:       'productadd',
    PRODUCT_REMOVE:    'productremove',
    OPTION_CHANGE:     'optionchange',
    QUANTITY_CHANGE:   'quantitychange',
    PRICE_CHANGE:      'pricechange',
    LINE_UPDATE:       'lineupdate',
    SAVE_QUOTE:        'savequote',
    NAVIGATE:          'navigate',
    SIDEBAR_TOGGLE:    'sidebartoggle',
    SIDEBAR_REFRESH:   'sidebarrefresh',
    BUNDLE_SELECT:     'bundleselect',
    ITEM_SELECT:       'itemselect',
    ITEM_DESELECT:     'itemdeselect',
    SEARCH:            'search',
    CTA_CLICK:         'ctabuttonclick'
});

/* ─── Empty State Illustrations ─── */
export const ILLUSTRATIONS = Object.freeze({
    // Access Related
    ACCESS_DELETED:       { name: 'access:deleted',         label: 'Deleted Access',        description: 'A cocoon or chrysalis' },
    ACCESS_LIMIT:         { name: 'access:limit',           label: 'Access Limit',          description: 'An extinguished candle' },
    ACCESS_REQUEST:       { name: 'access:request',         label: 'Access Request',        description: 'A locked padlock' },

    // Cart Related
    CART_NO_ITEMS:        { name: 'cart:noitems',           label: 'No Items in Cart',      description: 'An empty shopping bag' },

    // Error Related
    ERROR_APP_CONNECTION: { name: 'error:appconnection',    label: 'App Connection Error',  description: 'A stylized balloon' },
    ERROR_CONNECTION_ISSUE: { name: 'error:connectionissue', label: 'Connection Issue',     description: 'An unplugged electrical plug' },
    ERROR_RECOVERABLE:    { name: 'error:recoverable',      label: 'Recoverable Error',     description: 'A wilting plant' },
    ERROR_UNRECOVERABLE:  { name: 'error:unrecoverable',    label: 'Unrecoverable Error',   description: 'A rain cloud' },

    // Maintenance Related
    MAINTENANCE_PLANNED:  { name: 'maintenance:planned',    label: 'Planned Maintenance',   description: 'A healthy plant' },
    MAINTENANCE_UNPLANNED: { name: 'maintenance:unplanned', label: 'Unplanned Maintenance', description: 'A boomerang' },

    // No Results Related
    NORESULTS_FILTER:     { name: 'noresults:filter',       label: 'No Results - Filter',   description: 'Three plants, the tallest bending to the sun' },
    NORESULTS_SEARCH:     { name: 'noresults:search',       label: 'No Results - Search',   description: 'A telescope pointing away from the sky' },
    NORESULTS_UNKNOWN:    { name: 'noresults:unknown',      label: 'No Results - Unknown',  description: 'Mountains and clouds' },

    // Success Related
    SUCCESS_ASSIGNED:     { name: 'success:assigned',       label: 'Successfully Assigned', description: 'Umbrella planted on a beach' },
    SUCCESS_NEW:          { name: 'success:new',            label: 'Success - New',         description: 'A zen sand garden' },
    SUCCESS_SELF_ASSIGNED: { name: 'success:selfassigned',  label: 'Self Assigned',         description: 'A flag planted on a hill' }
});

/**
 * Get illustration by key
 * @param {string} key - Illustration key (e.g., 'CART_NO_ITEMS')
 * @returns {Object} Illustration object with name, label, and description
 */
export const getIllustration = (key) => {
    return ILLUSTRATIONS[key] || ILLUSTRATIONS.NORESULTS_UNKNOWN;
};
