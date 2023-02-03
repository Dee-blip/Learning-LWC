/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 08-18-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-22-2021   apyati   Initial Version
**/
// SF1_OpportunityFlowController
({
    // this function automatic call by aura:waiting event  
   showSpinner: function(component) {
      // make Spinner attribute true for display loading spinner 
       component.set("v.Spinner", true); 
   },

   backToListView : function() {
       window.history.back();
   },
   
   // this function automatic call by aura:doneWaiting event 
   hideSpinner : function(component){
    // make Spinner attribute to false for hide loading spinner    
      component.set("v.Spinner", false);
   },

   doInit : function(component, event, helper) {
       var value, context, defaultAcc;
       helper.getIntermediatePageAccess(component, event, helper);
       //SFDC-3903 
       value = helper.getParameterByName(component , event, 'inContextOfRef');
       context = JSON.parse(window.atob(value));
       defaultAcc = component.get("v.defaultAccount");
       defaultAcc.Id = context.attributes.recordId;
       component.set("v.defaultAccount", defaultAcc);
       component.set("v.doneLoading",true);
   }, 
   
   handleAccountChange : function() {
       /* reset all the data...*/
   },

   isEmpty : function(val) {
       return (val ? false : true);
   },

   handleCurrencyChange : function(component, event) {
       var noRecordsPresent, hascurrencyMisMatch, hasNoCurrency, renewalBtn;
       var selectedCurrency = event.getParam("currency");
       console.log('inside OpptyFlow.handleCurrencyChange...' + selectedCurrency);
       component.set("v.otherCurrency", selectedCurrency);
       console.log("otherCurrency:" + component.get("v.otherCurrency"));

       // call the fn from here to validate the buttonVisibility...
       noRecordsPresent =  component.get("v.noRecordsPresent");
       hascurrencyMisMatch =  component.get("v.isContractCurrencyMismatch");
       hasNoCurrency =  component.get("v.otherCurrency");

       if(!noRecordsPresent && (hascurrencyMisMatch && hasNoCurrency.toUpperCase() === "NONE")) {
           component.set("v.showNewOpptyBtn", true);
           component.find("createRenewalOppty").set("v.disabled", true);
       }
       // else {
       //  component.set("v.showNewOpptyBtn", false);
       //  //component.find("createRenewalOppty").set("v.disabled", false);
       // }
       else{
           component.set("v.showNewOpptyBtn", false);
           renewalBtn = component.find("createRenewalOppty");
           if(renewalBtn){
               console.log('renewalBtn exists=' + renewalBtn);
               renewalBtn.set("v.disabled", false);
           }
           else{
               console.log('renewalBtn does not exists=' + renewalBtn);
           }
           //component.find("createRenewalOppty").set("v.disabled", false);
       }

   },

   handleOpptyTypeChange : function(component, event, helper) {
       component.set("v.selectedOppType",null); //SFDC-3550
       helper.withoutBaselineCheck(component, event);
   },

   //SFDC-3550
   setOpptyType : function(component, event) {
       component.set("v.selectedOppType",event.getParam("opptyType"));
   },

   handleContractChange : function(component, event) {
       var accountId = event.getParam("accountId");
       var contractIds = event.getParam("contracts");
       var contractProductIds = event.getParam("contractproducts");
       var hasCurrencyMisMatch = event.getParam("hasCurrencyMisMatch");
       var noRecordsPresent, hascurrencyMisMatch, hasNoCurrency, renewalBtn;
       console.log('event' + event.getParams());

       console.log('inside OpptyFlow.handleContractChange...: accountId=' + accountId + "; contractIDs=" + JSON.stringify(contractIds)+ "; contractProductIds=" + JSON.stringify(contractProductIds) + '; hasCurrencyMisMatch=' + hasCurrencyMisMatch);

       //if (!this.isEmpty(contractIds) && contractIds.length>2) { // currently contracts.length is returning lenght of the string instead of array.length
       if(contractIds){ // currently contracts.length is returning lenght of the string instead of array.length
           if(contractIds.length>0){
               component.set("v.noRecordsPresent", false);
               component.set("v.selectedContracts", contractIds);
               component.set("v.selectedContractProducts", contractProductIds);
               component.set("v.isContractCurrencyMismatch", hasCurrencyMisMatch);
               console.log('opptyFlow.handleContractChange is a valid request.selectedContracts:' + component.get("v.selectedContracts")); 
               console.log('isContractCurrencyMismatch=' + component.get("v.isContractCurrencyMismatch"));
           }
           else{
               console.log('opptyFlow.handleContractChange is an empty request.');
               component.set("v.isContractCurrencyMismatch", hasCurrencyMisMatch);
               component.set("v.noRecordsPresent", true);
               component.set("v.selectedOppType","--None--");
           }
       }
       else{
           console.log('opptyFlow.handleContractChange is an empty request.');
           component.set("v.isContractCurrencyMismatch", hasCurrencyMisMatch);
           component.set("v.noRecordsPresent", true);
       }

       console.log('v.selectedContracts'+component.get("v.selectedContracts"));
       // call the fn from here to validate the buttonVisibility...
       noRecordsPresent =  component.get("v.noRecordsPresent");
       hascurrencyMisMatch =  component.get("v.isContractCurrencyMismatch");
       hasNoCurrency =  component.get("v.otherCurrency");

       if(!noRecordsPresent && (hascurrencyMisMatch && hasNoCurrency.toUpperCase() === "NONE")){
           component.set("v.showNewOpptyBtn", true);
           component.find("createRenewalOppty").set("v.disabled", true);
       }
       else{
           component.set("v.showNewOpptyBtn", false);
           renewalBtn = component.find("createRenewalOppty");
           if (renewalBtn) {
               console.log('renewalBtn exists=' + renewalBtn);
               renewalBtn.set("v.disabled", false);
           } else {
               console.log('renewalBtn does not exists=' + renewalBtn);
           }
           //component.find("createRenewalOppty").set("v.disabled", false);
       }
   },

   //showNewOpportunityBtn : function(component, event, h)

   // Account, 2-Qualify, Direct

   createOppty : function(component, event, helper) {
       var acc, evt;
       //SFDC-3550
       var selectedOppType = component.get("v.selectedOppType");
       if(selectedOppType === '--None--' || selectedOppType == null || selectedOppType === ""){
           helper.showError("Please select Opportunity Type.");
           return;
       }

       acc = component.get("v.acc");
       console.log('inside OpptyFlow.createOppty... acc:' + JSON.stringify(acc));
       
       evt = $A.get("e.force:createRecord");
       console.log('evt:' + evt);
       evt.setParams({
           'entityApiName':'Opportunity',  
           // @todo: defaultFieldValues needs to be enabled after Summer'17 goes to production ETA: Sep/15/2017.
           // 'defaultFieldValues': {
           //     'StageName':'2-Qualify',
           //     'AccountId': acc.Id,
           //     'Deal_Type__c': 'Direct'
           // },
           'recordTypeId':'012A0000000CvQLIA0',
           "defaultFieldValues": {
               'Opportunity_Type__c' : selectedOppType,
               //SFDC-3903
               'AccountId': acc.Id
           }
       });
       
       evt.fire();

       //  var createRecordEvent = $A.get("e.force:createRecord");
       // createRecordEvent.setParams({
       //     "entityApiName": inputSecret
       // });
       // createRecordEvent.fire();

   },
   
   toggle : function(component) {
       
       var toggleText = component.find("baselineType");
       console.log("toggleText" + toggleText);
       $A.util.toggleClass(toggleText, "toggle");

   },

   submitRequest : function(component, event, helper){
       var selectedOppType;
       console.log('submitRequest');
       //SFDC-3550
       selectedOppType = component.get("v.selectedOppType");
       if(selectedOppType === '--None--' || selectedOppType == null || selectedOppType === ""){
           helper.showError("Please select Opportunity Type.");
           return;
       }
       helper.createOpptyRec(component, event, helper);
   },
   
   handleCreateOppButtonVisibility : function(component, event){
       var createBtn;
       console.log('Currency in Handler == '+event.getParam("currencyValue"));
       createBtn = component.find("createOppDivId") ;
       if(event.getParam("currencyValue") === "none"){
           console.log("In none block");
           if(component.find("createRenewalOppty"))
               component.find("createRenewalOppty").set("v.disabled", true);
           $A.util.removeClass(createBtn, 'slds-show');
           $A.util.addClass(createBtn, 'slds-hide');
           console.log("In none block2");
       } else{
           component.find("createRenewalOppty").set("v.disabled", false);
           $A.util.removeClass(createBtn, 'slds-hide');
           $A.util.addClass(createBtn, 'slds-show');
       }
   },
   
   handleEnableOppButton : function(component){
       var createBtn = component.find("createOppDivId") ;
       $A.util.removeClass(createBtn, 'slds-hide');
       $A.util.addClass(createBtn, 'slds-show');
   },

   handleOpportunityType : function(component, event){ // Use metadata to alter the picklist value
       var type = component.get("v.opptyTypes");
       var flag = event.getParam("flag");
       console.log("Flag:"+flag);
       if(flag){
           if(!type.includes("Auto-Renewal"))
               type.push("Auto-Renewal");
       }else{
           if(type.includes("Auto-Renewal"))
               type.splice(type.indexOf("Auto-Renewal"), 1);
       }
       console.log("Type:"+type);
       component.set("v.opptyTypes", type);
   },
   
   contractChangeTypeSelection : function(component, event){
       var selected;
       var sel = "Create Contract Change Opportunity";
       var appEvent = $A.get("e.c:opportunityTypeChangeEvent");
       appEvent.setParams({ "selection" : sel });
       appEvent.setParams({"showContracts" : true});
       appEvent.setParams({ "acc" : component.get("v.acc") });
       appEvent.fire();
       selected = event.getSource().get("v.label");
       if(selected === 'BED Deferment'){
           component.set("v.contractChangeType","BEDD");
       }else if(selected === 'Extend Contract'){
           component.set("v.contractChangeType","CE");
       }else if(selected === 'Other'){
           component.set("v.contractChangeType","Other");
       }
   },
   
   nextScreen : function(component, event, helper) {
       var contractChangeType = component.get("v.contractChangeType");
       var selectedContract = "";
       var urlStr, urlEvent, action, state, oaDetailPageURL, res, accountId;
       if(component.get("v.selectedContracts") && component.get("v.selectedContracts").length > 0)
           selectedContract = component.get("v.selectedContracts")[0];
       accountId = component.get("v.acc.Id");
       if(contractChangeType === 'CE' || contractChangeType === 'BEDD'){
           urlStr = "/apex/GSM_Lite_Contract_BEDDeferement?contractId=" + selectedContract + "&pRequestType=" + contractChangeType + "&accountId=" + accountId;
           urlEvent = $A.get("e.force:navigateToURL");
           urlEvent.setParams({
               "url": urlStr
           });
           urlEvent.fire();
       }
       else if(contractChangeType === 'Other'){
           action = component.get("c.createPaperPOC");
           action.setParams({
               contractId: selectedContract,
               accountId: accountId            
           });
           action.setCallback(this, function(response) {
               state = response.getState();
               if(component.isValid() && state === "SUCCESS") {
                   res = response.getReturnValue();
                   //if(res !== '' && res !== 'ERROR'){
                    if(res !== '' && !res.includes('ERROR:')){
                       oaDetailPageURL = "/lightning/r/Order_Approval__c/"+res+"/view";
                       urlEvent = $A.get("e.force:navigateToURL");
                       urlEvent.setParams({
                           "url": oaDetailPageURL
                       });
                       urlEvent.fire();
                   }
                   else if(res.includes('ERROR:'))
                    {
                        helper.showError(res);
                     }
                   else{
                       helper.showError("Opportunity creation failed! Please contact your System Administrator.");
                   }
               }
           });
           $A.enqueueAction(action);
       }
           else{
                helper.showError("Please select Contract Change Type.");
               //alert("Please select Contract Change Type.");
           }
   }   
})