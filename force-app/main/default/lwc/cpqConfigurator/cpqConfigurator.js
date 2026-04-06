import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import OPP_NAME from "@salesforce/schema/Opportunity.Name";
import OPP_ACCOUNT_ID from "@salesforce/schema/Opportunity.AccountId";
import OPP_ACCOUNT_NAME from "@salesforce/schema/Opportunity.Account.Name";
import OPP_PRICEBOOK_ID from "@salesforce/schema/Opportunity.Pricebook2Id";
import OPP_PRICEBOOK_NAME from "@salesforce/schema/Opportunity.Pricebook2.Name";
import OPP_OFFER_TYPE from "@salesforce/schema/Opportunity.Offer_Type__c";
import OPP_OFFER_TYPE_NAME from "@salesforce/schema/Opportunity.Offer_Type__r.Name";
import getSidebarCategoriesByOfferType from "@salesforce/apex/ProductCategoryController.getSidebarCategoriesByOfferType";
import { STEPS, MESSAGES, STEP_LIST } from "c/cpqConstants";
import {
  deepClone,
  calculateSelectedProductTotal,
  formatCurrency,
  showToast
} from "c/cpqUtils";

const OPP_FIELDS = [
  OPP_NAME,
  OPP_ACCOUNT_ID,
  OPP_ACCOUNT_NAME,
  OPP_PRICEBOOK_ID,
  OPP_PRICEBOOK_NAME,
  OPP_OFFER_TYPE,
  OPP_OFFER_TYPE_NAME
];

export default class CpqConfigurator extends NavigationMixin(LightningElement) {
  @api recordId;
  @api objectApiName;
  @api opportunityNumber;

  /* ── wire data ────────────────────────────────── */
  opportunityRecord;

  @wire(getRecord, { recordId: "$recordId", fields: OPP_FIELDS })
  wiredOpportunityRecord(result) {
    this.opportunityRecord = result;
    this.initSidebarData(this.currentStep.key);
  }

  /* ── lifecycle ────────────────────────────────── */
  connectedCallback() {
    // Initialize sidebar data when component mounts
    this.initSidebarData(this.currentStep.key);
  }

  _goNext() {
    const currentIndex = STEP_LIST.findIndex(
      (s) => s.key === this.currentStep.key
    );
    if (currentIndex < STEP_LIST.length - 1) {
      this.currentStep = STEP_LIST[currentIndex + 1];
      this.initSidebarData(this.currentStep.key);
    }
  }

  _goBack() {
    const currentIndex = STEP_LIST.findIndex(
      (s) => s.key === this.currentStep.key
    );
    if (currentIndex > 0) {
      this.currentStep = STEP_LIST[currentIndex - 1];
      if (this.currentStep.key === STEPS.SELECTION.key) {
        this.selectedItemId = "";
        this.selectedItemLabel = "";
      }
      this.initSidebarData(this.currentStep.key);
    }
  }

  /* ── wizard state ─────────────────────────────── */
  currentStep = STEPS.SELECTION;

  /* ── sidebar state ────────────────────────────── */
  @track sidebarTitle = "Categories";
  @track sidebarIcon = "standard:category";
  @track sidebarSortLabel = "Name";
  @track sidebarIsLoading = false;
  @track sidebarItems = [];
  @track selectedItemId = "";
  @track selectedItemLabel = "";

  /* ── domain state ─────────────────────────────── */
  @track quoteState = {
    accountId: "",
    accountName: "",
    contactId: "",
    contactName: "",
    catalogId: "",
    catalogName: "",
    startDate: new Date().toISOString().split("T")[0],
    subscriptionTerm: 12,
    additionalDiscountPercent: 0
  };
  @track selectedProducts = [];
  @track logisticsState = {
    isTransportRequired: false,
    deliverySite: "",
    transportAgency: "",
    transportUrgency: "",
    notes: ""
  };

  /* ═══════════════════════════════════════════════
       GETTERS
       ═══════════════════════════════════════════════ */

  /* -- step booleans -- */
  get isStepSelection() {
    return this.currentStep.key === STEPS.SELECTION.key;
  }
  get isStepConfigure() {
    return this.currentStep.key === STEPS.CONFIGURE.key;
  }
  get isStepLineEditor() {
    return this.currentStep.key === STEPS.LINE_EDITOR.key;
  }
  get isStepLogistics() {
    return this.currentStep.key === STEPS.LOGISTICS.key;
  }
  get isStepReview() {
    return this.currentStep.key === STEPS.REVIEW.key;
  }

