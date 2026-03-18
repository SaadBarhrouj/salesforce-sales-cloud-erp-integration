/**
 * CPQ Configurator – Data Service Module
 * Promise-based data access layer returning mock data.
 * Phase 2: Replace each function body with wire() or imperative @AuraEnabled Apex calls.
 */
import {
    ACCOUNTS, CONTACTS, CATALOGS, CATEGORIES, PRODUCTS,
    PRODUCT_CATEGORY_PRODUCTS, BUNDLE_FEATURES, BUNDLE_OPTIONS,
    VOLUME_PRICING_SCHEDULES, VOLUME_PRICING_TIERS,
    PRODUCT_RULES, RULE_CONDITIONS, RULE_ACTIONS, BUNDLE_RULE_ASSIGNMENTS,
    LOCATIONS
} from 'c/cpqMockData';
import { deepClone, getCategoryIdsWithDescendants } from 'c/cpqUtils';

const SIMULATED_DELAY = 150; // ms – simulates network latency

function simulateAsync(data) {
    return new Promise((resolve) => {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => resolve(deepClone(data)), SIMULATED_DELAY);
    });
}

/* ═══════════════════════════════════════════
   Step 1 – Quote Setup
   ═══════════════════════════════════════════ */

/** Fetch active accounts for combobox. */
export function getAccounts() {
    const active = ACCOUNTS.filter(a => a.Active__c === 'Yes');
    return simulateAsync(active);
}

/** Fetch contacts related to an account. */
export function getContactsByAccount(accountId) {
    const filtered = CONTACTS.filter(c => c.AccountId === accountId);
    return simulateAsync(filtered);
}

/** Fetch available catalogs. */
export function getCatalogs() {
    return simulateAsync(CATALOGS);
}

/* ═══════════════════════════════════════════
   Step 2 – Product Selection
   ═══════════════════════════════════════════ */

/** Fetch categories for a catalog (hierarchical). */
export function getCategoriesByCatalog(catalogId) {
    const filtered = CATEGORIES.filter(c => c.CatalogId === catalogId);
    return simulateAsync(filtered);
}

/** Fetch products for a category (including sub-categories). */
export function getProductsByCategory(categoryId) {
    const categoryIds = getCategoryIdsWithDescendants(categoryId, CATEGORIES);
    const productIds = PRODUCT_CATEGORY_PRODUCTS
        .filter(pcp => categoryIds.includes(pcp.ProductCategoryId))
        .map(pcp => pcp.ProductId);
    const unique = [...new Set(productIds)];
    const products = PRODUCTS.filter(p => unique.includes(p.Id) && p.IsActive);
    return simulateAsync(products);
}

/** Fetch all active products. */
export function getAllProducts() {
    const products = PRODUCTS.filter(p => p.IsActive);
    return simulateAsync(products);
}

/** Search products by name or code (debounced on caller side). */
export function searchProducts(term, catalogId) {
    if (!term || term.length < 2) return simulateAsync([]);
    const lowerTerm = term.toLowerCase();

    // Restrict to catalog if provided
    let allowedProductIds = null;
    if (catalogId) {
        const catCategoryIds = CATEGORIES
            .filter(c => c.CatalogId === catalogId)
            .map(c => c.Id);
        allowedProductIds = new Set(
            PRODUCT_CATEGORY_PRODUCTS
                .filter(pcp => catCategoryIds.includes(pcp.ProductCategoryId))
                .map(pcp => pcp.ProductId)
        );
    }

    const results = PRODUCTS.filter(p => {
        if (!p.IsActive) return false;
        if (allowedProductIds && !allowedProductIds.has(p.Id)) return false;
        return (
            p.Name.toLowerCase().includes(lowerTerm) ||
            p.ProductCode.toLowerCase().includes(lowerTerm) ||
            (p.Family && p.Family.toLowerCase().includes(lowerTerm))
        );
    });
    return simulateAsync(results);
}

/* ═══════════════════════════════════════════
   Step 3 – Bundle Configuration
   ═══════════════════════════════════════════ */

/** Fetch features (tabs) for a bundle product. */
export function getFeaturesByProduct(productId) {
    const features = BUNDLE_FEATURES
        .filter(f => f.Product__c === productId)
        .sort((a, b) => a.Sort_Order__c - b.Sort_Order__c);
    return simulateAsync(features);
}

