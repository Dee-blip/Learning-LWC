/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 09-24-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-11-2021   apyati   Initial Version
**/
import { LightningElement, track, api } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import WrappedHeaderTable from "@salesforce/resourceUrl/l2qManageProductsCSS";

import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getContractProducts from '@salesforce/apex/l2qManageProductController.getContractProducts';
import getProduct2Records from '@salesforce/apex/l2qManageProductController.getProduct2Records';
export const KEYFIELD = 'Id';
export const DELAY = '300';
export const COLUMNS = [

    {
        type: 'text',
        fieldName: 'firstcolumn',
        label: '',
        initialWidth: 1,
    },
    {
        label: 'Action',
        type: 'button-icon',
        initialWidth: 40,
        typeAttributes:
        {
            iconName: { fieldName: 'actionIcon' },
            name: { fieldName: 'actionLabel' },
            class: { fieldName: 'icon_class' },
            disabled: { fieldName: 'actionDisabled' },
        }
    },
    {
        label: 'Preview',
        type: 'button-icon',
        initialWidth: 40,
        typeAttributes:
        {
            iconName: 'utility:preview',
            name: 'ContractPreview',
            class: { fieldName: 'icon_class' },
            disabled: { fieldName: 'actionDisabled' },
        }
    },

    {
        type: 'url',
        fieldName: 'ContractURL',
        label: 'Contract',
        //initialWidth: 150,
        typeAttributes: {
            label: { fieldName: 'ContractName' },
            target: '_blank'
        },
    },

    {
        type: 'date-local',
        fieldName: 'EffectiveEndDate',
        label: 'Contract Expiration Date',
        initialWidth: 150,
        typeAttributes: {
            month: "short",
            day: "2-digit"
        }

    },
    {
        type: 'text',
        fieldName: 'EndMonth',
        label: 'Product EndMonth',
        initialWidth: 150,
    },
    {
        type: 'url',
        fieldName: 'ProductURL',
        label: 'Product',
        // initialWidth: 150,
        typeAttributes: {
            label: { fieldName: 'ProductName' },
            target: '_blank'
        },

    },
    {
        type: 'date-local',
        fieldName: 'StartDate',
        label: 'Start Date',
        typeAttributes: {
            month: "short",
            day: "2-digit"
        }
    },
    {
        type: 'date-local',
        fieldName: 'EndDate',
        label: 'End Date',
        typeAttributes: {
            month: "short",
            day: "2-digit"
        }

    },
    {
        type: 'currency',
        fieldName: 'CommitMRR',
        label: ' MRR Commit',
        typeAttributes: {
            currencyCode: { fieldName: 'CurrencyIsoCode' },
            currencyDisplayAs: 'code'
        }

    },
    {
        type: 'currency',
        fieldName: 'UsageMRR',
        label: 'MRR Usage ',
        typeAttributes: {
            currencyCode: { fieldName: 'CurrencyIsoCode' },
            currencyDisplayAs: 'code'
        }
    },
    {
        type: 'text',
        fieldName: 'firstcolumn',
        label: ' ',
        initialWidth: 1
    },

];
export default class L2qAddRemoveContracts extends LightningElement {
    @api recordId;
    @api selectedProducts = [];

    @track gridColumns = [];
    @track gridDataAvailable;
    @track gridDataSelected;
    @track error;
    @track searchKey = '';
    @track showActions = false;
    @track isModalOpen = false;
    @track activesections = ['available', 'selected'];
    @track isSpinner = true;

    PROD_DATA = [];
    contractId;
    selectedContractProducts = [];
    selectedContractProductIds = [];
    noDataAvailable = 'No Contracts available to select'
    noDataSelected = 'No Contracts are selected'
    contractChange = false;
    hasRendered = false;
    product2data = [];

    connectedCallback() {
        this.gridColumns = COLUMNS;
        this.getContractData();
    }


    renderedCallback() {
        if (this.hasRendered) {
            return;
        }
        this.hasRendered = true;
        Promise.all([
            loadStyle(this, WrappedHeaderTable),
        ]).then(() => { })
    }