  /* -- opportunity data -- */
  get opportunityPricebookId() {
    if (this.opportunityRecord?.data) {
      return getFieldValue(this.opportunityRecord.data, OPP_PRICEBOOK_ID) || "";
    }
    return "";
  }

  get opportunityCatalogId() {
    if (this.opportunityRecord?.data) {
      return getFieldValue(this.opportunityRecord.data, OPP_OFFER_TYPE) || "";
    }
    return "";
  }

  /* -- header -- */
  get headerTopLabel() {
    if (this.opportunityRecord?.data) {
      const name = getFieldValue(this.opportunityRecord.data, OPP_NAME);
      if (name) return name;
    }
    return this.recordId || "OPP-000000";
  }
  get headerTitle() {
    return this.currentStep.label;
  }
  get headerSubtitle() {
    return "";
  }
  get headerIcon() {
    return this.currentStep.icon || "standard:product";
  }
  get headerMetadata() {
    const metadata = [];

    // Account - as LINK
    if (this.opportunityRecord?.data) {
      const accountName = getFieldValue(
        this.opportunityRecord.data,
        OPP_ACCOUNT_NAME
      );
      const accountId = getFieldValue(
        this.opportunityRecord.data,
        OPP_ACCOUNT_ID
      );
      if (accountName) {
        metadata.push({
          id: "account",
          label: "Account:",
          value: accountName,
          secondary: accountId,
          iconName: "standard:account",
          isLink: true,
          isBold: true,
          objectApiName: "Account"
        });
      }
    }

    // Pricebook - as LINK
    if (this.opportunityRecord?.data) {
      const pbName = getFieldValue(
        this.opportunityRecord.data,
        OPP_PRICEBOOK_NAME
      );
      const pbId = getFieldValue(this.opportunityRecord.data, OPP_PRICEBOOK_ID);

      metadata.push({
        id: "pricebook",
        label: "Pricebook:",
        value: pbName || "Standard Pricebook",
        secondary: pbId,
        iconName: "standard:pricebook",
        isLink: true,
        isBold: true,
        objectApiName: "Pricebook2"
      });
    } else {
      metadata.push({
        id: "pricebook",
        label: "Pricebook:",
        value: "Standard Pricebook",
        secondary: "#",
        iconName: "standard:pricebook",
        isLink: false,
        isBold: true,
        objectApiName: "Pricebook2"
      });
    }

    // Offer Type
    if (this.opportunityRecord?.data) {
      const offerTypeName = getFieldValue(
        this.opportunityRecord.data,
        OPP_OFFER_TYPE_NAME
      );
      metadata.push({
        id: "offerType",
        label: "Offer Type:",
        value: offerTypeName || "Catalog",
        iconName: "standard:category",
        isLink: false,
        isBold: true
      });
    }

    return metadata;
  }
  get headerShowSearch() {
    return this.currentStep.header?.showSearch || false;
  }

  get headerSearchPlaceholder() {
    return this.currentStep.header?.searchPlaceholder || "Search...";
  }

  get headerStepActions() {
    const actions = deepClone(this.currentStep.header?.stepActions || []);
    return actions.map((action) => {
      if (action.dynamicProperty === "disableIfCartEmpty") {
        action.disabled = (this.selectedProducts || []).length === 0;
      }
      return action;
    });
  }

  get headerGlobalActions() {
    const actions = deepClone(this.currentStep.header?.globalActions || []);
    const filtersOpen = this._getSelectionStep()?.filterPanelOpen;

    return actions.map((action) => {
      if (action.isGroup && action.items) {
        action.items = action.items.map((item) => {
          if (item.dynamicProperty === "highlightIfFiltersOpen") {
            item.variant = filtersOpen ? "brand" : "border-filled";
          }
          return item;
        });
      }
      return action;
    });
  }

  /* -- header actions -- */
  handleHeaderAction(event) {
    const action = event.detail.action;
    if (action === "back") this._goBack();
    else if (action === "next") this._goNext();
    else if (action === "select") this._goNext();
    else if (action === "save") this._triggerSave();
    else if (action === "cancel") this._navigateToOpportunity();
    else if (action === "refresh") this._handleRefresh();
    else if (action === "clearSelection") this._handleClearSelection();
    else if (action === "changeView") this._handleChangeView(event);
    else if (action === "resetConfig") this._handleResetConfig();
    else if (action === "saveConfig") this._handleSaveConfig();
    else if (action === "groupBySection") this._getBundleConfigStep()?.setFeatureOrganization("section");
    else if (action === "groupByTab") this._getBundleConfigStep()?.setFeatureOrganization("tab");
    else if (action === "applyRules") this._handleApplyRules();
  }

