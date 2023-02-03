// Import LWC Core Modules and Toast Notification Module
import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import Apex controller methods 
import getAccounts from '@salesforce/apex/SC_DD_DealDeskCont.getAccounts'; // Return Accounts that matches search string
import getProductDetails from '@salesforce/apex/SC_DD_DealDeskCont.getGssProductDetails'; // Get Product info for building Prod and Prod Type Picklists
import getConversionRates from '@salesforce/apex/SC_DD_DealDeskCont.getConversionRates'; // Get Conversion rates - For Equivalent USD/ Request Price in USD Calculation
import getCustomerMrr from '@salesforce/apex/SC_DD_DealDeskCont.getCustomerMrr'; // Get Customer MRR info for Selected Account

// Import UI API - Data Service methods for getting Pick List Values
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi'; // getObjectInfo - to get RecordType id of Pricing Obj
                                                                              // getPicklistValues - to get Currency Pick list Values  

// Import Pricing Object and it's currency field - to dynamically build Local Currency picklist
import PRICING_OBJECT from '@salesforce/schema/SC_DD_Product_Pricing__c';
import CURRENCY_FIELD from '@salesforce/schema/SC_DD_Product_Pricing__c.Currency__c';

// Import Constants from ddEvaluationFormConstants file
import {FORM_CONFIG, MRR_COLS, ERROR_MSGS, CURRENCY_CBOX_CONFIG, ACCOUNT_CBOX_CNFIG, OTHER_APPROVERS} from './ddEvaluationFormConstants';
// Import ServerCall Error function - shows toast notification
import {serverCallError} from 'c/scUtil';
export default class DdEvaluationForm extends LightningElement {

    HELP_LINK = 'https://collaborate.akamai.com/confluence/pages/viewpage.action?spaceKey=P2R&title=BRD-+Deal+Desk+Dashboard+Migration';
    BUG_REPORT = 'https://ac.akamai.com/docs/DOC-83883';

    // Form Meta data - which controls UI elements of form, picklist values to display, etc
    @track formConfig = FORM_CONFIG[this.mode]; // tells which field should be editable and which should not
    @track currencyOptions; // List of Valid Currencies for Local Currency Field - fetched from Pricing Object
    @track conversionRates; // Conversion rates for Local Currency to USD conversion
    @track isLoeCalcNeeded = false; // If true, display LOE Input element
    @track disableCustomization = true; // If true, disable Package Customization Button
    @track productOpt; // Product PickList values
    @track productTypePickValues; // Product Type PickList values
    @track productDepList = {}; // Product to Product Type Map, to populate Product Type picklist for Selected Product
    @track pricingObjRecordTypeId; // Record type id of Pricing Object, needed for getting Currency Picklist values
    @track otherApprovalType; // Controls visibility of "Amount of Discount" & "Explanation & Justification" fields on UI

    currProps = CURRENCY_CBOX_CONFIG; // Currency Combo box config data
    accComboProps = ACCOUNT_CBOX_CNFIG; // Account Combo box config data
    otherProdApprovalTypes = OTHER_APPROVERS // Picklist Values for "Approver" Field

    // Other meta data
    @track mrrData; // Customer MRR Data
    @track mrrColumns = MRR_COLS; // Column metdata for Customer MRR
    @track accNoResultsMsg; // Error message to display - if getAccounts() doesn't return any accounts
    prodComputedEsr = {}; // Computed ESR formulas for all products
    prodLoeConfigMap = {}; // Which Product need LOE input and which don't
    
    // Form data - entered by User
    @track accSearchStr = ''; // Account Search String *WIRED to getAccounts Apex method*
    @track prodSelected; // Selected Product
    @track subProdSelected; // Sub Prod Selected
    @track selectedCurr = {}; // Currency selected from Currency Combobox
    @track requestedPrice; // Requested Price
    @track requestedHours = 0; // Requested Hours - Package Customisation or LOE
    @track loeId;
    packComp; // Customised Package Component Info - JSON format

    // derived from user input
    @track akamAccId; // AKAM Id of selected Account * WIRED to getCustomerMrr Apex method*
    @track selAccount = ''; // Account selcetded by user - from Combobox list
    @track accId;     // Salesforce Id of selected Account
    @track accList; // List of Accounts matching search text, returned by Apex method
    @track reqPriceInUsd; // Requested Price in USD
    @track selectedCurrKey; // Currency Code of Local Currency
    isBelowMinPackageComp; // is any of the requested package component below minimum

