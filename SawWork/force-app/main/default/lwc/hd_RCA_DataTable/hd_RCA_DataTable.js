import { LightningElement, wire } from 'lwc';
import getDataTableValues from '@salesforce/apex/HD_lwcUtilityClass.getDataTableValues';

export default class DataTable extends LightningElement {

    @wire(getDataTableValues) 
    lineItems;
 
}