({
	doInit : function(component, event, helper) {
        helper.getOpportunity(component);
        var action=component.get("c.AccountCreateAccess");
        action.setCallback(this,function(a){
            if(a.getState()==="SUCCESS"){
                var SIRecs=a.getReturnValue();
                component.set("v.CheckAccess",SIRecs);
               
            }
            else if(a.getState()==="ERROR"){
                $A.log("Errors",a.getError());
            }
        });
        $A.enqueueAction(action); 
	},
    
    doSearch : function(component, event, helper) {
      
      helper.AccSearch(component);
        
         
    },
    Navigate : function(component, event, helper) {
        var accessflag = component.get("v.CheckAccess");
       // alert(checkaccess);
        if(accessflag){
         var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:SF1_CreateNewAccountCmp",
            componentAttributes: {
                "recordId": component.get("v.recordId")
            }
        });
    evt.fire(); }else{

             var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": "Account_Creation_Request__c"
            });
            createRecordEvent.fire();
        
    }   
		
	},
    showSpinner: function(cmp, event, helper) {
       /*if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "block";
           }*/
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
        
    },
        
    hideSpinner : function(cmp,event,helper){
        /*if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "none";
           }*/
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    },
    toggleSpinner: function (cmp, event) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.toggleClass(spinner, "slds-show");
    },
    onChange : function(component, event, helper) {
        console.log('Key Change done');
        component.set("v.keyChange",true);
        component.set("v.offset",0);
      }
    
})