    @track _mode = 'new'; 
    @api 
    get mode() {
        return this._mode;
    }
    set mode(value) {
        this._mode = value;
        this.formConfig = FORM_CONFIG[value];
    }

    // Set Deal - Used to set context in Edit mode, in new mode it is just empty object '{}'
    @track _deal;
    @api 
    get deal() {
        return this._deal;
    }
    // On Edit mode, deal will be passed by ddDealDesk parent component, using it to set context
    set deal(value) {
        this._deal = value;
        if(Object.keys(value).length > 1) {
            if(value.Account__r) {
                this.accList = [ value.Account__r ];
                this.akamAccId = value.Account__r.AKAM_Account_ID__c;
                this.accId = value.Account__r.Id;
                this.disableCustomization = false;
            }
            
            this.requestedPrice = value.Requested_Price__c;
            this.requestedHours = value.Requested_Hours__c;
            this.loeId = value.LOE_Id__c;
            this.isLoeCalcNeeded = value.LOE_Id__c;
            this.prodSelected =  value.GSS_Product_Name__c || this.prodSelected;
            this.subProdSelected = value.Product_Type__c || this.subProdSelected;
            this.isNapCustomer = value.is_NAP_Customer__c;
            if(this.currencyOptions) {
                let localCurr = value.Local_Currency__c;
                let currCode = localCurr.substring(localCurr.lastIndexOf('(') + 1, localCurr.lastIndexOf(')')) ;
                this.selectedCurr = { label: localCurr, value: currCode };
                this.selectedCurrKey = currCode;
            }
            
            if(this.mode !== 'new' && this.conversionRates) {
                this.reqPriceInUsd = this.deal.Requested_Price__c / this.conversionRates[this.selectedCurr.value];
            }
            if(value.Product_Type__c) {
                this.productTypePickValues = [   { label: value.Product_Type__c, value: value.Product_Type__c }  ];
            }
        }
    }
    // Label for Request Price Input Element
    get requestPriceLabel() {
        return `Requested Price (${this.selectedCurr.value})`;
    }
    // Label for Pricelist Price Input Element - Other Product
    get otherPriceInPriceListLabel() {
        return `Price in Pricelist (${this.selectedCurr.value})`;
    }  
    // Controls css of Akam Account Id, Contract Info, Customer MRR - Clickable or Disabled
    get accInfoCss() {
        return this.akamAccId ? '': 'disabled';
    }
    // Local Currency != USD, will display "Equivalent USD" in form
    get isUsd() {
        return this.selectedCurr.value === 'USD';
    }
    // In Edit mode, returns existing package comp info of deal
    get packCompDefaultValues() {
        return  this.mode === 'new' ? '': this.deal.Package_Comp_Info__c;
    }
    // is Other Product
    get isOtherProd() {
        return this.prodSelected === 'Other';
    }
    // Display/ hide Amount of Discount Field
    get showAmountOfDiscount() {
        return this.otherApprovalType === 'Discount';
    }
  
    get discount() {
        this.requestedPrice;
        let priceListPrice = this.getValue('[data-inpid="Price in Pricelist"]');
        let disc = this.requestedPrice && priceListPrice > 0 ?  (priceListPrice - this.requestedPrice ) * 100 / priceListPrice : 0;

        // rounding Down to one decimal
        return Math.floor(disc * 10) / 10;

    }
    approvalTypeChange(ev) {
        this.otherApprovalType = ev.currentTarget.value;
    }
  
    // Get Record Type Id of Pricing Object, 
    @wire(getObjectInfo, { objectApiName: PRICING_OBJECT })
    getObject({ error, data }) {
        if (data) {
            let rtypes = data.recordTypeInfos;
            this.pricingObjRecordTypeId = Object.keys(rtypes).find(rt => rtypes[rt].name === 'Master');
        } else if (error) {
            serverCallError(this, error, ERROR_MSGS.ERR_CURR_FETCH);
        }
    }

    // Get Currency__c picklist values
    @wire(getPicklistValues, { recordTypeId: '$pricingObjRecordTypeId', fieldApiName: CURRENCY_FIELD })
    getPickLists({ error, data }) {
        if (data) {
            this.currencyOptions = [];
            data.values.forEach(({ label, value }) => this.currencyOptions.push({
                label: label,
                value: value.substring(value.lastIndexOf('(') + 1, value.lastIndexOf(')'))
            }));

            if(this.deal.Local_Currency__c) {
                let localCurr = this.deal.Local_Currency__c;
                let currCode = localCurr.substring(localCurr.lastIndexOf('(') + 1, localCurr.lastIndexOf(')')) ;
                this.selectedCurrKey = currCode;
                this.selectedCurr = { label: localCurr , value: currCode };
            }
            else {
                this.selectedCurr = { label: 'US (USD)', value: 'USD' };
                this.selectedCurrKey = 'USD';
            }            
        } else if (error) {
            serverCallError(this, error, ERROR_MSGS.ERR_CURR_FETCH);
        }
    }

