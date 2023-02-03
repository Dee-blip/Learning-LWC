({
    doInit : function(component, event, helper) {
        component.set("v.CaseRecordID",component.get("v.recordId"));
        component.set("v.Spinner","true");
        var action = component.get("c.getCaseInitialSetupDetails");
        action.setParams({
            "caseId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            component.set("v.Spinner","false");
            var resp=response.getReturnValue();
            if(resp[0].Service_Category__c=='Internal'||resp[0].Service_Category__c=='SOA'||resp[0].Service_Category__c=='Non-Managed')
            {
                component.set("v.Optional","true");
            }
            if(resp[0].Service_Category__c==null)
            {
                component.set("v.CurrentStep","1");
            }
            else if(resp[0].Case_Product__c==null)
            {	        
                component.set("v.CurrentStep","2");
            }
                else if(resp[0].Policy_Domain__c==null )
                {
                    component.set("v.CurrentStep","3");
                    
                    var action = component.get("c.getPolicyDomainList");
                    action.setParams({
                        "caseId": component.get("v.recordId")
                    });
                    
                    action.setCallback(this, function(response) {
                        var retVal = response.getReturnValue();
                        if (retVal.policyDomainOptions != "null") {
                            var products = JSON.parse(retVal.policyDomainOptions);
                            var selectedProductId;
                            for(var eachProd in products){
                                if(products[eachProd]["selected"])
                                    selectedProductId = products[eachProd]["id"]
                                    }
                            
                            component.set('v.options', products);
                            // Set selectedProductId separately because it targets a race condition in which the options on the component does not reflect the new selected value.
                            if(selectedProductId != null)
                                component.set('v.selectedValue', selectedProductId);
                            else
                                component.set('v.selectedValue', products[0]["id"]);
                            component.set("v.haveProducts", true);
                            
                            //Getting associated situations
                            if (retVal.AssociatedSituationOptions != "null"){
                                var situations = JSON.parse(retVal.AssociatedSituationOptions);
                                var selectedSituationId;
                                for(var eachsit in situations){
                                    if(situations[eachsit]["selected"])
                                        selectedSituationId = situations[eachsit]["id"]
                                        }
                                
                                component.set('v.Situationoptions', situations);
                                if(selectedSituationId != null)
                                    component.set('v.SituationselectedValue', selectedSituationId);
                                else
                                    component.set('v.SituationselectedValue', situations[0]["id"]);
                                component.set("v.haveSituations", true);
                            }
                            else
                                component.set("v.haveSituations", false);
                        }
                        else
                            component.set("v.haveProducts", false);
                    });
                    $A.enqueueAction(action);
                    
                }
                    else
                    {
                        component.set("v.CurrentStep","4");
                    }
            
            
        });
        $A.enqueueAction(action);
        
    },
    
    savePolicyDomainjs : function (component, event, helper){
        var newPolicyId = component.find('PolicyDomainId').get('v.value');
        console.log(newPolicyId);
           var nullchecker=component.get('v.haveSituations');
        console.log('sit'+nullchecker);
        if(nullchecker==true){
            var newSituation = component.find('SituationIdselected').get('v.value');
            console.log(newSituation);
        }
        else
        {
            var newSituation =null;
        }
        component.set("v.Spinner", true);
        
        var action = component.get("c.savePolicyDomainandSituation");
        action.setParams({
            "caseId": component.get("v.recordId"),
            "newPolicyDomainId":newPolicyId,
            "newSituationID": newSituation
        });
        
        action.setCallback(this, function(response) {
            var retVal = response.getReturnValue();
            if (retVal === "success") 
            {
                helper.showToastMessage(component, event, helper,'Saved!','Policy Domain and Situation have been saved!','success','dismissible');
                component.set('v.CurrentStep','4');
                $A.get('e.force:refreshView').fire();
                
                
            }
            else
                helper.showToastMessage(component, event, helper,'Error',retVal,'error','dismissible');
            component.set("v.Spinner", false);
            
        });
        $A.enqueueAction(action); 
    },
    
    SaveandMoveon: function (component, event, helper){
        var SCData = component.find("Service_CategoryFieldValue").get("v.value");
        if(SCData=='Internal'||SCData=='SOA'||SCData=='Non Managed')
        {
            component.set("v.Optional","true");
        }
        component.find("editForm").submit();
        component.set("v.CurrentStep","2");
    },
    
    skipStep:function (component, event, helper){
        var currstep=component.get('v.CurrentStep');
        if(currstep=='3')
        {
            component.set('v.CurrentStep','4');
        }
        else
        {
            var action = component.get("c.UpdateImageBanner");
            action.setParams({
                "caseId": component.get("v.recordId"),
                "imageBanner":'Non Managed'
            });
            
            action.setCallback(this, function(response) {
                var retVal = response.getReturnValue();
                
                if (retVal === "success") 
                {
                    $A.get('e.force:refreshView').fire();
                    
                }
                else
                    helper.showToastMessage(component, event, helper,'Error',retVal,'error','dismissible');
            });
            $A.enqueueAction(action); 
            
        }
    },
    HeadBack:function (component, event, helper){
        var step=component.get('v.CurrentStep');
        if(step=='4')
        {
            component.set('v.CurrentStep','3');
        }
        else if(step=='3')
        {
            component.set('v.CurrentStep','2');
        }
        else
        {component.set('v.CurrentStep','1');}
    },
    sendEmail:function (component, event, helper){
        component.set("v.Spinner","true");
        
        var action = component.get("c.sendEmailToAccountTeam");
        action.setParams({
            "caseId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var returnVal = response.getReturnValue();
            if (returnVal === "Success") 
            {
                var action2 = component.get("c.UpdateImageBanner");
                action2.setParams({
                    "caseId": component.get("v.recordId"),
                    "imageBanner":'Managed Security: Policy Domain Pending'
                });
                
                action2.setCallback(this, function(response) {
                    var retVal = response.getReturnValue();
                    if (retVal === "success") 
                    {
                        helper.showToastMessage(component, event, helper,'Email has been sent!','The other case setup steps will be skipped!','success','dismissible');
                        $A.get('e.force:refreshView').fire();
                        component.set("v.Spinner","false");
                    }
                    else
                    { helper.showToastMessage(component, event, helper,'Error',retVal,'error','dismissible');
                     component.set("v.Spinner","false");}
                    
                });
                $A.enqueueAction(action2); 
            }
            else
            {
                helper.showToastMessage(component, event, helper,'Oops!',returnVal,'error','dismissible');
                component.set("v.Spinner","false");
            }
        });
        $A.enqueueAction(action); 
        
        
    },
    
    getsituations:function (component, event, helper){
        
        component.set("v.Spinner","true");
        var newPolicyId = component.find('PolicyDomainId').get('v.value');
        
        var action = component.get("c.getSituationsforPolicyDomain");
        action.setParams({
            "PolicyDomainId": newPolicyId,
            "caseId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var retVal = response.getReturnValue();
            if (retVal != "null") {
                var situations = JSON.parse(retVal);
                var selectedSituationId;
                for(var eachsit in situations){
                    if(situations[eachsit]["selected"])
                        selectedSituationId = situations[eachsit]["id"]
                        }
                
                component.set('v.Situationoptions', situations);
                if(selectedSituationId != null)
                    component.set('v.SituationselectedValue', selectedSituationId);
                else
                    component.set('v.SituationselectedValue', situations[0]["id"]);
                component.set("v.haveSituations", true);
                component.set("v.Spinner","false");
                
            }
            else
            {
                component.set("v.haveSituations", false);
                component.set("v.Spinner","false");
                
            }
            
        });
        $A.enqueueAction(action); 
        
        
    }
    
    
})