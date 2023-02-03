/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 09-08-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   08-12-2021   apyati   Initial Version
**/
import { LightningElement, track, api, wire } from 'lwc';
//import getForecastCategory from '@salesforce/apex/l2qManageProductController.getForecastCategory'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserInfo from '@salesforce/apex/l2qManageProductController.getUserInfo'; /* Apex method*/
import getGSMSettingValue from '@salesforce/apex/l2qManageProductController.getGSMSettingValue'; /* Apex method*/

import getOpportunityProductsWithContracts from '@salesforce/apex/l2qManageProductController.getOpportunityProductsWithContracts';

export default class L2qProductDetails extends LightningElement {
     @wire(getUserInfo) userData;// call Apex method and pass User id
     @wire(getGSMSettingValue, { name: 'specialistValidationProfiles' }) specialistValidationProfiles;// call Apex method and pass customsetting name
     @wire(getGSMSettingValue, { name: 'termValidationProfiles' }) termValidationProfiles;// call Apex method and pass customsetting name

     @api oppId;
     @api oppRecord;
     @api oppCurrency;
     @api oppClosedate;
     @api currencyRates;
     @api hasAccess;
     sequence = 0;
     showSpinner = true;
     oliToSelectedContracts;
     @track opportunityProducts = {
          'oppLineItems': [],
          'totals': {
               'Total_Baseline_Mrr': 0,
               'Total_Forecast_Mrr': 0,
               'Total_Net_Mrr': 0,
               'Total_Specialist_Net_Mrr': 0,
               'Total_Baseline_Usage': 0,
               'Total_Forecast_Usage': 0,
               'Total_Net_Usage': 0,
               'Total_Onetime_Fee': 0
          },
          'Currency': ''
     };
     showDeletePopup = false;
     showSpecialistPopupFlag = false;
     @track specialistFields = {};
     @track deleteOliList = [];
     popupTitle = '';
     showPopup = false;
     deleteRecordId = '';
     deleteProductRec = '';
     specialistPopupProduct;
     forecastCategoryList = []; // this will hold picklist values of forecast category
     specialistFieldArray = [];
     uniqueIdSequence = 0;
     editModeFields = ['Forecast_Mrr', 'Forecast_Usage', 'Onetime_Fee', 'Term'];
     mapOfProduct;
     mapOfProductToContracts;
     /**
      * This method will check user profile to enable /disable specialist popup
      */
     get isSpecialistDisabled() {

          let profileName = this.userData.data.Profile.Name;

          let profiles = [];
          if (this.specialistValidationProfiles.data && this.specialistValidationProfiles.data.includes(',')) {
               profiles = this.specialistValidationProfiles.data.split(',');
          } else {
               profiles.push(this.specialistValidationProfiles.data);
          }

          if (profiles.length > 0 && profiles.includes(profileName)) {
               return false;
          }

          /*
          if (profileName === 'System Administrator' || profileName === 'Business Operations' ||
               profileName === 'Sales Operations' || profileName === 'China Sales - ATG'
               || profileName === 'Sales - ATG') {
               return false;
          }
          */
          return true;
     }
     /**
     *get opportunity line items here
     */
     connectedCallback() {
          this.queryOppProducts();
     }

     /**
     * get opportunity line items here
     * get Renewal Products
     * get forecast category
     */
     @api
     queryOppProducts() {

          getOpportunityProductsWithContracts({ oppId: this.oppId }).then(response => {
               let allContracts = []
               let tempOliToSelectedContracts = new Map();
               response.forEach(oli => {
                    let tempSelectedContracts = new Set();
                    if (oli.Associated_Contract_Products__r) {
                         oli.Associated_Contract_Products__r.forEach(contract => {
                              tempSelectedContracts.add(contract.Contract_Product__c);
                              allContracts.push(contract.Contract_Product__c);
                         })
                    }
                    let tempSelectedContractsArr = [...tempSelectedContracts];
                    tempOliToSelectedContracts.set(oli.Id, tempSelectedContractsArr)
               })
               this.oliToSelectedContracts = tempOliToSelectedContracts;
               this.dispatchEvent(new CustomEvent('selectedcontracts', { 'detail': allContracts }));
               if (response) {
                    this.prepareOpportunityDetails(response);
               }
               this.showSpinner = false;
          }).catch(error => {
               console.log('error ', error);
               this.showToast('Error loading opportunituy products ',
                    error.body.message,
                    'error',
                    'sticky',
                    []);
          });

          this.forecastCategoryList = [
               { 'label': 'Omitted', 'value': 'Omitted' },
               { 'label': 'Pipeline', 'value': 'Pipeline' },
               { 'label': 'Upside', 'value': 'Upside' },
               { 'label': 'Commit', 'value': 'Commit' },
               { 'label': 'Closed', 'value': 'Closed' },
          ]
     }

