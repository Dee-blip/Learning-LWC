import { LightningElement, wire, track , api } from 'lwc';
import getContractWithDetails from '@salesforce/apex/PSA_ProjectContractSelectController.getContractWithDetails';
import getMorehDetails from '@salesforce/apex/PSA_ProjectContractSelectController.getMoreDetails';
import saveProject from '@salesforce/apex/PSA_ProjectContractSelectController.saveProject';
import getSelectedCli from '@salesforce/apex/PSA_ProjectContractSelectController.getSelectedCli';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getRecord } from 'lightning/uiRecordApi';


export default class psaProjectContractSelect extends NavigationMixin(LightningElement) {
    offset = 0;
    loading = false;
    contractId ;
    prodFilter = '' ;
    dateValue = 'Active';
    contractIndex = 0 ;
    detailIndex = 0 ;
    spinner = true;
    detailLoading = false;
    counter = 0;

    @track contractWithDetails = null;
    @track error;
    @track selected = '';
    @track initialId = '';
    @api recId;

    //projId = $recId ;

    @wire(getContractWithDetails, { projectId: '$recId' , offset: 0 , productFilter : 'class-none' , dateFilter: 'Active' } )
    wiredContractWithDetails({ error, data}) {
        this.contractWithDetails = null;
        if(data) {
            this.contractWithDetails = data;

            this.spinner = false;

            if(data.length < 30 )
            {
                //this.loading = true;
            }

            while( this.contractWithDetails.length < 30 && this.counter < 10)
            {
                this.offset = this.offset + 30;
                this.counter ++;
                getContractWithDetails({  projectId: this.recId, offset: this.offset , productFilter : 'class-none' , dateFilter: 'Active' })
                .then(result => {

                    // When data is intially assigned to this. contractWithDetails it will be set to read only mode ,
                    // hence cloning it and reassigning to remove the read only restriction and append new result to the lIst
                    this.contractWithDetails = Object.assign([], this.contractWithDetails );

                    this.contractWithDetails = this.contractWithDetails.concat(result);
                    
                    this.loading = false;

                    // set loading to true so stop making apex class if the result returned by apex is 0
                    if(result.length < 1)
                    {
                        this.loading = true;
                    }

                })
                .catch(error => {
                    console.log( ' error ?? :' ,error);
                    this.loading = false;
                });
                
            }

            // Get the CLI previously selected CLI Id and store to be used to uncheck the checkbox when an new CLI is selected
            getSelectedCli({projId : this.recId})
            .then(result => {
                this.selected = result;

                this.initialId = result;
            })
            .catch(error => {
                console.log(' get selected id error :' , error )
            });

        } else if(error) {
            console.log(error);
            this.error = error;
        }
    }
    

    value = 'Active';

    get options() {
        return [
            { label: 'Active', value: 'Active' },
            { label: 'Expired Contracts (Upto 90 Days)', value: 'Expired' },
            { label: 'Expired Contracts (90 Days to 1 year)', value: 'Expired More than 90 Days' },
        ];
    }

    hidefunc(event)
    {

        // Depending on the current label + or - , set the style of table row using contract key to display none or display block
        if(event.target.label === '+' )
        {
            event.target.label = '-';
            var contractKey = event.target.name;

            let element = this.template.querySelector("[data-key="+ contractKey +"]");
            element.style = "display:";


        } else if (event.target.label === '-')
        {
            var contractKey = event.target.name;
            console.log('name ::' , event.target.name);

            let element = this.template.querySelector("[data-key="+ contractKey +"]");
            element.style = "display:none";
            event.target.label = '+';
        }

    }

    expandAll()
    {
        // Get all the contract detail rows using the class name "detailRow" and 
        //set style to display block and change label to - if it is not already

        let detailElement = this.template.querySelectorAll(".detailRow");

        for( var i = 0 ; i <  detailElement.length ; i++ ) 
        {
            //console.log(' style of detail ele : ' , detailElement[i].style  );
            detailElement[i].style = "display:table-row";
        }
       
        let element1 = this.template.querySelectorAll("lightning-button");
        for(var i=0 ; i < element1.length ; i ++ )
        {
            if( element1[i].label == '+' )
            {
                element1[i].label = '-';
            }
        }
    }

