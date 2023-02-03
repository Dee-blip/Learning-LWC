import { LightningElement, wire, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
import getProductOptionDetails from "@salesforce/apex/CPQ_PM_BuildProduct.getProductOptionDetails";
import deleteSelectedProductOptions from "@salesforce/apex/CPQ_PM_BuildProduct.deleteSelectedProductOptions";

const PRODUCT_FIELDS = [
  "Product2.Name",
  "Product2.ProductCode",
  "Product2.Family",
];

const actions = [
  { label: "View", name: "view" },
  { label: "Edit", name: "edit" },
];

const columns = [
  {
    label: "Number",
    fieldName: "SBQQ__Number__c",
    type: "number",
    sortable: true,
  },
  {
    label: "Optional Product",
    fieldName: "SBQQ__OptionalSKU__r_Name",
    type: "text",
    sortable: true,
    wrapText: true,
  },
  {
    label: "Feature",
    fieldName: "SBQQ__Feature__r_Name",
    type: "text",
    sortable: true,
    wrapText: true,
  },
  {
    label: "UOM",
    fieldName: "CPQ_Measurement__c",
    type: "text",
  },
  // {
  //     label: 'Billing Frequency',
  //     fieldName: 'CPQ_Billing_Frequency__c',
  //     type: 'text'
  // },
  {
    label: "Pricing Model",
    fieldName: "CPQ_Charge_Type__c",
    type: "text",
    wrapText: true,
  },
  {
    label: "Notes",
    fieldName: "CPQ_Product_Notes__c",
    type: "text",
    wrapText: true,
  },
  {
    type: "action",
    typeAttributes: { rowActions: actions, menuAlignment: "right" },
  },
];

export default class CpqPartnerProductDetails extends NavigationMixin(
  LightningElement
) {
  @api configuredSkuId;
  // configuredSkuId = '01t19000006ZlrLAAS';
  columns = columns;
  data = [];
  error;
  buttonLabel = "Delete Selected Options";
  selectedRecords = [];
  recordsCount = 0;
  deleteButtonDisable = false;

  @wire(getRecord, { recordId: "$configuredSkuId", fields: PRODUCT_FIELDS })
  product;

  get name() {
    return this.product.data.fields.Name.value;
  }

  get productCode() {
    return this.product.data.fields.ProductCode.value;
  }

  get family() {
    return this.product.data.fields.Family.value;
  }

  @wire(getProductOptionDetails, { configuredSkuId: "$configuredSkuId" })
  wiredGetProductOptionDetails(value) {
    this.wiredProductOptions = value;
    const { data, error } = value;
    if (data) {
      this.data = data;
      this.error = undefined;
      console.log(this.data);
      console.log(JSON.stringify(this.data));

      this.data = data.map((record) => ({
        ...record,
        SBQQ__OptionalSKU__r_Name:
          record.SBQQ__OptionalSKU__r == null
            ? ""
            : record.SBQQ__OptionalSKU__r.Name,
        SBQQ__Feature__r_Name: record.SBQQ__Feature__r.Name,
      }));
    } else if (error) {
      this.error = error;
      this.data = undefined;
    }
  }

  getSelectedRecords(event) {
    // getting selected rows
    const selectedRows = event.detail.selectedRows;

    this.recordsCount = event.detail.selectedRows.length;

    // this set elements the duplicates if any
    let recIds = new Set();

    // getting selected record id
    for (let i = 0; i < selectedRows.length; i++) {
      recIds.add(selectedRows[i].Id);
    }

    // coverting to array
    this.selectedRecords = Array.from(recIds);

    window.console.log("selectedRecords ====> " + this.selectedRecords);
  }

  deleteRecords() {
    if (this.selectedRecords) {
      // setting values to reactive variables
      this.buttonLabel = "Processing....";
      this.deleteButtonDisable = true;

      // calling apex class to delete selected records.
      this.deleteProductOptions();
    }
  }

  deleteProductOptions() {
    deleteSelectedProductOptions({ prodOptionIds: this.selectedRecords })
      .then((result) => {
        window.console.log("result ====> " + result);

        this.buttonLabel = "Delete Selected Options";
        this.deleteButtonDisable = false;

        // showing success message
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success!!",
            message: this.recordsCount + " Options are deleted.",
            variant: "success",
          })
        );

        // Clearing selected row indexs
        this.template.querySelector("lightning-datatable").selectedRows = [];

        this.recordsCount = 0;

        // refreshing table data using refresh apex
        return refreshApex(this.wiredProductOptions);
      })
      .catch((error) => {
        window.console.log(error);
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error while getting Contacts",
            message: error.message,
            variant: "error",
          })
        );
      });
  }

  handleRowAction(event) {
    const action = event.detail.action;
    // const row = event.detail.row;
    switch (action.name) {
      case "view":
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: event.detail.row.Id,
            actionName: "view",
          },
        });
        break;
      case "edit":
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: event.detail.row.Id,
            objectApiName: "SBQQ__ProductOption__c",
            actionName: "edit",
          },
        });
        break;
      default:
    }
  }

  navigateToProductPage() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.configuredSkuId,
        objectApiName: "Product2",
        actionName: "view",
      },
    });
  }
}