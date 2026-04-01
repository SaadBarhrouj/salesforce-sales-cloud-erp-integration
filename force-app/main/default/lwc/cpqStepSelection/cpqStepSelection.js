import { LightningElement, api, track } from 'lwc';
import { getAllProducts, searchProducts, getProductsByCategory } from 'c/cpqDataService';
import { EVENTS, getIllustration } from 'c/cpqConstants';
import { debounce, generateId } from 'c/cpqUtils';

const COLUMNS = [
    { label: 'Code', fieldName: 'ProductCode', type: 'text', sortable: true },
    { label: 'Product Name', fieldName: 'Name', type: 'text', sortable: true, wrapText: true },
    { label: 'Description', fieldName: 'Description', type: 'text', wrapText: true },
    { label: 'Category', fieldName: 'Family', type: 'text', sortable: true },
    { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', typeAttributes: { currencyCode: 'USD', minimumFractionDigits: 2 }, sortable: true, cellAttributes: { alignment: 'right' } },
    { label: 'Bundle', fieldName: 'IsBundle', type: 'boolean', sortable: true }
];

const BUNDLE_TYPE_OPTIONS = [
    { label: 'All', value: 'all' },
    { label: 'Bundles', value: 'bundle' },
    { label: 'Standalone', value: 'standalone' }
];

export default class CpqStepSelection extends LightningElement {
    @api catalogId = '';
    @api cartItems = [];
    columns = COLUMNS;
    products = [];
    searchTerm = '';
    isLoading = false;
    _debouncedSearch;

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
        this._debouncedSearch = debounce((term) => this.performSearch(term), 350);
        await this.loadAllProducts();
    }

    /* ═══════════════════════════════════════
       GETTERS
       ═══════════════════════════════════════ */

    get selectedProductIds() {
        return (this.cartItems || []).map(item => item.productId);
    }

    get filteredProducts() {
        let result = [...this.products];

        if (this.filterProductCode) {
            const term = this.filterProductCode.toLowerCase();
            result = result.filter(product => (product.ProductCode || '').toLowerCase().includes(term));
        }

        if (this.filterBundleType === 'bundle') {
            result = result.filter(p => p.IsBundle);
        } else if (this.filterBundleType === 'standalone') {
            result = result.filter(p => !p.IsBundle);
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
        if (this.filterProductCode) {
            filters.push({ id: 'productCode', label: 'Product Code', value: this.filterProductCode, field: 'productCode' });
        }
        if (this.filterBundleType !== 'all') {
            filters.push({ id: 'bundleType', label: 'Product Type', value: this.filterBundleType === 'bundle' ? 'Bundles Only' : 'Standalone Only', field: 'bundleType' });
        }
        return filters;
    }

    get hasActiveFilters() { return this.activeFilters.length > 0; }

    /* ═══════════════════════════════════════
       DATA LOADING
       ═══════════════════════════════════════ */

    async loadAllProducts() {
        this.isLoading = true;
        try { this.products = await getAllProducts(); }
        catch (e) { console.error('Error loading products:', e); }
        finally { this.isLoading = false; }
    }

    async performSearch(term) {
        this.isLoading = true;
        try { this.products = await searchProducts(term, this.catalogId); }
        catch (e) { console.error('Error searching products:', e); }
        finally { this.isLoading = false; }
    }

    /* ═══════════════════════════════════════
       PUBLIC API (called by parent)
       ═══════════════════════════════════════ */

    @api
    handleSearchInput(searchValue) {
        this.searchTerm = searchValue || '';
        if (this.searchTerm && this.searchTerm.length >= 2) {
            this._debouncedSearch(this.searchTerm);
        } else if (!this.searchTerm) {
            this.loadAllProducts();
        }
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
        this.loadAllProducts();
    }

    @api
    clearSelections() {
        (this.cartItems || []).forEach(item => {
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
        const cartIds = new Set((this.cartItems || []).map(item => item.productId));

        selectedRows.forEach(row => {
            if (!cartIds.has(row.Id)) {
                this._dispatchProductAdd(row);
            }
        });

        (this.cartItems || []).forEach(item => {
            if (!currentSelectedIds.has(item.productId)) {
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
            isBundle: product.IsBundle,
            quantity: 1,
            listUnitPrice: product.UnitPrice,
            additionalDiscount: 0,
            netUnitPrice: product.UnitPrice,
            netTotal: product.UnitPrice,
            configured: !product.IsBundle,
            options: [],
            weight: product.Unit_Weight_Kg__c || 0
        };
        this.dispatchEvent(new CustomEvent(EVENTS.PRODUCT_ADD, { detail: { cartItem } }));
    }

    /* ═══════════════════════════════════════
       EVENT HANDLERS - Filters
       ═══════════════════════════════════════ */

    handleProductCodeChange(event) {
        this.pendingFilterProductCode = event.detail.value || '';
    }

    handleBundleTypeChange(event) {
        this.pendingFilterBundleType = event.detail.value;
    }

    handleRemoveFilter(event) {
        const field = event.detail?.name || event.target?.name || event.currentTarget?.dataset?.field;
        if (field === 'productCode') this.filterProductCode = '';
        else if (field === 'bundleType') this.filterBundleType = 'all';
    }

    applyFilters() {
        /* Apply pending filters to actual filters */
        this.filterProductCode = this.pendingFilterProductCode;
        this.filterBundleType = this.pendingFilterBundleType;
        this.isFilterPanelOpen = false;
    }

    handleRemoveAllFilters() {
        this.pendingFilterProductCode = '';
        this.pendingFilterBundleType = 'all';
        this.filterProductCode = '';
        this.filterBundleType = 'all';
    }

    closeFilterPanel() {
        this.isFilterPanelOpen = false;
    }
}