    collapseAll()
    {        
        // Get all the contract detail rows using the class name "detailRow" and 
        //set style to display none and change label to + if it is not already

        let detailElement = this.template.querySelectorAll(".detailRow");
        for( var i = 0 ; i <  detailElement.length ; i++ ) 
        {
            //console.log(' style of detail ele : ' , detailElement[i].style  );
            detailElement[i].style = "display:none";
        }
        
        let element1 = this.template.querySelectorAll("lightning-button");
        for(var i=0 ; i < element1.length ; i ++ )
        {
            
            if( element1[i].label == '-' )
            {
                element1[i].label = '+';
            }
        }
    }

    filter(event)
    {
        var prodFilter1 = this.template.querySelector("[data-key=\"filterProduct\"]").value.trim() ;
        var dateValue1 = this.template.querySelector("[data-key=\"filterDate\"]").value;

        this.prodFilter = prodFilter1 ;
        this.dateValue = dateValue1;

        this.spinner = true;
        this.offset = 0;

        this.contractWithDetails = null;

        this.contractId = null ;
        this.contractIndex = 0 ;
        this.detailIndex = 0 ;
        

        // Get the value of the product name or date value to be filtered and make an apex call 

        getContractWithDetails({ projectId: this.recId, offset: 0 , productFilter: prodFilter1 , dateFilter: dateValue1 })
        .then(result => {
            this.contractWithDetails = result;

            console.log(' result  :' , result );

            while( this.contractWithDetails.length < 10 && this.offset < 100 )
            {
                this.offset = this.offset + 30;
                getContractWithDetails({  projectId: this.recId, offset: this.offset , productFilter : prodFilter1 , dateFilter: dateValue1 })
                .then(result => {

                    // When data is intially assigned to this. contractWithDetails it will be set to read only mode ,
                    // hence cloning it and reassigning to remove the read only restriction and append new result to the lIst
                    this.contractWithDetails = Object.assign([], this.contractWithDetails );

                    this.contractWithDetails = this.contractWithDetails.concat(result);
                    
                    this.loading = false;

                    // set loading to true so stop making apex class if the result returned by apex is 0
                    if(result.length < 1)
                    {
                        this.loading = true;
                    }

                })
                .catch(error => {
                    console.log( ' error ?? :' ,error);
                    this.loading = false;
                });
                
            }

            this.spinner = false; // Hiding the spinner by setting the value to false once the apex results are processsed
            this.loading = false;

            getSelectedCli({projId : this.recId})
            .then(result => {
                this.selected = result;

            })
            .catch(error => {
                console.log(' get selected id error :' , error )
            });
        })
        .catch(error => {
            console.log(error);
            this.spinner = false; // set the spinner to false even when the result has errored
        });
    }

    clear()
    {

        // Change the value of the filter to default value and make an apex call with default filter values to retrive fresh results
        this.prodFilter = '';
        this.dateValue = 'Active';
        this.offset = 0;

        this.template.querySelector("[data-key=\"filterProduct\"]").value = '' ;
        this.template.querySelector("[data-key=\"filterDate\"]").value = 'Active';

        this.spinner = true;
        this.contractWithDetails = null;
        this.contractId = null ;
        this.contractIndex = 0 ;
        this.detailIndex = 0 ;

        
        getContractWithDetails({ projectId: this.recId, offset: 0 , productFilter: 'class-none' , dateFilter: 'Active' })
        .then(result => {
            this.contractWithDetails = result;

            while( this.contractWithDetails.length < 10 && this.offset < 100 )
            {
                this.offset = this.offset + 30;
                getContractWithDetails({  projectId: this.recId, offset: this.offset , productFilter : 'class-none' , dateFilter: 'Active' })
                .then(result => {

                    // When data is intially assigned to this. contractWithDetails it will be set to read only mode ,
                    // hence cloning it and reassigning to remove the read only restriction and append new result to the lIst
                    this.contractWithDetails = Object.assign([], this.contractWithDetails );

                    this.contractWithDetails = this.contractWithDetails.concat(result);
                    
                    this.loading = false;

                    // set loading to true so stop making apex class if the result returned by apex is 0
                    if(result.length < 1)
                    {
                        this.loading = true;
                    }

                })
                .catch(error => {
                    console.log( ' error ?? :' ,error);
                    this.loading = false;
                });
                
            }


            this.spinner = false;
            this.loading = false;

            getSelectedCli({projId : this.recId})
            .then(result => {
                this.selected = result;
                console.log(' selected : ' , this.selected );
            })
            .catch(error => {
                console.log(' get selected id error :' , error )
            });
        })
        .catch(error => {
            console.log(error);
            this.spinner = false;
        });

    }

