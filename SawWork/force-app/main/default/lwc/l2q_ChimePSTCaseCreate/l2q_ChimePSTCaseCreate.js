import { LightningElement,wire,track,api } from 'lwc';
//import getPSTData from '@salesforce/apex/chimePSTClass.getChimePSTData';
import chimeDetails from '@salesforce/apex/chimePSTClass.getChimeDetails';
import chimeProdDetails from '@salesforce/apex/chimePSTClass.getChimeProdDetails';
import createChimeCase from '@salesforce/apex/chimePSTClass.createChimeCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import chimeDetails from '@salesforce/apex/ChimeTriggerClass.getChimeDetails';
import ID_FIELD from '@salesforce/schema/CHIME__c.Id';



//Added by Ashin
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
//Added by Ashin

//Added by Manish
import CaseCreationFlagCheck from '@salesforce/apex/ChimeTriggerClass.CaseCreationFlagCheck';

export default class L2q_ChimePSTCaseCreate extends LightningElement {

    @api recordId;
    @api chimeId;
    @track chimedata;
    @track showError = true;
    @track productList;
    @track submitdisable =  false;
    @track chimeProdnames ;
    @track warningshown = false;
    @track showWarning = false;

    // Below Added by Ashin with regards to select products while creating PST cases
    @track productMasterList=[];
    @track selectedPrds;
    @track finalPrdList=[];
    @track errorStr ='';
    @track picklistValues =[];
    @track comparePickListValues=[];
    @track showSpinner=false;   
    @track pstCaseRecordTypeId;
    @track chimeProdDSRMapData;
    @track showDSRError=false;
    @track cancelJustificationError=true;
    //@track isDisabled= false;
    // Above Added by Ashin with regards to select products while creating PST cases
    
    //Added by Manish
    firstrunflag = true;

    connectedCallback() {
        this.loadChimeDetails();
       
        //this.loadProdData();

    }

    loadChimeDetails() {
        console.log('inside : ', this.chimeId);
        chimeDetails({ chimeId: this.chimeId })
            .then(result => {
                console.log(' wher ar1' , result);
                this.chimedata = JSON.parse(JSON.stringify(result));

                console.log(' each val ' , this.chimedata );
                
                if(this.chimedata.Is_All_Qun_Ans_Complete__c === true && this.chimedata.Stage__c !== 'Integration' && this.chimedata.Stage__c !== 'Closed' )
                {
                    this.showError = false;
                    //console.log(' not error : ' , );
                    if(this.firstrunflag){
                        this.loadProdData();
                    }
                } else {
                    this.showError = true;
                    //console.log('error rr :');
                }
                if(this.firstrunflag){
                    this.calculateChimeFlag();
                }

            })
            .catch(error => {
                console.log(' in ser :' , error);
                this.error = error;
                this.isloading = false;
            });
            
    }

    calculateChimeFlag(){
        this.firstrunflag = false;
        let ispoc = false;
        if (this.chimedata.Is_POC_Demo__c && this.chimedata.POC_Type__c == 'Standard-POC') {
            ispoc = true;
        } else {
            ispoc = false;
        }
        CaseCreationFlagCheck({chimeId : this.chimeId,currentStage : this.chimedata.Stage__c,isPOC : ispoc})
        .then(result=>{
            console.log('CaseCreationFlagCheck',CaseCreationFlagCheck);
            this.loadChimeDetails();
            
            
        })
        .catch(error =>{
            console.log('error',error);
        })


    }
       
   


   //Below Added by Ashin, to fetch the recordtypeID of 'PST' record type from case object dynamically
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    getObjectData({data,error}){
       if(data){
          let recordtypeinfo = data.recordTypeInfos;
         
         for(var eachRecordtype in recordtypeinfo)
         {
             if(recordtypeinfo[eachRecordtype].name==='PST')
             {
                 this.pstCaseRecordTypeId=recordtypeinfo[eachRecordtype].recordTypeId;
                 break;   
             }
         }
         console.log('>>>>> PST_Case recordType ID is', this.pstCaseRecordTypeId);
       }else if(error){
           this.error=error;
        }
     };
     //Above Added by Ashin, to fetch the recordtypeID of 'PST' record type from case object dynamically


    //Below Added by Ashin to fetch picjkist values of cases 
        @wire(getPicklistValuesByRecordType, {
        recordTypeId : '$pstCaseRecordTypeId',
        objectApiName : CASE_OBJECT
    })
        wiredRecordtypeValues({data, error}){
            if(data){
                this.picklistValues = data.picklistFieldValues.PST_Case_Product__c.values;
                for(var i =0 ; i<this.picklistValues.length ; i++)
                 {
                     this.comparePickListValues.push(this.picklistValues[i].label.toLowerCase());
                     //this.comparePickListValues.push(this.picklistValues[i].label);
                 }
            }
            if(error){
                console.log(error);
            }
        }
        //Above Added by Ashin to fetch picjkist values of cases 

