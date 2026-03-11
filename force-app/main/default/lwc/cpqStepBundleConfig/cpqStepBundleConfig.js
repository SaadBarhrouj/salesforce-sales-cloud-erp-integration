import { LightningElement, api } from 'lwc';
import { getFeaturesByProduct, getOptionsByFeature } from 'c/cpqDataService';
import { deepClone, isSingleSelect, getSelectionMode, validateFeatureSelections, calculateCompleteness, formatCurrency } from 'c/cpqUtils';
import { SELECTION_MODES } from 'c/cpqConstants';

export default class CpqStepBundleConfig extends LightningElement {
    @api cartItems = [];

    features = [];
    activeBundleKey = null;
    activeFeatureId = null;
    isLoading = false;

    _optionsByFeature = {}; // { featureId: [options] }
    _sidebarCollapsed = false;

    async connectedCallback() {
        const bundles = this.bundleItems;
        if (bundles.length > 0) {
            this.activeBundleKey = bundles[0]._key;
            await this.loadFeaturesForBundle(bundles[0].productId);
        }
    }

    /* ─── Computed ─── */

    get bundleItems() {
        return (this.cartItems || []).filter(i => i.isBundle);
    }

    get hasActiveBundle() {
        return !!this.activeBundleKey && this.features.length > 0;
    }

    get hasNoBundles() {
        return this.bundleItems.length === 0 && !this.isLoading;
    }

    get activeBundleName() {
        const item = this.bundleItems.find(b => b._key === this.activeBundleKey);
        return item ? item.productName : '';
    }

    get sidebarItems() {
        return this.bundleItems.map(b => {
            const completeness = this.getBundleCompleteness(b);
            return {
                id: b._key,
                label: b.productName,
                subtitle: b.productCode,
                badge: `${completeness}%`,
                badgeClass: completeness === 100
                    ? 'slds-badge slds-theme_success'
                    : 'slds-badge slds-theme_warning',
                isActive: b._key === this.activeBundleKey,
                itemClass: [
                    'slds-listbox__item',
                    b._key === this.activeBundleKey ? 'slds-is-selected' : ''
                ].filter(Boolean).join(' ')
            };
        });
    }

    get completenessValue() {
        return calculateCompleteness(this.features, this._optionsByFeature);
    }

    get completenessLabel() {
        return `${this.completenessValue}% configured`;
    }

    get completenessStyle() {
        return `width: ${this.completenessValue}%`;
    }

    /* ─── Data Loading ─── */

    async loadFeaturesForBundle(productId) {
        this.isLoading = true;
        try {
            const rawFeatures = await getFeaturesByProduct(productId);
            this._optionsByFeature = {};

            // Load options for each feature in parallel
            const optionPromises = rawFeatures.map(f => getOptionsByFeature(f.Id));
            const optionResults = await Promise.all(optionPromises);

            rawFeatures.forEach((f, idx) => {
                this._optionsByFeature[f.Id] = optionResults[idx];
            });

            // Restore previously saved selections from cart
            const activeBundle = this.bundleItems.find(b => b._key === this.activeBundleKey);
            if (activeBundle && activeBundle.options && activeBundle.options.length > 0) {
                this.restoreSelectionsFromCart(activeBundle.options);
            }

            this.rebuildFeatures(rawFeatures);

            if (rawFeatures.length > 0) {
                this.activeFeatureId = rawFeatures[0].Id;
            }
        } catch (e) {
            console.error('Error loading bundle configuration:', e);
        } finally {
            this.isLoading = false;
        }
    }

    restoreSelectionsFromCart(savedOptions) {
        const savedMap = {};
        savedOptions.forEach(o => { savedMap[o.optionId] = o; });

        Object.keys(this._optionsByFeature).forEach(featureId => {
            this._optionsByFeature[featureId] = this._optionsByFeature[featureId].map(opt => {
                const saved = savedMap[opt.Id];
                if (saved) {
                    return { ...opt, isSelected: saved.isSelected, quantity: saved.quantity };
                }
                return opt;
            });
        });
    }

    rebuildFeatures(rawFeatures) {
        this.features = rawFeatures.map(f => {
            const mode = getSelectionMode(f);
            const isSingle = isSingleSelect(f);
            const options = this._optionsByFeature[f.Id] || [];
            const selectedCount = options.filter(o => o.isSelected).length;
            const errors = validateFeatureSelections(f, selectedCount);

            return {
                ...f,
                _options: options,
                _isSingleSelect: isSingle,
                _radioGroup: `radio-${f.Id}`,
                _selectionLabel: isSingle ? 'Single Select' : 'Multi Select',
                _minLabel: f.Min_Options__c ? `Min: ${f.Min_Options__c}` : null,
                _maxLabel: f.Max_Options__c ? `Max: ${f.Max_Options__c}` : null,
                _errors: errors
            };
        });
    }