    saveProject(event)
    {

        // On click of save check if the newly selected cli is same the previously selected cli and show error message
        // and return if they are same
        if(this.initialId === this.selected )
        {
            this.template.querySelector('c-psa-custom-toast').showToast('info', 'No Change in CLI, Closing the select Page');
            clearTimeout(this.timeoutId);
            this.timeoutId = setTimeout(this.closePopUps.bind(this), 2000);
            return;
        }

        this.timeoutId = setTimeout(this.closePopUps.bind(this), 10000);
        //this.template.querySelector('c-psa-custom-toast').autoCloseTime = 10000 ; 
        //this.template.querySelector('c-psa-custom-toast').showToast('info', 'Saving the PCLI !');

        this.spinner = true;
        
        

        saveProject({ detailIdstr: this.selected , contractIdstr: this.contractId  , projIdstr: this.recId })
        .then(result => {
            
            // call a custom LWC component to show toast message
            this.template.querySelector('c-psa-custom-toast').showToast('success', 'The Project Contract Line Item has been Saved!');
            
            clearTimeout(this.timeoutId); // clears the timeout if it has been set already
            this.timeoutId = setTimeout(this.closePopUps.bind(this), 2000); // adds a delay of 2 sec before method closepopups is called
            this.spinner = false;
        })
        .catch(error => {
            console.log(' error ' , error );
            this.template.querySelector('c-psa-custom-toast').autoCloseTime = 2000 ; 

            this.template.querySelector('c-psa-custom-toast').showToast('error', 'The PCLI was not Saved!');

            clearTimeout(this.timeoutId);
            this.timeoutId = setTimeout(this.closePopUps.bind(this), 2000);
            this.spinner = false;
        })
        
    }

    closePopUps(){
        // Fire a custom event which is handled by the host aura component Project Contract Select Button to close the PCLi popup
        const closeQA = new CustomEvent('close'); 
        this.dispatchEvent(closeQA);

        let selectedRow = this.contractWithDetails[this.contractIndex].childObjects[this.detailIndex].contractDetail ;

        const payload = this.selected;
        // Fire a custom event with selected id , contract id and Product name which is handled by the host aura component and VF page to
        // pass value from LWC -> Aura -> VF
        const closeQA1 = new CustomEvent("parentclose" , {
            detail: { val1: payload  , val2: selectedRow.Product__c , val3: selectedRow.Name  },
            
        } );
        this.dispatchEvent(closeQA1);

    }

    handleScroll(event){
        let area = this.template.querySelector('.scrollArea');
        let area1 = this.template.querySelector('.scrollContainer');
        let threshold = 2 * event.target.clientHeight;
        let areaHeight = area.clientHeight;
        let scrollTop = event.target.scrollTop;
        //let loading = false;

        var prodFilter1 = this.template.querySelector("[data-key=\"filterProduct\"]").value.trim() ;
        var dateValue1 = this.template.querySelector("[data-key=\"filterDate\"]").value;

        if(this.offset == undefined)
        {
            this.offset = 0;
        }

        // 460 is the height of the scroll container div , below statement check if the scrollbar has reached to 
        //the (bottom - 400) height to make an apex class and retrive next set of records

        console.log(' scroll vals : ' ,  ( (scrollTop + 460) > Math.trunc(event.target.scrollHeight - 400) && (!this.loading) ) );

        console.log('vals : ' , (scrollTop + 460) > Math.trunc(event.target.scrollHeight - 400) , ' this.loading -- ' , this.loading );


        if( (scrollTop + 460) > Math.trunc(event.target.scrollHeight - 400) && (!this.loading) )
        {
            this.loading = true ;
            let headerLoader = this.template.querySelector('.headerLoader');
            headerLoader.style = "display:table-row"; // setting the style display row to show the spinner at the botton of the table

            this.offset = this.offset + 30;
            

            getContractWithDetails({  projectId: this.recId, offset: this.offset , productFilter : prodFilter1 , dateFilter: dateValue1 })
            .then(result => {

                // When data is intially assigned to this. contractWithDetails it will be set to read only mode ,
                // hence cloning it and reassigning to remove the read only restriction and append new result to the lIst
                this.contractWithDetails = Object.assign([], this.contractWithDetails );

                this.contractWithDetails = this.contractWithDetails.concat(result);
                
                // for(let index = 0 ; index < result.length ; index++ )
                // {
                //     this.contractWithDetails.push(result[index]);
                //     //console.log(' contact leng ', this.contractWithDetails.length );
                // }
                headerLoader.style = "display:none";
                this.loading = false;
                getSelectedCli({projId : this.recId})
                .then(result => {
                    this.selected = result;
                })
                .catch(error => {
                    console.log(' get selected id error :' , error )
                });

                // set loading to true so stop making apex class if the result returned by apex is 0
                if(result.length < 1)
                {
                    this.loading = true;
                }

                //this.contractWithDetails = result[0];
                //this.contractWithDetails = result;
            })
            .catch(error => {
                console.log( ' error ?? :' ,error);
                headerLoader.style = "display:none";
                this.loading = false;
            });
            
        }
        
    }

