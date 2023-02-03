/* 
Created By : Tejaswini
Jira       : ESESP-4953
Purpose    : Component to assciate and remove contacts
Date       : 19-April-2020
*/
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllContactRecs from '@salesforce/apex/SC_LWCAddAuthorizedContactsCtrl.getAllContactRecs';
import addContactRecs from '@salesforce/apex/SC_LWCAddAuthorizedContactsCtrl.addContactRecs';
import getAllAuthContactRecs from '@salesforce/apex/SC_LWCAddAuthorizedContactsCtrl.getAllAuthContactRecs';
import deleteAuthContact from '@salesforce/apex/SC_LWCAddAuthorizedContactsCtrl.deleteAuthContact';

//const DELAY = 300;

const recordsPerPage = [10,25,50];

export default class ScAddAuthorizedContacts extends LightningElement {

    @api notifyViaAlerts = false;
    @api pageSizeOptions = recordsPerPage; 
    @api showTable = false;
    @api recordsperpage;
    @api columns;
    @api recordid;
    @api showModal;
    @api showDeleteModal;

    @track contactSpinner=true;
    @track pageSize=10;
    @track selectedId = [];
    @track SlicedDatalistId=[];
    @track status;

    pageNo;
    @track sortDirection = 'asc';
    @track sortedBy ='contactUrl';
    selectedRows = [];
    contactSearchText = '';
    contactDataCopy = [];
    totalContacts=0;
    offset = 1;
    paginationNumbers;
    SlicedDatalist;
    currentpage;
    totalContacts =0;
    loadSpinner = false;
    records=[];
    fromModal=false;
    
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    connectedCallback() {
        console.log('The record Id is');
        console.log(this.recordid);
        //this.showTable=true;
        console.log(this.showModal);
        console.log(this.showDeleteModal);

        if(this.showModal){
            this.getAllContactRecs();
        }
        
        else if(this.showDeleteModal){
              this.getAllAuthContactRecs();      
        }
        
    }

    getAllContactRecs()
    {
        //const cloneData=[];
        getAllContactRecs({ pdId: this.recordid })
        .then(result => {
            this.records = result;
            this.error = undefined;
            if(this.records.length===0)
            {
                //this.showModal=false;
                if(this.fromModal===true){
                    this.handleClose();
                }
                else{
                this.notifyUser('Warning !', 'No records to display', 'warning','dismissable');
                this.handleClose();
                }
            }
            this.totalContacts=this.records.length;
            this.contactDataCopy=this.records;

            const cloneData = [...this.contactDataCopy];
            cloneData.sort(this.sortBy(this.sortedBy, this.sortDirection === 'asc' ? 1 : -1));
            this.contactDataCopy=cloneData;

            this.calculatepaginationlogic();
            //this.disableEnableActions();
            this.contactSpinner=false;
            
        })
        .catch(error => {
            this.error = error;
            this.records = undefined;
        });

    }

    getAllAuthContactRecs()
    {
        //const cloneData=[];
        getAllAuthContactRecs({ pdId: this.recordid })
        .then(result => {
            this.records = result;
            this.error = undefined;
            if(this.records.length===0)
            {
                //this.showDeleteModal=false;
                if(this.fromModal===true){
                    this.handleClose();
                }
                else{
                this.notifyUser('Warning !', 'No records to display', 'warning','dismissable');
                this.handleClose();
                }
                
            }
            this.totalContacts=this.records.length;
            this.contactDataCopy=this.records;

            const cloneData = [...this.contactDataCopy];
            cloneData.sort(this.sortBy(this.sortedBy, this.sortDirection === 'asc' ? 1 : -1));
            this.contactDataCopy=cloneData;

            this.calculatepaginationlogic();
            this.contactSpinner=false;
        })
        .catch(error => {
            this.error = error;
            this.records = undefined;
        });
    }

    handleClick(event) {
        let label = event.target.label;
        if (label === "First") {
            this.handleFirst();
        } else if (label === "Previous") {
            this.handlePrevious();
        } else if (label === "Next") {
            this.handleNext();
        } else if (label === "Last") {
            this.handleLast();
        }
    }

    handleNext() {
        this.offset += 1;
        this.calculatepaginationlogic();
    }

    handlePrevious() {
        this.offset -= 1;
        this.calculatepaginationlogic();
    }

    handleFirst() {
        this.offset=1;
        this.calculatepaginationlogic();
    }

    handleLast() {
        this.offset=this.paginationNumbers;
        this.calculatepaginationlogic();
    }

