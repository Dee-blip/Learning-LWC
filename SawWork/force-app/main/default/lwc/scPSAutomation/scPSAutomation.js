import { LightningElement,track,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendMissingTeamMemberEmail from '@salesforce/apex/SC_PSAutomationController.sendEmailForMissingTeamMember';
import getDL from '@salesforce/apex/SC_PSAutomationController.getDLList';
import sendEmailControllerForMailer from '@salesforce/apex/SC_PSAutomationController.sendEmailControllerForMailer';
import createRecs from '@salesforce/apex/SC_PSAutomationController.createRecords';
import getAccounts from '@salesforce/apex/SC_PSAutomationController.getMappedAccounts';
import hasCustomerMailerPermission from '@salesforce/customPermission/PSCustomerMailerCreatePermission';
//import { NavigationMixin } from 'lightning/navigation';




export default class ScPSAutomation extends LightningElement {
    @api defaultcc = ['visharm@akamai.com'];
    @track dlList = [];
    @track dataTableColumns = [
        { label: 'Account', fieldName: 'Name',type:'text',cellAttributes : {class:{fieldName: 'colour'}},initialWidth: 250},
        { label: 'Geography', fieldName: 'Geography',type:'text',cellAttributes : {class:{fieldName: 'colour'}},initialWidth: 150},
        { label: 'Product', fieldName: 'Product',type:'text',cellAttributes : {class:{fieldName: 'colour'}},initialWidth: 150},
        { label: 'SSP Team Member', fieldName: 'TeamMember',type:'text',cellAttributes : {class:{fieldName: 'colour'}}},

    ];
    @track applicableAccountsData =[];
    @track applicableAccountsDataBackup =[];
    @track isAnyAccountMissingTeamMember = false;
    @track searchKey = '';
       /* {
            Id:'1',Name:'test account',Geography:'Americas',Product:'Managed Kona',TeamMember:'Vishnu Sharma',colour:'black'
        },
        {
            Id:'2',Name:'Test account FFDec1',Geography:'APJ',Product:'MSS',TeamMember:'',colour:'red'
        }
    ];*/
    @track productOptions= [
        
        { label: 'Managed Kona', value: 'Managed Kona' },
        { label: 'MSS', value: 'MSS' },
        { label: 'PLX', value: 'PLX' }

    ];
   
    @track recordTypeValue = "Security Bulletin";
    @track selectedProducts = ['Managed Kona','MSS','PLX'];
    @track contentValue;
    @track showApplicableAccountsList = false;
    @track selectedProductsBlank = false;
    @track teamMemberEmail = '';
    @track toAddress = [];
    @track ccAddress = [];
    subject = "";
    body = "";
    @track files = [];
    @track fileData = [];
    @track mailerName;
    @track instructions;
    @track showSpinner = false;
    @track showAuthorizationError = false;
    @track showOtherRecipients = false;
    @track currentFilesSize = 0;
    maxSize = 7340032;
    @track textFiles;
    @track showTooltip = false;
    
    @track accountCount =0;
    @track isToggleChecked = false;
    @track sortBy;
    @track sortDirection;
   // @track accountReturnData = [];

   handleFileRemove(event){
   // alert(event.target.name);
       var i=0;
       for(i=0;i<this.fileData.length;i++){
           if(this.fileData[i].fileName === event.target.name){
            this.currentFilesSize = this.currentFilesSize -  this.fileData[i].fileSize;
            //  this.fileData.pop(this.fileData[i]);

              this.fileData.splice(i,1);
           }
       }
   }

   async openfileUpload(event) {
    var i=0;
    var newSize;
    var itrFile;
    for(i=0;i<event.target.files.length;i++){
        newSize = this.currentFilesSize+event.target.files[i].size;
    }
    if(newSize > this.maxSize){
        this.showToast('Total file Size can not be more tha 7 MB','error','dismissable');
    }else{
        this.textFiles = await Promise.all(
        [...event.target.files].map(file => this.readFile(file))
        );
        this.currentFilesSize = newSize;
        for(i=0;i<this.textFiles.length;i++){
            itrFile = this.textFiles[i];
            this.fileData.push(itrFile);
        }
    }

    // Here, you can now upload the files to the server //
  }
  readFile(fileSource) {
    return new Promise((resolve, reject) => {
      const fileReader = new FileReader();
      const fileName = fileSource.name;
      const fileSize = fileSource.size;
      fileReader.onerror = () => reject(fileReader.error);
      fileReader.onload = () => resolve({ fileName,fileSize, base64: fileReader.result.split(',')[1]});
      fileReader.readAsDataURL(fileSource);
    });
  }

 

  
  handleManageRecipients() {
    window.open('/lightning/o/PS_Automation_Admin_DL__c/list?filterName=All', '_blank');
    }
 

    connectedCallback(){
        //alert(JSON.stringify(this.applicableAccountsData));
        var i;
        var colour;
        var members;
        if(!hasCustomerMailerPermission || hasCustomerMailerPermission === undefined){
         //   alert(this.showAuthorizationError);
            this.showAuthorizationError = true;
          //  alert(this.showAuthorizationError);
        }else{
        
            getAccounts({ products: this.selectedProducts })
            .then(result => {
            var returnResult = JSON.parse(result);
            // alert(JSON.stringify(returnResult));
                for(i=0;i<returnResult.length;i++){
                    members = '';
                
                
                for(let key in returnResult[i].memberVsEmail){
                    if(key != null){
                    members = members+' '+key+';';
                    this.teamMemberEmail = this.teamMemberEmail+returnResult[i].memberVsEmail[key].User.Email+';';
                    }
                }
                    if(members === ''){
                        colour = 'red';
                        this.isAnyAccountMissingTeamMember = true;
                    }else{
                        colour = 'black';
                    }
                /*  if(returnResult[i].memberVsEmail.size > 0){
                        // this.toAddress.push(returnResult[i].TeamMemberEmail);
                        returnResult[i].memberVsEmail.values().forEach(element => {
                            this.teamMemberEmail = element+';';
                        });
                    
                    }*/
                    this.applicableAccountsData.push({Id:returnResult[i].accountRec.Id,Name:returnResult[i].accountRec.Name,Geography:returnResult[i].accountRec.TERR_HIER_1__c,Product:returnResult[i].product,TeamMember:members,TeamMemberMap:returnResult[i].memberVsEmail,colour:colour,ownerId:returnResult[i].ownerId });
                  /*  for(var i=0;i<7000;i++){
                        this.applicableAccountsData.push({Id:i,Name:'Abhilasha',Geography:'Kanpur',Product:'Gold',TeamMember:'Vishnu',TeamMemberMap:null,colour:'black',ownerEmail:'visharm@akamai.com' });
                    } */
                }
                this.accountCount = this.applicableAccountsData.length;
                this.applicableAccountsDataBackup = this.applicableAccountsData;
              /*  for(i=0;i<returnResult.dlList.length;i++){
                    this.defaultcc.push(returnResult.dlList[i]);
                }*/
                
            // this.showApplicableAccountsList = true;
            })
            .catch((error) => {
                console.error("Error in handleApplicableAccountsShow:", error);
            });

            getDL({ type: 'Internal',recId:null })
            .then(result => {
                for(i=0;i<result.length;i++){
                    this.dlList.push(result[i]);
                   // alert(JSON.stringify(this.dlList));
                }
               // this.showOtherRecipients = true;
            }).catch((error) => {
                console.error("Error in handleApplicableAccountsShow:", error);
            });
        }
        
        
  

    }
    get recordTypeOptions() {
        return [
            { label: 'Security Bulletin', value: 'Security Bulletin' }
        ];
    }

    

    
    
    handleProductChange(e){
        var i;
        var colour;
        var members = '';
        var returnResult;
        this.toAddress = [];
        this.teamMemberEmail = '';
        this.selectedProducts = e.detail.value;
        this.showSpinner = true;
        if(this.selectedProducts.length === 0){
        this.selectedProductsBlank = true;
        }else{
            this.selectedProductsBlank = false;
        }

        
        getAccounts({ products: this.selectedProducts })
        .then(result => {
            this.applicableAccountsData = [];
            
            returnResult= JSON.parse(result);
         //   alert(JSON.stringify(returnResult));
            for(i=0;i<returnResult.length;i++){
                members = '';
              
               
                for(let key in returnResult[i].memberVsEmail){
                    if(key != null){
                    members = members+' '+key+';';
                    this.teamMemberEmail = this.teamMemberEmail+returnResult[i].memberVsEmail[key].User.Email+';';
                    }
                }
                 if(members === ''){
                     colour = 'red';
                     this.isAnyAccountMissingTeamMember = true;
                 }else{
                     colour = 'black';
                 }
                
                
                 this.applicableAccountsData.push({Id:returnResult[i].accountRec.Id,Name:returnResult[i].accountRec.Name,Geography:returnResult[i].accountRec.TERR_HIER_1__c,Product:returnResult[i].product,TeamMember:members,TeamMemberMap:returnResult[i].memberVsEmail,colour:colour,ownerId:returnResult[i].ownerId });
               
                
                }
                this.accountCount = this.applicableAccountsData.length;
                this.applicableAccountsDataBackup = this.applicableAccountsData;
                this.showSpinner = false;
            
        })
        .catch((error) => {
            this.showSpinner = false;
            console.error("Error in handleApplicableAccountsShow:", error);
        });
    }

    handleContentChange(){
        
    }

    handleMailerNameChange(e){
        this.mailerName = e.detail.value;
    }

    handleInstructionsChange(e){
        this.instructions = e.detail.value;
    }

    renderedCallback(){
        const dualComboBoxStyle = document.createElement('style');
        dualComboBoxStyle.innerText = `c-sc-p-s-automation .slds-dueling-list__column_responsive .slds-dueling-list__options{
        height:120px;   
        }`;
        this.template.querySelector('lightning-dual-listbox').appendChild(dualComboBoxStyle);

        

        if(this.showApplicableAccountsList){
            const redStyle = document.createElement('style');
            redStyle.innerText = `c-sc-p-s-automation .slds-table .red{
            background-color: #F7BEC0;
            }`;
            this.template.querySelector('lightning-datatable').appendChild(redStyle);

            const modalWidthStyle = document.createElement('style');
            modalWidthStyle.innerText = `c-sc-p-s-automation .customModal .slds-modal__container {
            width:70%;
            max-width:80rem;
            }`;
            this.template.querySelector('section').appendChild(modalWidthStyle);

        }   

        if(this.isAnyAccountMissingTeamMember){
            const toolTipStyle = document.createElement('style');
            toolTipStyle.innerText = `c-sc-p-s-automation .tooltipIdentifier svg{
            background-color: red;
            border-radius:4px;
            }`;
            this.template.querySelector('lightning-icon').appendChild(toolTipStyle);
        }

        if(this.showSpinner){
            const spinnerStyle = document.createElement('style');
            spinnerStyle.innerText = `c-sc-p-s-automation .slds-spinner_container{
                height:1200px;
                }`;
                this.template.querySelector('lightning-spinner').appendChild(spinnerStyle);
        }

    }

    handleApplicableAccountsShow(){
        var i;
        var colour;
        var members = '';
        var returnResult;
        this.toAddress = [];
        this.teamMemberEmail = '';
        this.showSpinner = true;
        getAccounts({ products: this.selectedProducts })
        .then(result => {
            this.applicableAccountsData = [];
            
            returnResult= JSON.parse(result);
         //   alert(JSON.stringify(returnResult));
            for(i=0;i<returnResult.length;i++){
                members = '';
              
               
                for(let key in returnResult[i].memberVsEmail){
                    if(key != null){
                    members = members+' '+key+';';
                    this.teamMemberEmail = this.teamMemberEmail+returnResult[i].memberVsEmail[key].User.Email+';';
                    }
                }
                 if(members === ''){
                     colour = 'red';
                     this.isAnyAccountMissingTeamMember = true;
                 }else{
                     colour = 'black';
                 }
                
                
                 this.applicableAccountsData.push({Id:returnResult[i].accountRec.Id,Name:returnResult[i].accountRec.Name,Geography:returnResult[i].accountRec.TERR_HIER_1__c,Product:returnResult[i].product,TeamMember:members,TeamMemberMap:returnResult[i].memberVsEmail,colour:colour,ownerId:returnResult[i].ownerId });
               /*  for(var i=0;i<7000;i++){
                    this.applicableAccountsData.push({Id:i,Name:'Abhilasha',Geography:'Kanpur',Product:'Gold',TeamMember:'Vishnu',TeamMemberMap:null,colour:'black',ownerEmail:'visharm@akamai.com' });
                }*/
                
                }
                this.accountCount = this.applicableAccountsData.length;
                this.applicableAccountsDataBackup = this.applicableAccountsData;
            this.showApplicableAccountsList = true;
            this.showSpinner = false;
        })
        .catch((error) => {
            this.showSpinner = false;
            console.error("Error in handleApplicableAccountsShow:", error);
        });
        
    }

    handleClosePopUp(){
        this.showApplicableAccountsList =false;
    }

    sendEmailForMissingMember(){
        this.showSpinner = true;
        sendMissingTeamMemberEmail({accountList:JSON.stringify(this.applicableAccountsData)})
        .then(result =>{
               console.log(result); 
               this.showSpinner = false;
               this.showToast('Account Owners are notified for missing Security Services Primary Member.','SUCCESS','dismissable');
            }
    
          
           
           ).catch(error => {
               this.showSpinner = false;
               console.log(JSON.stringify(error));
             
           }); 
       } 

       // Handling toasts
     showToast(message,variant,mode) {
        // alert('here');
        const evt = new ShowToastEvent({
            
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }


    handleDiscard(){
        window.open('lightning/o/PS_Customer_Mailers__c/home','_self');
    }

    handleTestEmail(){
        if(this.isValidForm()){
            let emailDetails = {
                toAddress: this.toAddress,
                ccAddress: this.ccAddress,
                dlList:this.dlList,
                subject: this.subject,
                body: this.body,
                Instruction : this.instructions
            };
            sendEmailControllerForMailer({ emailDetailStr: JSON.stringify(emailDetails),parentRecId:null,accMailerMap:null,accountList:JSON.stringify(this.applicableAccountsData) })
                        .then(() => {
                            this.showSpinner = false;
                            this.showToast('Test email has been sent successfully.','SUCCESS','dismissable');
                            

                        })
                        .catch((error) => {
                            console.error("Error in sendEmailController:", error);
                            this.showSpinner = false;
                        });
        }  else{
            this.showToast('Please fill all required fields','error','dismissable');
        }          
    }

    isValidForm(){
        var isValid;
         if(this.mailerName === '' || this.mailerName === undefined || this.teamMemberEmail === '' || this.subject === '' || this.subject === undefined || this.body === undefined || this.body === ''){
            isValid = false;
           // return false;   
        }else{
            isValid = true;
          //  return true;
        }
        return isValid;
    }

    handleSaveDraft(){
       
        if(this.isValidForm()){
        this.showSpinner = true;
       // const {base64, filename} = this.fileData;
       
        let emailDetails = {
            toAddress: this.toAddress,
            ccAddress: this.ccAddress,
            dlList:this.dlList,
            subject: this.subject,
            body: this.body,
            Instruction : this.instructions
        };
        
      //  createRecs({ mailerName: this.mailerName,instructions:this.instructions,accountsList:JSON.stringify(this.applicableAccountsData),audienceType:'Internal',products:this.selectedProducts })
        createRecs({ emailDetailStr: JSON.stringify(emailDetails),mailerName: this.mailerName,instructions:this.instructions,accountsList:JSON.stringify(this.applicableAccountsData),audienceType:'Internal',products:this.selectedProducts,files:JSON.stringify(this.fileData),isPublish:false }) 
        .then(resultRec => {
                console.log("Parent Record Created");
               
                this.showToast('PS Customer Mailer record has been created.','SUCCESS','dismissable');

              
                window.open('/'+resultRec,'_self');
               
                   

            })
            .catch((error) => {
                console.error("Error in create records", error);
                this.showSpinner = false;
            });
       }else{
            this.showToast('Please fill all required fields','error','dismissable');
        }    
    }

    handleShowTooltip(){
        this.showTooltip = true;
    }

    handleHideTooltip(){
        this.showTooltip = false;
    }

  

    handlePublish(){
        
        if(this.isValidForm()){
        this.showSpinner = true;
       // const {base64, filename} = this.fileData;
        let emailDetails = {
            toAddress: this.toAddress,
            ccAddress: this.ccAddress,
            dlList:this.dlList,
            subject: this.subject,
            body: this.body,
            Instruction : this.instructions
        };
      //  createRecs({ emailDetailStr: JSON.stringify(emailDetails),mailerName: this.mailerName,instructions:this.instructions,accountsList:JSON.stringify(this.applicableAccountsData),audienceType:'Internal',products:this.selectedProducts,base64:base64,filename:filename })
      createRecs({ emailDetailStr: JSON.stringify(emailDetails),mailerName: this.mailerName,instructions:this.instructions,accountsList:JSON.stringify(this.applicableAccountsData),audienceType:'Internal',products:this.selectedProducts,files:JSON.stringify(this.fileData),isPublish:true})
            .then(resultRec => {
                console.log("Records Created");
               // console.log(JSON.stringify(result));
               // result = JSON.parse(resultRec);
                this.showSpinner = false;
                this.showToast('PS Customer Mailer records have been created and notifications are sent.','SUCCESS','dismissable');
                window.open('/'+resultRec,'_self');
                
              //  alert(JSON.stringify(result.accVsMailerRecMap));
              /*  sendEmailControllerForMailer({ emailDetailStr: JSON.stringify(emailDetails),parentRecId:result.masterRecId,accMailerMap:result.accVsMailerRecMap,accountList:JSON.stringify(this.applicableAccountsData),testEmail:false })
                    .then(() => {
                        this.showSpinner = false;
                        this.showToast('PS Customer Mailer records have been created and notifications are sent successfully.','SUCCESS','dismissable');
                        window.open('/'+result.masterRecId,'_self');

                    })
                    .catch((error) => {
                        console.error("Error in sendEmailController:", error);
                        this.showSpinner = false;
                    });*/
              /*  this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'PS_Customer_Mailers__c',
                        actionName: 'view'
                    },
                });*/
            })
            .catch((error) => {
                console.error("Error in create records", error);
                this.showSpinner = false;
            });
        } else{
            this.showToast('Please fill all required fields','error','dismissable');
        }    
        
        
    }

    handleCcAddressChange(event) {
        this.ccAddress = event.detail.selectedValues;
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }


    handleBodyChange(event) {
        this.body = event.target.value;
    }

    keycheck(event){
        if(event.which === 13){
            this.handleSearch(event);
        }
    } 

    handleSearch(event){
        var searchString ;
        var tempList = [];
        var backUpList = [];
        var i;
        this.searchKey = event.target.value;
        // At least 3 characters required for search
        if(event.target.value !=='' && event.target.value.length < 3){
            this.showToast('Please type at least 3 characters for search.','error','dismissable');
            
        }else{
            if(event.target.value === ''){
                this.applicableAccountsData = this.applicableAccountsDataBackup;
                this.isToggleChecked =false;
            }else{
               // this.searchKeyMyIncidentsSection = event.target.value;
                searchString = this.searchKey.toLowerCase();
                backUpList = this.applicableAccountsData;
                for(i=0;i<backUpList.length;i++){
                let tempRecord = Object.assign({}, backUpList[i]); 
                if(tempRecord.Name.toLowerCase().includes(searchString)){
                    //if(tempRecord.Incident_ID.includes(this.searchKeyMyIncidentsSection) || tempRecord.Title.includes(this.searchKeyMyIncidentsSection) || tempRecord.Status.includes(this.searchKeyMyIncidentsSection) || tempRecord.Impact.includes(this.searchKeyMyIncidentsSection) || tempRecord.OwnerName.includes(this.searchKeyMyIncidentsSection) || tempRecord.Incident_Requested_By.includes(this.searchKeyMyIncidentsSection) || tempRecord.TIM.includes(this.searchKeyMyIncidentsSection)){
                        tempList.push(tempRecord); 
                    } 
                }
               this.applicableAccountsData = tempList;
            }   
            this.accountCount = this.applicableAccountsData.length;
        }
        
    }   
    
    handleToggleChange(event){
        var dataList;
        var tempList = [];
        var i;
        this.searchKey = '';
        
        try{
        if(event.detail.checked){
                
                this.isToggleChecked = true;
                dataList = this.applicableAccountsDataBackup;
                for(i=0;i<dataList.length;i++){
                let tempRecord = Object.assign({}, dataList[i]); 
                if(tempRecord.colour === 'red'){
                    //if(tempRecord.Incident_ID.includes(this.searchKeyMyIncidentsSection) || tempRecord.Title.includes(this.searchKeyMyIncidentsSection) || tempRecord.Status.includes(this.searchKeyMyIncidentsSection) || tempRecord.Impact.includes(this.searchKeyMyIncidentsSection) || tempRecord.OwnerName.includes(this.searchKeyMyIncidentsSection) || tempRecord.Incident_Requested_By.includes(this.searchKeyMyIncidentsSection) || tempRecord.TIM.includes(this.searchKeyMyIncidentsSection)){
                        tempList.push(tempRecord); 
                    } 
                }
               this.applicableAccountsData = tempList;

        }else{
            this.isToggleChecked = false;
            this.applicableAccountsData = this.applicableAccountsDataBackup;
        }
        this.accountCount = this.applicableAccountsData.length;
    }catch(error) {
        console.error("Error in handleApplicableAccountsShow:", error);
    }

    }
    
}