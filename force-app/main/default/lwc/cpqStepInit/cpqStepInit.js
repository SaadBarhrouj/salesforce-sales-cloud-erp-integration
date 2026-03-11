import { LightningElement, api } from 'lwc';
import { getAccounts, getContactsByAccount, getCatalogs } from 'c/cpqDataService';
import { deepClone } from 'c/cpqUtils';

export default class CpqStepInit extends LightningElement {
    @api quoteState = {};

    accounts = [];
    contacts = [];
    catalogs = [];
    accountDetails = null;

    selectedAccountId = '';
    selectedContactId = '';
    selectedCatalogId = '';
    startDate = '';
    subscriptionTerm = null;
    additionalDiscountPercent = 0;

    _isLoading = true;

    async connectedCallback() {
        try {
            const [accs, cats] = await Promise.all([getAccounts(), getCatalogs()]);
            this.accounts = accs;
            this.catalogs = cats;

            // Restore state from parent if exists
            if (this.quoteState) {
                this.selectedAccountId = this.quoteState.accountId || '';
                this.selectedContactId = this.quoteState.contactId || '';
                this.selectedCatalogId = this.quoteState.catalogId || '';
                this.startDate = this.quoteState.startDate || '';
                this.subscriptionTerm = this.quoteState.subscriptionTerm;
                this.additionalDiscountPercent = this.quoteState.additionalDiscountPercent || 0;

                if (this.selectedAccountId) {
                    await this.loadContacts(this.selectedAccountId);
                    this.accountDetails = this.accounts.find(a => a.Id === this.selectedAccountId) || null;
                }
            }
        } catch (e) {
            // In Phase 2, use ShowToastEvent
            console.error('Error loading init data:', e);
        } finally {
            this._isLoading = false;
        }
    }

    /* ─── Computed Properties ─── */

    get accountOptions() {
        return this.accounts.map(a => ({ label: a.Name, value: a.Id }));
    }

    get contactOptions() {
        return this.contacts.map(c => ({
            label: `${c.FirstName} ${c.LastName} – ${c.Title || ''}`,
            value: c.Id
        }));
    }

    get catalogOptions() {
        return this.catalogs.map(c => ({ label: c.Name, value: c.Id }));
    }

    get isContactDisabled() {
        return !this.selectedAccountId;
    }

    get hasAccountDetails() {
        return !!this.accountDetails;
    }

    get isNextDisabled() {
        return !this.selectedAccountId || !this.selectedCatalogId || !this.startDate;
    }

    /* ─── Event Handlers ─── */

    async handleAccountChange(event) {
        this.selectedAccountId = event.detail.value;
        this.selectedContactId = '';
        this.contacts = [];
        this.accountDetails = this.accounts.find(a => a.Id === this.selectedAccountId) || null;

        if (this.selectedAccountId) {
            await this.loadContacts(this.selectedAccountId);
        }
        this.emitChange();
    }

    handleContactChange(event) {
        this.selectedContactId = event.detail.value;
        this.emitChange();
    }

    handleCatalogChange(event) {
        this.selectedCatalogId = event.detail.value;
        this.emitChange();
    }

    handleDateChange(event) {
        this.startDate = event.detail.value;
        this.emitChange();
    }

    handleTermChange(event) {
        this.subscriptionTerm = parseInt(event.detail.value, 10) || null;
        this.emitChange();
    }

    handleGlobalDiscountChange(event) {
        this.additionalDiscountPercent = parseFloat(event.detail.value) || 0;
        this.emitChange();
    }

    handleNext() {
        if (this.isNextDisabled) return;
        this.emitChange();
        this.dispatchEvent(new CustomEvent('initcomplete', {
            detail: { quoteState: this.buildState() }
        }));
    }

    /* ─── Internal ─── */

    async loadContacts(accountId) {
        try {
            this.contacts = await getContactsByAccount(accountId);
        } catch (e) {
            console.error('Error loading contacts:', e);
        }
    }

    buildState() {
        const selectedAccount = this.accounts.find(a => a.Id === this.selectedAccountId);
        const selectedContact = this.contacts.find(c => c.Id === this.selectedContactId);
        const selectedCatalog = this.catalogs.find(c => c.Id === this.selectedCatalogId);

        return {
            accountId: this.selectedAccountId,
            accountName: selectedAccount ? selectedAccount.Name : '',
            contactId: this.selectedContactId,
            contactName: selectedContact ? `${selectedContact.FirstName} ${selectedContact.LastName}` : '',
            catalogId: this.selectedCatalogId,
            catalogName: selectedCatalog ? selectedCatalog.Name : '',
            startDate: this.startDate,
            subscriptionTerm: this.subscriptionTerm,
            additionalDiscountPercent: this.additionalDiscountPercent
        };
    }

    emitChange() {
        this.dispatchEvent(new CustomEvent('statechange', {
            detail: { quoteState: deepClone(this.buildState()) }
        }));
    }
}
