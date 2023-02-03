({
	setStatuses : function(component) {
        
        try{
        var currentCmr=component.get("v.change");
        var currentCmrStatus=currentCmr.HD_Change_Status__c;
        var currentCmrStatusApprovalStatus=currentCmr.CR_Approval_Status__c;
      }catch(Exception){
        
      }

         component.set("v.isAuthorized",false);
         component.set("v.isFailed",false);
        component.set("v.isCanceled",false);
          component.set("v.isClosed",false);
          component.set("v.isCompleted",false);
          component.set("v.isInProgress",false);
          component.set("v.isOpened",false);
          component.set("v.isSubmittedForApproval",false);
           component.set("v.isRejected",false);
            component.set("v.isRecalled",false);



        if(currentCmrStatus=="AUTHORIZED"){
            component.set("v.isAuthorized",true);
        }else if(currentCmrStatus=="AUTO FAILED"){
            component.set("v.isFailed",true);
        }else if(currentCmrStatus=="CANCELLED"){
            component.set("v.isCanceled",true);
        }else if(currentCmrStatus=="CHANGE FAILED"){
            component.set("v.isFailed",true);
        }else if(currentCmrStatus=="CLOSED"){
            component.set("v.isClosed",true);
        }else if(currentCmrStatus=="COMPLETED"){
            component.set("v.isCompleted",true);
        }else if(currentCmrStatus=="IN PROGRESS"){
            component.set("v.isInProgress",true);
        }else if(currentCmrStatus=="OPENED"){
            component.set("v.isOpened",true);
        }else if(currentCmrStatus=="PENDING APPROVAL"){
            if(currentCmrStatusApprovalStatus=="Recalled"){
              component.set("v.isRecalled",true);
            }else{
               component.set("v.isSubmittedForApproval",true);
            }
        }else if(currentCmrStatus=="REJECTED"){
            component.set("v.isRejected",true);
        }
		
	}
})