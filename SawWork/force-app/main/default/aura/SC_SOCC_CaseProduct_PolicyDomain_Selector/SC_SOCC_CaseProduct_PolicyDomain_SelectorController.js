({
    init: function (component, event, helper) {
        
        var action = component.get("c.getCaseProductList");
        action.setParams({
            "caseId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            
            var retVal = response.getReturnValue();
            if (retVal=='null') {               
                component.set("v.haveProducts", false);                
            }
            else
            {var products = JSON.parse(retVal);
             //console.log('Products'+products);
             var selectedProductId;
             for(var eachProd in products){
                 if(products[eachProd]["selected"])
                 {selectedProductId = products[eachProd]["id"];}
             }
             
             component.set('v.options', products);
             // Set selectedProductId separately because it targets a race condition in which the options on the component does not reflect the new selected value.
             if(selectedProductId != null)
                 component.set('v.selectedValue', selectedProductId);
             else
                 component.set('v.selectedValue', products[0]["id"]);
             component.set("v.haveProducts", true);}
        });
        $A.enqueueAction(action);
        
        //Getting list of policy domains
        var action = component.get("c.getPolicyDomainList");
        action.setParams({
            "caseId": component.get("v.recordId"),
            "CaseProdID":null
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
                
                component.set('v.optionsPD', products);
                if(selectedProductId != null)
                    component.set('v.selectedValuePD', selectedProductId);
                else
                    component.set('v.selectedValuePD', products[0]["id"]);
                
                if (retVal.AssociatedSituationOptions != "null"){
                    //var situations = JSON.parse(retVal.AssociatedSituationOptions);
                    let situations = JSON.parse((retVal.AssociatedSituationOptions).replace(/\t/g,''));//Added as part of JIRA ESESP-4157
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
            {
                component.set("v.havePD", false);
                component.set("v.haveSituations", false);
            }
        });
        $A.enqueueAction(action);
    },
    
    //Method to save the Case Product and Policy Domain selected
    saveCaseProductandpd : function (component, event, helper){
        var newCaseProductId = component.find('caseProductId').get('v.value');
        if(component.get("v.havePD")){
            var newPDId= component.find('PolicyDomainId').get('v.value');}
        else
            var newPDId=null;
        
        if(component.get("v.haveSituations")) {
            var SitID= component.find('SituationId').get('v.value');
        }       
        else
            var SitID=null
            component.set("v.Spinner", true);
        var action = component.get("c.saveProduct");
        
        action.setParams({
            "caseId": component.get("v.recordId"),
            "newProductId":newCaseProductId,
            "newPolicyDomainId":newPDId,
            "newSituationID":SitID
        });
        action.setCallback(this, function(response) {
            var retVal = response.getReturnValue();
            if (retVal === "success") {
                helper.showToastMessage(component, event, helper,'Success','Case product, Policy Domain and Situation saved Successfully!','success','dismissible');
                $A.get('e.force:refreshView').fire();
            }
            else    
            {
                if(retVal.includes("association"))
                {
                    helper.showToastMessage(component, event, helper,'Oops!','The selected Case Product and Policy Domain do not match the account','error','dismissible');
                }
                else
                    helper.showToastMessage(component, event, helper,'Oops!',retVal,'error','dismissible');   
            }
            component.set("v.Spinner", false);
        });
        $A.enqueueAction(action); 
    },
    
    refreshentireselection:function (component, event, helper){
        component.set("v.Spinner", true);
        
        var CaseProdName= component.find('caseProductId').get('v.value');
        var action = component.get("c.getPolicyDomainList");
        action.setParams({
            "caseId": component.get("v.recordId"),
            "CaseProdID":CaseProdName
        });
        
        action.setCallback(this, function(response) {
            var retVal = response.getReturnValue();
            if (retVal.policyDomainOptions != "null") {
                component.set("v.havePD", true);
                component.set("v.Spinner", false);
                var products = JSON.parse(retVal.policyDomainOptions);
                var selectedProductId;
                for(var eachProd in products){
                    if(products[eachProd]["selected"])
                        selectedProductId = products[eachProd]["id"]
                        }
                
                component.set('v.optionsPD', products);
                // Set selectedProductId separately because it targets a race condition in which the options on the component does not reflect the new selected value.
                if(selectedProductId != null)
                    component.set('v.selectedValuePD', selectedProductId);
                else
                    component.set('v.selectedValuePD', products[0]["id"]);
                
                if (retVal.AssociatedSituationOptions != "null"){
                    //var situations = JSON.parse(retVal.AssociatedSituationOptions); 
                    let situations = JSON.parse((retVal.AssociatedSituationOptions).replace(/\t/g,''));//Added as part of JIRA ESESP-4157
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
            {
                component.set("v.havePD", false);
                component.set("v.haveSituations", false);
                component.set("v.Spinner", false);
            }
        });
        $A.enqueueAction(action);
    },
    
    refreshSituationselection:function (component, event, helper){
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