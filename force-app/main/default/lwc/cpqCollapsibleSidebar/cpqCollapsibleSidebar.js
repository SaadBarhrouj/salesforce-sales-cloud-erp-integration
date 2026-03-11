import { LightningElement, api } from 'lwc';

export default class CpqCollapsibleSidebar extends LightningElement {
    @api title = 'Bundles';
    @api items = []; // [{ id, label, subtitle, badge, isActive, badgeVariant }]
    @api activeItemId = null;

    _collapsed = false;

    get isExpanded() {
        return !this._collapsed;
    }

    get toggleIcon() {
        return this._collapsed ? 'utility:right' : 'utility:left';
    }

    get toggleLabel() {
        return this._collapsed ? 'Expand sidebar' : 'Collapse sidebar';
    }

    get sidebarClass() {
        return [
            'cpq-sidebar',
            this._collapsed ? 'cpq-sidebar_collapsed' : 'cpq-sidebar_expanded'
        ].join(' ');
    }

    get computedItems() {
        return this.items;
    }

    handleToggle() {
        this._collapsed = !this._collapsed;
        this.dispatchEvent(new CustomEvent('sidebartoggle', {
            detail: { collapsed: this._collapsed }
        }));
    }

    handleItemClick(event) {
        const itemId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('itemselect', {
            detail: { itemId }
        }));
    }
}
