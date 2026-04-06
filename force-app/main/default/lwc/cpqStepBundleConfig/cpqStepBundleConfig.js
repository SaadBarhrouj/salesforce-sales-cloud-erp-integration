import { LightningElement, api, track } from 'lwc';
import { getFeaturesByProduct, getOptionsByFeature } from 'c/cpqDataService';
import { deepClone, isSingleSelect, getSelectionMode, validateFeatureSelections, calculateCompleteness, formatCurrency } from 'c/cpqUtils';
import { SELECTION_MODES } from 'c/cpqConstants';

export default class CpqStepBundleConfig extends LightningElement {
    @api selectedProducts = [];

    _selectedBundleId = null;

    @api
    get selectedBundleId() {
        return this._selectedBundleId;
    }

    set selectedBundleId(value) {
        const oldValue = this._selectedBundleId;
        this._selectedBundleId = value || null;

        if (oldValue !== this._selectedBundleId && this._selectedBundleId) {
            this.activeBundleKey = this._selectedBundleId;
            const bundle = this.bundleItems.find(
                (b) => b._key === this._selectedBundleId
            );
            if (bundle) {
                this.loadFeaturesForBundle(bundle.productId);
            }
        }
    }

    @track features = [];
    @track activeBundleKey = null;
    @track activeFeatureId = null;
    @track isLoading = false;
    @track hasError = false;
    @track errorMessage = '';
    @track featureOrganization = 'default';

    _optionsByFeature = {};

    async connectedCallback() {
        const bundles = this.bundleItems;
        if (bundles.length > 0) {
            const initialBundleKey =
                this._selectedBundleId || bundles[0]._key;
            this.activeBundleKey = initialBundleKey;
            const bundle = bundles.find((b) => b._key === initialBundleKey);
            if (bundle) {
                await this.loadFeaturesForBundle(bundle.productId);
            }
        }
    }

    /* ─── Computed Properties ─── */

    get bundleItems() {
        return (this.selectedProducts || []).filter(i => i.isBundle);
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

    get activeBundleProductId() {
        const item = this.bundleItems.find(b => b._key === this.activeBundleKey);
        return item ? item.productId : null;
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

    /* ─── Public API Methods ─── */

    @api
    refresh() {
        if (this.activeBundleKey && this.activeBundleProductId) {
            this.loadFeaturesForBundle(this.activeBundleProductId);
        }
    }

    @api
    resetCurrentBundle() {
        if (!this.activeBundleKey) return;
        
        this._optionsByFeature = {};
        this.features = [];
        
        if (this.activeBundleProductId) {
            this.loadFeaturesForBundle(this.activeBundleProductId);
        }
    }

    @api
    setFeatureOrganization(organization) {
        this.featureOrganization = organization;
        if (organization === 'section') {
            this._groupFeaturesBySection();
        } else if (organization === 'tab') {
            this.featureOrganization = 'default';
        }
    }

    /* ─── Data Loading ─── */

    async loadFeaturesForBundle(productId) {
        if (!productId) return;
        
        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';

        try {
            const rawFeatures = await getFeaturesByProduct(productId);
            
            if (!rawFeatures || rawFeatures.length === 0) {
                this.features = [];
                this.isLoading = false;
                return;
            }

            this._optionsByFeature = {};

            const optionPromises = rawFeatures.map(f => getOptionsByFeature(f.Id));
            const optionResults = await Promise.all(optionPromises);

            rawFeatures.forEach((f, idx) => {
                this._optionsByFeature[f.Id] = optionResults[idx] || [];
            });

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
            this.hasError = true;
            this.errorMessage = e.message || 'Failed to load bundle configuration';
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
        if (bundleItem._key === this.activeBundleKey && this.features.length > 0) {
            return calculateCompleteness(this.features, this._optionsByFeature);
        }
        return bundleItem.configured ? 100 : 0;
    }

    _groupFeaturesBySection() {
        const sections = {};
        this.features.forEach(f => {
            const section = f.Section__c || 'Default';
            if (!sections[section]) {
                sections[section] = [];
            }
            sections[section].push(f);
        });
    }

    /* ─── Event Handlers ─── */

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
            options = options.map(o => ({
                ...o,
                isSelected: o.Id === optionId ? selected : false
            }));
        } else {
            options = options.map(o => {
                if (o.Id === optionId) {
                    if (o.Is_Required__c && !selected) return o;
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
        
        this._autoSaveConfig();
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
        
        this._autoSaveConfig();
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

    _autoSaveConfig() {
        this.saveCurrentConfig();
    }

    @api
    saveCurrentConfig() {
        if (!this.activeBundleKey) return;

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
