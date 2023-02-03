import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMapOfData from '@salesforce/apex/ChimeTriggerClass.getAssignedChimeForm';
export default class L2q_ChimeFormList extends NavigationMixin(LightningElement) {
    isloading = false;
    @track chimeWithProducts = [];
    @track showChimeList = false;

    connectedCallback() {
        this.isloading = true;
    }

    @wire(getMapOfData)
    mapOfData({ data, error }) {
        if (data) {
            for (let key in data) {
                //if (data.hasOwnProperty(key)) {
                    this.chimeWithProducts.push({ value: data[key], key: key });
                //}
            }
            if (this.chimeWithProducts.length > 0) {
                this.showChimeList = true;
            }
        }
        else if (error) {
            window.console.log(error);
        }
    }

    navigateToChimeDetails(event) {
        let cId = event.target.id;
        cId = cId.split('-')[0];
        let selectedChimeName = '';
        this.chimeWithProducts.forEach(el => {
            if (el.key === cId) {
                selectedChimeName = el.value;
            }
        })
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: {
                name: "ChimeCustomerForm__c"
            },
            state: {
                c__chimeId: cId,
                c__chimeName: selectedChimeName
            }
        });
    }
}