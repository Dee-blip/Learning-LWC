({
    navigateToSelf : function(component,event,helper,formId) {
        
        
        helper.gotoURL(component,event,helper,formId , false);
        
        
    }, 
    navigateToSelfPub : function(component,event,helper,formId) {
        
        
        helper.gotoURL(component,event,helper,formId , true);
        
        
    },
    
    gotoURL : function (component,event,helper,formId, isPublish) {
        if(!component.get("v.isClassic")){
            var url = "/lightning/cmp/c__Sales_ERSS_NewForm?c__id="+formId;
            if(isPublish){
                url = url + "&c__pub=1" ;  
            }
            window.location.href = url;
        }
        else{
            var url = "/apex/Sales_ERSS_FormClassicPage?id="+formId;
            window.location.href = url;
        }
        
    },
    
    reviseFormHelper: function(component, event, helper){
        component.set("v.loading",true);
        var action = component.get("c.createRevisedForm");
        action.setParams({
            rSSFormId : component.get("v.existingRSSForm"),
            
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                var newFormId =  a.getReturnValue();
                
                helper.navigateToSelf(component, event, helper,newFormId);
                
            }
            else{
                console.log('error in Success');
                console.log(JSON.stringify(a.getError()));
                component.set("v.loading",false);
                if(component.get("v.isClassic")){
                    helper.showToastClassic(component,'Error in Creating Revision Version', a.getError()[0].pageErrors[0].message, 'error');
                    
                }else{
                    helper.showToast('Error in Creating Revision Version', a.getError()[0].pageErrors[0].message, 'error');
                    
                }
                
            }
        });
        $A.enqueueAction(action);
        
    },
    
    opportunitySetHelper : function(component, event, helper, oppId){
        
        if(oppId != null && oppId != ''){
            var action = component.get("c.getOpportunityFields");
            action.setParams({
                oppId : oppId,
                
            });
            action.setCallback(this,function(a){
                var state = a.getState();
                if(state == "SUCCESS"){
                    var map =  a.getReturnValue();
                    console.log(map);
                    component.set("v.accountInformation",JSON.parse(map));
                }
                else{
                    console.log('error in Success');
                    console.log(JSON.stringify(a.getError()));
                    component.set("v.accountInformation",null);
                }
            });
            $A.enqueueAction(action);
        }
        else{
            component.set("v.accountInformation",null);
        }
    },
    
    opportunitySetFormHelper : function(component, event, helper, formId){
        
        console.log('Entry');
        
        if(formId != null && formId != ''){
            var action = component.get("c.getOpportunityFieldsFromForm");
            action.setParams({
                formId : formId,
                
            });
            action.setCallback(this,function(a){
                var state = a.getState();
                if(state == "SUCCESS"){
                    var map =  a.getReturnValue();
                    console.log(map);
                    if(map != null && map != ''){
                        component.set("v.accountInformation",JSON.parse(map));
                        
                        
                        
                        
                        
                        component.set("v.published",JSON.parse(map).published);
                        // If we have Stage populated at backend then use it else compute on the fly
                        if(component.get("v.accountInformation").stage == null || component.get("v.accountInformation").stage == ''){
                            if(component.get("v.accountInformation").version != 0 && component.get("v.accountInformation").version != null){
                                if( !component.get("v.accountInformation").published){
                                    component.set("v.readOnlyMode", true);
                                    component.set("v.stage", "Voided");
                                }
                                else{
                                    component.set("v.stage", "Published");
                                    component.set("v.readOnlyMode", true);
                                }
                                
                            } 
                            else{
                                component.set("v.stage", "Draft");
                            }
                        }
                        else{
                            component.set("v.stage",component.get("v.accountInformation").stage);
                            if(component.get("v.stage") == 'Voided' || component.get("v.stage") == 'Published'){
                                component.set("v.readOnlyMode", true);
                            }
                        }
                        
                        
                    }                
                }
                else{
                    console.log('error in Success');
                    console.log(JSON.stringify(a.getError()));
                    component.set("v.accountInformation",null);
                }
            });
            $A.enqueueAction(action);
        }
        else{
            component.set("v.accountInformation",null);
        }
        console.log('Exit');
    },
    permissionHelper : function(component, event, helper){
        
        var rSSFormId = component.get("v.existingRSSForm");
        
        var action = component.get("c.getFormWriteAccess");
        
        action.setParams({
            rSSFormId : rSSFormId,
            
        });
        
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                console.log('Succ Success');
                var map =  a.getReturnValue();
                console.log('PermissionMap');
                console.log(map);
                component.set("v.permissionMap",map);
                if(component.get("v.permissionMap") != null){
                    if(component.get("v.permissionMap").profileAccess == false  ){
                        component.set("v.readOnlyMode", true);
                    }
                    
                    
                }
                
                
                
            }
            else{
                console.log('error in Success');
                console.log(JSON.stringify(a.getError()));
                
            }
        });
        $A.enqueueAction(action);
        
        
    },
    publishRSSFormHelper : function(component, event, helper){
        
        var publishComments = component.get("v.publishComments");
        var action = component.get("c.publishNewForm");
        action.setParams({
            rSSFormId : component.get("v.existingRSSForm"),
            publishComments : publishComments
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                
                var formId = a.getReturnValue();
                
                helper.gotoURL(component,event,helper,formId, true); 
                
                
                
                
            }
            else{
                console.log('error in Success');
                console.log(JSON.stringify(a.getError()));
                component.set("v.loading",false);
            }
        });
        $A.enqueueAction(action);
        
        
    },
    
    
    
    showToast : function(title, message,type) {
        var toastEvent = $A.get("e.force:showToast");
        var mode = 'dismissible';
        
        toastEvent.setParams({
            "mode":  mode,
            "title": title,
            "message": message,
            type : type
        });
        toastEvent.fire();
        
    },
    
    showToastClassic : function(component,title, message,type) {
        if(type=='error'){
            component.set("v.classicToastError",title+ ' '+message);
        }
        
        if(type=='success'){
            component.set("v.classicToastSuccess",title+ ' '+message);
        }
        
        
        
        
    },
    
    productQuestionInit : function(component, event, helper, isInit){
        component.set("v.showProducts", false);     
        var action = component.get("c.getRSSQuestionaire");
        action.setParams({
            rSSFormId : component.get("v.existingRSSForm"),
        });
        
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                console.log('get resp');
                
                console.log(a.getReturnValue());
                
                
                var arr = new Array();
                let resArray = new Array();
                var arrString = new Array();
                let invalidTemplateArray = new Array();
                let invalidTemplateArrayUnique = new Array();
                let map = new Map();
                for(let ob of a.getReturnValue()){
                    let product = ob.SurveyTaker__r.Survey__r ;
                    if(product.RSS_Published__c !=  true && !invalidTemplateArrayUnique.includes(product.Id)){
                        invalidTemplateArray.push(product);
                        invalidTemplateArrayUnique.push(product.Id);
                    }
                    
                    if(!arrString.includes(product.Name)){
                        
                        arr.push(product);
                        arrString.push(product.Name);
                    }
                    let q = ob.Survey_Question__r;
                    if(q.Choices__c!= null && q.Choices__c!= ''){
                        
                        let strList = q.Choices__c.split('\n');
                        q.Choices__c  = new Array();
                        if(q.Type__c == "Picklist"){
                            q.Choices__c.push({ label:'-select-',value: ''});
                        }
                        let iden = 0;
                        for(let s of strList){
                            if (s!='') {
                                let opt = { label:s+'',value: s+''};
                                if(q.Type__c == "Multi-Select--Vertical" ){
                                    opt.value=iden+'__' +opt.value;
                                    map.set(s,iden);
                                    iden++;
                                }
                                q.Choices__c.push(opt);       
                            }
                        }
                    }
                    // Handle multiselect Dynamically
                    if(q.Type__c == "Multi-Select--Vertical" ){
                        q.ResponseArray__c = new Array();
                        
                        if(ob.Response__c != null){
                            for(let sel of ob.Response__c.split(",")){
                                if (sel!=''){
                                    if(!sel.includes('__')){
                                        sel=  map.get(sel)+'__'+sel;
                                        q.ResponseArray__c.push(sel); 
                                    }
                                    else{
                                        q.ResponseArray__c.push(sel); 
                                    }
                                    
                                    
                                }
                            }
                        }
                        
                        console.log(component.find("questionMultiselect"));
                        // console.log(component.find('questionMultiselect').get("v.value"));
                        
                        
                    }
                    
                    
                    resArray.push(ob);
                }
                console.log('Updated q');
                console.log(resArray);
                component.set("v.productOptionsView",arr);
                component.set("v.questionResponse",resArray);
                
                component.set("v.invalidProductTemplates",invalidTemplateArray);
                
                if(!isInit){
                    if(component.get("v.isClassic")){
                        helper.showToastClassic(component,'ERSS Form saved successfully',' ','success');
                        
                    }else{
                        helper.showToast('ERSS Form saved successfully',' ','success');
                    }
                    
                }
                component.set("v.showProducts", true); 
                component.set("v.loading",false);
                
            }
            else{
                console.log('error in Success');
                component.set("v.loading",false);
            }
        });
        $A.enqueueAction(action);
    },
    saveproductsHelper: function(component, event, helper) {
        
        var action = component.get("c.saveRSSQuestionaire");
        action.setParams({
            response : component.get("v.questionResponse"),
        });
        
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                
                console.log('Saved products successfully');
                
                
            }
            else{
                
                console.log('error in Success');
                console.log(JSON.stringify(a.getError()));
                component.set("v.loading",false);
            }
        });
        $A.enqueueAction(action);
        
        
    },
    
    validateProducts: function(component, event, helper) {
        
        var valid = true;
        var i = 0;
        
        
        /*  while (i < component.find('question').length) { 
            var comp = component.find('question')[i];
            console.log(comp);
            console.log(comp.get('v.validity'));
            if(comp.get('v.validity') != null && !comp.get('v.validity').valid){
                comp.showHelpMessageIfInvalid();
                valid = false;
                
            }
            
            
            i++;
        }*/
        
        // Required attribute is not supported on Rich text
        // Do it Custom way
        var validRichText = true;
        var invalidTemplatesNAme = new Array();
        var newQuestionResponse = component.get('v.questionResponse');
        for(let j=0;j<newQuestionResponse.length;j++){
            var question =newQuestionResponse[j];
            
            if(question.Survey_Question__r.Required__c == true && 
               (question.Response__c ==null || question.Response__c =="")){
                question.error = 'true';
                validRichText = false;
                if(!invalidTemplatesNAme.includes(question.SurveyTaker__r.Survey__r.Name)){
                    
                    invalidTemplatesNAme.push(question.SurveyTaker__r.Survey__r.Name)
                }
            }
            else{
                question.error = 'false';
            }
        }
        if(!validRichText){
            component.set('v.questionResponse',newQuestionResponse);
            component.set("v.incompleteProducts",invalidTemplatesNAme); 
        }
        
        
        return valid && validRichText;
    },
    
    getPreviousVersions: function(component, event, helper){
        
        var action = component.get("c.getPreviousVersionsOfRSSForm");
        action.setParams({
            rSSFormId : component.get("v.existingRSSForm"),
        });
        
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                //alert(JSON.stringify(a.getReturnValue()));
                component.set("v.previousForms",a.getReturnValue());
                
                
            }
            else{
                
                console.log('error in Success');
                console.log(JSON.stringify(a.getError()));
            }
        });
        $A.enqueueAction(action);
    },
    
    leaveHandler: function(event) {
        // event.returnValue = "Are you sure you want to leave? All changes will be lost!";
    },
    preventLeaving: function(event) {
        // window.addEventListener("beforeunload", this.leaveHandler);
    },
    allowLeaving: function(event) {
        //window.removeEventListener("beforeunload", this.leaveHandler);
    },
    updateProductFormsHelper: function(component, event, helper){
        component.set("v.loading",true);
        var action = component.get("c.updateProductTemplates");
        action.setParams({
            rssFormId : component.get("v.existingRSSForm"),
        });
        
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                //alert("success");
                window.location.href = window.location.href;
            }
            else{
                component.set("v.loading",false);
                alert('Some Error Occurred');
                console.log(JSON.stringify(a.getError()));
            }
        });
        $A.enqueueAction(action);
        
    },
    setRecordTypeID: function(component, event, helper){
        var action = component.get("c.getInitFields");
        action.setParams({
            rssFormId : component.get("v.existingRSSForm"),
        });
        
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                var initObject = JSON.parse(a.getReturnValue());
                // set recordType id
                component.set("v.rSSFormRecordTypeId",initObject.recordtypeid);
            }
            else{
                
                alert('Some Error Occurred');
                console.log(JSON.stringify(a.getError()));
            }
        });
        $A.enqueueAction(action);
    },
    getDiffFromPreviousVersion: function(component, event, helper){
        var version = component.get("v.accountInformation").version;
        if(version != null && version >1){
            var action = component.get("c.getFormDiffFromPreviousVersion");
            
            action.setParams({
                formId : component.get("v.existingRSSForm"),
                oldVersion : version-1
            });
            
            action.setCallback(this,function(a){
                var state = a.getState();
                if(state == "SUCCESS"){
                    let returnValue = JSON.parse(a.getReturnValue());
                    component.set("v.diffText",returnValue);
                    component.set('v.diffModalOpen', true);    
                }
                else{
                    
                    helper.showToast('Could not produce Diff results for Version: '+version,JSON.stringify(a.getError()), 'error');
                    
                }
            });
            $A.enqueueAction(action);
        }
        else{
            helper.showToast('No previous version exist for this Form', 'Version: '+version, 'error');
            
        }
    },
    
    uploadAttachmentsHelper : function(component) {
        
        var action = component.get("c.getAttachments");
        
        action.setParams({
            
            'formId' : component.get("v.existingRSSForm"),
            
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS"){
                component.set("v.files",response.getReturnValue());
                
            }
            
            else{
                if(component.get("v.isClassic")){
                    
                    helper.showToastClassic(component,'Failed to Upload', 'Error', 'error');
                }else{
                    
                    helper.showToast('Failed to Upload', 'Error', 'error');
                    
                }
            }
        });
        
        $A.enqueueAction(action);
    }
    
})