    refreshGridData() {
        if (this.selectedProducts) {
            let selectedRows = [];
            let availableRows = [];
            this.PROD_DATA.forEach(row => {
                for (let i = 0; i < row._children.length; i++) {
                    if (JSON.stringify(this.selectedProducts).includes(row._children[i].Id)) {
                        row.actionLabel = 'Remove';
                        row.actionIcon = 'utility:delete';
                        selectedRows.push(row);
                        break;
                    } else {
                        availableRows.push(row);
                        break;
                    }
                }
            });

            this.gridDataAvailable = [...availableRows];
            this.gridDataSelected = [...selectedRows];
            if (this.gridDataAvailable.length > 0) {
                this.noDataAvailable = undefined;
            }
            else {
                this.noDataAvailable = 'No Contracts available to select';
            }
            if (this.gridDataSelected.length > 0) {
                this.noDataSelected = undefined;
            }
            else {
                this.noDataSelected = 'No Contracts selected';
            }
        }
        else {
            this.gridDataAvailable = [...this.PROD_DATA];
        }
        this.isSpinner = false;
    }

    getContractData() {
        this.isSpinner = true;
        console.log('this.recordId ->' + this.recordId);
        getProduct2Records({ accountId: this.recordId })
            .then(data => {
                this.product2data = JSON.parse(JSON.stringify(data));
                //console.log('product2data ->' + JSON.stringify(this.product2data));
                getContractProducts({ accountId: this.recordId })
                    .then(result => {
                        //console.log('result ->' + JSON.stringify(result));
                        let tempData = JSON.parse(JSON.stringify(result));

                        Object.keys(tempData).forEach(key => {

                            let contract = JSON.parse(key);
                            let con = {
                                Id: contract.Id,
                                Name: contract.Name,
                                CurrencyIsoCode: contract.Currency__c,
                                EffectiveStartDate: contract.Effective_Start_Date__c,
                                EffectiveEndDate: contract.Effective_End_Date__c,
                                OriginalContractId: contract.Original_Contract_Id__c,
                                AutoRenew: contract.Auto_Renew__c,
                                ParentAccountName: contract.Parent_Account_Name__c,
                                ParentContract: contract.Parent_Contract__c,
                                OrderId: contract.Order_Id__c,
                                ContractType: contract.Contract_Type__c
                            }
                            Object.keys(tempData[key]).forEach(enddate => {

                                let rowEnddate = {
                                    Id: con.Id + '' + enddate,
                                    ContractId: con.Id,
                                    Contract: con,
                                    ContractName: con.Name,
                                    ContractURL: '/' + con.Id,
                                    EffectiveEndDate: con.EffectiveEndDate,
                                    EndMonth: 'Products Expiring ' + enddate,
                                    actionLabel: 'Add',
                                    actionDisabled: false,
                                    actionIcon: 'utility:add',
                                    icon_class: 'slds-show',
                                    hasChildren: true,
                                    firstcolumn: ' ',
                                    _children: tempData[key][enddate]
                                }

                                let prods = [];
                                rowEnddate._children.forEach(prod => {

                                    if (this.product2data[prod.Forecast_Product_Id__c]) {
                                        let rowProd = {
                                            Id: prod.Id,
                                            Contract: con,
                                            CurrencyIsoCode: con.CurrencyIsoCode,
                                            ProductName: this.product2data[prod.Forecast_Product_Id__c].Name,
                                            ProductId: this.product2data[prod.Forecast_Product_Id__c].Id,
                                            ProductURL: '/' + prod.Id,
                                            StartDate: prod.Effective_Start_Date__c,
                                            EndDate: prod.Effective_End_Date__c,
                                            CommitMRR: prod.Average_Renewal_Commit_MRR__c,
                                            UsageMRR: prod.Average_Renewal_Usage_MRR__c,
                                            actionDisabled: true,
                                            icon_class: 'slds-hide',
                                            hasChildren: false
                                        }
                                        prods.push(rowProd);
                                    }
                                });

                                rowEnddate._children = prods;
                                delete tempData[key][enddate];
                                this.PROD_DATA.push(rowEnddate);
                            });
                        });
                        this.refreshGridData();
                    })
                    .catch(error => {
                        this.isSpinner = false;
                        console.error(error);
                        let message = 'Unknown error';
                        if (Array.isArray(error.body)) {
                            message = error.body.map(e => e.message).join(',');
                        } else if (typeof error.body.message === 'string') {
                            message = error.body.message;
                        }
                        this.showToast('Error loading contract products',
                            message,
                            'error',
                            'sticky',
                            []);
                    });

            })
            .catch(error => {
                this.isSpinner = false;
                console.error(error);
                let message = 'Unknown error';
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(',');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.showToast('Error loading contract products',
                    message,
                    'error',
                    'sticky',
                    []);
            });
    }

