import { LightningElement, api, track } from 'lwc';
import { dispatchCustomEvent } from 'c/cpqUtils';
import { EVENTS, getIllustration } from 'c/cpqConstants';

export default class CpqCollapsibleSidebar extends LightningElement {

    /* ── Public API ─────────────────────────────── */
    @api title     = 'Categories';
    @api iconName  = 'standard:category';
    @api sortLabel = 'Name';
    @api sortField = 'label';
    @api sortDirection = 'asc';
    @api items     = [];
    @api selectedItemId = null;
    @api isLoading = false;

    /* ── Private State ──────────────────────────── */
    @track isExpanded      = true;
    @track _expandedMap    = {};

    /* ═══════════════════════════════════════════════
       GETTERS — Panel
       ═══════════════════════════════════════════════ */

    get isCollapsed() {
        return !this.isExpanded;
    }

    get containerClass() {
        return 'slds-split-view_container '
             + (this.isExpanded ? 'slds-is-open' : 'slds-is-closed');
    }

    get toggleIcon() {
        return this.isExpanded ? 'utility:left' : 'utility:right';
    }

    get toggleTitle() {
        return this.isExpanded ? 'Close Split View' : 'Open Split View';
    }

    get toggleAriaExpanded() {
        return this.isExpanded ? 'true' : 'false';
    }

    get buttonClass() {
        const base = 'slds-button slds-button_icon slds-split-view__toggle-button';
        return this.isExpanded ? base + ' slds-is-open' : base;
    }

    /* ═══════════════════════════════════════════════
       GETTERS — Sort
       ═══════════════════════════════════════════════ */

    get sortIconName() {
        return this.sortDirection === 'asc'
            ? 'utility:arrowup'
            : 'utility:arrowdown';
    }

    get sortDirectionLabel() {
        return this.sortDirection === 'asc' ? 'Ascending' : 'Descending';
    }

    get sortHeaderClass() {
        return 'cpq-sort-header slds-split-view__list-header slds-grid';
    }

    /* ═══════════════════════════════════════════════
       GETTERS — List
       ═══════════════════════════════════════════════ */

    get itemCount() {
        return this.items.length;
    }

    get hasItems() {
        return this.items && this.items.length > 0;
    }

    get emptyStateIllustration() {
        return getIllustration('NORESULTS_UNKNOWN').name;
    }

    /* ═══════════════════════════════════════════════
       SORTING LOGIC
       ═══════════════════════════════════════════════ */

    _sortItems(items) {
        if (!items || items.length === 0) {
            return items;
        }

        const sorted = [...items];
        const field = this.sortField || 'label';
        const direction = this.sortDirection === 'desc' ? -1 : 1;

        sorted.sort((a, b) => {
            const aVal = (a[field] ?? '').toString().toLowerCase();
            const bVal = (b[field] ?? '').toString().toLowerCase();
            return aVal.localeCompare(bVal) * direction;
        });

        return sorted;
    }

    get computedItems() {
        const sortedItems = this._sortItems(this.items);

        return sortedItems.map(item => {
            const hasChildren    = !!(item.children && item.children.length);
            const isItemExpanded = !!this._expandedMap[item.id];
            const sortedChildren = hasChildren
                ? this._sortItems(item.children)
                : [];

            return {
                ...item,
                ariaCurrent:  item.id === this.selectedItemId ? 'page' : null,
                tabIndex:     item.id === this.selectedItemId ? '0'    : '-1',
                hasChildren,
                noChildren: !hasChildren,
                isItemExpanded,
                chevronClass: 'cpq-chevron'
                            + (isItemExpanded ? ' cpq-chevron-rotated' : ''),
                computedChildren: sortedChildren.map(child => ({
                    ...child,
                    ariaCurrent: child.id === this.selectedItemId ? 'page' : null,
                    tabIndex:    child.id === this.selectedItemId ? '0'    : '-1'
                }))
            };
        });
    }

    /* ═══════════════════════════════════════════════
       LIFECYCLE
       ═══════════════════════════════════════════════ */

    connectedCallback() {
        dispatchCustomEvent(this, EVENTS.SIDEBAR_REFRESH, { title: this.title });
    }

    /* ═══════════════════════════════════════════════
       HANDLERS
       ═══════════════════════════════════════════════ */

    handleSortToggle() {
        const newDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        
        console.log('[Sidebar] handleSortToggle: current direction =', this.sortDirection, 'new direction =', newDirection);
        
        dispatchCustomEvent(this, EVENTS.SORT_CHANGE, {
            sortField: this.sortField,
            sortDirection: newDirection
        });
    }

    handleToggle() {
        this.isExpanded = !this.isExpanded;
    }

    handleItemSelect(event) {
        event.preventDefault();
        const itemId = event.currentTarget.dataset.itemId;

        if (this.selectedItemId === itemId) {
            this.selectedItemId = null;
            dispatchCustomEvent(this, EVENTS.ITEM_DESELECT, { itemId });
        } else {
            this.selectedItemId = itemId;
            dispatchCustomEvent(this, EVENTS.ITEM_SELECT, { selectedItemId: itemId });
        }
    }

    handleChevronClick(event) {
        event.preventDefault();
        event.stopPropagation();

        const itemId = event.currentTarget.dataset.itemId;
        const updated = { ...this._expandedMap };

        if (updated[itemId]) {
            delete updated[itemId];
        } else {
            updated[itemId] = true;
        }

        this._expandedMap = updated;
    }

    handleRefresh() {
        if (this.selectedItemId) {
            const itemId = this.selectedItemId;
            this.selectedItemId = null;
            dispatchCustomEvent(this, EVENTS.ITEM_DESELECT, { itemId: itemId });
        }
        dispatchCustomEvent(this, EVENTS.SIDEBAR_REFRESH, { title: this.title });
    }
}