    // Get Currency Conversion Rates, used for calculating Equivalent USD/ requestedPriceInUsd
    @wire(getConversionRates)
    getCurrConversions({error, data}) {
        if(data) {
            this.conversionRates = {};
            data.forEach(curr => {
                this.conversionRates[curr.IsoCode] = curr.ConversionRate;
            });
            if(this.mode !== 'new') {
                this.reqPriceInUsd = this.deal.Requested_Price__c / this.conversionRates[this.selectedCurr.value];
            }
        }
        else if(error) {
            serverCallError(this, error, ERROR_MSGS.ERR_CURR_CNV_FETCH);
        }
    }

    // Get List of Active GSS Products, and Create Product - Product Type Dependency Map
    @wire(getProductDetails)
    getProducts({ error, data }) {
        if (data) {
            data.forEach((el) => {
                this.prodComputedEsr[el.Product_Combination__c] = el.Computed_ESR_Formula__c;

                if (el.Product_Type__c) {
                    this.productDepList[el.Name] = this.productDepList[el.Name] || [];
                    this.productDepList[el.Name].push({ label: el.Product_Type__c, value: el.Product_Type__c });
                }
                else {
                    this.productDepList[el.Name] = '';
                }
                this.prodLoeConfigMap[el.Name] = el.LOE_API_Call_Required__c;
            });

            this.productOpt = [];
            Object.keys(this.productDepList).forEach((pd) => {
                this.productOpt.push({ label: pd, value: pd });
            });

        }
        else if (error) {
            let errorCode  = error && error.body && error.body.message ;
            let errorConfig = ERROR_MSGS[errorCode] || ERROR_MSGS.ERR_PROD_FETCH;

            serverCallError(this, error, errorConfig);
        }
    }

    // Get List of accounts matching Search String - Searches on AKAM ID and Account Name fields
    @wire(getAccounts, { searchStr: '$accSearchStr' })
    getAccounts({ error, data }) {
        if (data) {
            this.accList = data;
            // If account list is not empty or search string is empty, DON'T show message
            this.accNoResultsMsg = this.accList.length || !this.accSearchStr? '': `Couldn't find any account matching "${this.accSearchStr}"`;
        } else if (error) {
            if(JSON.stringify(error).includes('Error: newValue cannot be undefined.')) {
                return;
            }
            serverCallError(this, error, ERROR_MSGS.ERR_ACC_SEARCH);
        }
    }
    // Customer MRR
    @wire(getCustomerMrr, { akamAccId: '$akamAccId' })
    processCustMrr({ data, error }) {
        if (data) {
            this.mrrData = data;
        }
        else if (error) {
            serverCallError(this, error, ERROR_MSGS.ERR_MRR_FETCH);
        }
    }

    // Open help page in new tab
    openHelpPage() {
        window.open(this.HELP_LINK, '_blank');
    }
    // Open bug/enhancement report page in new tab
    openBugReport() {
        window.open(this.BUG_REPORT, '_blank');
    }
    
    // Get updated Package Cutomizations
    handleReqHoursChange(ev) {
        this.packComp = ev.detail.packageCompInfo;
        this.requestedHours = ev.detail.requestedHours;
        this.isBelowMinPackageComp = ev.detail.isBelowMin;
        if(!ev.detail.initialization) {
            this.template.querySelector('[data-id="package-cust"]').toggle();
        }
    }
    // On LOE
    handleLoe(ev){
        this.loeId = ev.detail.loeId;
        this.requestedHours = ev.detail.requestedHours;
        this.template.querySelector('[data-id="loe-calc"]').toggle();
    }

    // On User Input in Combo box, get the search text
    // Since Search text is wired, server call will be made to get list of Accounts matching search text
    handleAccChange(ev) {
        ev.preventDefault();
        this.accSearchStr = ev.detail;
    }

    // On Currency Change - calculate USD price
    handleCurrChange(ev) {
        // if (ev.detail) {
        this.selectedCurr = this.currencyOptions.find(el => el.value === ev.detail.value);// { label: ev.detail.label, value: ev.target.value };
        this.selectedCurrKey = ev.target.value;
        this.reqPriceInUsd = this.requestedPrice / this.conversionRates[this.selectedCurr.value];
        // }
    }