    handleDetailScroll(event)
    {

        let rowNum =  event.target.id.split('-')[0] ;
        let detailScrollArea = this.template.querySelectorAll('.detailScrollArea')[rowNum];
                
        let detailareaHeight = detailScrollArea.clientHeight;
        let detailScrollTop = event.target.scrollTop;
        let detailscrollBottom = (detailareaHeight * 20 ) / 100 ;

        console.log( ' detailScrollTop :' , detailScrollTop , ' detailareaHeight :' , detailareaHeight  , ' detailscrollBottom : '  , detailscrollBottom );

        console.log( ' detail off set  ' , this.contractWithDetails[rowNum].offset );


        // check if the contract detail scroll bar has reached to the bottom and make an apex call
        if( detailScrollTop > Math.trunc(detailscrollBottom) && !this.detailLoading )
        {
            var prodFilter1 = this.template.querySelector("[data-key=\"filterProduct\"]").value.trim() ;
            var dateValue1 = this.template.querySelector("[data-key=\"filterDate\"]").value;

            this.contractWithDetails = Object.assign([], this.contractWithDetails );
            this.contractWithDetails[rowNum] = Object.assign([], this.contractWithDetails[rowNum]);
            this.detailLoading = true;

            // Make an apex call with detail offset value in the wrapper to fetch the next set of detail records for that particular header row
            getMorehDetails({ productName: this.contractWithDetails[rowNum].obj.Id , detailOffset: this.contractWithDetails[rowNum].offset , productFilter : prodFilter1 , selectedId: this.selected , dateFilter: dateValue1 })
            .then(result => {

                console.log( ' redaitl scroll result : ' , result );

                if(result !== null)
                {
                    // since the this.contract with details variable is read only mode , clone it and reassign to remove the read only restriction
                    let tempContracts = Object.assign([], this.contractWithDetails );
                    let childObjects = tempContracts[rowNum].childObjects;
                    childObjects = Object.assign([], childObjects);                
                    let eachContract = tempContracts[rowNum];

                    eachContract = Object.assign([], eachContract);
                    eachContract.childObjects = Object.assign([], eachContract.childObjects );
                    // once the read nly restriciton is removed contact the result with previosly present child records
                    eachContract.childObjects = eachContract.childObjects.concat(result);

                    // for(let index = 0 ; index < result.length ; index++ )
                    // {
                    //     eachContract.childObjects.push(result[index]);   
                    // }
                    this.contractWithDetails[rowNum] = eachContract;

                    if( this.contractWithDetails[rowNum].offset > 2000 )
                    { this.contractWithDetails[rowNum].offset = 50001; }
                    else { this.contractWithDetails[rowNum].offset = this.contractWithDetails[rowNum].offset + 15; }
                    
                }
                this.detailLoading = false;

            } )
            .catch(error => {
                console.log(error);
                this.detailLoading = false;
            });

        }

    }

    uncheckothers(event)
    {
        var index ;        
        this.contractId = event.target.dataset.item;
        this.contractIndex = event.target.id.split('-')[0] ;
        this.detailIndex = event.target.dataset.id ;

        // get the priviously selected contract detail and set the checked option to false 
        let prevelement;
        if(this.selected != '' )
        {
            prevelement = this.template.querySelector("[data-key="+ this.selected +"]");
        }

        if(prevelement != null)
        {
            prevelement.checked = false;
        }

        this.selected = event.target.name; // set the current selected id to be passed to apex class
        event.target.checked = true;
        
    }

    closeQuickAction() {
        console.log(' this selcted ?? ' , this.selected);
        
        const closeQA1 = new CustomEvent('close');
        this.dispatchEvent(closeQA1);

        const payload = this.selected;
        const closeQA = new CustomEvent("parentclose" , {
            detail: { val1: ''  , val2: '' , val3: ''  }
        } );

        try
        {
            this.dispatchEvent(closeQA);
        } catch (e)
        {
            console.log(' e msg ' , e.message , ' e name ', e.name, ' ::e. tsack : ' , e.stack );
        }
        console.log( 'dis pac ev ' , this.dispatchEvent(closeQA) );
        
    }

}