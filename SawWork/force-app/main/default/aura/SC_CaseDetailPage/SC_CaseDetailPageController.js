({
    //Method 1: Called on load of the component, to set the Ids of Related records(Account,Opportunity and OA) 
    doInit: function(component, event, helper)
    {  
        component.set("v.iconAcc","utility:chevrondown");
        component.set("v.iconOA","utility:chevrondown");
        var caseId = component.get("v.recordId");
        component.set('v.caseId',caseId);
        var getCaseDetails = component.get("c.fetchCaseDetails");
        getCaseDetails.setParams({
            "caseRecordId": caseId
        })
        
        getCaseDetails.setCallback(this, function(response){
            if(response.getState() == "SUCCESS")
            {
                var caseRec = response.getReturnValue();
                component.set('v.caseDetails',caseRec);
                component.set("v.accId",caseRec.AccountId);
                component.set("v.oppId",caseRec.Opportunity__c);
                component.set("v.oaId",caseRec.Order_Approval__c);
                if(caseRec.RecordType.Name == 'Order Approval-Order Management'){
                    component.set("v.isOpptyPromoId",true);
                }
            }
        });
        $A.enqueueAction(getCaseDetails);   
    },
    
    //Method 2: Called when there is any update on the case, to reload the Related records(Account,Opportunity and OA) 
    updateCase : function(component, event, helper)
    {        
        var oppDetailsTemp = component.find("oppDetails");
        oppDetailsTemp.set("v.oppRecordId",component.get("v.oppId"));
        oppDetailsTemp.reloadRecord(); 
        
        var accDetailsTemp = component.find("accDetails");
        accDetailsTemp.set("v.accRecordId",component.get("v.accId"));
        accDetailsTemp.reloadRecord(); 
        
        var oaDetailsTemp = component.find("oaDetails");
        oaDetailsTemp.set("v.oaRecordId",component.get("v.oaId"));
        oaDetailsTemp.reloadRecord(); 
    },
    changeState : function changeState (component)
    { 
        //var cmpTarget = component.find('oaSecId');
		//$A.util.toggleClass(cmpTarget, "toggle");
        //component.set("v.iconOA",component.get("v.iconOA")=="utility:chevronright"?"utility:chevrondown":"utility:chevronright");
    },
    changeStateAcc : function changeState (component)
    { 
        //var cmpTarget = component.find('accSecId');
		//$A.util.toggleClass(cmpTarget, "toggle");
        //component.set("v.iconAcc",component.get("v.iconAcc")=="utility:chevronright"?"utility:chevrondown":"utility:chevronright");
    }
})