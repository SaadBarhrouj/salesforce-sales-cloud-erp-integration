import { LightningElement, api } from 'lwc';
import { getCategoriesByCatalog, getProductsByCategory, searchProducts } from 'c/cpqDataService';
import { buildCategoryTree, debounce, deepClone, generateId } from 'c/cpqUtils';

export default class CpqStepSelection extends LightningElement {
    @api catalogId = '';
    @api cartItems = [];

    categories = [];
    categoryTree = [];
    products = [];
    selectedCategoryId = null;
    searchTerm = '';
    isLoading = false;

    _debouncedSearch;

    async connectedCallback() {
        this._debouncedSearch = debounce((term) => this.performSearch(term), 350);
        if (this.catalogId) {
            await this.loadCategories();
        }
    }

    /* ─── Computed ─── */

    get displayProducts() {
        const cartIds = new Set((this.cartItems || []).map(i => i.productId));
        return this.products.map(p => ({
            ...p,
            _inCart: cartIds.has(p.Id)
        }));
    }

    get hasProducts() {
        return !this.isLoading && this.products.length > 0;
    }

    get hasNoProducts() {
        return !this.isLoading && this.products.length === 0;
    }

    get cartCountLabel() {
        const count = (this.cartItems || []).length;
        return `${count} product${count !== 1 ? 's' : ''} in cart`;
    }

    get isNextDisabled() {
        return !this.cartItems || this.cartItems.length === 0;
    }

    /* ─── Data Loading ─── */

    async loadCategories() {
        try {
            this.categories = await getCategoriesByCatalog(this.catalogId);
            this.categoryTree = buildCategoryTree(this.categories, this.catalogId);
        } catch (e) {
            console.error('Error loading categories:', e);
        }
    }

    async loadProducts(categoryId) {
        this.isLoading = true;
        try {
            this.products = await getProductsByCategory(categoryId);
        } catch (e) {
            console.error('Error loading products:', e);
        } finally {
            this.isLoading = false;
        }
    }

    async performSearch(term) {
        this.isLoading = true;
        try {
            this.products = await searchProducts(term, this.catalogId);
        } catch (e) {
            console.error('Error searching products:', e);
        } finally {
            this.isLoading = false;
        }
    }

    /* ─── Event Handlers ─── */

    handleCategorySelect(event) {
        this.selectedCategoryId = event.detail.name;
        this.searchTerm = '';
        this.loadProducts(this.selectedCategoryId);
    }

    handleSearchInput(event) {
        this.searchTerm = event.target.value;
        if (this.searchTerm && this.searchTerm.length >= 2) {
            this._debouncedSearch(this.searchTerm);
        } else if (!this.searchTerm && this.selectedCategoryId) {
            this.loadProducts(this.selectedCategoryId);
        }
    }

    handleProductToggle(event) {
        const { productId, selected } = event.detail;
        const product = this.products.find(p => p.Id === productId);
        if (!product) return;

        if (selected) {
            this.dispatchEvent(new CustomEvent('productadd', {
                detail: {
                    cartItem: {
                        _key: generateId('item'),
                        productId: product.Id,
                        productCode: product.ProductCode,
                        productName: product.Name,
                        isBundle: product.IsBundle || false,
                        quantity: 1,
                        listUnitPrice: product.UnitPrice || 0,
                        additionalDiscount: 0,
                        netUnitPrice: product.UnitPrice || 0,
                        netTotal: product.UnitPrice || 0,
                        configured: !product.IsBundle,
                        options: [],
                        weight: product.Unit_Weight_Kg__c || 0
                    }
                }
            }));
        } else {
            this.dispatchEvent(new CustomEvent('productremove', {
                detail: { productId }
            }));
        }
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'back' } }));
    }

    handleNext() {
        if (this.isNextDisabled) return;
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'next' } }));
    }
}
