import { LightningElement, api, track } from 'lwc';
import { dispatchCustomEvent } from 'c/cpqUtils';
import { EVENTS } from 'c/cpqConstants';

export default class CpqCollapsibleSidebar extends LightningElement {

    /* ── Public API ─────────────────────────────── */
    @api title     = 'Categories';
    @api iconName  = 'standard:category';
    @api sortLabel = 'Name';
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
       GETTERS — List
       ═══════════════════════════════════════════════ */

    get itemCount() {
        return this.items.length;
    }

    get computedItems() {
        return this.items.map(item => {
            const hasChildren    = !!(item.children && item.children.length);
            const isItemExpanded = !!this._expandedMap[item.id];

            return {
                ...item,
                ariaCurrent:  item.id === this.selectedItemId ? 'page' : null,
                tabIndex:     item.id === this.selectedItemId ? '0'    : '-1',
                hasChildren,
                noChildren: !hasChildren,
                isItemExpanded,
                chevronClass: 'cpq-chevron'
                            + (isItemExpanded ? ' cpq-chevron-rotated' : ''),
                computedChildren: hasChildren
                    ? item.children.map(child => ({
                          ...child,
                          ariaCurrent: child.id === this.selectedItemId ? 'page' : null,
                          tabIndex:    child.id === this.selectedItemId ? '0'    : '-1'
                      }))
                    : []
            };
        });
    }

    /* ═══════════════════════════════════════════════
       HANDLERS
       ═══════════════════════════════════════════════ */

    handleToggle() {
        this.isExpanded = !this.isExpanded;
    }

    handleItemClick(event) {
        event.preventDefault();
        const itemId = event.currentTarget.dataset.itemId;
        
        if (this.selectedItemId === itemId) {
            this.selectedItemId = null;
            dispatchCustomEvent(this, EVENTS.ITEM_DESELECT, { itemId: itemId });
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
        dispatchCustomEvent(this, EVENTS.SIDEBAR_REFRESH, { title: this.title });
    }
}