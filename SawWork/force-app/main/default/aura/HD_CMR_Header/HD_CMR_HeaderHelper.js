({
	helperMethod : function() {
		
	},
    
    populateChange : function(component, event, helper){
        component.set("v.showApproval", false);
        var action = component.get("c.getChange"); 
        var RecordID = component.get("v.recordId");
        console.log('->> Record ID: '+RecordID);
        action.setParams({ Id : RecordID });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var statustxt = '';
                var ch = response.getReturnValue();
                console.log("CHANGE SUCCESS");
                console.log(ch);
                component.set("v.change", ch);
                console.log(" - "+ch.HD_Change_Status__c)
                if(ch.HD_Change_Status__c != 'OPENED' && ch.HD_Change_Status__c != 'CANCELLED' && ch.CR_Approval_Status__c != 'Recalled')
                {
                    component.set("v.showApproval", true);
                }
                var sttxt =  ch.HD_Change_Status__c;
                component.set("v.statusclass",sttxt.toUpperCase().replace(/ /g,''));
                component.set("v.st_hlp",statustxt);
            }else if (state === "ERROR") {
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
            }
            
        });
        
        $A.enqueueAction(action); 
        
    },
    
    populateActionApprovals: function(cmp, event, helper){
        var action = cmp.get("c.getApprovalHistory");
        var response="";
        console.log(" ..... Here .... ");
        console.log(cmp.get("v.recordId"));
        action.setParams({
            "currentCMRId" : cmp.get("v.recordId")
        });
        
       action.setCallback(this,function(data){
            var state=data.getState();
            if(state==="SUCCESS"){
                let arrayOfApprovedMapKeys=[];
                let arrayOfRejectedMapKeys=[];
                let arrayOfPendingMapKeys=[];
                let listOFActionsWhichCurrentUserCanPerform=[]; 
                let result=data.getReturnValue();
                
                for(var key in result){
                    
                    var tempValue=result[key].status;
                    if(tempValue=="Approved"||tempValue=="Submitted"){
                        arrayOfApprovedMapKeys.push(key);
                    }else if(tempValue=="Rejected"){
                        arrayOfRejectedMapKeys.push(key);
                    }else if(tempValue=="listOFActionsWhichCurrentUserCanPerform"){
                        listOFActionsWhichCurrentUserCanPerform=result[key].utilityList;
                    }else{
                        arrayOfPendingMapKeys.push(key);
                    }
                }
                var flag=arrayOfApprovedMapKeys.length;
                var arrayOfKeys;
                if(!(flag==1 && arrayOfRejectedMapKeys.length==0 && arrayOfPendingMapKeys==0)){
                    var arrayOfKeys=arrayOfApprovedMapKeys.concat(arrayOfRejectedMapKeys,arrayOfPendingMapKeys)
                }                
                try{
                    var listOfAllActions=listOFActionsWhichCurrentUserCanPerform;
                    var numberOfActions=listOfAllActions.length;
                    if(numberOfActions>4){
                        cmp.set("v.isDropDownMenuAvailable",true);
                        var listOfActionsDisplay=listOfAllActions.slice(0,3);
                        var listOfActionsMenuDisplay=listOfAllActions.slice(3,numberOfActions);
                        cmp.set('v.listOfActionsDisplay',listOfActionsDisplay);
                        cmp.set('v.listOfActionsMenuDisplay',listOfActionsMenuDisplay);
                    }else{
                        cmp.set('v.listOfActionsDisplay',listOfAllActions);
                    }
                }catch(Exception){
                    console.log(" ERROR OCCURED");
                }
            
                
                
                cmp.set('v.approvalsProgress',result);
                cmp.set('v.listOfActions',listOFActionsWhichCurrentUserCanPerform);
                cmp.set('v.lstKey',arrayOfKeys);
                cmp.set('v.flag',flag);
            }else if (state === "ERROR") {
                var errors = data.getError();
                HD_Error_Logger.createLogger(cmpt, event, helper, errors[0].message, errors[0].message, false);
            }
        });
        
        $A.enqueueAction(action);
        
    },
    
    shAppr : function(component,event,helper) {

        var rt_arr = component.find("rightArrow");
        var dw_arr = component.find("downArrow");
        var appr_tb = component.find("ApprTable");


            $A.util.toggleClass(dw_arr, 'slds-hide');
            $A.util.toggleClass(appr_tb, 'slds-hide');
            $A.util.toggleClass(rt_arr, 'slds-hide');
        
	}
})