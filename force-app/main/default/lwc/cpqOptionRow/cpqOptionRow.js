import { LightningElement, api } from 'lwc';
import { formatCurrency, formatNumber } from 'c/cpqUtils';

export default class CpqOptionRow extends LightningElement {
    @api option = {};
    @api isSingleSelect = false;
    @api radioGroupName = 'options';

    _expanded = false;

    get isMultiSelect() {
        return !this.isSingleSelect;
    }

    get isExpanded() {
        return this._expanded;
    }

    get expandIcon() {
        return this._expanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get rowClass() {
        return [
            'slds-hint-parent option-row',
            this.option.isSelected ? 'row-selected' : '',
            this.option.Is_Required__c ? 'row-required' : ''
        ].filter(Boolean).join(' ');
    }

    get isQuantityEditable() {
        return this.option.Quantity_Editable__c && this.option.isSelected;
    }

    get formattedPrice() {
        return formatCurrency(this.option.listUnitPrice);
    }

    get formattedQuantity() {
        return formatNumber(this.option.quantity, 2);
    }

    get formattedWeight() {
        return formatNumber(this.option.weight, 1);
    }

    get requiredLabel() {
        return this.option.Is_Required__c ? 'Yes' : 'No';
    }

    handleSelectionChange() {
        this.dispatchEvent(new CustomEvent('optionselect', {
            detail: {
                optionId: this.option.Id,
                selected: !this.option.isSelected
            }
        }));
    }

    handleQuantityChange(event) {
        const qty = parseFloat(event.target.value) || 0;
        this.dispatchEvent(new CustomEvent('optionquantity', {
            detail: {
                optionId: this.option.Id,
                quantity: qty
            }
        }));
    }

    handleExpandToggle() {
        this._expanded = !this._expanded;
    }
}