    disableEnableActions() {
        let buttons = this.template.querySelectorAll("lightning-button");

        buttons.forEach(bun => {
            /*if (bun.label === this.pageNo) {
                bun.disabled = false;
            } else {
                bun.disabled = true;
            }*/
            /*if (bun.label === this.currentpage) {
                bun.disabled = true;
            }*/

            if (bun.label === "First") {
                bun.disabled = this.offset === 1 ? true : false;
            } else if (bun.label === "Previous") {
                bun.disabled = this.offset === 1 ? true : false;
            } else if (bun.label === "Next") {
                bun.disabled = this.offset === this.paginationNumbers ? true : false;
            } else if (bun.label === "Last") {
                bun.disabled = this.offset === this.paginationNumbers ? true : false;
            }
        });
    }

    handlePage(button) {
        this.pageNo = button.target.label;
        this.calculatepaginationlogic();
    }

    onHandleSort(event) {
             
        const { fieldName: sortedBy, sortDirection } = event.detail;
        //const cloneData = [...this.SlicedDatalist];
        const cloneData = [...this.contactDataCopy];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        
        this.contactDataCopy=cloneData;
        this.totalContacts=this.contactDataCopy.length;
        this.calculatepaginationlogic();

        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    sortBy( field, reverse, primer ) {
        if(field==='contactUrl')
            field='contactName';
        if(field==='accountUrl')
            field='accountName';
        const key = primer
        ? function( x ) {
            return primer(x[field]);
        }
        : function( x ) {
            return x[field];
        };

        return function( a, b ) {
            a = key(a);
            b = key(b);
            return reverse * ( ( a > b ) - ( b > a ) );
        };
    }

    
    handlePaginationClick(event) {
        
         let page = event.target.dataset.item;
         this.offset=page;
         this.SlicedDatalist = this.contactDataCopy.slice((this.offset - 1) * this.pageSize, this.offset * this.pageSize);
         this.currentpage=this.offset+'/'+this.paginationNumbers;

        
        /*window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.disableEnableActions();
        }, DELAY);*/

        this.disableEnableActions();

        const tempArrayId=[];
        this.SlicedDatalist.forEach(row =>{
            tempArrayId.push(row.Id);
        });
        this.SlicedDatalistId=[...tempArrayId];

        console.log('The SlicedDatalistId are'+this.SlicedDatalistId);

        const tempArray=[];
        this.SlicedDatalist.forEach(row => {
            if(this.selectedId.includes(row.Id))
            {
                tempArray.push(row.Id);
            }
        });

        this.selectedRows=[...tempArray];
        
        console.log('The rows are'+this.selectedRows);

     }

    calculatepaginationlogic()
    {
        var i ;
        if(!this.pageSize)
            this.pageSize = this.totalContacts;

        if(this.totalContacts === 0)
        {
            this.paginationNumbers = 1;
        }
        else
        {
            this.paginationNumbers = Math.ceil(this.totalContacts / this.pageSize);
        }
        if(this.offset>this.paginationNumbers) this.offset=1;
        
        this.currentpage=this.offset+'/'+this.paginationNumbers;
        this.paginationRange = [];
        for (i = 1; i <= this.paginationNumbers; i++) {
            this.paginationRange.push(i);
        }
        this.SlicedDatalist = this.contactDataCopy.slice((this.offset - 1) * this.pageSize, this.offset * this.pageSize);

        //this.disableEnableActions();
        /*window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.disableEnableActions();
        }, DELAY);*/

        this.disableEnableActions();

        const tempArrayId=[];
        this.SlicedDatalist.forEach(row =>{
            //this.SlicedDatalistId.push(row.Id);
            tempArrayId.push(row.Id);
        });
        this.SlicedDatalistId=[...tempArrayId];
        console.log('The SlicedDatalistId are'+this.SlicedDatalistId);

        const tempArray=[];
        this.SlicedDatalist.forEach(row => {
            if(this.selectedId.includes(row.Id))
            {
                
                //console.log(row.Id);
                tempArray.push(row.Id);
            }
        });

        this.selectedRows=[...tempArray];
        console.log('The rows are'+this.selectedRows);
    }
     
    contactSelected(){
             
        const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('the selected rows are');
        console.log(selectedRows);
        
        const selectedRowsId=[];

        selectedRows.forEach(row => {
            if(!this.selectedId.includes(row.Id)) {
                    this.selectedId.push(row.Id)
                }
                selectedRowsId.push(row.Id);
            });
        
        const notSelectedRows = this.SlicedDatalistId.filter(x => !selectedRowsId.includes(x));
        console.log('the notSelectedRows array '+ notSelectedRows);

        const finalSelectedIdList= this.selectedId.filter(x => !notSelectedRows.includes(x));
        console.log('the finalSelectedIdList array '+ finalSelectedIdList);

        this.selectedId = finalSelectedIdList;
        console.log('the final array is '+this.selectedId);

        if(this.selectedId.length===50)
        {
            this.notifyUser('Warning !', 'You have reached the maximum selection of 50 records', 'warning','dismissable');
        }
    }

    delayedSearch() 
    {
        clearTimeout(this.timeoutId); // no-op if invalid id
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timeoutId = setTimeout(this.searchContacts.bind(this), 500); // Adjust as necessary
    }

    searchContacts()
    {
        this.sortDirection='asc';
        let allContactData = this.records;
        let searchFilter = this.template.querySelector('.labelHidden').value;
        this.contactSearchText = searchFilter;
        searchFilter = searchFilter.toUpperCase();

        //search the dashboard
        let tempArray = [];
        allContactData.forEach(function(eachRow)
        {
            //console.log(eachRow[i].subject);
            if((eachRow.accountName && eachRow.contactName.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.akamContactId && eachRow.akamContactId.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.title && eachRow.title.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.email && eachRow.email.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.accountName && eachRow.accountName.toUpperCase().indexOf(searchFilter) !== -1)
            
            )
            {
                tempArray.push(eachRow);
            }
        });
        
        this.contactDataCopy = tempArray;
        this.totalContacts = tempArray.length;

        //this.records=tempArray;
        this.totalContacts = this.contactDataCopy.length;

        this.calculatepaginationlogic();

        /*let x = this.template.querySelector(".panelCase");
        if (this.totalCases <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "70vh";*/

        //If Search term is blank then display records in sorted order */
        
        if(searchFilter === '') {
            const cloneData = [...this.records];
            cloneData.sort(this.sortBy(this.sortedBy, this.sortDirection === 'asc' ? 1 : -1));
            //this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1);
        }
    }

    clearSelections(){
        this.template.querySelector('lightning-datatable').selectedRows=[];
        this.selectedId=[];
    }

    addContacts(){
        console.log('The final array to be inserted' + this.selectedId);
        //const tempArray=[];

        if( this.selectedId.length>0){

            this.loadSpinner = true;

            addContactRecs({ pdId: this.recordid , arrContact: this.selectedId })
            .then(result => {
                this.loadSpinner = false;
                this.status=result;
                if(this.status.successCount>0){
                    this.notifyUser('Success !', this.status.successCount+' Authorized contacts added Successfully', 'success','dismissable');
                }
                
                if(this.status.errorMsg.length>0){
                this.notifyUser('Something went wrong : ', this.status.errorMsg + '\n Akam Contact Ids are : \n'+this.status.errorId , 'error','sticky');
                }
                //this.notifyUser('Error !',this.status.errorId,'error','sticky');
                console.log('RESULT message : '+this.status.errorMsg);
                console.log('RESULT ids: '+this.status.errorId);

                //eval("$A.get('e.force:refreshView').fire();");
                //this.notifyUser('Success !', this.selectedId.length+' Authorized contacts added Successfully', 'success','dismissable');
                //this.connectedCallback();
                this.contactSpinner=true;
                this.fromModal = true;
                this.getAllContactRecs();
                
            })
            .catch(error => {
                this.loadSpinner = false;
                console.log('the error message is '+error.body.message);
                this.notifyUser('Error !', error.body.message, 'error','sticky');

            });
        }
        else
            this.notifyUser('Error !', 'Please select atleast one row to add!', 'error','dismissable');
    }

    deleteAuthContacts(){
        console.log('The final array to be inserted' + this.selectedId);
        
        if( this.selectedId.length>0){
        this.loadSpinner = true;
        
        deleteAuthContact({arrAuthContact:this.selectedId})
        .then(result => {
            this.loadSpinner = false;
            this.status=result;
                if(this.status.successCount>0){
                    this.notifyUser('Success !', this.status.successCount+' Authorized contacts deleted Successfully', 'success','dismissable');
                }
                
                if(this.status.errorMsg.length>0){
                this.notifyUser('Something went wrong : ', this.status.errorMsg + '\n Akam Contact Ids are : \n'+this.status.errorId , 'error','sticky');
                }
                //this.notifyUser('Error !',this.status.errorId,'error','sticky');
                console.log('RESULT message : '+this.status.errorMsg);
                console.log('RESULT ids: '+this.status.errorId);

            //eval("$A.get('e.force:refreshView').fire();");
            
            //this.connectedCallback();
            this.contactSpinner=true;
            this.fromModal=true;
            this.getAllAuthContactRecs();
            
        })
        .catch(error => {
            this.loadSpinner = false;
            console.log('the error message is '+error.body.message);
            this.notifyUser('Error !', error.body.message, 'error','sticky');
            
        });
        
        }
        else
            this.notifyUser('Error !', 'Please select atleast one row to delete!', 'error','dismissable');
    }

    
    handleRecordsPerPage(event){
        this.pageSize = event.target.value;
        this.calculatepaginationlogic();
        
    }

    notifyUser(title, message, variant,mode) {
        /*if (this.notifyViaAlerts) {
            // Notify via alert
            alert(`${title}\n${message}`);
        } else {*/
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant,mode });
            this.dispatchEvent(toastEvent);
        
    }

}