    getBundleCompleteness(bundleItem) {
        if (!bundleItem.isBundle) return 100;
        // If this bundle is actively being configured, use live data
        if (bundleItem._key === this.activeBundleKey && this.features.length > 0) {
            return calculateCompleteness(this.features, this._optionsByFeature);
        }
        // Otherwise check if previously configured
        return bundleItem.configured ? 100 : 0;
    }

    /* ─── Event Handlers ─── */

    async handleBundleSelect(event) {
        // Save current config before switching
        this.saveCurrentConfig();

        const itemId = event.detail.itemId;
        this.activeBundleKey = itemId;
        const bundle = this.bundleItems.find(b => b._key === itemId);
        if (bundle) {
            await this.loadFeaturesForBundle(bundle.productId);
        }
    }

    handleSidebarToggle(event) {
        this._sidebarCollapsed = event.detail.collapsed;
    }

    handleFeatureTabChange(event) {
        this.activeFeatureId = event.target.value;
    }

    handleOptionSelect(event) {
        const { optionId, selected } = event.detail;
        const featureId = this.findFeatureIdForOption(optionId);
        if (!featureId) return;

        const feature = this.features.find(f => f.Id === featureId);
        let options = deepClone(this._optionsByFeature[featureId]);

        if (isSingleSelect(feature)) {
            // Deselect all others, select clicked one
            options = options.map(o => ({
                ...o,
                isSelected: o.Id === optionId ? selected : false
            }));
        } else {
            options = options.map(o => {
                if (o.Id === optionId) {
                    if (o.Is_Required__c && !selected) return o; // Can't deselect required
                    return { ...o, isSelected: selected };
                }
                return o;
            });
        }

        this._optionsByFeature[featureId] = options;
        this.rebuildFeatures(this.features.map(f => {
            const { _options, _isSingleSelect, _radioGroup, _selectionLabel, _minLabel, _maxLabel, _errors, ...raw } = f;
            return raw;
        }));
    }

    handleOptionQuantity(event) {
        const { optionId, quantity } = event.detail;
        const featureId = this.findFeatureIdForOption(optionId);
        if (!featureId) return;

        this._optionsByFeature[featureId] = this._optionsByFeature[featureId].map(o => {
            if (o.Id === optionId) {
                const clampedQty = Math.min(Math.max(quantity, o.Min_Quantity__c || 1), o.Max_Quantity__c || 999);
                return { ...o, quantity: clampedQty };
            }
            return o;
        });
        this.rebuildFeatures(this.features.map(f => {
            const { _options, _isSingleSelect, _radioGroup, _selectionLabel, _minLabel, _maxLabel, _errors, ...raw } = f;
            return raw;
        }));
    }

    handleBack() {
        this.saveCurrentConfig();
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'back' } }));
    }

    handleNext() {
        this.saveCurrentConfig();
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'next' } }));
    }

    /* ─── Internal Helpers ─── */

    findFeatureIdForOption(optionId) {
        for (const [featureId, options] of Object.entries(this._optionsByFeature)) {
            if (options.some(o => o.Id === optionId)) {
                return featureId;
            }
        }
        return null;
    }

    saveCurrentConfig() {
        if (!this.activeBundleKey) return;

        // Flatten all options across all features
        const allOptions = [];
        Object.entries(this._optionsByFeature).forEach(([featureId, options]) => {
            options.forEach(o => {
                allOptions.push({
                    optionId: o.Id,
                    featureId,
                    featureName: o.featureName || '',
                    productId: o.Option_Product__c,
                    productCode: o.productCode,
                    productName: o.productName,
                    optionType: o.Option_Type__c,
                    isSelected: o.isSelected,
                    isRequired: o.Is_Required__c,
                    quantity: o.quantity,
                    listUnitPrice: o.listUnitPrice,
                    additionalDiscount: 0,
                    weight: o.weight || 0
                });
            });
        });

        this.dispatchEvent(new CustomEvent('configupdate', {
            detail: {
                itemKey: this.activeBundleKey,
                options: deepClone(allOptions),
                configured: this.completenessValue === 100
            }
        }));
    }
}
