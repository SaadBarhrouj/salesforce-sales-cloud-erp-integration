import { LightningElement, api } from 'lwc';
import { formatCurrency } from 'c/cpqUtils';

export default class CpqProductCard extends LightningElement {
    @api product = {};
    @api isInCart = false;

    get formattedPrice() {
        return formatCurrency(this.product.UnitPrice);
    }

    get cardClass() {
        return [
            'product-card slds-box slds-box_x-small',
            this.isInCart ? 'card-selected' : ''
        ].filter(Boolean).join(' ');
    }

    handleToggle(event) {
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent('producttoggle', {
            detail: {
                productId: this.product.Id,
                selected: !this.isInCart
            }
        }));
    }
}
