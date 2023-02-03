({
    doInit : function(component, event, helper) {
        
       
        component.set("v.loading",true);
        
        component.set("v.isMobile",($A.get("$Browser.formFactor")== 'PHONE' || $A.get("$Browser.formFactor")== 'TABLET'?true:false));

        
        var existingId = component.get("v.pageReference.state.c__id");
        
        if(component.get("v.pageReference.state.c__pub") == 1  ){
            if(component.get("v.isClassic")){
              helper.showToastClassic(component,'ERSS Form Published successfully',' ','success');
            }
            else{
              helper.showToast('ERSS Form Published successfully',' ','success');
            }
            
        }
        
        if(existingId == null || existingId == ''){
            if(component.get("v.recordId")!= null && component.get("v.recordId")!= '' ){
                existingId = component.get("v.recordId");
            }
        }        
        
        component.set("v.existingRSSForm",existingId);
        helper.setRecordTypeID(component, event, helper);
        helper.permissionHelper(component, event, helper);
        if(existingId!= null){
            helper.opportunitySetFormHelper(component, event, helper,existingId);
            component.set("v.showProducts", true);
            
        }
        else{
            component.set("v.stage", "Draft");
        }
       
        
        var action = component.get("c.getProductList");
        var arr = new Array();
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                
                
                var options = new Array();
                console.log(a.getReturnValue());
                for(let item of a.getReturnValue()){
                    arr.push(item);
                    let option = { value: item.Id, label: item.Name };
                    
                    options.push(option);
                }
                component.set("v.productOptions", options);
                 
                
                if(component.get("v.existingRSSForm") != null){
                    var actionSelected = component.get("c.getSelectedProductList");
                    actionSelected.setParams({
                        newRSSFormId : component.get("v.existingRSSForm")});
                    actionSelected.setCallback(this,function(a){
                        var state = a.getState();
                        if(state == "SUCCESS"){
                            component.set("v.selectedProductOptions", a.getReturnValue());
                            component.set("v.existingOptions", a.getReturnValue());
                            
                            helper.productQuestionInit(component, event, helper, true);
                            helper.getPreviousVersions(component, event, helper);
                            helper.uploadAttachmentsHelper(component);
                        }
                        else{
                            console.log('error');
                            component.set("v.loading",false);
                        }
                    });
                    $A.enqueueAction(actionSelected);
                }
                else{
                    component.set("v.loading",false);
                }
                
            }
            else{
                console.log('error');
                component.set("v.loading",false);
            }
        });
        $A.enqueueAction(action);
    },
    
    handleChange : function(component, event, helper) {
        // component.set("v.showProducts", false);   
        var selectedOptionsList = event.getParam("value");
        
        
        component.set("v.selectedProductOptions", selectedOptionsList);
        
        if(selectedOptionsList == null || selectedOptionsList.length == 0) {
            component.set("v.showProductError", true);
            $A.util.addClass(component.find('productsBox'), 'slds-has-error');
        }
        else{
            component.set("v.showProductError", false);
            $A.util.removeClass(component.find('productsBox'), 'slds-has-error');
        }
        
    },
    
    
    
    saveRecord : function(component, event, helper) {
        
        component.set("v.showOppError", false);
        $A.util.removeClass(component.find('oppFieldDiv'), 'slds-has-error');
        event.preventDefault();
        var productField = component.find('productsBox');
        var value = productField.get('v.value');
        if(component.get('v.selectedProductOptions') == null || component.get('v.selectedProductOptions').length == 0) {
            component.set("v.showProductError", true);
            $A.util.addClass(component.find('productsBox'), 'slds-has-error');
            if(component.get("v.isClassic")){
                helper.showToastClassic(component,'Please select atleast one product to continue',' ','error');
              }else{
                helper.showToast('Please select atleast one product to continue',' ','error');
              }
        }
        else{
            
            
            
            component.set("v.showProductError", false);
            $A.util.removeClass(component.find('productsBox'), 'slds-has-error');
            component.set("v.loading",true);
            var eventFields = event.getParam("fields");
         
            if(component.find('oppField').get('v.value') != null && 
               component.find('oppField').get('v.value')!= ''){
              var accountinfo = component.get("v.accountInformation");
                eventFields.Account__c  = accountinfo.accountId;
                eventFields.TSP__c   = accountinfo.tsp;
                eventFields.AEName__c   = accountinfo.ae;
                eventFields.Partner_Involved__c   = accountinfo.partnerInvolved == 'true'?true:false;
                eventFields.Partner_Name__c   = accountinfo.partnerId;
                
               
            }
            else{
                eventFields.Account__c  = null;
                eventFields.TSP__c   = null;
                eventFields.AEName__c   = null;
                eventFields.Partner_Involved__c   =false;
                eventFields.Partner_Name__c   = null;
            }
            if(component.get("v.existingRSSForm") == null || component.get("v.existingRSSForm") == ''){
                eventFields.Form_Stage__c = 'Draft';
            }
            component.find('eRSSCreateForm').submit(eventFields);
            helper.saveproductsHelper(component, event, helper);
            
        }
        
    },
    errorForm: function(component, event, helper) {
        var errors = event.getParams();
       console.log(JSON.stringify(errors));
    },
      
    saveRecordNew : function(component, event, helper) {
        
        component.set("v.showOppError", false);
        $A.util.removeClass(component.find('oppFieldDiv'), 'slds-has-error');
        
        var productField = component.find('productsBox');
        var value = productField.get('v.value');
        if(component.get('v.selectedProductOptions') == null || component.get('v.selectedProductOptions').length == 0) {
            component.set("v.showProductError", true);
            $A.util.addClass(component.find('productsBox'), 'slds-has-error');
            if(component.get("v.isClassic")){
              helper.showToastClassic(component,'Please select atleast one product to continue',' ','error');
            }else{
              helper.showToast('Please select atleast one product to continue',' ','error');
            }
        }
        else{
            
            
            
            component.set("v.showProductError", false);
            $A.util.removeClass(component.find('productsBox'), 'slds-has-error');
            component.set("v.loading",true);
            
            if(component.find('oppField').get('v.value') != null && 
               component.find('oppField').get('v.value')!= ''){
            var accountinfo = component.get("v.accountInformation"); 
                
                component.find('accountInput').set('v.value',accountinfo.accountId);
                component.find('tspnameInput').set('v.value',accountinfo.tsp);
                component.find('aenameInput').set('v.value',accountinfo.ae);
                component.find('partnerinvlolveInput').set('v.value',accountinfo.partnerInvolved == 'true'?true:false);
                component.find('partnernameInput').set('v.value',accountinfo.partnerId);
            }
            else{
                component.find('accountInput').set('v.value',null);
                component.find('tspnameInput').set('v.value',null);
                component.find('aenameInput').set('v.value',null);
                component.find('partnerinvlolveInput').set('v.value',false);
                component.find('partnernameInput').set('v.value',null);
            }
            if(component.get("v.existingRSSForm") == null || component.get("v.existingRSSForm") == ''){
                component.find('formstageInput').set('v.value','Draft');
                
            }
            component.find('eRSSCreateForm').submit();
            helper.saveproductsHelper(component, event, helper);
            
        }
        
    },
    
    handleSuccess : function(component, event, helper) {
        
        
        
        
        console.log("Handle success");
        var payload = event.getParams().response;
        console.log(payload.id);
        console.log(component.get("v.selectedProductOptions"));
        console.log(component.get("v.existingOptions"));
        if(component.get("v.publishModalOpen")){
            helper.publishRSSFormHelper(component, event, helper);
            component.set("v.publishModalOpen",false);
        }
        else{
            var action = component.get("c.addProductsToRSSForm");
            action.setParams({
                newRSSFormId : payload.id,
                productListId :  component.get("v.selectedProductOptions")
            });
            action.setCallback(this,function(a){
                var state = a.getState();
                if(state == "SUCCESS"){
                    
                    helper.allowLeaving(event);
                    component.set("v.existingRSSForm",payload.id);  
                    helper.productQuestionInit(component, event, helper, false);
                    if(!component.get("v.isClassic")){
                    if(!window.location.href.includes ('c__id')){
                        
                        helper.navigateToSelf(component,event,helper,payload.id);
                    }
                    }
                }
                else{
                    
                    console.log('error in Success');
                    console.log(JSON.stringify(a.getError()));
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    publishRSSForm : function(component, event, helper){
        var inputField = component.find('oppField');
        var value = inputField.get('v.value');
        if(value == null || value == '') {
            component.set("v.showOppError", true);
            $A.util.addClass(component.find('oppFieldDiv'), 'slds-has-error');
            
        }
        else{
            component.set("v.showOppError", false);
            $A.util.removeClass(component.find('oppFieldDiv'), 'slds-has-error');
            var valid = helper.validateProducts(component, event, helper);
            if(valid){
                component.set("v.loading",true);
                helper.saveproductsHelper(component, event, helper);
                component.find('eRSSCreateForm').submit();
                
            }else
            {
              if(component.get("v.isClassic")){
                  helper.showToastClassic(component,'Please complete all the questions', ' ', 'error');
                }else{
                  helper.showToast('Please complete all the questions', ' ', 'error');
                }
                
            }
        }
        
        
    },
    
    reviseForm: function(component, event, helper){
        if(component.get("v.accountInformation").revisePermission != null && 
               component.get("v.accountInformation").revisePermission)
            {
                helper.reviseFormHelper(component, event, helper);
            }
            else{
                 helper.navigateToSelf(component,event,helper,component.get("v.accountInformation").reviseFormId);    
            }
      
    },
    hidePublishModal: function(component, event, helper){
        component.set("v.publishModalOpen",false);
        
        
    },
    showPublishModal: function(component, event, helper){
        var inputField = component.find('oppField');
        var value = inputField.get('v.value');
        if(value == null || value == '') {
            component.set("v.showOppError", true);
            $A.util.addClass(component.find('oppFieldDiv'), 'slds-has-error');
            if(component.get("v.isClassic")){
              helper.showToastClassic(component,'Opportunity is mandatory for Publishing the form',' ','error');
            }else{
               helper.showToast('Opportunity is mandatory for Publishing the form',' ','error');
            }
        }
        else{
            component.set("v.showOppError", false);
            $A.util.removeClass(component.find('oppFieldDiv'), 'slds-has-error');
            
            var valid = helper.validateProducts(component, event, helper);
            if(valid){
                if(component.get("v.invalidProductTemplates") != null && 
                   component.get("v.invalidProductTemplates").length >0 ){
                   if(component.get("v.isClassic")){
                      helper.showToastClassic(component,'Error: Can not publish form', 'There are outdated product templates in the form ', 'error');
                    }else{
                      helper.showToast('Error: Can not publish form', 'There are outdated product templates in the form ', 'error');
                    }
                }
                else{
                   component.set("v.publishModalOpen",true); 
                }
                
            }else
            {
                //component.set("v.loading",true);
                var products = component.get("v.incompleteProducts");
                var pNames='';
                if(products!=null && products.length>0){
                for(let i=0;i< products.length;i++){
                    if(i==0){
                        pNames = products[i];
                    }else{
                        pNames = pNames +', '+products[i];
                    }
                    
                }
                    
                    
                }
                component.find("mainTab").set("v.selectedTabId","productTab" );
                if(component.get("v.isClassic")){
                  helper.showToastClassic(component,'Error: Can not publish form. Please complete all the questions', pNames, 'error');
                }else{
                  helper.showToast('Error: Can not publish form. Please complete all the questions', pNames, 'error');
                }
                if(products!=null && products.length>0){
                  component.find("productTabs").set("v.selectedTabId",products[0] );
                }
                
               
            }
            
        }
        
        
        
    },
    
    onOpportunitySet: function(component, event, helper){
        component.set("v.showOppError", false);
        $A.util.removeClass(component.find('oppFieldDiv'), 'slds-has-error');
        var oppId = event.getSource().get("v.value");
        helper.opportunitySetHelper(component, event, helper,oppId);
    },
    addContact: function(component, event, helper){
        
        var email = component.find('cEmail').get("v.value");
        var name = component.find('cName').get("v.value");
        var phone = component.find('cPhone').get("v.value");
        var type = component.find('cType').get("v.value");
        var valid = true;
        if(!component.find('cEmail').get('v.validity').valid){
            component.find('cEmail').showHelpMessageIfInvalid();
            valid = false;
        }
        if(!component.find('cName').get('v.validity').valid){
            component.find('cName').showHelpMessageIfInvalid();
            valid = false;
        }
        if(!component.find('cPhone').get('v.validity').valid){
            component.find('cPhone').showHelpMessageIfInvalid();
            valid = false;
        }
        if(!component.find('cType').get('v.validity').valid){
            component.find('cType').showHelpMessageIfInvalid();
            valid = false;
        }
        
        
        if(valid){
            var newContact = {'email':email,'name':name,'phone':phone,'type':type};
            var existingList = component.get("v.contactList");
            existingList.push(newContact);
            component.find('contactjson').set("v.value",JSON.stringify(existingList));
            component.set("v.contactList",existingList);
            component.set("v.isModalOpen", false); 
        }
    },
    showContactModal: function(component, event, helper){
        component.set("v.isModalOpen", true);
    },
    hideContactModal: function(component, event, helper){
        component.set("v.isModalOpen", false);
    },
    showOwnerModal: function(component, event, helper){
        component.set("v.ownerModalOpen", true);
    },
    hideOwnerModal: function(component, event, helper){
        component.set("v.ownerModalOpen", false);
    },
    pdfDownload: function(component, event, helper){
       
         if(!component.get("v.isClassic")){
        var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      "url": "/apex/RSSFormView?id="+component.get("v.existingRSSForm")
    });
    urlEvent.fire();
         }
        else{
            window.location.href = "/apex/RSSFormView?id="+component.get("v.existingRSSForm");
        }
    },
    changeOwnerRSSForm: function(component, event, helper){
        
      var action = component.get("c.changeOwnerOfRSSForm");
            action.setParams({
                rSSFormId : component.get("v.existingRSSForm"),
                newOwnerId :  component.get("v.newOwnerId"),
                ownershipComments : component.get("v.ownerComments")
            });
            action.setCallback(this,function(a){
                var state = a.getState();
                if(state == "SUCCESS"){

                    component.set("v.ownerModalOpen", false);
                     
                   helper.gotoURL(component,event,helper,component.get("v.existingRSSForm") , false);
                    
                }
                else{
                    
                    console.log('error in Success');
                    console.log(JSON.stringify(a.getError()));
                    component.set("v.ownerModalOpen", false);
                    if(component.get("v.isClassic")){
                      helper.showToastClassic(component,'Error in transferring Owner', a.getError()[0].pageErrors[0].message, 'error');
                    }
                    else{
                      helper.showToast('Error in transferring Owner', a.getError()[0].pageErrors[0].message, 'error');
                    }
                    
                }
            });
            $A.enqueueAction(action);
    },
    
    
    
    handleLoad: function(component, event, helper) {
        var existing = component.find('contactjson').get("v.value");
        
        if(existing == null){
            existing = JSON.stringify(new Array());
        }
        component.set("v.contactList",JSON.parse(existing));
        
        var version = component.find('formversion').get("v.value");
        component.set("v.version",version);
         
         var createdbyClassic = component.find('createdbyClassic').get("v.value");
        component.set("v.createdbyClassic",createdbyClassic);
        
        var ownerIdClassic = component.find('ownerIdClassic').get("v.value");
        component.set("v.ownerIdClassic",ownerIdClassic);
        var publishedFormClassic = component.find('publishedFormClassic').get("v.value");
        component.set("v.publishedFormClassic",publishedFormClassic);
        var publishedByClassic = component.find('publishedByClassic').get("v.value");
        component.set("v.publishedByClassic",publishedByClassic);
        var opportunityClassic = component.find('opportunityClassic').get("v.value");
        component.set("v.opportunityClassic",opportunityClassic);
    
    
   
        
        
    },
    removeContact: function(component, event, helper) {
        let i = event.target.name;
        var existingList = component.get("v.contactList");
        
        if(existingList != null && existingList.length >0){
            existingList.splice(i, 1);
            component.set("v.contactList",existingList);
            component.find('contactjson').set("v.value",JSON.stringify(existingList));
        }
        
    },
    saveproducts: function(component, event, helper) {
        
        helper.saveproductsHelper(component, event, helper);
    },
    showUpdateProductModal: function(component, event, helper) {
        
        component.set('v.updateProductModalOpen', true);
    },
    hideUpdateProductModal: function(component, event, helper) {
        
        component.set('v.updateProductModalOpen', false);
    },
    showDiffModal: function(component, event, helper) {
        helper.getDiffFromPreviousVersion(component, event, helper);
        
        
    },
    hideDiffModal: function(component, event, helper) {
        
        component.set('v.diffModalOpen', false);
    },
    
    proceedUpdateProductModal: function(component, event, helper) {
        component.set('v.updateProductModalOpen', false);        
        helper.updateProductFormsHelper(component, event, helper);
    },
    
    handleCheckBoxChange: function (component, event, helper) {
        var listOfSelections = event.getParam("value");
        
        var listOfSelectionsString = '';
       
        for(let i=0; i<listOfSelections.length;i++){
            let op = listOfSelections[i];
            if(i ==0){
               listOfSelectionsString = op;
               
            }
            else{
                listOfSelectionsString = listOfSelectionsString+','+op;
            }
            
        }
        var questionId = event.getSource().get("v.name").split(":")[1];
        
        var response = component.get("v.questionResponse");
        for(let i=0;i<response.length;i++){
            let question =response[i]; 
            if(question.Survey_Question__c == questionId){
                question.Response__c = listOfSelectionsString;
                console.log(question);
            }
            
            
        }
        
        
    },
    
    uploadFile: function(component, event, helper){
     helper.uploadAttachmentsHelper(component);
        
    },
    closeSuccess: function(component, event, helper){
     component.set("v.classicToastSuccess",null);
        
    },
    closeError: function(component, event, helper){
     component.set("v.classicToastError",null);
        
    }
   
    
    
})