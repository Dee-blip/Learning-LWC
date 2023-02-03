import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation';
import getProductDetails from '@salesforce/apex/CPQ_PM_ApiCalllout.getProductDetails';
import buildProduct from '@salesforce/apex/CPQ_PM_BuildProduct.buildProduct';


const sectionColumns = [
    {
        label: 'Ranking', fieldName: 'ranking', type: 'number', sortable: true
    },
    {
        label: 'Section Name', fieldName: 'name', type: 'text', sortable: true
    },
    {
        label: 'LI group info', fieldName: 'listItemGroupInfoString', type: 'text'
    }
];

export default class CpqCreatePartnerProduct extends NavigationMixin(LightningElement) {

    buttonLabel = 'Get Product Details';
    mktProdId = '';
    productDetailsResponse = {
        "validity": false
    };
    error;
    sectionData;
    sectionColumns = sectionColumns;
    selectedSectionId;
    filteredSectionData;
    createButtonDisable = false;
    detailsButtonDisable = false;
    billingModelValue = [];
    hasMultipleBillingModels = true;
    recordId;

    get billingModelOptions() {
        return [
            { label: 'Usage Commitment', value: 'Usage Commitment' },
            { label: 'Straight Line Commitment', value: 'Straight-line Commitment' },
        ];
    }

    get selectedBillingModelValues() {
        return this.billingModelValue.join(',');
    }

    handleBillingModelChange(event) {
        this.billingModelValue = event.detail.value;
    }

    handleProductCodeChange(event) {
        this.mktProdId = event.target.value;
    }

    /**
     * validate API callout, error handling
     * get sections - show in a selectable tab format, user selects usage section (required)
     * start the product creation logic
     */

    //imperative call to validate the product
    handleGetProductDetails() {

        this.buttonLabel = 'Fetching Product Details...'
        this.detailsButtonDisable = true;

        getProductDetails({ mktProdId: this.mktProdId })
            .then((result) => {
                console.log(typeof result, ' :result: ', result);
                this.productDetailsResponse = result;
                this.error = undefined;

                if (this.productDetailsResponse.validity) {

                    this.showToast('Success', 'Product data fetched successfully!', 'success', 'pester');

                    this.sectionData = JSON.parse(this.productDetailsResponse.sectionResponse);
                    this.filteredSectionData = this.sectionData.filter(function (section) {
                        return section.name !== 'End of sale' && section.name.toLowerCase().indexOf('netstorage') === -1;
                    });

                    this.filteredSectionData = this.filteredSectionData.map(record => {
                        let x = record;
                        x.listItemGroupInfoString = x.listItemGroupInfo ? JSON.stringify(x.listItemGroupInfo) : '';
                        return x;
                    });

                } else {

                    this.showToast('Error', this.productDetailsResponse.errorResponse.detail, 'error', 'pester');
                    this.buttonLabel = 'Get Product Details';
                    this.detailsButtonDisable = false;

                }
            })
            .catch((error) => {
                console.log('error: ', error);
                this.error = error;
                this.productDetailsResponse = undefined;
                this.buttonLabel = 'Get Product Details';
                this.detailsButtonDisable = false;
            });
    }

    handleCreateProduct() {

        if (this.selectedSectionId) {

            this.createButtonDisable = true;

            buildProduct({
                prodDetailsResponse: JSON.stringify(this.productDetailsResponse),
                billModels: this.billingModelValue,
                usgSectionId: this.selectedSectionId
            })
                .then((result) => {
                    console.log('inside result');
                    console.log(result);
                    this.recordId = result;

                })
                .catch((error) => {
                    console.log('inside error');
                    console.log(error);
                    this.error = error;

                });
        } else {
            this.showToast('Error', 'Select usage section.', 'error', 'pester');
        }

    }

    getSelectedSectionId(event) {
        const selectedRows = event.detail.selectedRows;

        //since we have limited the selection to 1
        this.selectedSectionId = selectedRows[0].id;
        console.log('selected row id: ', this.selectedSectionId);
    }

    showToast(title, message, variant, mode, messageData) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                messageData: messageData,
                variant: variant,
                mode: mode
            })
        );
    }

}