  _handleRefresh() {
    if (this.isStepSelection) {
      this._getSelectionStep()?.refreshProducts();
    } else if (this.isStepConfigure) {
      this._getBundleConfigStep()?.refresh();
    } else {
      this.initSidebarData(this.currentStep.key);
    }
  }

  _handleSettings() {
    this._showToast("Settings", "Settings panel opened", "info");
  }

  _handleChangeView(event) {
    const viewType = event.detail.value;
    if (viewType === "viewTable") this._getSelectionStep()?.setViewMode("table");
    else if (viewType === "viewCards") this._getSelectionStep()?.setViewMode("cards");
  }

  _handleResetConfig() {
    const bundleConfig = this._getBundleConfigStep();
    if (bundleConfig) {
      bundleConfig.resetCurrentBundle();
      this._showToast("Configuration Reset", "Bundle configuration has been reset", "info");
    }
  }

  _handleSaveConfig() {
    const bundleConfig = this._getBundleConfigStep();
    if (bundleConfig) {
      bundleConfig.saveCurrentConfig();
      this._showToast("Configuration Saved", "Bundle configuration saved successfully", "success");
    }
  }

  _handleApplyRules() {
    this._showToast("Apply Rules", "Rules applied successfully", "success");
  }

  handleHeaderSearch(event) {
    const searchValue = event.detail.searchValue;
    const step = this._getSelectionStep();
    if (step) step.handleSearchInput(searchValue);
  }

  _getSelectionStep() {
    return this.template.querySelector("c-cpq-step-selection");
  }

  _getBundleConfigStep() {
    return this.template.querySelector("c-cpq-step-bundle-config");
  }

  _handleClearSelection() {
    this.selectedProducts = [];
  }

  /* ── Sidebar Data Management ──────────────────── */

  initSidebarData(stepKey) {
    if (stepKey === STEPS.SELECTION.key) {
      this._loadSelectionSidebar();
    } else if (stepKey === STEPS.CONFIGURE.key) {
      this._loadConfigureSidebar();
    } else if (stepKey === STEPS.LINE_EDITOR.key) {
      this._loadLineEditorSidebar();
    } else {
      this._loadReviewSidebar();
    }
  }

  _loadSelectionSidebar() {
    this.sidebarTitle = "Categories";
    this.sidebarIcon = "standard:category";
    this.sidebarSortLabel = "Products";

    if (!this.recordId) {
      this.sidebarItems = [];
      this._showToast("Error", "Opportunity ID not available", "error");
      return;
    }

    this.sidebarIsLoading = true;
    getSidebarCategoriesByOfferType({ opportunityId: this.recordId })
      .then((result) => {
        this.sidebarItems = result || [];
      })
      .catch((error) => {
        console.error("Error loading sidebar categories:", error);
        this._showToast("Error", "Failed to load categories", "error");
        this.sidebarItems = [];
      })
      .finally(() => {
        this.sidebarIsLoading = false;
      });
  }

  _loadConfigureSidebar() {
    this.sidebarTitle = "Bundles";
    this.sidebarIcon = "standard:bundle_config";
    this.sidebarSortLabel = "Configuration";

    this.sidebarIsLoading = true;

    setTimeout(() => {
      const bundleItems = (this.selectedProducts || []).filter(
        (item) => item.isBundle === true
      );

      if (bundleItems.length === 0) {
        this.sidebarItems = [];
        this.sidebarIsLoading = false;
        return;
      }

      this.sidebarItems = bundleItems.map((bundle) => {
        return {
          id: bundle._key,
          label: bundle.productName,
          subtitle: bundle.productCode
        };
      });
      this.sidebarIsLoading = false;
    }, 300);
  }

  _loadLineEditorSidebar() {
    this.sidebarTitle = "Lines";
    this.sidebarIcon = "standard:list_item";
    this.sidebarSortLabel = "Added Date";
    this.sidebarItems = (this.selectedProducts || []).map((item) => ({
      id: item._key,
      label: item.productName,
      value: item.quantity.toString()
    }));
  }

  _loadReviewSidebar() {
    this.sidebarTitle = "Details";
    this.sidebarIcon = "standard:info";
    this.sidebarSortLabel = "Field";
    this.sidebarItems = [
      { id: "det-001", label: "Account", value: this.quoteState.accountName },
      { id: "det-002", label: "Start Date", value: this.quoteState.startDate },
      {
        id: "det-003",
        label: "Term",
        value: `${this.quoteState.subscriptionTerm}m`
      }
    ];
  }