    handleRowAction(event) {
        const row = event.detail.row;
        console.log('handleRowAction called' + row.Id);
        console.log('row.actionLabel' + row.actionLabel);
        const actionName = event.detail.action.name;

        if (actionName === 'ContractPreview') {
            console.log('contract preview');
            this.isModalOpen = true;
            this.contractId = row.ContractId;
        }
        else {

            this.contractChange = true;
            let selectedRecords = this.gridDataSelected;
            let availableRecords = this.gridDataAvailable;
            this.selectedContractProducts = [];
            this.selectedContractProductIds = [];

            if (row.actionLabel === 'Add') {
                for (let i = 0; i < availableRecords.length; i++) {
                    if (availableRecords[i].Id === row.Id) {
                        availableRecords[i].actionLabel = 'Remove';
                        availableRecords[i].actionIcon = 'utility:delete'
                        selectedRecords.push(availableRecords[i]);
                        availableRecords.splice(i, 1);
                        break;
                    }
                }
            }
            if (row.actionLabel === 'Remove') {
                for (let i = 0; i < selectedRecords.length; i++) {
                    if (selectedRecords[i].Id === row.Id) {
                        selectedRecords[i].actionLabel = 'Add';
                        selectedRecords[i].actionIcon = 'utility:add'
                        availableRecords.push(selectedRecords[i]);
                        selectedRecords.splice(i, 1);
                        break;
                    }
                }
            }

            if (selectedRecords) {
                //for manage products
                selectedRecords.forEach(con => {
                    con._children.forEach(prod => {
                        let rec = {
                            Id: prod.Id,
                            Contract: prod.Contract,
                            ProductId: prod.ProductId,
                            ProductName: prod.ProductName,
                            UsageMRR: prod.UsageMRR,
                            CommitMRR: prod.CommitMRR,
                            CurrencyIsoCode: prod.CurrencyIsoCode
                        };
                        this.selectedContractProducts.push(rec);
                        this.selectedContractProductIds.push(prod.Id);
                    })
                });
            }

            this.gridDataSelected = [...selectedRecords];
            this.gridDataAvailable = [...availableRecords];

            if (this.gridDataAvailable.length > 0) {
                this.noDataAvailable = undefined;
            }
            else {
                this.noDataAvailable = 'No Contracts available to select';
            }
            if (this.gridDataSelected.length > 0) {
                this.noDataSelected = undefined;
            }
            else {
                this.noDataSelected = 'No Contracts selected';
            }

            console.log('availableRecords' + availableRecords.length);
            console.log('selectedRecords' + selectedRecords.length);
            console.log('selectedProducts' + this.selectedContractProductIds.length);
            console.log('contractProducts' + this.selectedContractProducts.length);

        }
    }

    handleSave() {
        console.log('handleSave()');
        this.isModalOpen = false;
        //for product details
        this.dispatchEvent(new CustomEvent('addcontracts', { detail: { contractProducts: this.selectedContractProducts, contractChange: this.contractChange } }));
        //for sending products
        this.dispatchEvent(new CustomEvent('selectcontractproducts', { detail: this.selectedContractProductIds }));
    }

    handleClose() {
        console.log('handleClose()');
        this.dispatchEvent(new CustomEvent('closeaddcontracts'));
    }

    handleClosePreview() {
        this.isModalOpen = false;
    }

    showToast(title, message, variant, mode, messageData) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode,
                messageData: messageData
            }),
        );
    }

}