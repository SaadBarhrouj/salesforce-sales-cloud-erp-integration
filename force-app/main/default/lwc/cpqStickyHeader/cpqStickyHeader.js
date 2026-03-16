import { LightningElement, api } from 'lwc';

export default class CpqStickyHeader extends LightningElement {
    @api topLabel = '';
    @api title = '';
    @api subtitle = '';
    @api iconName = '';
    @api stepActions = []; // [{ name, label, variant, iconName, disabled }]
    @api globalActions = []; // [{ name, label, variant, iconName, disabled }]

    handleAction(event) {
        const actionName = event.currentTarget.dataset.action;
        this.dispatchEvent(new CustomEvent('headeraction', {
            detail: { action: actionName }
        }));
    }
}
