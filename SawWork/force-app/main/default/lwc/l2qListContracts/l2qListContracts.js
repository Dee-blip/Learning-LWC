/**
 * @description       : 
 * @author            : apyati
 * @group             : L2Q
 * @last modified on  : 09-29-2021
 * @last modified by  : apyati
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
        label: ' ',
        initialWidth: 1
    },
    {
        label: 'Action',
        type: 'button-icon',
        initialWidth: 60,
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
        initialWidth: 60,
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
        initialWidth: 150,
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
            currencyCode:  { fieldName: 'CurrencyIsoCode' },
            currencyDisplayAs : 'code'

        }
    },
    {
        type: 'currency',
        fieldName: 'UsageMRR',
        label: 'MRR Usage ',
        typeAttributes: {
            currencyCode:  { fieldName: 'CurrencyIsoCode' },
            currencyDisplayAs : 'code'

        }
        //initialWidth: 110,

    },
    {
        type: 'text',
        fieldName: 'firstcolumn',
        label: ' ',
        initialWidth: 1
    },
];
export default class L2qListContracts extends LightningElement {
    @api recordId;

    @track gridColumns = [];
    @track gridData = [];
    @track gridDataSelected = [];
    @track error;
    @track isModalOpen = false;

    PROD_DATA = [];
    contractId;
    selectedContractProducts = [];
    noDataAvailable = 'No Contracts available to select'
    noDataSelected = 'No Contracts are selected'
    contractChange = false;
    hasRendered = false;


    @api connectedCallback() {

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



    getContractData() {
        this.isSpinner = true;
        getProduct2Records({ accountId: this.recordId })
            .then(data => {
                this.product2data = JSON.parse(JSON.stringify(data));

                getContractProducts({ accountId: this.recordId })
                    .then(result => {

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
                                    format: 'slds-cell-wrap',
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
                                        format: '',

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
                        this.gridData = [...this.PROD_DATA];
                        if (this.gridData.length > 0) {
                            this.noDataAvailable = undefined;
                        }
                        else {
                            this.noDataAvailable = 'No Contracts available to select';
                        }
                        this.isSpinner = false;

                    })
                    .catch((error) => {
                        this.isSpinner = false;
                        console.error('error' + JSON.stringify(error));
                        let message = 'Unknown error';
                        if (Array.isArray(error.body)) {
                            message = error.body.map(e => e.message).join(', ');
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
        const actionName = event.detail.action.name;

        if (actionName === 'ContractPreview') {

            this.isModalOpen = true;
            this.contractId = row.ContractId;
        }
        else {

        
            let selectedRecords = [...this.gridDataSelected];
            let availableRecords = [...this.gridData];
            this.selectedContractProducts = [];


           

            for (let i = 0; i < availableRecords.length; i++) {
                if (availableRecords[i].Id === row.Id) {
                    if (row.actionLabel === 'Add') {
                        availableRecords[i].actionLabel = 'Remove';
                        availableRecords[i].actionIcon = 'utility:delete'
                        selectedRecords.push(availableRecords[i]);
                        break;
                    }
                    if (row.actionLabel === 'Remove') {
                        let rowIndex = selectedRecords.indexOf(availableRecords[i]);
                        selectedRecords.splice(rowIndex, 1);
                        availableRecords[i].actionLabel = 'Add';
                        availableRecords[i].actionIcon = 'utility:add'
                        break;
                    }
                }
            }


            if (selectedRecords) {
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

                        }
                        this.selectedContractProducts.push(rec);
                    })
                });
            }

            this.gridData = [...availableRecords];
            this.gridDataSelected = [...selectedRecords];

            if (this.gridData.length > 0) {
                this.noDataAvailable = undefined;
            }
            else {
                this.noDataAvailable = 'No Contracts available to select';
            }



            //for opportunity with baseline
            const contractProducts = this.selectedContractProducts;
            const evt = new CustomEvent('selectcontractevent', {
                detail: { contractProducts }
            });
            this.dispatchEvent(evt);
        }
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