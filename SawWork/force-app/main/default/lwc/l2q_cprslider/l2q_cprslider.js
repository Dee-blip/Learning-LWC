/* Author : Rajesh Kumar - GSM Sales Team 
   JIRA# : SFDC-7608
   Description : Static component for CPR Filter 
*/

import { LightningElement, api, track } from 'lwc';
import { isEmpty } from 'c/l2QlwcUtil';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class L2q_cprslider extends LightningElement {
    @api schemadetail = [];
    mpdata = new Map();
    rendered = false;
    histAllowed = false;
    @track fielddetail;
    @track eventLabel = 'Event Start Date (<=)'

    connectedCallback() {
        this.schemadetail.forEach(el => {
            if (el.fieldType === 'PICKLIST') {
                let esl = JSON.parse(JSON.stringify(el.picklistValues));
                this.mpdata.set(el.fieldapiName.toLowerCase(), esl);
            }
        })
    }

    @api
    clearFilter() {
        let check = false;
        this.template.querySelectorAll('.select').forEach(el => {
            check = check || !isEmpty(el.value);
            el.value = '';
        })
        return check;
    }

    @api
    clearAll() {
        if (this.clearFilter()) {
            this.dispatchCustomevent(this.histAllowed, '');
        }
    }

    @api
    closeNav() {
        const data = this.template.querySelector(`[data-id="mySidebar"]`);
        data.style.width = "0";
        data.style.border = "unset";

    }
    @api
    openNav() {
        try {
            const data = this.template.querySelector(`[data-id="mySidebar"]`);
            data.style.width = "250px";
            data.style.border = "0.5px solid rgba(0, 153, 204, 1)";
        }
        catch (error) {
            this.showToast('FILTER ERROR : ', error.message, 'error');
        }
    }

    @api
    applyFilter() {
        let whereClause = '';
        try {
            if (this.validateName()) {
                if (this.validateFilter()) {
                    this.template.querySelectorAll('.select').forEach(el => {
                        if (!isEmpty(el.value)) {
                            switch (el.name) {
                                case 'name':
                                    whereClause = whereClause + ` and  name like  '%${el.value}%' `;
                                    break;
                                case 'status__c':
                                    whereClause = whereClause + ` and status__c =  '${el.value}' `;
                                    break;
                                case 'event_type__c':
                                    whereClause = whereClause + ` and event_type__c =  '${el.value}' `;
                                    break;
                                case 'delivery_product__c':
                                    whereClause = whereClause + ` and delivery_product__c =  '${el.value}' `;
                                    break;
                                case 'event_start_date_time__c':
                                    whereClause = whereClause + ` and  DAY_ONLY(convertTimezone(event_start_date_time__c))  >=  ${el.value}`;
                                    break;
                                case 'eventstartdatetime':
                                    whereClause = whereClause + ` and DAY_ONLY(convertTimezone(event_start_date_time__c)) <=  ${el.value}`;
                                    break;
                                case 'createddate':
                                    whereClause = whereClause + ` and createddate =  ${el.value} `;
                                    break;
                                default:
                                    break;
                            }
                        }
                    })
                    this.dispatchCustomevent(this.histAllowed, whereClause);
                }
                else {
                    this.showToast('FILTER ERROR : ', 'One of the filter field must have valid filter value.', 'error');
                }
            }
            else {
                this.showToast('FILTER ERROR : ', 'Minimum 2 character is required to search event name.', 'error');
            }
        }
        catch (error) {
            this.showToast('FILTER ERROR : ', error.message, 'error');
        }
    }

    validateFilter = () => {
        let count = 0;
        this.template.querySelectorAll('.select').forEach(el => {
            count = (!isEmpty(el.value) ? count + 1 : count);
        })
        return count > 0 ? true : false;

    }

    validateName = () => {
        let name = this.template.querySelector(`[data-id="name"]`);
        if (!isEmpty(name.value)) {
            if (name.value.trim().length < 2) {
                return false;
            }
        }
        return true;
    }

    renderedCallback() {
        if (!this.rendered) {
            this.rendered = true;
            this.template.querySelectorAll('.select').forEach(el => {
                if (this.mpdata.has(el.name.toLowerCase())) {
                    try {
                        let data = [...this.mpdata.get(el.name.toLowerCase())];
                        el.options = data;
                    }
                    catch (error) {
                        console.log(error.message);
                    }
                }
            })
        }
    }

    historyCheck(event) {
        this.histAllowed = event.target.checked;
        this.dispatchCustomevent(this.histAllowed, '');
    }

    dispatchCustomevent = (mode, filter) => {
        const selectedEvent = new CustomEvent('select', { detail: { searchmode: mode, filter: filter } });
        this.dispatchEvent(selectedEvent);
    }
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title, //'ERROR !',
            message: message, //'one of the filter must have a valid value ',
            variant: variant
        });
        this.dispatchEvent(evt);
    }

}