    loadProdData()
    {
        chimeProdDetails({chimeRecordId:this.chimeId})
             .then(result =>{
                 var i=0;
                 var returnResult = JSON.parse(result);
                 console.log(' wher to : ' , returnResult );
                 this.productList = returnResult.productList;
                 this.chimeProdnames = returnResult.chimeProducts;

                 /* Below added by Ashin :- To store the fetched "this.productList" into "this.productMasterList" along with {product & isChecked =false}. 
                    So that we can identify the final list of products that are selected & that needs to be passed to create PST cases*/
                 for(var i =0 ; i<this.productList.length ; i++)
                 {
                    this.productMasterList.push({ product:this.productList[i], isChecked:false, isDisabled:false, isDisabledforDSR: false, isDisabledforPSTnDSR:false , eitherDisabled : false });
                 }
                 console.log('>>> Initial Loaded Product Master List is >>>', JSON.stringify(this.productMasterList));
                 //Above added by Ashin to fetch the selected list

                 //Below added by Ashin to check if loaded products exist in the case picklist
                    for(var i=0; i<this.productMasterList.length; i++)
                    {
                            var productToCompare = this.productMasterList[i].product.pstProdName;
                            console.log(' each roow : ' , this.productMasterList[i] );
                            //var productToCompare = this.productMasterList[i].product.dealsupport.Product__c;
                            if( !this.comparePickListValues.includes(productToCompare) || this.productMasterList[i].product.justificationStr === 'DSR is not yet associated with this product')
                            {
                                console.log(' int erorors :: ' , this.comparePickListValues );
                                if( !this.comparePickListValues.includes(productToCompare) )
                                {
                                    console.log(' each prod name : ' , this.productMasterList[i].product.prodName );
                                    this.productMasterList[i].isDisabled=true;
                                }
                                if( this.productMasterList[i].product.justificationStr === 'DSR is not yet associated with this product' )
                                {
                                    this.productMasterList[i].isDisabledforDSR=true;
                                }
                                if( this.productMasterList[i].product.justificationStr === 'DSR is not yet associated with this product' && !this.comparePickListValues.includes(productToCompare) )
                                {
                                    console.log(' each prod name both: ' , this.productMasterList[i].product.prodName );
                                    this.productMasterList[i].isDisabledforPSTnDSR=true;
                                }
                                this.productMasterList[i].eitherDisabled = true;

                            }   
                               
                   }
                   console.log(' final master list leng :  ' , this.productMasterList.length );
                   console.log('final master list ',JSON.stringify(this.productMasterList) );
                 //Above added by Ashin to check if loaded products exist in the case picklist
                
                }).catch(error => {
                  console.log('error** :'+error);
                }); 
    }