/** Fetch options for a feature, enriched with product details. */
export function getOptionsByFeature(featureId) {
    const options = BUNDLE_OPTIONS
        .filter(o => o.Feature__c === featureId)
        .sort((a, b) => (a.Sort_Order__c || 0) - (b.Sort_Order__c || 0))
        .map(o => {
            const product = PRODUCTS.find(p => p.Id === o.Option_Product__c) || {};
            return {
                ...o,
                productName: product.Name || 'Unknown',
                productCode: product.ProductCode || '',
                productDescription: product.Description || '',
                listUnitPrice: product.UnitPrice || 0,
                family: product.Family || '',
                weight: product.Unit_Weight_Kg__c || 0,
                isSelected: o.Is_Selected__c,
                quantity: o.Default_Quantity__c || 1
            };
        });
    return simulateAsync(options);
}

/** Fetch ALL options for a bundle product (all features), enriched. */
export function getAllOptionsByProduct(productId) {
    const features = BUNDLE_FEATURES.filter(f => f.Product__c === productId);
    const featureIds = features.map(f => f.Id);
    const options = BUNDLE_OPTIONS
        .filter(o => featureIds.includes(o.Feature__c))
        .sort((a, b) => (a.Sort_Order__c || 0) - (b.Sort_Order__c || 0))
        .map(o => {
            const product = PRODUCTS.find(p => p.Id === o.Option_Product__c) || {};
            const feature = features.find(f => f.Id === o.Feature__c);
            return {
                ...o,
                featureName: feature ? feature.Name : 'Other Options',
                productName: product.Name || 'Unknown',
                productCode: product.ProductCode || '',
                productDescription: product.Description || '',
                listUnitPrice: product.UnitPrice || 0,
                family: product.Family || '',
                weight: product.Unit_Weight_Kg__c || 0,
                isSelected: o.Is_Selected__c,
                quantity: o.Default_Quantity__c || 1
            };
        });
    return simulateAsync(options);
}

/* ═══════════════════════════════════════════
   Volume Pricing
   ═══════════════════════════════════════════ */

/** Fetch volume pricing tiers for a product. */
export function getVolumePricing(productId) {
    const schedules = VOLUME_PRICING_SCHEDULES.filter(
        s => s.Product__c === productId && s.Is_Active__c
    );
    const result = schedules.map(s => ({
        ...s,
        tiers: VOLUME_PRICING_TIERS
            .filter(t => t.Volume_Pricing_Schedule__c === s.Id)
            .sort((a, b) => a.Sort_Order__c - b.Sort_Order__c)
    }));
    return simulateAsync(result);
}

/* ═══════════════════════════════════════════
   Product Rules
   ═══════════════════════════════════════════ */

/** Fetch active rules assigned to a bundle. */
export function getRulesByProduct(productId) {
    const assignmentRuleIds = BUNDLE_RULE_ASSIGNMENTS
        .filter(a => a.Bundle_Product__c === productId && a.Is_Active__c)
        .map(a => a.Product_Rule__c);
    const rules = PRODUCT_RULES
        .filter(r => assignmentRuleIds.includes(r.Id) && r.Is_Active__c)
        .sort((a, b) => (a.Evaluation_Order__c || 0) - (b.Evaluation_Order__c || 0))
        .map(r => ({
            ...r,
            conditions: RULE_CONDITIONS.filter(c => c.Product_Rule__c === r.Id),
            actions: RULE_ACTIONS.filter(a => a.Product_Rule__c === r.Id)
        }));
    return simulateAsync(rules);
}

/* ═══════════════════════════════════════════
   Step 5 – Logistics
   ═══════════════════════════════════════════ */

/** Fetch available locations (warehouses, agencies, client sites). */
export function getLocations() {
    const active = LOCATIONS.filter(l => l.IsActive);
    return simulateAsync(active);
}

/** Simulate saving a quote. */
export function saveQuote(quotePayload) {
    // Phase 2: Replace with Apex DML
    return new Promise((resolve) => {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            resolve({
                success: true,
                quoteId: 'Q-' + String(Math.floor(Math.random() * 90000) + 10000),
                message: 'Quote saved successfully (mock).'
            });
        }, SIMULATED_DELAY * 2);
    });
}
