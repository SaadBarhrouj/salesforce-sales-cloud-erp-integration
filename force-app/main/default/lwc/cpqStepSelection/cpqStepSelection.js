import { LightningElement, api, track } from 'lwc';
import { getProducts } from 'c/cpqDataService';
import { EVENTS, getIllustration } from 'c/cpqConstants';
import { generateId, showToast } from 'c/cpqUtils';

const COLUMNS = [
    { label: 'Product Code', fieldName: 'ProductCode', type: 'text', sortable: true },
    { label: 'Product Name', fieldName: 'Name', type: 'text', sortable: true, wrapText: true },
    { label: 'Description', fieldName: 'Description', type: 'text', wrapText: true },
    { label: 'isBundle', fieldName: 'isBundle', type: 'boolean', sortable: true }
];

const BUNDLE_TYPE_OPTIONS = [
    { label: 'All', value: 'all' },
    { label: 'Bundles', value: 'bundle' },
    { label: 'Standalone', value: 'standalone' }
];

export default class CpqStepSelection extends LightningElement {
    @api selectedProducts = [];
    columns = COLUMNS;
    products = [];
    searchTerm = '';
    isLoading = false;

    /* ── View Mode ────────────────────────── */
    @track viewMode = 'table';

    /* ── Filter Panel ─────────────────────── */
    @track isFilterPanelOpen = false;
    /* Pending filters (temporary, before apply) */
    @track pendingFilterProductCode = '';
    @track pendingFilterBundleType = 'all';
    /* Applied filters (active, used for filtering) */
    @track filterProductCode = '';
    @track filterBundleType = 'all';
    bundleTypeOptions = BUNDLE_TYPE_OPTIONS;

    emptyStateIllustration = getIllustration('NORESULTS_SEARCH').name;

    async connectedCallback() {
        await this.loadAllProducts(this.categoryId, this.pricebookId, this.catalogId);
    }

    /* ── Reactive Category Change ─────────────── */
    /* External API: categoryId / categoryLabel / pricebookId / catalogId (domain-specific) */
    _categoryId = '';
    _categoryLabel = '';
    _pricebookId = '';
    _catalogId = '';
    _loadRequestCounter = 0;

    @api
    get categoryId() {
        return this._categoryId;
    }

    set categoryId(value) {
        const oldValue = this._categoryId;
        this._categoryId = value || '';
        if (oldValue !== this._categoryId) {
            this.loadAllProducts(this._categoryId, this._pricebookId, this._catalogId);
        }
    }

    @api
    get categoryLabel() {
        return this._categoryLabel;
    }

    set categoryLabel(value) {
        this._categoryLabel = value || '';
    }

    @api
    get pricebookId() {
        return this._pricebookId;
    }

    set pricebookId(value) {
        const oldValue = this._pricebookId;
        this._pricebookId = value || '';
        if (this._pricebookId && oldValue !== this._pricebookId) {
            this.loadAllProducts(this._categoryId, this._pricebookId, this._catalogId);
        }
    }

    @api
    get catalogId() {
        return this._catalogId;
    }

    set catalogId(value) {
        const oldValue = this._catalogId;
        this._catalogId = value || '';
        if (this._catalogId && oldValue !== this._catalogId) {
            this.loadAllProducts(this._categoryId, this._pricebookId, this._catalogId);
        }
    }

    /* ═══════════════════════════════════════
       GETTERS
       ═══════════════════════════════════════ */

    get selectedProductIds() {
        return (this.selectedProducts || []).map(item => item.productId);
    }

    get filteredProducts() {
        let result = [...this.products];

        if (this.searchTerm) {
            const term = this.searchTerm.trim().toLowerCase();
            if (term) {
                result = result.filter(product => (
                    (product.Name || '').toLowerCase().includes(term) ||
                    (product.ProductCode || '').toLowerCase().includes(term) ||
                    (product.Description || '').toLowerCase().includes(term)
                ));
            }
        }

        if (this.filterProductCode) {
            const term = this.filterProductCode.toLowerCase();
            result = result.filter(product => (product.ProductCode || '').toLowerCase().includes(term));
        }

        if (this.filterBundleType !== 'all') {
            const isBundle = this.filterBundleType === 'bundle';
            result = result.filter(product => product.isBundle === isBundle);
        }

        return result;
    }

    get hasProducts() { return !this.isLoading && this.filteredProducts.length > 0; }
    get hasNoProducts() { return !this.isLoading && this.filteredProducts.length === 0; }

    get isTableView() { return this.viewMode === 'table'; }
    get isCardView() { return this.viewMode === 'cards'; }

    get cardProducts() {
        const selectedIds = new Set(this.selectedProductIds);
        return this.filteredProducts.map(p => ({
            ...p,
            _isInCart: selectedIds.has(p.Id)
        }));
    }

    get filterPanelClass() {
        const base = 'filter-panel';
        return this.isFilterPanelOpen ? `${base} filter-panel--open` : base;
    }

    get filterPanelHidden() {
        return !this.isFilterPanelOpen;
    }

    @api
    get filterPanelOpen() {
        return this.isFilterPanelOpen;
    }

    get activeFilters() {
        const filters = [];
        if (this._categoryLabel) {
            filters.push({ id: 'category', label: 'Category: ' + this._categoryLabel, value: this._categoryId, field: 'category' });
        }
        if (this.filterProductCode) {
            filters.push({ id: 'productCode', label: 'Product Code', value: this.filterProductCode, field: 'productCode' });
        }
        if (this.filterBundleType !== 'all') {
            const label = this.filterBundleType === 'bundle' ? 'Bundles' : 'Standalone';
            filters.push({ id: 'bundleType', label: 'Type: ' + label, value: this.filterBundleType, field: 'bundleType' });
        }
        return filters;
    }

