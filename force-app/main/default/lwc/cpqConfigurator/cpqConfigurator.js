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
import OPP_TRANSPORT_REQUIRED from "@salesforce/schema/Opportunity.Is_Transport_Required__c";
import OPP_DEFAULT_AGENCY from "@salesforce/schema/Opportunity.Default_Agency__c";
import OPP_TRANSPORT_URGENCY from "@salesforce/schema/Opportunity.Transport_Urgency__c";
import OPP_DELIVERY_SITE from "@salesforce/schema/Opportunity.Delivery_Site__c";
import getSidebarCategoriesByOfferType from "@salesforce/apex/ProductCategoryController.getSidebarCategoriesByOfferType";
import getBundleData from "@salesforce/apex/BundleOptionController.getBundleData";
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
  OPP_OFFER_TYPE_NAME,
  OPP_TRANSPORT_REQUIRED,
  OPP_DEFAULT_AGENCY,
  OPP_DELIVERY_SITE,
  OPP_TRANSPORT_URGENCY
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
    if (result.data) {
      const accountId = getFieldValue(result.data, OPP_ACCOUNT_ID);
      const defaultAgencyId = getFieldValue(result.data, OPP_DEFAULT_AGENCY) || "";
      const deliverySiteId = getFieldValue(result.data, OPP_DELIVERY_SITE) || "";
      
      this.logisticsState = {
        ...this.logisticsState,
        accountId: accountId,
        isTransportRequired: getFieldValue(result.data, OPP_TRANSPORT_REQUIRED) || false,
        agencyId: defaultAgencyId,
        deliverySiteId: deliverySiteId,
        urgency: getFieldValue(result.data, OPP_TRANSPORT_URGENCY) || "Standard"
      };
    }
    this.initSidebarData(this.currentStep.key);
  }

  /* ── lifecycle ────────────────────────────────── */
  connectedCallback() {
    // Initialize sidebar data when component mounts
    this.initSidebarData(this.currentStep.key);
  }

  async _goNext() {
    if (this.isStepConfigure) {
      const saved = await this._ensureAllBundlesConfigured();
      if (!saved) return;
    }

    if (this.isStepLineEditor) {
      const lineEditor = this._getLineEditorStep();
      if (lineEditor) {
        if (lineEditor.isLoading) {
          showToast(this, 'Validation Blocked', 'Pricing is still being calculated. Please wait.', 'warning');
          return;
        }
        const isValid = lineEditor.validate();
        if (!isValid) {
          showToast(this, 'Validation Failed', 'Please fix all line editor errors before proceeding.', 'error');
          return;
        }
        lineEditor.saveLines();
      }
    }

    const currentIndex = STEP_LIST.findIndex(
      (s) => s.key === this.currentStep.key
    );
    if (currentIndex < STEP_LIST.length - 1) {
      let nextIndex = currentIndex + 1;
      
      // Skip logistics step if transport not required
      if (STEP_LIST[nextIndex].key === STEPS.LOGISTICS.key && !this.logisticsState.isTransportRequired) {
        nextIndex++;
      }
      
      if (nextIndex < STEP_LIST.length) {
        this.currentStep = STEP_LIST[nextIndex];
        this.initSidebarData(this.currentStep.key);
      }
    }
  }

  async _goBack() {
    if (this.isStepConfigure) {
      const bundleConfig = this._getBundleConfigStep();
      if (bundleConfig && this.selectedItemId) {
        const isValid = bundleConfig.saveCurrentConfig();
        if (!isValid) return;
      }
    }

    if (this.isStepLineEditor) {
      const lineEditor = this._getLineEditorStep();
      if (lineEditor) {
        lineEditor.saveLines();
      }
    }

    const currentIndex = STEP_LIST.findIndex(
      (s) => s.key === this.currentStep.key
    );
    if (currentIndex > 0) {
      let prevIndex = currentIndex - 1;
      
      // Skip logistics step if transport not required
      if (STEP_LIST[prevIndex].key === STEPS.LOGISTICS.key && !this.logisticsState.isTransportRequired) {
        prevIndex--;
      }
      
      if (prevIndex >= 0) {
        this.currentStep = STEP_LIST[prevIndex];
        
        if (this.currentStep.key === STEPS.SELECTION.key) {
          this.selectedItemId = "";
          this.selectedItemLabel = "";
        }
        this.initSidebarData(this.currentStep.key);
      }
    }
  }

  /* ── wizard state ─────────────────────────────── */
  currentStep = STEPS.SELECTION;

  /* ── sidebar state ────────────────────────────── */
  @track sidebarTitle = "Categories";
  @track sidebarIcon = "standard:category";
  @track sidebarSortLabel = "Name";
  @track sidebarSortField = "label";
  @track sidebarSortDirection = "asc";
  @track sidebarIsLoading = false;
  @track sidebarItems = [];
  @track selectedItemId = "";
  @track selectedItemLabel = "";

  /* ── domain state ─────────────────────────────── */
  @track opportunityState = {
    accountId: "",
    accountName: "",
    pricebookId: "",
    pricebookName: "",
    offerTypeId: "",
    offerTypeName: ""
  };
  @track selectedProducts = [];
  @track logisticsState = {
    accountId: "",
    isTransportRequired: false,
    deliverySiteId: "",
    agencyId: "",
    urgency: "",
    notes: ""
  };

  @track bundleConfigCache = {};

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
    return this.currentStep.key === STEPS.LOGISTICS.key && this.logisticsState.isTransportRequired;
  }
  get isStepReview() {
    return this.currentStep.key === STEPS.REVIEW.key;
  }

  get showSidebar() {
    return this.isStepSelection || this.isStepConfigure;
  }

  /* -- bundle config -- */
  get selectedBundleProductId() {
    if (!this.selectedItemId || !this.isStepConfigure) return "";
    const selectedBundle = (this.selectedProducts || []).find(
      (item) => item._key === this.selectedItemId && item.isBundle
    );
    return selectedBundle?.productId || "";
  }

  get selectedBundleCachedFeatures() {
    const itemKey = this.selectedItemId;
    if (!itemKey || !this.bundleConfigCache[itemKey]) {
      return null;
    }
    return this.bundleConfigCache[itemKey].features || null;
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
  get opportunityOfferType() {
    if (this.opportunityRecord?.data) {
      return getFieldValue(this.opportunityRecord.data, OPP_OFFER_TYPE) || "";
    }
    return "";
  }

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
      
      if (action.dynamicProperty === "disableIfInvalidLogistics") {
        // Reference logisticsState to trigger reactivity
        const stateTracker = this.logisticsState;
        const step = this._getLogisticsStep();
        if (step) {
            action.disabled = step.isCalculateDisabled;
        } else {
            action.disabled = true;
        }
      }
      
      return action;
    });
  }

  @track hasLineSelection = false;

    get headerGlobalActions() {
    const actions = deepClone(this.currentStep.header?.globalActions || []);
    let filtersOpen = false;

    if (this.isStepSelection) {
      filtersOpen = this._getSelectionStep()?.filterPanelOpen;
    }

    return actions.map((action) => {
      if (action.dynamicProperty === "disableIfNoSelection") {
        action.disabled = !this.hasLineSelection;
      }

      if (action.dynamicProperty === "disableIfNoRoute") {
        // Query logistics step directly for real-time route validity
        // Reference logisticsState to trigger reactivity
        const stateTracker = this.logisticsState;
        const logisticsStep = this._getLogisticsStep();
        action.disabled = !logisticsStep?.hasValidRoute;
      }

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
    else if (action === "saveLines") this._triggerSaveLines();
    else if (action === "cancel") this._navigateToOpportunity();
    else if (action === "refresh") this._handleRefresh();
    else if (action === "clearSelection") this._handleClearSelection();
    else if (action === "changeView") this._handleChangeView(event);
    else if (action === "resetConfig") this._handleResetConfig();
    else if (action === "saveConfig") this._handleSaveConfig();
    else if (action === "groupBySection") this._getBundleConfigStep()?.switchToSections();
    else if (action === "groupByTab") this._getBundleConfigStep()?.switchToTabs();
    else if (action === "applyRules") this._handleApplyRules();
    else if (action === "toggleFilters") this._handleToggleFilters();
    else if (action === "refreshPricing") this._getLineEditorStep()?.handleHeaderAction('refreshPricing');
    else if (action === "deleteSelected") this._getLineEditorStep()?.handleHeaderAction('deleteSelected');
    else if (action === "resetEditing") this._handleResetEditing();
    else if (action === "calculateTransport") this._getLogisticsStep()?.handleCalculateTrips();
    else if (action === "openGoogleMaps") this._getLogisticsStep()?.openRouteInGoogleMaps();
  }

  _handleToggleFilters() {
    if (this.isStepSelection) {
      this._getSelectionStep()?.toggleFilterPanel();
    } else if (this.isStepConfigure) {
      this._showToast("Info", "Filters are not currently available for this step.", "info");
    }
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

  _handleResetEditing() {
    this._getLineEditorStep()?.resetLineItems();
  }

  async _ensureAllBundlesConfigured() {
    const bundleConfig = this._getBundleConfigStep();
    if (bundleConfig && this.selectedItemId) {
      const isValid = bundleConfig.saveCurrentConfig();
      if (!isValid) return false;
    }

    const unconfiguredBundles = this.selectedProducts.filter(
      p => p.isBundle && (!p.configuredOptions || p.configuredOptions.length === 0)
    );

    if (unconfiguredBundles.length === 0) return true;

    for (const bundle of unconfiguredBundles) {
      if (this.bundleConfigCache[bundle._key]) {
        const cached = this.bundleConfigCache[bundle._key];
        const productsList = deepClone(this.selectedProducts);
        const idx = productsList.findIndex(p => p._key === bundle._key);
        if (idx !== -1) {
          productsList[idx].configuredOptions = deepClone(cached.selectedOptions);
          productsList[idx].featuresState = deepClone(cached.features);
        }
        this.selectedProducts = productsList;
      } else {
        try {
          const result = await getBundleData({ bundleId: bundle.productId });
          const selectedOptions = this._extractDefaultSelectedOptions(result.features || []);
          const productsList = deepClone(this.selectedProducts);
          const idx = productsList.findIndex(p => p._key === bundle._key);
          if (idx !== -1) {
            productsList[idx].configuredOptions = selectedOptions;
            productsList[idx].featuresState = result.features;
          }
          this.selectedProducts = productsList;
          this.bundleConfigCache[bundle._key] = {
            features: deepClone(result.features),
            selectedOptions: deepClone(selectedOptions)
          };
        } catch (error) {
          console.error('Error loading bundle data for unconfigured bundle:', error);
          showToast(this, 'Configuration Error', `Failed to load configuration for "${bundle.productName}".`, 'error');
          return false;
        }
      }
    }

    return true;
  }

  _extractDefaultSelectedOptions(features) {
    const selected = [];
    for (const feature of features) {
      for (const option of (feature.options || [])) {
        if (option.isSelected || option.isRequired) {
          selected.push({
            Id: option.Id,
            productId: option.productId,
            productCode: option.productCode,
            productName: option.productName,
            quantity: option.defaultQuantity || option.quantity || 1,
            unitPrice: option.unitPrice || 0,
            isRequired: option.isRequired,
            isSelected: true
          });
        }
      }
    }
    return selected;
  }

  _handleSaveConfig() {
    const bundleConfig = this._getBundleConfigStep();
    if (bundleConfig) {
      if (bundleConfig.saveCurrentConfig()) {
        this._goNext();
      }
    }
  }

  handleBundleConfigSaved(event) {
    const { itemKey, bundleId, selectedOptions, featuresState } = event.detail;

    this.bundleConfigCache[itemKey] = {
      features: deepClone(featuresState),
      selectedOptions: deepClone(selectedOptions)
    };

    let productsList = deepClone(this.selectedProducts);
    let bundleIndex = productsList.findIndex(p => p._key === itemKey);

    if (bundleIndex !== -1) {
        productsList[bundleIndex].configuredOptions = selectedOptions;
        productsList[bundleIndex].featuresState = featuresState;
    }

    this.selectedProducts = productsList;
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

  _getLineEditorStep() {
    return this.template.querySelector("c-cpq-step-line-editor");
  }

  _getLogisticsStep() {
    return this.template.querySelector("c-cpq-step-logistics");
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
      this.sidebarItems = [];
      this.sidebarIsLoading = false;
    } else if (stepKey === STEPS.REVIEW.key) {
      // No sidebar for review step
      this.sidebarItems = [];
      this.sidebarIsLoading = false;
    }
  }

  _loadSelectionSidebar() {
    this.sidebarTitle = "Categories";
    this.sidebarIcon = "standard:category";
    this.sidebarSortLabel = "Name";
    this.sidebarSortField = "label";
    this.sidebarSortDirection = "asc";

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
    this.sidebarSortLabel = "Name";
    this.sidebarSortField = "label";
    this.sidebarSortDirection = "asc";

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

  handleItemSelect(event) {
    if (this.isStepConfigure) {
      const bundleConfig = this._getBundleConfigStep();
      if (bundleConfig && this.selectedItemId) {
        const isValid = bundleConfig.saveCurrentConfig();
        if (!isValid) return; 
      }
    }

    const { selectedItemId } = event.detail;
    const selectedItem = this._findSidebarItemById(selectedItemId);
    this.selectedItemId = selectedItem ? selectedItem.id : "";
    this.selectedItemLabel = selectedItem ? selectedItem.label : "";
  }

  handleItemDeselect() {
    if (this.isStepConfigure) {
      const bundleConfig = this._getBundleConfigStep();
      if (bundleConfig && this.selectedItemId) {
        const isValid = bundleConfig.saveCurrentConfig();
        if (!isValid) return; 
      }
    }

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

  handleSortChange(event) {
    this.sidebarSortField = event.detail.sortField;
    this.sidebarSortDirection = event.detail.sortDirection;
  }

  /* ── Step 1 events ── */
  handleProductAdd(event) {
    const cartItem = deepClone(event.detail.cartItem);
    cartItem._formattedTotal = formatCurrency(
      calculateSelectedProductTotal(cartItem)
    );
    const items = deepClone(this.selectedProducts);
    items.push(cartItem);
    this.selectedProducts = items;

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
    const idx = items.findIndex((i) => i._key === itemKey);
    if (idx !== -1) {
      items[idx].configuredOptions = deepClone(options);
      items[idx].configured = configured;
      items[idx]._formattedTotal = formatCurrency(
        calculateSelectedProductTotal(items[idx])
      );
    }
    this.selectedProducts = items;
  }

  /* -- Step 4 events -- */
  handleLineUpdate(event) {
    const { itemKey, field, value, optionId } = event.detail;
    const items = deepClone(this.selectedProducts);
    const idx = items.findIndex((i) => i._key === itemKey);
    if (idx !== -1) {
      if (field === "quantity") items[idx].quantity = value;
      else if (field === "additionalDiscount") items[idx].additionalDiscount = value;
      else if (field === "optionQuantity" && optionId) {
        const opt = (items[idx].configuredOptions || []).find((o) => o.Id === optionId);
        if (opt) opt.quantity = value;
      } else if (field === "pricingMethod") items[idx].pricingMethod = value;
      else if (field === "isOptional") items[idx].isOptional = value;
      else if (field === "packageProductCode") items[idx].packageProductCode = value;
      else if (field === "originalPrice") items[idx].originalPrice = value;
      else if (field === "unitCost") items[idx].unitCost = value;
      else if (field === "markup") items[idx].markup = value;
      else if (field === "specialPrice") items[idx].specialPrice = value;
      else if (field === "regularUnitPrice") items[idx].regularUnitPrice = value;
      else if (field === "customerUnitPrice") items[idx].customerUnitPrice = value;
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

  handleLineProductChange(event) {
    const { itemKey, field, value, optionId } = event.detail;
    const items = deepClone(this.selectedProducts);
    const idx = items.findIndex((i) => i._key === itemKey);
    if (idx !== -1) {
      if (optionId) {
        const optIdx = items[idx].configuredOptions?.findIndex((o) => o.Id === optionId);
        if (optIdx !== -1) {
          items[idx].configuredOptions[optIdx][field] = value;
        }
      } else {
        items[idx][field] = value;
      }
      this.selectedProducts = items;
    }
  }

  handleLineSelectionChange(event) {
    this.hasLineSelection = event.detail.hasSelection;
  }

  handleLineSave(event) {
    const updatedLineItems = event.detail.lineItems;
    const products = deepClone(this.selectedProducts);

    for (const lineItem of updatedLineItems) {
      const idx = products.findIndex(p => p._key === lineItem._key);
      if (idx !== -1) {
        products[idx].quantity = lineItem.quantity;
        products[idx].listUnitPrice = lineItem.listUnitPrice;
        products[idx].additionalDiscount = lineItem.additionalDiscount;
        products[idx].netUnitPrice = lineItem.netUnitPrice;
        products[idx].netTotal = lineItem.netTotal;
        products[idx]._formattedTotal = formatCurrency(lineItem.netTotal);
        if (lineItem.configuredOptions && lineItem.configuredOptions.length > 0) {
          products[idx].configuredOptions = lineItem.configuredOptions;
        }
      }
    }

    this.selectedProducts = products;
  }

  /* -- Step 5 events -- */
  handleLogisticsChange(event) {
    const updatedLogistics = event.detail.logistics;
    this.logisticsState = {
      ...this.logisticsState,
      agencyId: updatedLogistics.config ? updatedLogistics.config.agencyId : this.logisticsState.agencyId,
      deliverySiteId: updatedLogistics.config ? updatedLogistics.config.deliverySiteId : this.logisticsState.deliverySiteId,
      urgency: updatedLogistics.config ? updatedLogistics.config.urgency : this.logisticsState.urgency,
      trips: updatedLogistics.trips,
      isValid: updatedLogistics.isValid
    };
  }

  handleSaveOpportunity() {
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
    const items = deepClone(this.selectedProducts);
    items.forEach((item) => {
      item._formattedTotal = formatCurrency(
        calculateSelectedProductTotal(item)
      );
    });
    this.selectedProducts = items;
  }

  _triggerSave() {
    this._showToast("Success", MESSAGES.SAVE_SUCCESS, "success");
  }

  _triggerSaveLines() {
    const lineEditor = this._getLineEditorStep();
    if (lineEditor) {
      lineEditor.saveLines();
      this._showToast("Success", MESSAGES.LINE_SAVE, "success");
    }
  }

  _showToast(title, message, variant = "success") {
    showToast(this, title, message, variant);
  }
}