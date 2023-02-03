import { api, LightningElement, track, wire } from 'lwc'; 
import fetchRecs from '@salesforce/apex/ChimeTriggerClass.fetchChimeContacts';  
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import {refreshApex} from '@salesforce/apex';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class L2Q_chimeContactListComponentample extends NavigationMixin( LightningElement ) {  
 
    @track listRecs;  
    @track initialListRecs;
    @track error;  
    @track columns;  
    @api parentId;
    @api accountId;
    @api relatedObject;
    @api fields;
    @api relatedField;
    @api tableColumns;
    @api title;
    sortedBy;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    wiredList;

    connectedCallback() {

        console.log( 'Columns are ' + this.tableColumns );

        this.tableColumns = "[{label:'Name',fieldName: 'Name__c', sortable:true},{ label:'Email',fieldName:'Email__c'},{label:'Phone',fieldName:'Contact_Phone__c' },{label:'Chime Access', fieldName:'Chime_access__c', type: 'boolean'},{type:'action',typeAttributes:{rowActions:[{label:'View/Edit',name:'edit'},{label:'Remove',name:'delete'}]}}]"
        this.columns = JSON.parse( this.tableColumns.replace( /([a-zA-Z0-9]+?):/g, '"$1":' ).replace( /'/g, '"' ) );
        console.log( 'Columns are ' + this.columns );


        this.fields = "Name__c, Email__c, Chime_access__c,Contact_Phone__c";
        this.title = "CHIME Contacts";
        this.relatedObject = "CHIME_Contact__c";
        this.relatedField = "CHIME__c";
        

    }
    renderedCallback() {
        if(this.wiredList){
            return refreshApex(this.wiredList);
        }
        else{
            return false;
        }
    }

    get vals() {  

        return this.relatedObject + '-' + this.fields + '-' +   
               this.relatedField + '-' + this.parentId;  

    }

    @wire(fetchRecs, { listValues: '$vals' })  
    wiredRecs(  result  ) {
        this.wiredList = result;
        if ( result.data ) {

            console.log( 'Records are ' + JSON.stringify( result.data ) );
            this.listRecs = result.data;
            this.initialListRecs = result.data;

        } else if ( result.error ) {
            console.log("Error getting contacts");
            console.log(result.error);
            this.listRecs = null;
            this.initialListRecs = null;
            this.error = result.error;

        }
        
    }

    handleKeyChange( event ) {  
          
        const searchKey = event.target.value.toLowerCase();  
        console.log( 'Search Key is ' + searchKey );
 
        if ( searchKey ) {  

            this.listRecs = this.initialListRecs;
 
             if ( this.listRecs ) {

                let recs = [];
                for ( let rec of this.listRecs ) {

                    console.log( 'Rec is ' + JSON.stringify( rec ) );
                    let valuesArray = Object.values( rec );
                    console.log( 'valuesArray is ' + valuesArray );
 
                    for ( let val of valuesArray ) {
                        
                        if ( val.toLowerCase().includes( searchKey ) ) {

                            recs.push( rec );
                            break;
                        
                        }

                    }
                    
                }

                console.log( 'Recs are ' + JSON.stringify( recs ) );
                this.listRecs = recs;

             }
 
        }  else {

            this.listRecs = this.initialListRecs;

        }
 
    }  

    onHandleSort( event ) {

        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.listRecs];
        cloneData.sort( this.sortBy( sortedBy, sortDirection === 'asc' ? 1 : -1 ) );
        this.listRecs = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;

    }

    sortBy( field, reverse, primer ) {

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

    handleRowAction( event ) {
        
        
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        switch ( actionName ) {
            case 'edit':
            this.dispatchEvent(new CustomEvent("closecontacts"));
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: this.relatedObject,
                        actionName: 'edit'
                    }
                });
                break;
            case 'delete':
                if(window.confirm("Are you sure you want to remove this Chime Contact?")){
                    this.deleteContactAssociation(row.Id);
                }
                break;                      
            default:
        }

    }

    createNewExisting() {
        const defaultValues = encodeDefaultFieldValues({
            CHIME__c: this.parentId
        });
        console.log(defaultValues);
        this[NavigationMixin.Navigate]({            
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.relatedObject,
                actionName: 'new'                
            },
            state: {
                defaultFieldValues: defaultValues
            }
        });


    }
    createNew() {
        var contextObject = {};
        contextObject.attributes = {};
        contextObject.attributes.recordId = this.accountId;
        contextObject.attributes.returnURL = '/lightning/o/CHIME_Contact__c/new?defaultFieldValues='+encodeURIComponent("CHIME__c="+this.parentId+",Contact__c=newcontactid")+'&backgroundContext='+encodeURIComponent('/lightning/r/CHIME__c/'+this.parentId+'/view');
       
        
       
        let encodeContextObject = btoa(JSON.stringify(contextObject));
        

       this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: '/lightning/o/Contact/new?useRecordTypeCheck=true&inContextOfRef=1.'+encodeContextObject
            
        }


    });
    }
    deleteContactAssociation(recordId) {
        // Pass the record id to deleteRecord method
        deleteRecord(recordId)
            .then(() => {
                console.log('Deleted');
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'CHIME Contact has been removed',
                    variant: 'success'
                });
                this.dispatchEvent(event);
                this.dispatchEvent(new CustomEvent("closecontacts"));
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }


    handleClose(){
        this.dispatchEvent(new CustomEvent('close'));
    }
 
}