    get hasActiveFilters() { return this.activeFilters.length > 0; }

    /* ═══════════════════════════════════════
       DATA LOADING
       ═══════════════════════════════════════ */

    async loadAllProducts(categoryId, pricebookId, catalogId) {
        this.isLoading = true;
        const requestId = ++this._loadRequestCounter;
        try {
            const products = await getProducts(categoryId, pricebookId, catalogId);
            if (requestId === this._loadRequestCounter) {
                this.products = products;
            }
        }
        catch (e) {
            if (requestId === this._loadRequestCounter) {
                const message = e?.body?.message || e?.message || 'Failed to load products.';
                showToast(this, 'Error', message, 'error');
            }
        }
        finally {
            if (requestId === this._loadRequestCounter) {
                this.isLoading = false;
            }
        }
    }

    /* ═══════════════════════════════════════
       PUBLIC API (called by parent)
       ═══════════════════════════════════════ */

    @api
    handleSearchInput(searchValue) {
        this.searchTerm = searchValue || '';
    }

    @api
    toggleFilterPanel() {
        this.isFilterPanelOpen = !this.isFilterPanelOpen;
        /* Sync pending filters with applied filters when opening */
        if (this.isFilterPanelOpen) {
            this.pendingFilterProductCode = this.filterProductCode;
            this.pendingFilterBundleType = this.filterBundleType;
        }
    }

    @api
    refreshProducts() {
        this.searchTerm = '';
        this.loadAllProducts(this._categoryId, this._pricebookId, this._catalogId);
    }

    @api
    clearSelections() {
        (this.selectedProducts || []).forEach(item => {
            this.dispatchEvent(new CustomEvent(EVENTS.PRODUCT_REMOVE, {
                detail: { productId: item.productId }
            }));
        });
    }

    @api
    setViewMode(mode) {
        if (mode === 'table' || mode === 'cards') {
            this.viewMode = mode;
        }
    }

    /* ═══════════════════════════════════════
       EVENT HANDLERS - Selection
       ═══════════════════════════════════════ */

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows || [];
        const currentSelectedIds = new Set(selectedRows.map(row => row.Id));
        const visibleProductIds = new Set(this.filteredProducts.map(product => product.Id));
        const cartIds = new Set((this.selectedProducts || []).map(item => item.productId));

        selectedRows.forEach(row => {
            if (!cartIds.has(row.Id)) {
                this._dispatchProductAdd(row);
            }
        });

        (this.selectedProducts || []).forEach(item => {
            if (visibleProductIds.has(item.productId) && !currentSelectedIds.has(item.productId)) {
                this.dispatchEvent(new CustomEvent(EVENTS.PRODUCT_REMOVE, {
                    detail: { productId: item.productId }
                }));
            }
        });
    }

    handleProductToggle(event) {
        const { productId, selected } = event.detail;
        if (selected) {
            const product = this.products.find(p => p.Id === productId);
            if (product) this._dispatchProductAdd(product);
        } else {
            this.dispatchEvent(new CustomEvent(EVENTS.PRODUCT_REMOVE, { detail: { productId } }));
        }
    }

    _dispatchProductAdd(product) {
        const cartItem = {
            _key: generateId('item'),
            productId: product.Id,
            productCode: product.ProductCode,
            productName: product.Name,
            isBundle: !!product.isBundle,
            quantity: 1,
            listUnitPrice: 0,
            additionalDiscount: 0,
            netUnitPrice: 0,
            netTotal: 0,
            configured: true,
            options: [],
            weight: product.Unit_Weight_Kg__c || 0
        };
        this.dispatchEvent(new CustomEvent(EVENTS.PRODUCT_ADD, { detail: { cartItem } }));
    }

    /* ═══════════════════════════════════════
       EVENT HANDLERS - Filters
       ═══════════════════════════════════════ */

    handleFilterProductCodeChange(event) {
        this.pendingFilterProductCode = event.detail.value || '';
    }

    handleFilterBundleTypeChange(event) {
        this.pendingFilterBundleType = event.detail.value;
    }

    handleRemoveFilter(event) {
        const field = event.detail?.name || event.target?.name || event.currentTarget?.dataset?.field;
        if (field === 'category') {
            this._categoryId = '';
            this._categoryLabel = '';
            this.dispatchEvent(new CustomEvent(EVENTS.ITEM_DESELECT, { detail: {} }));
            this.loadAllProducts(this._categoryId, this._pricebookId, this._catalogId);
        } else if (field === 'productCode') {
            this.filterProductCode = '';
            this.pendingFilterProductCode = '';
        } else if (field === 'bundleType') {
            this.filterBundleType = 'all';
            this.pendingFilterBundleType = 'all';
        }
    }

    handleApplyFilters() {
        this.filterProductCode = this.pendingFilterProductCode;
        this.filterBundleType = this.pendingFilterBundleType;
        this.isFilterPanelOpen = false;
    }

    handleResetFilters() {
        this.pendingFilterProductCode = '';
        this.pendingFilterBundleType = 'all';
        this.filterProductCode = '';
        this.filterBundleType = 'all';
        this.loadAllProducts(this._categoryId, this._pricebookId, this._catalogId);
    }

    handleCloseFilterPanel() {
        this.isFilterPanelOpen = false;
    }
}