    // When Price is Changed, calculate USD price
    handleReqPriceChange(ev) {
        this.requestedPrice = ev.detail.value;
        this.reqPriceInUsd = this.requestedPrice / this.conversionRates[this.selectedCurr.value] || 0;
        this.reqPriceInUsd = this.reqPriceInUsd.toFixed(2);
    }
    // When Product is selected -> Update Product Type picklist values, check if LOE or Package Comp Cust is needed
    handleProdSelected = (ev) => {
        this.prodSelected = ev.target.value;
        this.productTypePickValues = this.productDepList[this.prodSelected];
        this.subProdSelected = null;
        this.disableCustomization = this.formConfig.packageComp.disabled || !(this.prodSelected && (this.subProdSelected || !this.productTypePickValues));
        this.requestedHours = 0;
        this.isLoeCalcNeeded = this.prodLoeConfigMap[ev.target.value];
    }

    // When Sub Product is Selected/ Changed, reset requested hours
    handleSubProdSelected = (ev) => {
        this.subProdSelected = ev.target.value;
        this.disableCustomization = !(this.prodSelected && (this.subProdSelected || !this.productTypePickValues));
        this.requestedHours = 0;
    }
    // When Account is selected, update class variables
    handleAccSel(ev) {
        this.akamAccId = ev.detail.AKAM_Account_ID__c;
        this.selAccount = ev.detail;
        this.accList = '';
    }

    // On Evaluate, fire "evaluate" event, will be handled by ddDealDesk component
    handleEvaluate(ev) {

        if(!this.validate()) {
            return;
        }

        let selProdCombination = this.prodSelected + (this.subProdSelected ? '-' + this.subProdSelected: '' );
        let computedEsrFormula = this.prodComputedEsr[selProdCombination];
        let computedEsr = computedEsrFormula && eval(computedEsrFormula.replaceAll('requestedPrice', this.requestedPrice).replaceAll('requestedHours', this.requestedHours));
        this.dispatchEvent(new CustomEvent('evaluate', {
            detail: {
                akamAccId: this.akamAccId,
                prodSelected: this.prodSelected,
                subProdSelected: this.subProdSelected,
                packComp: this.isLoeCalcNeeded? '': this.packComp,
                requestedHours: this.requestedHours,
                requestedPrice: this.requestedPrice,
                localCurrency: this.selectedCurr.label,
                computedEsr: computedEsr,
                loeId: this.isLoeCalcNeeded? 'LOE': '',
                isNapCustomer: this.template.querySelector('.nap-cust').checked,
                isBelowMinPackageComp: this.isBelowMinPackageComp
            }
        }));
    }

    hanldeOtherProdSubmit(ev) {
        if(!this.validate()) {
            return;
        }
        this.dispatchEvent(new CustomEvent('submitotherproduct', {
            detail: {
                akamAccId: this.akamAccId,
                prodSelected: this.prodSelected,
                productName: this.getValue('[data-inpid="Product Name"]'),
                productDescription: this.getValue('[data-inpid="Product Description"]'),
                approvalType: this.getValue('[data-inpid="Approval Type"]'),
                localCurrency: this.selectedCurr.label,
                requestedPrice:this.requestedPrice, 
                priceListPrice: this.getValue('[data-inpid="Price in Pricelist"]'),
                explanationAndJustification: this.getValue('[data-inpid="Explanation & Justification"]'),
                isNapCustomer: this.template.querySelector('.nap-cust').checked
            }}));
    }

    getValue(selector) {
        const el = this.template.querySelector(selector);
        return el && el.value;
    }
  
    // Validate input form
    validate() {
        let invalidEls = [];
        this.template.querySelectorAll("[data-inpid]")
                        .forEach((inpEl) => {
                            if(!inpEl.reportValidity()) {
                                invalidEls.push(inpEl.getAttribute('data-inpid'));
                            }
                        });

        if(!this.requestedHours && !this.isOtherProd) {
            invalidEls.push('Total Custom Package Hrs/Month');
        }

        if(invalidEls.length) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Mandatory Fields Missing',
                message: invalidEls.join(', '),
                variant: 'error'
            }));
            return false;
        }
        return true;
    }

    // Toggle Modal
    toggleModal(ev) {
        let toggleId = ev.currentTarget.dataset.toggleid;
        let modal = this.template.querySelector('[data-id="'+ toggleId + '"');
        if(modal) {
            modal.toggle();
        }
    }
}