  handleItemSelect(event) {
    const { selectedItemId } = event.detail;
    const selectedItem = this._findSidebarItemById(selectedItemId);
    this.selectedItemId = selectedItem ? selectedItem.id : "";
    this.selectedItemLabel = selectedItem ? selectedItem.label : "";

    // For Step 2 (Bundle Configuration), this triggers reactive change in cpqStepBundleConfig
    // via the selectedBundleId prop setter, which loads features for the selected bundle
  }

  handleItemDeselect() {
    this.selectedItemId = "";
    this.selectedItemLabel = "";
  }

  _findSidebarItemById(itemId) {
    for (const item of this.sidebarItems) {
      if (item.id === itemId) {
        return item;
      }
      if (item.children) {
        for (const child of item.children) {
          if (child.id === itemId) {
            return child;
          }
        }
      }
    }
    return null;
  }

  handleSidebarRefresh() {
    this.initSidebarData(this.currentStep.key);
  }

  /* ── Step 1 events ── */
  handleProductAdd(event) {
    const cartItem = deepClone(event.detail.cartItem);
    const discount = this.quoteState.additionalDiscountPercent || 0;
    cartItem._formattedTotal = formatCurrency(
      calculateSelectedProductTotal(cartItem, discount)
    );
    const items = deepClone(this.selectedProducts);
    items.push(cartItem);
    this.selectedProducts = items;

    // If now in Step 2 (Configure), refresh sidebar to show updated bundle list
    if (this.isStepConfigure) {
      this._loadConfigureSidebar();
    }
  }

  handleProductRemove(event) {
    const { productId } = event.detail;
    const items = deepClone(this.selectedProducts).filter(
      (i) => i.productId !== productId
    );
    this.selectedProducts = items;
  }

  /* -- Step 3 events -- */
  handleConfigUpdate(event) {
    const { itemKey, options, configured } = event.detail;
    const items = deepClone(this.selectedProducts);
    const discount = this.quoteState.additionalDiscountPercent || 0;
    const idx = items.findIndex((i) => i._key === itemKey);
    if (idx !== -1) {
      items[idx].options = deepClone(options);
      items[idx].configured = configured;
      items[idx]._formattedTotal = formatCurrency(
        calculateSelectedProductTotal(items[idx], discount)
      );
    }
    this.selectedProducts = items;
  }

  /* -- Step 4 events -- */
  handleLineUpdate(event) {
    const { itemKey, field, value, optionId } = event.detail;
    const items = deepClone(this.selectedProducts);
    const discount = this.quoteState.additionalDiscountPercent || 0;
    const idx = items.findIndex((i) => i._key === itemKey);
    if (idx !== -1) {
      if (field === "quantity") items[idx].quantity = value;
      else if (field === "additionalDiscount")
        items[idx].additionalDiscount = value;
      else if (field === "optionQuantity" && optionId) {
        const opt = (items[idx].options || []).find((o) => o.Id === optionId);
        if (opt) opt.quantity = value;
      }
      items[idx]._formattedTotal = formatCurrency(
        calculateSelectedProductTotal(items[idx], discount)
      );
    }
    this.selectedProducts = items;
  }

  handleLineRemove(event) {
    const { itemKey } = event.detail;
    const items = deepClone(this.selectedProducts).filter(
      (i) => i._key !== itemKey
    );
    this.selectedProducts = items;
  }

  handleGlobalDiscount(event) {
    const disc = event.detail.value;
    const qs = deepClone(this.quoteState);
    qs.additionalDiscountPercent = disc;
    this.quoteState = qs;
    this._recalcAllTotals();
  }

  /* -- Step 5 events -- */
  handleLogisticsChange(event) {
    this.logisticsState = deepClone(event.detail.logistics);
  }

  handleSaveQuote() {
    this._triggerSave();
  }

  /* -- child navigate -- */
  handleNavigate(event) {
    const direction = event.detail.direction || event.detail;
    if (direction === "next") this._goNext();
    else if (direction === "back") this._goBack();
  }

  /* ═══════════════════════════════════════════════
       HELPERS
       ═══════════════════════════════════════════════ */

  _navigateToOpportunity() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.recordId,
        objectApiName: "Opportunity",
        actionName: "view"
      }
    });
  }

  _recalcAllTotals() {
    const discount = this.quoteState.additionalDiscountPercent || 0;
    const items = deepClone(this.selectedProducts);
    items.forEach((item) => {
      item._formattedTotal = formatCurrency(
        calculateSelectedProductTotal(item, discount)
      );
    });
    this.selectedProducts = items;
  }

  _triggerSave() {
    this._showToast("Success", MESSAGES.SAVE_SUCCESS, "success");
  }

  _showToast(title, message, variant = "success") {
    showToast(this, title, message, variant);
  }
}
