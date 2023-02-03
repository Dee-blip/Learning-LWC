/** @Date		:	June 20 2020
* @Author		: 	Sumukh SS 
* @Description	:	Re-write of Akatec all queue cases in LWC
*/

import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getsidata from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getAllServiceIncidents';
import { SI_COLS } from './sC_Akatec_Homepage_RecentIncidents_Const';

export default class SC_Akatec_Homepage_RecentIncidents extends NavigationMixin(LightningElement) {
    columns = SI_COLS;
    data;
    showSIspinner = true;
    TotalCount = 0;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy = 'outagestartdate';
    displaySI = true;
    ServiceIncidentnow;

    hideOpenSITable() {
        var x = this.template.querySelector(".panelServiceIncidents");
        x.style.height = "0vh";
        this.displaySI = !this.displaySI;
    }

    showOpenSITable() {
        let x = this.template.querySelector(".panelServiceIncidents");
        if (this.TotalCount <= 5)
            x.style.height = "30vh";
        else
            x.style.height = "40vh";
        this.displaySI = !this.displaySI;
    }


    connectedCallback() {
        //Getting data from server
        this.getdata();
    }

    getdata() {
        this.showSIspinner = true;
        getsidata({
        })
            .then(result => {
                this.ServiceIncidentnow=Date.now();
                this.data = result;
                this.TotalCount=result.length;
                this.showSIspinner = false;

                if (this.displaySI) {
                    let x = this.template.querySelector(".panelServiceIncidents");
                    if (this.TotalCount <= 5)
                        x.style.height = "30vh";
                    else
                        x.style.height = "40vh";
                }

            }).catch(error => {
                console.log(JSON.stringify(error));
            });

    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                if (typeof x[field] === 'string') { return primer(x[field].toLowerCase()); }
                else { return primer(x[field]); }
            }
            : function (x) {
                if (typeof x[field] === 'string') { return x[field].toLowerCase(); }
                else { return x[field]; }
            };

        return function (a, b) {

            if (key(a) === null || typeof key(a) === 'undefined') {
                return 1;
            }
            else if (key(b) === null || typeof key(b) === 'undefined') {
                return -1;
            }
            else {
                a = key(a);
                b = key(b);
                return reverse * ((a > b) - (b > a));
            }
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;

        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;

    }

}