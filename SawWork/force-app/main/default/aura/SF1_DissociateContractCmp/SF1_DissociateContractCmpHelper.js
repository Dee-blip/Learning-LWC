({
    dissociateContractsHelper: function(component, event, helper) {
        component.set("v.loading",true);
        var allContracts = component.get("v.listOfMergeContractHeader");
        var contractsToDelete = new Array();
        for(let contract of component.get("v.selectedContractList")){
            contractsToDelete.push(contract.Original_Contract_Id__c);
        }
        var selectedContractIds = new Array();
        for(let contract of allContracts ){
            if(!contractsToDelete.includes(contract.Original_Contract_Id__c)){
                
                var c = new Object();
                c.Id = contract.Id;
                c.Original_Contract_Id__c = contract.Original_Contract_Id__c;
                c.Currency__c = contract.Currency__c;
                
                selectedContractIds.push(c);
            }
            
        }
        
       
        
        var dissociateContract = component.get("c.disassociateContracts");
        
        dissociateContract.setParams({
            "opportunityID": component.get("v.opportunityID"),
            "contractsToRetain" :selectedContractIds
        });
        
        dissociateContract.setCallback(this, function(response) {
            var state = response.getState();
            var returnVal = response.getReturnValue();
           
            returnVal = JSON.parse(returnVal);
            if (component.isValid() && state === "SUCCESS") {
                
                if (returnVal.errorOccured) {
                     returnVal = JSON.parse(returnVal.returnMessage);
                    helper.setMessage(component, returnVal.returnMessage,"error");
                } else {
                   
                    helper.checkPermissionsAndLoadContracts(component,event,helper);
                    helper.setMessage(component, returnVal.returnMessage,"confirm");
                    
                }
            }
            component.set("v.loading",false);
        });
        $A.enqueueAction(dissociateContract);
        
    },
    loadContracts: function(component, event, helper){
        component.set("v.messageObject",null);
    var getContracts = component.get("c.getAssociatedContracts");
        
        getContracts.setParams({
            "opportunityID": component.get("v.opportunityID")
        });
        
        getContracts.setCallback(this, function(response) {
            var state = response.getState();
            var returnVal = response.getReturnValue();
            
            
            
            if (component.isValid() && state === "SUCCESS") {
                var productIds = new Array();
                for(let r of returnVal){
                    r.Contract_Product_Count__c = 'View ('+r.Contract_Product_Count__c+')';
                    if(r.Parent_Contract__c != null){
                        r.Parent_Contract__c = '/lightning/r/Merge_Contract_Header__c/'+ r.Parent_Contract__c+'/view';
                    }
                    else{
                        r.Parent_Contract__c = '';
                    }
                    if(r.Parent_Contract__r != null){
                        r.Parent_ContractName = r.Parent_Contract__r.Original_Contract_Id__c;
                    }
                    else{
                        r.Parent_ContractName = '-';
                    }
                    if(r.Parent_Account_Name__c != null){
                        r.Parent_Account_Name__c = '/lightning/r/Account/'+ r.Parent_Account_Name__c+'/view';
                    }
                    else{
                        r.Parent_Contract__c = '';
                    }
                    if(r.Parent_Account_Name__r != null){
                        r.Parent_AccountName = r.Parent_Account_Name__r.Name;
                    }
                    else{
                        r.Parent_ContractName = '-';
                    }
                    
                    for(let pr of r.Contract_Products__r){
                        productIds.push(pr.Forecast_Product_Id__c);
                    }
                    
                }
                component.set("v.listOfMergeContractHeader",returnVal);
                helper.loadProductNames(component, productIds);
                
            }
        });
        $A.enqueueAction(getContracts);
    },
    loadProductNames : function(component, productIds){
       
        var productNamesMethod = component.get("c.getProductNames");
        
        productNamesMethod.setParams({
            "akamProductIds": productIds,     
        });
        
        productNamesMethod.setCallback(this, function(response) {
            var state = response.getState();
            var productIdToName = response.getReturnValue();
           
            if (component.isValid() && state === "SUCCESS") {
                var contracts = component.get("v.listOfMergeContractHeader");
                for(let contract of contracts){
                    for(let pr of contract.Contract_Products__r){
                        pr['ProductName'] =  productIdToName[pr.Forecast_Product_Id__c];
                    }
                }
               component.set("v.listOfMergeContractHeader",contracts);
            }
            
        });
        $A.enqueueAction(productNamesMethod);
       
    },
    setMessage : function(component, message,type) {
       
        
        var messageObject = new Object();
        messageObject.text = message;
        messageObject.type = type;
        component.set("v.message",messageObject);
       
        
    },
    checkPermissionsAndLoadContracts : function(component, event, helper){
       
        var isDissociableSF1Method = component.get("c.isDissociableSF1");
        
        isDissociableSF1Method.setParams({
            "opportunityID": component.get("v.opportunityID")
        });
        
        isDissociableSF1Method.setCallback(this, function(response) {
            var state = response.getState();
            var permissionMessages = JSON.parse(response.getReturnValue());
            
            if (component.isValid() && state === "SUCCESS") {
                if(permissionMessages.errorOccured){
                    component.set('v.errorMessage',permissionMessages.returnMessage);
                }else{
                    component.set('v.errorMessage',null);
                    helper.loadContracts(component, event, helper);
                    
                }
            }
            
        });
        $A.enqueueAction(isDissociableSF1Method);
       
    },
    
})