    handleSubmit()
    {
        this.showSpinner =true;
        console.log('error string ---------',this.errorStr);
        this.submitdisable = true;
        //let dsrJustification = []; commented by Ashin
        let dsrJustification1=[];
        console.log(' hand submit' , this.template);
        let values = this.template.querySelectorAll("[data-key=justification]");
        console.log('all ' , this.template);
        let notes = this.template.querySelectorAll("[data-key=casenotes]")[0];
        console.log(' nots : ' , notes);
        //var errorStr = '';

        //>>>>> Below code added by Ashin >>>>>>>
        var productIsEmpty = '';
        let selectedRows = this.template.querySelectorAll("[data-key=SelectedPrds]"); //Fetching all the checkboxes
        for(var i = 0; i < selectedRows.length; i++)
        {
            if(selectedRows[i].checked && selectedRows[i].type === 'checkbox' && this.productMasterList[i].product.justificationStr==='DSR is not yet associated with this product')
            {
                this.showDSRError=true;
                this.showSpinner=false;
                this.cancelJustificationError=false;
                this.showToast('One or more products which you have selected, does not have a DSR associated. Please associate the DSR for the products which you have selected','Error','dismissable');
                this.submitdisable = false;
                
            }
        }

        for(var i = 0; i < selectedRows.length; i++) 
        {
            //since productMasterList.length and selectedRows.length will always be same, Copying selectedRows.checked(if true) into productMasterList.isChecked as true
            if(selectedRows[i].checked && selectedRows[i].type === 'checkbox' && this.productMasterList[i].isChecked===false)  
            {
                this.productMasterList[i].isChecked=true;
                
            }
            if(!selectedRows[i].checked && selectedRows[i].type === 'checkbox' && this.productMasterList[i].isChecked===true) //else revert it back to false
            {
                this.productMasterList[i].isChecked=false;
            }
        }
        console.log('>>>> Final product Master list >>>>',JSON.stringify(this.productMasterList) );
        for(var i = 0; i < this.productMasterList.length; i++) 
        {
            //Storing only the selected products inside "this.finalPrdList" -- this list will be sent to Apex to create PST cases
            if(this.productMasterList[i].isChecked===true)
            {
               this.finalPrdList.push(this.productMasterList[i].product);
            }
            //If incase the product is selected and no justification value is given and if user hits submit -- need to show error
            if (this.productMasterList[i].isChecked===true && this.productMasterList[i].product.justificationNeeded === false && (values[i].value === '' || values[i].value === null ) && this.productMasterList[i].product.prodName === values[i].name)
            {
                this.errorStr = 'Justification required';
                this.submitdisable = false;
            }  
        }
        console.log('>>>>> Final list that has the selected product >>>>>', JSON.stringify(this.finalPrdList)); 
        //Here we are loopiong through the final product list "this.finalPrdList" which we selected and comparing this.finalPrdList.dealsupport.Id with the text-input field's name (because both are same)
        //We are looping and checking, so that we can send the justification texts of only the final selected products "this.finalPrdList" into the Apex
        for (var i=0; i<this.finalPrdList.length;i++)
        {
            for(var j=0; j<values.length;j++)
            {
                if(this.finalPrdList[i].prodName === values[j].name )
                {
                    dsrJustification1.push(values[j].value);
                }
            }
        }
        console.log('>>>> Final justification List is >>>>',dsrJustification1);
        // <<<<<<< Above code added by Ashin >>>>>>>


        //below code added by Ashin : If user doesnt select any product and hits SUBMIT, need to show error
        if(this.finalPrdList.length===0)
        {
            productIsEmpty = 'No products added';
        }
        if(productIsEmpty!=='')
        {
            this.showToast('Please choose atleast one product before you click on "SUBMIT"','Error','dismissable');
            this.submitdisable = false;
        }
        //above code added by Ashin : If user doesnt select any product and hits SUBMIT, need to show error
        
        if(this.errorStr !== '' && this.cancelJustificationError==true)
        {
            console.log('teas ?');
            this.showToast('Inorder to continue to create PST Case :- Please enter justification for products which you have choosen and that does not have DSR approved ','Error','dismissable');
            this.showSpinner =false;
            this.submitdisable = false;
            this.errorStr='';
            this.finalPrdList=[];
            return;
        }

        //console.log(' all dsr ' , dsrJustification);
        //console.log(' pl in js : ', this.productList);
        let pli = JSON.stringify(this.finalPrdList); //We are sending our final selected products
        console.log('pli : ' , pli);
        //console.log(pli.replace(/[\[\]']+/g,''));
        console.log(pli);
        const cancelEvent = new CustomEvent('cancel',{});
        
    // If condition added by Ashin
    if(this.showDSRError===false)
    {
    createChimeCase({dsrJustificationList:dsrJustification1,productListStr : pli, chimeNotes : notes.value, chimeProdNames:this.chimeProdnames })
             .then(result =>{
                 this.showSpinner =false;
                 console.log('received re');
                 this.showToast('PST Case has been created','Success','dismissable');
                 this.dispatchEvent(cancelEvent);
                 window.setTimeout(function(){ window.location.reload() }, 2000);
                
                }).catch(error => {
                  console.log('error** :: ' , error );
                  //this.showToast('Error in creating PST Cases','Warning','dismissable');
                  this.dispatchEvent(cancelEvent);
                }); 

    }
    }

    handleCancel(){
        const cancelEvent = new CustomEvent('cancel',{});
            this.dispatchEvent(cancelEvent);
    }

    showToast(message,variant,mode) {
        // alert('here');
        const evt = new ShowToastEvent({
            
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    showWarningToast()
    {
        console.log('NAY ' , this.warningshown);
        if(this.warningshown === false)
        {
            console.log('NAY ded' , this.warningshown);
            var toastMsg = 'Justification for unapproved DSR will be reviewed by the implementation team before assigning a resource.\n ';
            toastMsg = toastMsg + ' Best practice for faster resource assignment is to have approved DSR before raising a case ';
            //this.showToast( toastMsg ,'Warning','sticky');
            this.showWarning = true;
            // console.log('indeden :');
            //this.showToast( toastMsg ,'Warning','sticky');
            // console.log(' nwn s : ' , this.template.querySelectorAll(".hideshow")  ) ;
            //window.setTimeout(function(){ this.showWarning = false; }, 1000);
            this.warningshown = true;
        }
        
    }


}