     /* 
     *generic method to show toast 
     */
     showToast(title, message, variant, mode, messageData) {
          this.dispatchEvent(
               new ShowToastEvent({
                    title: title,
                    message: message,
                    messageData: messageData,
                    variant: variant,
                    mode: mode
               }),
          );
     }
     /**
      * this method shows edit icon on hover
      */
     showEditIcon(event) {
          event.preventDefault();
          if (this.hasAccess) {
               let dataid = event.target.dataset.id;
               dataid = dataid.split(":");
               dataid = dataid[1];
               let elementFound = this.opportunityProducts.oppLineItems.filter(e1 => {
                    return e1.Uniqueid === dataid && e1.isDelete === false;
               })
               if (elementFound.length > 0) {
                    this.showComponent('lightning-button-icon[data-id="' + event.target.dataset.id + '"]');
               }
          }
     }
     /**
      * this method will make lightning input visible
      */
     showComponent(dataid) {
          let element = this.template.querySelector(dataid);
          element.style.display = 'block';

     }
     /**
     * this method will make lightning input visible
     */
     hideComponent(dataid) {
          let element = this.template.querySelector(dataid);
          element.style.display = 'none';
     }
     /**
      * this method will make text with p tag hidden
      */
     hideInputTextBoxes(dataid) {
          let element = this.template.querySelector('lightning-input[data-id="' + dataid + '"]');
          element.style.display = 'none';

     }
     /**
      * this method hide edit or gear icon on mouse out
     */
     hideEditIcon(event) {
          event.preventDefault();
          let element = this.template.querySelector('lightning-button-icon[data-id="' + event.target.dataset.id + '"]');
          element.style.display = 'none';
     }
     /**
      * this method hide p tag for a particular row
     */
     hideTextInRows(dataid) {
          let element = this.template.querySelectorAll('p[product-id="' + dataid + '"]');
          element.forEach(e => {
               e.style.display = 'none';
          });
     }
     /**
      *this method enables rows in edit mode when an edit icon is clicked
     */
     rowEditHandler(event) {
          event.preventDefault();
          if (this.hasAccess) {
               let dataids = event.target.dataset.id;
               dataids = dataids.split(":");
               let dataid = dataids[1];
               let elementFound = this.opportunityProducts.oppLineItems.filter(e1 => {
                    return (e1.Uniqueid === dataid && !e1.isDelete);
               });
               if (elementFound.length > 0) {
                    this.hideTextInRows(dataid);
                    this.opportunityProducts.oppLineItems.forEach(opp => {
                         let Uniqueid = opp.Uniqueid;
                         if (Uniqueid === dataid) {
                              this.editModeFields.forEach(fieldId => {
                                   this.showComponent('lightning-input[data-id="' + opp.ids[fieldId] + '"]');
                              });
                         }
                    });
               }
          }
     }
     /**
      *this method update text color on any change
     */
     updateTextColorOnChange(dataid) {
          let elementInput = this.template.querySelector(dataid);
          if (elementInput) {
               elementInput.style.color = "orange";
          }
     }
     /**
      *this method will enable save buttons
     */
     dispatchEnableSaveEvent() {
          const evt = new CustomEvent('enablesavebutton', { 'detail': 'Product' });
          this.dispatchEvent(evt);
     }
     /**
      *this method will recalculate non ediatble columns on opportunity line item
     */
     doRecalculationOnOli(oli) {
          oli.Net_Mrr = oli.Forecast_Mrr - (oli.Baseline_Mrr ? oli.Baseline_Mrr : 0);
          oli.Net_Usage = oli.Forecast_Usage - (oli.Baseline_Usage ? oli.Baseline_Usage : 0);
          if (!oli.SpCommitTouched /*&& (oli.Baseline_Mrr === undefined || oli.Baseline_Mrr === null)*/) {
               oli.Specialist_Projected_Monthly_Commit = oli.Forecast_Mrr; // copy projected monthly commit if it is not touched.
          }
          if (!oli.SpOneTimeFeeTouched) {
               oli.Specialist_OneTimeFee = oli.Onetime_Fee;
          }
          if (oli.Baseline_Mrr) {
               oli.Specialist_Net_Mrr = oli.Specialist_Projected_Monthly_Commit - oli.Baseline_Mrr;
          } else {
               oli.Specialist_Net_Mrr = oli.Specialist_Projected_Monthly_Commit;
          }
     }
     /**
      *this method changes text color and total column color when a field is updated
     */
     onChangeHandler(event) {
          let dataid = event.target.dataset.id;
          this.updateTextColorOnChange('lightning-input[data-id="' + dataid + '"]');
          this.updateTextColorOnChange('p[data-id="' + dataid + '"]');
          let idArray = event.target.dataset.id.split(':');
          let totalId = 'Total_' + idArray[0];

          this.opportunityProducts.oppLineItems.forEach(oli => {
               if (oli.Uniqueid === idArray[1]) {
                    oli[idArray[0]] = event.target.value ? event.target.value : 0;
                    this.doRecalculationOnOli(oli);
                    if (idArray[0] === 'Forecast_Mrr') {
                         this.updateTextColorOnChange('p[data-id="' + oli.ids.Net_Mrr + '"]');
                    }
                    if (idArray[0] === 'Forecast_Usage') {
                         this.updateTextColorOnChange('p[data-id="' + oli.ids.Net_Usage + '"]');
                    }
               }
          });
          this.updateTextColorOnChange('lightning-formatted-number[data-id="' + totalId + '"]');
          if (idArray[0] === 'Forecast_Mrr') {
               totalId = 'Total_Net_Mrr';
               this.updateTextColorOnChange('lightning-formatted-number[data-id="' + totalId + '"]');
          }
          if (idArray[0] === 'Forecast_Usage') {
               totalId = 'Total_Net_Usage';
               this.updateTextColorOnChange('lightning-formatted-number[data-id="' + totalId + '"]');
          }
          this.calculateTotal();
          this.dispatchEnableSaveEvent();
     }
     /**
      *default opp line items on load
      */
     defaultOliWithBlankRec() {
          this.opportunityProducts = {
               'oppLineItems': [],
               'totals': {
                    'Total_Baseline_Mrr': 0,
                    'Total_Forecast_Mrr': 0,
                    'Total_Net_Mrr': 0,
                    'Total_Specialist_Net_Mrr': 0,
                    'Total_Baseline_Usage': 0,
                    'Total_Forecast_Usage': 0,
                    'Total_Net_Usage': 0,
                    'Total_Onetime_Fee': 0
               },
               'Currency': ''
          };
          this.opportunityProducts.Currency = this.oppCurrency;
     }
     /**
      *this method will be called on page load to prepare data for UI
     */
     prepareOpportunityDetails(data) {
          this.defaultOliWithBlankRec();
          this.sequence = 0;
          data.forEach(oli => {
               this.opportunityProducts.Currency = oli.CurrencyIsoCode;
               this.opportunityProducts.oppLineItems.push(this.populateOliRecord(oli));
          });
          this.calculateTotal();
     }
     /**
      * prepare single oli record on load
      */
     populateOliRecord(oli) {
          let isDeleteDisabled = false;
          console.log('populateOliRecord hasAccess' + this.hasAccess);
          if (oli.Average_Renewal_Commit_MRR__c !== undefined || (!this.hasAccess)) {
               isDeleteDisabled = true;
          }
          this.sequence++;
          let uniqueid = ++this.uniqueIdSequence;
          let productId = oli.Product2.Id;
          let obj = {
               'sequence': this.sequence,
               'Name': oli.Product2.Name,
               'Uniqueid': String(uniqueid),
               'Product': productId,
               'SFid': oli.Id,
               'Baseline_Mrr': oli.Average_Renewal_Commit_MRR__c !== undefined ? parseFloat(oli.Average_Renewal_Commit_MRR__c) : oli.Average_Renewal_Commit_MRR__c,
               'Forecast_Mrr': oli.Projected_Monthly_commit_fees__c !== undefined ? parseFloat(oli.Projected_Monthly_commit_fees__c) : 0,
               'Net_Mrr': oli.MRR__c !== undefined ? parseFloat(oli.MRR__c) : 0,
               'Specialist_Net_Mrr': oli.Specialist_Net_MRR__c !== undefined ? parseFloat(oli.Specialist_Net_MRR__c) : 0,
               'Baseline_Usage': oli.Average_Renewal_Usage_MRR__c !== undefined ? parseFloat(oli.Average_Renewal_Usage_MRR__c) : oli.Average_Renewal_Usage_MRR__c,
               'Forecast_Usage': oli.Projected_Avg_Rev_Non_Commit__c !== undefined ? parseFloat(oli.Projected_Avg_Rev_Non_Commit__c) : 0,
               'Net_Usage': oli.Net_Non_Commit__c !== undefined ? parseFloat(oli.Net_Non_Commit__c) : 0,
               'Onetime_Fee': oli.NRR__c !== undefined ? parseFloat(oli.NRR__c) : 0,
               'Term': oli.Term__c !== undefined ? oli.Term__c : 0,
               'Specialist_Projected_Monthly_Commit': oli.Specialist_Projected_Monthly_Commit__c !== undefined ? parseFloat(oli.Specialist_Projected_Monthly_Commit__c) : 0,
               'Specialist_Forecast_Category': oli.Specialist_Forecast_Category__c,
               'Specialist_Close_Date': oli.Specialist_Close_Date__c,
               'isNew': false,
               'isDelete': false,
               'isDeleteDisabled': isDeleteDisabled,
               'SpCommitTouched': oli.Specialist_Touched__c,
               'SpUsageTouched': oli.Specialist_Usage_Touched__c,
               'SpForecastTouched': oli.Specialist_Forecast_Touched__c,
               'SpOneTimeFeeTouched': oli.Specialist_NRR_Touched__c,
               'SpCloseDateTouched': oli.Specialist_Close_Date_Touched__c,
               'Specialist_OneTimeFee': oli.Specialist_NRR__c !== undefined ? oli.Specialist_NRR__c : 0,
               'Emri': oli.Emri__c !== undefined ? oli.Emri__c : 0,
               'contractProductIdSet': this.oliToSelectedContracts.get(oli.Id),
               'ids': {
                    'Forecast_Mrr': 'Forecast_Mrr:' + uniqueid,
                    'Net_Mrr': 'Net_Mrr:' + uniqueid,
                    'Specialist_Net_Mrr': 'Specialist_Net_Mrr:' + uniqueid,
                    'Forecast_Usage': 'Forecast_Usage:' + uniqueid,
                    'Net_Usage': 'Net_Usage:' + uniqueid,
                    'Onetime_Fee': 'Onetime_Fee:' + uniqueid,
                    'Term': 'Term:' + uniqueid
               }
          }
          return obj;
     }
     /**
      * this method will be called on click of delete icon to show popup
      * this method will populate deleteProductRec and deleteRecordId to keep track of which icon was clicked
      */
     deleteProductHandler(event) {
          this.showPopup = true;
          this.showDeletePopup = true;
          this.deleteRecordId = event.target.dataset.id;
          this.opportunityProducts.oppLineItems.forEach(oli => {
               if (oli.Uniqueid === this.deleteRecordId) {
                    this.deleteProductRec = oli.Name;
               }
          })
          this.popupTitle = 'Product Deletion - ' + this.deleteProductRec;
     }
     /**
      * Change text color of multiple elements
      */
     changeTextColorOfMultipleElements(dataid, color, display) {
          let element = this.template.querySelectorAll(dataid);
          element.forEach(e => {
               e.style.color = color;
               e.style.display = display;
          });
     }
     /**
      *this method will be called on click of undelete icon 
      *Make isDelete as False and change text color back to black
      */
     undeleteProductHandler(event) {
          let uid = event.target.dataset.id;
          this.opportunityProducts.oppLineItems.forEach(oli => {
               if (oli.Uniqueid === uid) {
                    oli.isDelete = false;
               }
          })
          this.changeTextColorOfMultipleElements('p[delete-id="' + uid + '"]', 'black', 'block');
          this.calculateTotal();

     }
     /**
      * this method is generic one to calculate all the totals
      */
     calculateTotal() {
          this.setDefaultToZero();
          this.sequence = 0;
          this.opportunityProducts.oppLineItems.forEach(oli => {
               this.sequence++;
               oli.sequence = this.sequence;
               if (oli.isDelete === false) {
                    this.opportunityProducts.totals.Total_Baseline_Mrr += oli.Baseline_Mrr ? parseFloat(oli.Baseline_Mrr) : 0;
                    this.opportunityProducts.totals.Total_Forecast_Mrr = this.opportunityProducts.totals.Total_Forecast_Mrr + (oli.Forecast_Mrr ? parseFloat(oli.Forecast_Mrr) : 0);
                    this.opportunityProducts.totals.Total_Net_Mrr = this.opportunityProducts.totals.Total_Net_Mrr + (oli.Net_Mrr ? parseFloat(oli.Net_Mrr) : 0);
                    this.opportunityProducts.totals.Total_Specialist_Net_Mrr = this.opportunityProducts.totals.Total_Specialist_Net_Mrr + (oli.Specialist_Net_Mrr ? parseFloat(oli.Specialist_Net_Mrr) : 0);
                    this.opportunityProducts.totals.Total_Baseline_Usage += oli.Baseline_Usage ? parseFloat(oli.Baseline_Usage) : 0;
                    this.opportunityProducts.totals.Total_Forecast_Usage = this.opportunityProducts.totals.Total_Forecast_Usage + (oli.Forecast_Usage ? parseFloat(oli.Forecast_Usage) : 0);
                    this.opportunityProducts.totals.Total_Net_Usage = this.opportunityProducts.totals.Total_Net_Usage + (oli.Net_Usage ? parseFloat(oli.Net_Usage) : 0);
                    this.opportunityProducts.totals.Total_Onetime_Fee = this.opportunityProducts.totals.Total_Onetime_Fee + (oli.Onetime_Fee ? parseFloat(oli.Onetime_Fee) : 0);
               }
          });
     }
     /**
      * this method is generic one to defaults all the totals to 0
      */
     setDefaultToZero() {
          this.opportunityProducts.totals.Total_Baseline_Mrr = 0;
          this.opportunityProducts.totals.Total_Forecast_Mrr = 0;
          this.opportunityProducts.totals.Total_Net_Mrr = 0;
          this.opportunityProducts.totals.Total_Specialist_Net_Mrr = 0;
          this.opportunityProducts.totals.Total_Baseline_Usage = 0;
          this.opportunityProducts.totals.Total_Forecast_Usage = 0;
          this.opportunityProducts.totals.Total_Net_Usage = 0;
          this.opportunityProducts.totals.Total_Onetime_Fee = 0;
     }

