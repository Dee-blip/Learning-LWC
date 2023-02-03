({
    init: function (component, event, helper) {
        
        var childcmp=component.get("v.isChildComponent");   
          var action = component.get("c.getCaseProductList");
        if(childcmp=='true'){
            action.setParams({
                "caseId": component.get("v.CaseRecID")
            });
        }
        else
        {	
            action.setParams({
                "caseId": component.get("v.recordId")
            });
        }
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
    },
    
    saveCaseProduct : function (component, event, helper){
        var newCaseProductId = component.find('caseProductId').get('v.value');
        component.set("v.Spinner", true);
        
        var action = component.get("c.saveProduct");
        var childcmp=component.get("v.isChildComponent");        
        if(childcmp=='true'){        
            action.setParams({
                "caseId": component.get("v.CaseRecID"),
                "newProductId":newCaseProductId
            });
        }
        else
        {
            action.setParams({
                "caseId": component.get("v.recordId"),
                "newProductId":newCaseProductId
            });
        }
        action.setCallback(this, function(response) {
            var retVal = response.getReturnValue();
            if (retVal === "success") {
                helper.showToastMessage(component, event, helper,'Success','Saved Successfully!','success','dismissible');
                $A.get('e.force:refreshView').fire();
            }
            else
                helper.showToastMessage(component, event, helper,'Error',retVal,'error','dismissible');
            component.set("v.Spinner", false);
        });
        $A.enqueueAction(action); 
    }
})