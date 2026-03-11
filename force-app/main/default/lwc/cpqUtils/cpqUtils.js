/**
 * CPQ Configurator – Shared Utilities Module
 * Pure functions for formatting, calculations, deep cloning, and validation.
 */
import { SELECTION_MODES } from 'c/cpqConstants';

/* ─── Unique Id Generator ─── */
let _idCounter = 0;
export function generateId(prefix = 'cpq') {
    _idCounter += 1;
    return `${prefix}-${Date.now()}-${_idCounter}`;
}

/* ─── Deep Clone (bypasses LWC reactive Proxy) ─── */
export function deepClone(obj) {
    if (obj === null || obj === undefined) return obj;
    return JSON.parse(JSON.stringify(obj));
}

/* ─── Currency Formatting ─── */
const currencyFormatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
});

export function formatCurrency(value) {
    if (value === null || value === undefined) return '$0.00';
    return currencyFormatter.format(value);
}

/* ─── Number Formatting ─── */
export function formatNumber(value, decimals = 2) {
    if (value === null || value === undefined) return '0';
    return Number(value).toFixed(decimals);
}

/* ─── Feature Selection Mode ─── */
export function getSelectionMode(feature) {
    const min = feature.Min_Options__c || 0;
    const max = feature.Max_Options__c || 999;

    if (max === 1 && min === 1) return SELECTION_MODES.SINGLE_REQUIRED;
    if (max === 1 && min === 0) return SELECTION_MODES.SINGLE_OPTIONAL;
    if (min >= 1)               return SELECTION_MODES.MULTI_REQUIRED;
    return SELECTION_MODES.MULTI_OPTIONAL;
}

export function isSingleSelect(feature) {
    const mode = getSelectionMode(feature);
    return mode === SELECTION_MODES.SINGLE_REQUIRED || mode === SELECTION_MODES.SINGLE_OPTIONAL;
}

/* ─── Price Calculation Helpers ─── */
export function calculateLineTotal(quantity, unitPrice, discountPercent = 0) {
    const net = unitPrice * (1 - (discountPercent / 100));
    return round(quantity * net, 2);
}

export function calculateNetUnitPrice(unitPrice, discountPercent = 0) {
    return round(unitPrice * (1 - (discountPercent / 100)), 2);
}

export function round(value, decimals = 2) {
    const factor = Math.pow(10, decimals);
    return Math.round(value * factor) / factor;
}

/* ─── Cart Item Total (bundle + options) ─── */
export function calculateCartItemTotal(cartItem) {
    let total = calculateLineTotal(
        cartItem.quantity,
        cartItem.listUnitPrice,
        cartItem.additionalDiscount || 0
    );

    if (cartItem.options) {
        for (const opt of cartItem.options) {
            if (opt.isSelected) {
                total += calculateLineTotal(
                    opt.quantity * cartItem.quantity,
                    opt.listUnitPrice,
                    opt.additionalDiscount || 0
                );
            }
        }
    }
    return round(total, 2);
}

/* ─── Cart Subtotal ─── */
export function calculateCartSubtotal(cartItems) {
    return round(
        cartItems.reduce((sum, item) => sum + calculateCartItemTotal(item), 0),
        2
    );
}

/* ─── Category Tree Builder (flat → hierarchical) ─── */
export function buildCategoryTree(categories, catalogId) {
    const filtered = categories.filter(c => c.CatalogId === catalogId);
    const map = {};
    const roots = [];

    filtered.forEach(c => {
        map[c.Id] = { ...c, label: c.Name, name: c.Id, items: [], expanded: true };
    });

    filtered.forEach(c => {
        const node = map[c.Id];
        if (c.ParentCategoryId && map[c.ParentCategoryId]) {
            map[c.ParentCategoryId].items.push(node);
        } else {
            roots.push(node);
        }
    });

    // Sort children
    const sortNodes = (nodes) => {
        nodes.sort((a, b) => (a.SortOrder || 0) - (b.SortOrder || 0));
        nodes.forEach(n => sortNodes(n.items));
    };
    sortNodes(roots);

    return roots;
}

/* ─── Flatten Category Ids (include children) ─── */
export function getCategoryIdsWithDescendants(categoryId, categories) {
    const ids = [categoryId];
    const children = categories.filter(c => c.ParentCategoryId === categoryId);
    children.forEach(child => {
        ids.push(...getCategoryIdsWithDescendants(child.Id, categories));
    });
    return ids;
}

/* ─── Validation Helpers ─── */
export function validateFeatureSelections(feature, selectedCount) {
    const min = feature.Min_Options__c || 0;
    const max = feature.Max_Options__c || 999;
    const errors = [];

    if (selectedCount < min) {
        errors.push(`At least ${min} option(s) must be selected in "${feature.Name}".`);
    }
    if (selectedCount > max) {
        errors.push(`No more than ${max} option(s) allowed in "${feature.Name}".`);
    }
    return errors;
}

/* ─── Configuration Completeness ─── */
export function calculateCompleteness(features, optionsByFeature) {
    if (!features || features.length === 0) return 100;

    let configured = 0;
    let required = 0;

    features.forEach(f => {
        const minRequired = f.Min_Options__c || 0;
        if (minRequired > 0) {
            required += 1;
            const featureOptions = optionsByFeature[f.Id] || [];
            const selectedCount = featureOptions.filter(o => o.isSelected).length;
            if (selectedCount >= minRequired) {
                configured += 1;
            }
        }
    });

    return required === 0 ? 100 : round((configured / required) * 100, 0);
}

/* ─── Message Template Formatter ─── */
export function formatMessage(template, ...args) {
    return template.replace(/\{(\d+)\}/g, (match, index) => {
        return args[index] !== undefined ? args[index] : match;
    });
}

/* ─── Debounce ─── */
export function debounce(fn, delay = 300) {
    let timeoutId;
    return function (...args) {
        clearTimeout(timeoutId);
        timeoutId = setTimeout(() => fn.apply(this, args), delay);
    };
}