     /**
      * this method is to close popup
      */
     closeModal() {
          this.showPopup = false;
          this.showDeletePopup = false;
          this.showSpecialistPopupFlag = false;
          this.specialistPopupProduct = null;
     }
     /**
      * this method is to close specialist popup
      */
     closeSpecialistPopup() {
          this.closeModal();
     }
     /**
      * this method will copy the specialisr fields values from popup on click of confirm
      */
     submitSpecialistPopup() {
          if (this.showSpecialistPopupFlag) {
               this.opportunityProducts.oppLineItems.forEach(oli => {
                    if (oli.Uniqueid === this.specialistPopupProduct) {
                         this.specialistFieldArray.forEach(fieldDetail => {
                              oli[fieldDetail.field] = fieldDetail.value;
                              if (fieldDetail.field === 'Specialist_Close_Date') {
                                   oli.SpCloseDateTouched = true;
                              }
                              if (fieldDetail.field === 'Specialist_Projected_Monthly_Commit') {
                                   oli.SpCommitTouched = true;
                                   if (oli.Baseline_Mrr) {
                                        oli.Specialist_Net_Mrr = oli.Specialist_Projected_Monthly_Commit - oli.Baseline_Mrr;
                                   } else {
                                        oli.Specialist_Net_Mrr = oli.Specialist_Projected_Monthly_Commit;
                                   }
                              }
                              if (fieldDetail.field === 'Specialist_Forecast_Category') {
                                   oli.SpForecastTouched = true;
                              }
                              if (fieldDetail.field === 'Specialist_OneTimeFee') {
                                   oli.SpOneTimeFeeTouched = true;
                              }
                         })
                         this.updateTextColorOnChange('p[data-id="' + oli.ids.Specialist_Net_Mrr + '"]');
                    }
               })
               this.specialistPopupProduct = null;
               this.specialistFieldArray = [];
               this.calculateTotal();
               this.showSpecialistPopupFlag = false;
               this.showPopup = false;
               this.dispatchEnableSaveEvent();
          }
     }
     /**
      * this method will delete record on click of confirm
      */
     submitDetails() {
          let dataid = this.deleteRecordId;
          this.opportunityProducts.oppLineItems.forEach(oli => {
               if (dataid === oli.Uniqueid) {
                    oli.isDelete = true;
               }
          });
          //disable edit mode incase fields are in view and enable view
          this.opportunityProducts.oppLineItems.forEach(opp => {
               let Uniqueid = opp.Uniqueid;
               if (Uniqueid === dataid) {
                    this.editModeFields.forEach(fieldName => {
                         this.hideInputTextBoxes(opp.ids[fieldName]);
                    })
               }
          })
          this.changeTextColorOfMultipleElements('p[delete-id="' + dataid + '"]', 'red', 'block');
          this.calculateTotal();
          this.dispatchEnableSaveEvent();
          this.showPopup = false;
          this.showDeletePopup = false;
     }
     specialistPopupRecord;
     /**
      * this method will open specialist popup
      */
     showSpecialistPopup(event) {
          event.preventDefault();
          let dataid = event.target.dataset.id;
          dataid = dataid.split(":");
          dataid = dataid[1];
          let elementFound = this.opportunityProducts.oppLineItems.filter(e1 => {
               return e1.Uniqueid === dataid && e1.isDelete === false;
          })
          if (elementFound.length > 0) {
               this.popupTitle = elementFound[0].Name;
               let uid = event.target.dataset.id;
               uid = uid.split(':');
               uid = uid[1];
               this.specialistPopupProduct = uid; // to track the record
               this.opportunityProducts.oppLineItems.forEach(oli => {
                    if (uid === oli.Uniqueid) {
                         this.specialistFields = this.createSpecialistFieldObj(oli);
                         this.specialistPopupRecord = oli;
                    }
               });
               this.showPopup = true;
               this.showSpecialistPopupFlag = true;
          }

     }
     /**
      * this method will create special fields object to hold the specialist field values from clicked row
      */
     createSpecialistFieldObj(oli) {
          let specialistFieldObj = {
               'Specialist_Projected_Monthly_Commit': oli.Specialist_Projected_Monthly_Commit,
               'Specialist_Forecast_Category': oli.Specialist_Forecast_Category,
               'Specialist_Close_Date': oli.Specialist_Close_Date,
               'Baseline_Mrr': oli.Baseline_Mrr,
               'Specialist_Net_Mrr': oli.Specialist_Net_Mrr,
               'Specialist_OneTimeFee': oli.Specialist_OneTimeFee,
               'Specialist_Comments': oli.Specialist_Comments
          };
          return specialistFieldObj;
     }
     /**
      * This method will do manipulation when there is any change in specialist popup input fields
      */
     onChangeOfSpecialistFields(event) {
          this.dispatchEnableSaveEvent();
          this.opportunityProducts.oppLineItems.forEach(oli => {
               if (oli.Uniqueid === this.specialistPopupProduct) {
                    let found = false;
                    this.specialistFieldArray.forEach(eachField => {
                         if (eachField.field === event.target.name) {
                              eachField.value = event.target.value;
                              found = true;
                         }
                    });
                    if (found === false) {
                         this.specialistFieldArray.push({ 'field': event.target.name, 'value': event.target.value });
                    }
                    if (event.target.name === 'Specialist_Projected_Monthly_Commit') {
                         if (this.specialistFields.Baseline_Mrr) {
                              this.specialistFields.Specialist_Net_Mrr = event.target.value - this.specialistFields.Baseline_Mrr;
                         } else {
                              this.specialistFields.Specialist_Net_Mrr = event.target.value;
                         }
                    }
               }
          })
          this.calculateTotal();
     }
     /**
      * to handle forecast category change from specialist field popup
      */
     handleForecastCategoryChange(event) {
          this.dispatchEnableSaveEvent();
          this.opportunityProducts.oppLineItems.forEach(oli => {
               if (oli.Uniqueid === this.specialistPopupProduct) {
                    this.specialistFieldArray.push({ 'field': 'Specialist_Forecast_Category', 'value': event.target.value });
               }
          })
     }
     /**
      * to add new products from add product screen
      */
     @api
     addProducts(productList) {
          this.dispatchEnableSaveEvent();
          productList.forEach(product => {
               this.sequence++;
               let uniqueid = ++this.uniqueIdSequence;
               let obj = {
                    'Name': product.ProductName,
                    'Uniqueid': String(uniqueid),
                    'Product': product.Id,
                    'Baseline_Mrr': null,
                    'Baseline_Usage': null,
                    'isDeleteDisabled': false,
                    'Net_Mrr': 0,
                    'Net_Usage': 0,
                    'Specialist_Net_Mrr': 0,
               }
               this.assignDefaultFields(obj, this.oppRecord, uniqueid);
               this.opportunityProducts.oppLineItems.push(obj);
          });
          this.calculateTotal();
     }
     /*
     * Validate one time fee to not have negative value
     */
     validateOneTimeFee(oli) {
          if (oli.Onetime_Fee < 0) {
               this.showToast('Product One Time Fee validation ',
                    oli.Name + ' is having negative One Time Fee ' + oli.Onetime_Fee + ', update it to positive value and try again',
                    'error',
                    'sticky',
                    []);
               const evt = new CustomEvent('hidespinner');
               this.dispatchEvent(evt);
               return true;
          }
          return false;
     }
     /*
     * Validate term to be within 0 to 24
     */
     validateTermOnOli(oli) {
          let profiles = [];
          if (this.termValidationProfiles.data && this.termValidationProfiles.data.includes(',')) {
               profiles = this.termValidationProfiles.data.split(',');
          } else {
               profiles.push(this.termValidationProfiles.data);
          }


          if (profiles.includes(this.userData.data.Profile.Name)//   === 'Sales - Carrier'
               && (oli.Term && (oli.Term < 0 || oli.Term > 24))) {
               this.showToast('Product Term validation ',
                    'Term is required, update ' + oli.Name + ' with term value from 0 to 24',
                    'error',
                    'sticky',
                    []);
               const evt = new CustomEvent('hidespinner');
               this.dispatchEvent(evt);
               return true;
          }
          return false;
     }
     /**
      * this method will form data for apex to do dml operations - todo
      */
     @api
     quickSaveHandler() {
          let listOfOli = [];
          let errorFound = false;
          for (let i = 0; i < this.opportunityProducts.oppLineItems.length; i++) {
               let oli = this.opportunityProducts.oppLineItems[i];
               errorFound = this.validateOneTimeFee(oli);
               if (errorFound) break;
               errorFound = this.validateTermOnOli(oli);
               if (errorFound) break;

               if (oli.Baseline_Mrr) {
                    let round_Baseline_Mrr = (Math.round(oli.Baseline_Mrr * 100) / 100).toFixed(2);
                    let round_Forecast_Mrr = (Math.round(oli.Forecast_Mrr * 100) / 100).toFixed(2);
                    if (round_Baseline_Mrr === round_Forecast_Mrr) {
                         oli.Forecast_Mrr = oli.Baseline_Mrr;
                    }
               }

               if (oli.Baseline_Usage) {
                    let round_Baseline_Usage = (Math.round(oli.Baseline_Usage * 100) / 100).toFixed(2);
                    let round_Forecast_Usage = (Math.round(oli.Forecast_Usage * 100) / 100).toFixed(2);
                    if (round_Baseline_Usage === round_Forecast_Usage) {
                         oli.Forecast_Usage = oli.Baseline_Usage;
                    }
               }
               this.doRecalculationOnOli(oli);

               let prod = {
                    'Name': oli.Name,
                    'SFid': oli.SFid,
                    'ProductId': oli.Product,
                    'Baseline_Mrr': oli.Baseline_Mrr,
                    'Forecast_Mrr': oli.Forecast_Mrr,
                    'Net_Mrr': oli.Net_Mrr,
                    'Specialist_Net_Mrr': oli.Specialist_Net_Mrr,
                    'Baseline_Usage': oli.Baseline_Usage,
                    'Forecast_Usage': oli.Forecast_Usage,
                    'Net_Usage': oli.Net_Usage,
                    'Onetime_Fee': oli.Onetime_Fee,
                    'Term': oli.Term,
                    'Specialist_Projected_Monthly_Commit': oli.Specialist_Projected_Monthly_Commit,
                    'Specialist_Forecast_Category': oli.Specialist_Forecast_Category,
                    'Specialist_Close_Date': oli.Specialist_Close_Date,
                    'isNew': oli.isNew,
                    'isDelete': oli.isDelete,
                    'isFromContractScreen': oli.isFromContractScreen,
                    'currencyOpp': this.opportunityProducts.Currency,
                    'oppId': this.oppId,
                    'SpCommitTouched': oli.SpCommitTouched,
                    'SpUsageTouched': oli.SpUsageTouched,
                    'SpForecastTouched': oli.SpForecastTouched,
                    'SpOneTimeFeeTouched': oli.SpOneTimeFeeTouched,
                    'SpCloseDateTouched': oli.SpCloseDateTouched,
                    'Specialist_Onetime_Fee': oli.Specialist_OneTimeFee
               };
               prod.contractDetailObj = [];
               if (oli.Contract && oli.Contract.length > 0) {
                    let conprods = [];
                    oli.Contract.forEach(e => {
                         conprods.push({
                              "ContractId": e.ContractId,
                              "Name": e.Name,
                              "CurrencyIsoCode": e.CurrencyIsoCode,
                              "EffectiveStartDate": e.EffectiveStartDate,
                              "EffectiveEndDate": e.EffectiveEndDate,
                              "AutoRenew": e.AutoRenew,
                              "ParentContract": e.ParentContract,
                              "OrderId": e.OrderId,
                              "ContractType": e.ContractType,
                              "contractProductId": e.contractProductId
                         });
                    });
                    prod.contractDetailObj = [...conprods];
               }
               listOfOli.push(prod);
          }
          if (errorFound === false) {
               const evt = new CustomEvent('productsave', { 'detail': { 'oliRecords': listOfOli, 'totals': this.opportunityProducts.totals } });
               this.dispatchEvent(evt);
          }
     }
     /**
      * this method will enable view mode once everything is saved to database
      */
     @api
     enableViewMode() {
          this.changeTextColorOfMultipleElements('p', 'black', 'block');
          this.changeTextColorOfMultipleElements('lightning-input', 'black', 'none');
          this.changeTextColorOfMultipleElements('lightning-formatted-number', 'black', 'block');
     }
     /**
      * this method will reset forecast mrr, forecast usage to baseline mrr,baseline usage respectively
      */
     @api
     resetToBaseLine() {
          this.opportunityProducts.oppLineItems.forEach(oli => {
               if (oli.Baseline_Mrr !== undefined) {
                    oli.Forecast_Mrr = parseFloat(oli.Baseline_Mrr);
                    oli.Forecast_Usage = parseFloat(oli.Baseline_Usage);
                    oli.Specialist_Projected_Monthly_Commit = oli.Baseline_Mrr;
                    oli.Net_Mrr = 0;
                    oli.Net_Mrr = oli.Forecast_Mrr - (oli.Baseline_Mrr ? oli.Baseline_Mrr : 0);
                    oli.Net_Usage = oli.Forecast_Usage - (oli.Baseline_Usage ? oli.Baseline_Usage : 0);
                    oli.Specialist_Net_Mrr = oli.Specialist_Projected_Monthly_Commit - oli.Baseline_Mrr;
                    oli.Emri = 0;
                    this.changeTextColorOfMultipleElements('p[delete-id="' + oli.Uniqueid + '"]', 'orange', 'block');
                    this.editModeFields.forEach(fieldName => {
                         this.hideInputTextBoxes(oli.ids[fieldName]);
                    });
               } else {
                    oli.isDelete = true;
                    this.changeTextColorOfMultipleElements('p[delete-id="' + oli.Uniqueid + '"]', 'red', 'block');
                    this.editModeFields.forEach(fieldName => {
                         this.hideInputTextBoxes(oli.ids[fieldName]);
                    });
               }

          })
          this.calculateTotal();
          this.changeTextColorOfMultipleElements('lightning-formatted-number', 'orange', 'block');
          this.dispatchEnableSaveEvent();
     }
     /**
      * reset forecast fields to zero 
      */
     @api
     churnCancelContract() {
          this.opportunityProducts.oppLineItems.forEach(oli => {
               oli.Forecast_Mrr = 0;
               oli.Onetime_Fee = 0;
               oli.Forecast_Usage = 0;
               oli.Specialist_Projected_Monthly_Commit = 0;
               oli.Net_Mrr = oli.Forecast_Mrr - (oli.Baseline_Mrr ? oli.Baseline_Mrr : 0);
               oli.Net_Usage = oli.Forecast_Usage - (oli.Baseline_Usage ? oli.Baseline_Usage : 0);
               oli.Specialist_Net_Mrr = oli.Specialist_Projected_Monthly_Commit - (oli.Baseline_Mrr ? oli.Baseline_Mrr : 0);
               oli.Specialist_OneTimeFee = 0;
               this.changeTextColorOfMultipleElements('p[delete-id="' + oli.Uniqueid + '"]', 'orange', 'block');
               this.editModeFields.forEach(fieldName => {
                    this.hideInputTextBoxes(oli.ids[fieldName]);
               });
          })
          this.calculateTotal();
          this.changeTextColorOfMultipleElements('lightning-formatted-number', 'orange', 'block');

          this.dispatchEnableSaveEvent();
     }
     /**
      * to merge contract based on contract id , these contracts are coming from add or remove contract screen
      */
     mergeContractLineItems(productList) {
          this.mapOfProduct = new Map();
          this.mapOfProductToContracts = new Map();
          productList.forEach(product => {
               if (this.mapOfProduct.has(product.ProductId)) {
                    let contracts = this.mapOfProductToContracts.get(product.ProductId);
                    let conArray = [];
                    conArray.push(product);
                    conArray.push(...contracts);
                    this.mapOfProductToContracts.set(product.ProductId, conArray);
                    let tempProduct = this.mapOfProduct.get(product.ProductId);
                    product.UsageMRR += tempProduct.UsageMRR;
                    product.CommitMRR += tempProduct.CommitMRR;
                    this.mapOfProduct.set(product.ProductId, product);
               }
               else if (this.mapOfProduct.has(product.ProductId) === false) {
                    this.mapOfProduct.set(product.ProductId, product);
                    let newArray = [];
                    newArray = [product];
                    this.mapOfProductToContracts.set(product.ProductId, newArray);
               }
          });
     }
     /**
      * to convert currency values to optycurrency
      */
     convertProductCurrency(productList) {
          let mapIsocodeCD = JSON.parse(JSON.stringify(this.currencyRates));
          if (mapIsocodeCD) {
               productList.forEach(product => {
                    if (product.CurrencyIsoCode !== this.oppCurrency) {
                         product.CommitMRR = (product.CommitMRR / mapIsocodeCD[product.CurrencyIsoCode]) * mapIsocodeCD[this.oppCurrency];
                         product.UsageMRR = (product.UsageMRR / mapIsocodeCD[product.CurrencyIsoCode]) * mapIsocodeCD[this.oppCurrency];
                    }
               });
          }
     }
     /**
      * handle adding or removing new contracts
      */
     @api
     addOrRemoveContracts(detail) {
          let productList = detail.contractProducts;
          let contractChange = detail.contractChange;
          if (contractChange === false) {
               return;
          }
          let oppRecordDetail = this.oppRecord;
          this.dispatchEnableSaveEvent(); //code for mergin productList based on product id
          let lineItems = this.opportunityProducts.oppLineItems;
          this.convertProductCurrency(productList);
          this.mergeContractLineItems(productList);
          let uniqueIdSetForDelete = [];
          let uniqueIdSetForUpdate = [];
          let mapOfProductToContracts = this.mapOfProductToContracts;
          let mapOfProduct = this.mapOfProduct;
          lineItems.forEach(oli => {
               if (oli.Baseline_Mrr !== undefined) {
                    let changed = true;
                    if (oli.contractProductIdSet) { // this block is to check if there is any update on contracts or not

                         let existingContracts = oli.contractProductIdSet;
                         let updatedContracts = [];
                         if (mapOfProductToContracts.get(oli.Product)) {
                              mapOfProductToContracts.get(oli.Product).forEach(con => {
                                   updatedContracts.push(con.Id);
                              });
                         }
                         existingContracts = JSON.parse(JSON.stringify(existingContracts));
                         existingContracts.sort();
                         updatedContracts.sort();
                         let is_same = (existingContracts.length === updatedContracts.length) && existingContracts.every(function (element, index) {
                              return element === updatedContracts[index];
                         });
                         if (is_same) {
                              changed = false;
                         }
                         oli.contractProductIdSet = updatedContracts;
                    }
                    if (changed) {
                         if (mapOfProduct.has(oli.Product) === true) { // if contract list for a particular product is updated then update baseline fields and related contracts
                              oli.Baseline_Mrr = parseFloat(mapOfProduct.get(oli.Product).CommitMRR); //mapOfProduct.get(oli.Product).CommitMRR;
                              oli.Baseline_Usage = parseFloat(mapOfProduct.get(oli.Product).UsageMRR); //mapOfProduct.get(oli.Product).UsageMRR; 
                              oli.isFromContractScreen = true;
                              oli.isDelete = false;
                              oli.isNew = true;
                              uniqueIdSetForUpdate.push(oli);
                              let contracts = mapOfProductToContracts.get(oli.Product);
                              oli.Contract = [];
                              let ArrayOfContract = [];
                              oli.contractProductIdSet = [];
                              this.assignContractsToOli(contracts, ArrayOfContract, oli);
                              oli.Contract = ArrayOfContract;
                         }
                         else {  //in case it is not in list of product that means product is deleted , so make it deleted on UI
                              oli.isDelete = true;
                              oli.isFromContractScreen = true;
                              oli.isDeleteDisabled = true;
                              uniqueIdSetForDelete.push(oli);
                         }
                    }
               }
          });
          uniqueIdSetForDelete.forEach(opp => { // for deleted one , remove input text boxes and set color to red
               this.editModeFields.forEach(fieldName => {
                    this.hideInputTextBoxes(opp.ids[fieldName]);
               })
               this.changeTextColorOfMultipleElements('p[delete-id="' + opp.Uniqueid + '"]', 'red', 'block');
          });
          uniqueIdSetForUpdate.forEach(opp => {  // for updated one , remove input text boxes and set color to orange
               this.editModeFields.forEach(fieldName => {
                    this.hideInputTextBoxes(opp.ids[fieldName]);
               })
               this.changeTextColorOfMultipleElements('p[delete-id="' + opp.Uniqueid + '"]', 'orange', 'block');
          });
          let tempSequence = this.uniqueIdSequence;
          let newListOfOli = [];
          //this block will add line items to UI if it doesn't exist already
          mapOfProduct.forEach(function (value, key) {
               let ProductId = key;
               let ProductObj = value;
               const lineitem = lineItems.filter(oli => oli.Product === ProductId && oli.Baseline_Mrr !== undefined);
               if (lineitem.length === 0) {
                    let uniqueid = ++tempSequence;
                    let baselineMrr = (ProductObj.CommitMRR);
                    let baselineUSage = (ProductObj.UsageMRR);
                    let obj = {
                         'Name': ProductObj.ProductName,
                         'Uniqueid': String(uniqueid),
                         'Product': ProductObj.ProductId,
                         'Baseline_Mrr': baselineMrr,
                         'Baseline_Usage': baselineUSage,
                         'isDeleteDisabled': true,
                         'isFromContractScreen': true,
                         'Net_Mrr': -baselineMrr,
                         'Net_Usage': -baselineUSage,
                         'Specialist_Net_Mrr': -baselineMrr,
                         'Contract': [],
                         'contractProductIdSet': []
                    };
                    newListOfOli.push(obj);
               }
          });
          newListOfOli.forEach(oli => { // this block will assign contracts
               this.assignDefaultFields(oli, oppRecordDetail);
               let contracts = mapOfProductToContracts.get(oli.Product);
               let ArrayOfContract = [];
               this.assignContractsToOli(contracts, ArrayOfContract, oli);
               oli.Contract = ArrayOfContract;
               lineItems.push(oli);
          })
          this.opportunityProducts.oppLineItems = lineItems;
          this.uniqueIdSequence = tempSequence;
          this.calculateTotal();
     }
     /*
     *method to assign contracts on baseline products
      */
     assignContractsToOli(contracts, ArrayOfContract, obj) {
          contracts.forEach(con => {
               ArrayOfContract.push({
                    "ContractId": con.Contract.Id,
                    "Name": con.Contract.Name,
                    "CurrencyIsoCode": con.Contract.CurrencyIsoCode,
                    "EffectiveStartDate": con.Contract.EffectiveStartDate,
                    "EffectiveEndDate": con.Contract.EffectiveEndDate,
                    "AutoRenew": con.Contract.AutoRenew,
                    "ParentContract": con.Contract.ParentContract,
                    "OrderId": con.Contract.OrderId,
                    "ContractType": con.Contract.ContractType,
                    "contractProductId": con.Id
               });
               obj.contractProductIdSet.push(con.Id);
          });
     }
     /*
     * method to assign default fields on oli creation
     */
     assignDefaultFields(oli, oppRecordDetail) {

          oli.Forecast_Mrr = 0;
          oli.Forecast_Usage = 0;
          oli.Onetime_Fee = 0;
          oli.Term = 0;
          oli.Specialist_Projected_Monthly_Commit = 0;
          oli.isNew = true;
          oli.isDelete = false;
          oli.SpCommitTouched = false;
          oli.SpUsageTouched = false;
          oli.SpForecastTouched = false;
          oli.SpOneTimeFeeTouched = false;
          oli.SpCloseDateTouched = false;
          oli.Specialist_OneTimeFee = 0;
          oli.Emri = 0;
          oli.Specialist_Forecast_Category = oppRecordDetail.fields.Forecast_Category__c.value;
          oli.Specialist_Close_Date = oppRecordDetail.fields.CloseDate.value;
          oli.SFid = null;
          oli.sequence = 0;
          oli.ids = {
               'Forecast_Mrr': 'Forecast_Mrr:' + oli.Uniqueid,
               'Net_Mrr': 'Net_Mrr:' + oli.Uniqueid,
               'Specialist_Net_Mrr': 'Specialist_Net_Mrr:' + oli.Uniqueid,
               'Forecast_Usage': 'Forecast_Usage:' + oli.Uniqueid,
               'Net_Usage': 'Net_Usage:' + oli.Uniqueid,
               'Onetime_Fee': 'Onetime_Fee:' + oli.Uniqueid,
               'Term': 'Term:' + oli.Uniqueid
          }
     }
}