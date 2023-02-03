({
	init: function(component, event, helper) 
    {
        var recordId = component.get("v.recordId");
        var recTypeId = '';
        var caseRec = '';
        var recType = 'Akatec';
        var currentShiftDet;
        var getCTRT;
        component.set("v.spinner",true);

        // get Case Details
        var caseDet = component.get("c.retCaseDetails");
        caseDet.setParams({
            "caseId":  recordId
        	});
        caseDet.setCallback(this, function(result)
        {
            caseRec = result.getReturnValue();
            component.set("v.caseObj",caseRec);
            
            // check if User can create Case Transition
            var canCreateCT = component.get("c.canCreateCT");
            canCreateCT.setParams({"caseObj": caseRec});
            console.log(caseRec.has_active_transition__c);
            canCreateCT.setCallback(this, function(result)
                                 {
                                     var res = result.getReturnValue();
                                     if(res == true)
                                         component.set("v.showNewCT",true);
                                     else
                                         component.set("v.hideNewCT",true);
                                     console.log("ShowNew? : " + res);
                                 });
            $A.enqueueAction(canCreateCT);
            
            // get Akatec Record Type ID for Case Transition
            //changes by Saiyam for ESESP-5957 - BOCC case transition.
            
            if(caseRec.Sub_Type__c === 'BOCC') {
                recType = 'BOCC';
            }
            
            // get Akatec Record Type ID for Case Transition
            getCTRT = component.get("c.getCaseTransRecTypeId");
            getCTRT.setParams({
                "recordTypeLabel": recType
            });
            
            getCTRT.setCallback(this, function(res)
            {           
                recTypeId = res.getReturnValue();
                component.set("v.akatecRecTypeId", recTypeId);
            });
            $A.enqueueAction(getCTRT);
            
            // get Current Shift
            //changes by Saiyam for ESESP-5957 - BOCC case transition.
            
            if(recType === 'BOCC')
                currentShiftDet = component.get("c.getCurrentShiftDetailsBOCC");
            else
                currentShiftDet = component.get("c.getCurrentShiftDetails");
            //currentShiftDet = component.get("c.getCurrentShiftDetails");
            currentShiftDet.setCallback(this,function(response)
                                        {
                                            var state = response.getState();
                                            if(state === "SUCCESS")
                                            {
                                                component.set("v.currentShift",response.getReturnValue());
                                            }
                                        });
            $A.enqueueAction(currentShiftDet);
        }); 
        
        $A.enqueueAction(caseDet);
        
        // get User Name
        var action = component.get("c.getUserName");
        action.setCallback(this, function(response)
        {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Name", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        
        
        component.set("v.spinner",false);
    },
    
    updateWakeupTime: function(component,event,helper)
    {
        var recType = 'Akatec';
        var getWakeTime; 
        var shift = "";
        shift = event.getParams("Target_Shift__c").value;
        
        var caseRec = component.get("v.caseObj");
        
        //changes by Saiyam for ESESP-5957 - BOCC case transition.
        
            if(caseRec.Sub_Type__c === 'BOCC') {
                recType = 'BOCC';
            }
        
        if(recType === 'BOCC') 
            getWakeTime = component.get("c.wakeUpTimeMethodBOCC");
        else
            getWakeTime = component.get("c.wakeUpTimeMethod");
        
        getWakeTime.setParams({
            "targetShiftTime": shift
        });
        
        getWakeTime.setCallback(this, function(result)
        {
            var res = result.getReturnValue();
            if(res !== "")
                component.set("v.blankShift",false);
            else
                component.set("v.blankShift",true);
            component.set("v.wakeupTime",res);                      
        });
        $A.enqueueAction(getWakeTime);
    },
    
    saveCaseTransition: function(component,event,helper)
    {
        component.set("v.blankShift",false);
        component.set("v.spinner",true);
        var err = false;
        
        if(component.get("v.currentShift") === component.find("targetShift").get("v.value"))
        {
            component.set("v.spinner",false);
            helper.showToastMessage(component, event, helper,"Same Shift? WHY!? 😑","Current Shift and Target Shift cannot be the same.","error","dismissable");
            err = true;
        }
        else
        if(!component.get("v.caseObj").Issue_Summary__c || !component.get("v.caseObj").Troubleshooting_to_Date__c
           || !component.get("v.caseObj").Data_Collected__c || !component.get("v.caseObj").Next_Action_Recommendation__c
           || !component.get("v.caseObj").Customer_Expectations__c
          )
           /*if(!component.get("v.caseObj").Issue_Summary__c .length() === 0 || !component.get("v.caseObj").Issue_Summary__c.trim()
           || !component.get("v.caseObj").Data_Collected__c || !component.get("v.caseObj").Customer_Expectations__c
           || !component.get("v.caseObj").Next_Action_Recommendation__c
           || component.get("v.caseObj").Issue_Summary__c === "" || component.get("v.caseObj").Troubleshooting_to_Date__c === ""
           || component.get("v.caseObj").Data_Collected__c === "" || component.get("v.caseObj").Customer_Expectations__c === ""
           || component.get("v.caseObj").Next_Action_Recommendation__c === ""
          )*/
        {
            component.set("v.spinner",false);
            helper.showToastMessage(component, event, helper,"Got to fill 'em all!","Please ensure all the Living Summary fields on the Case are filled","error","dismissable");
            err = true;
        }
        else
        if(component.find("targetShift").get("v.value") === "--None--" || component.find("targetShift").get("v.value") === "")
        {
            component.set("v.spinner",false);
            helper.showToastMessage(component, event, helper,"Gimme a target! 🎯","Please select a Target Shift","error","dismissable");
            err = true;
        }
       
        if(err === false)
        {
            var warmTransition = false;
            if(component.find("warmTrans").get("v.value") === true) 
                warmTransition = true;
            var targShift = component.find("targetShift").get("v.value");
            
            var saveCT = component.get("c.createTransitionRec");
            var caseRec = component.get("v.caseObj");
            saveCT.setParams({
                "caseRec": caseRec,
                "warmTrans": warmTransition,
                "targetShift": targShift
            });
            
            saveCT.setCallback(this, function(result)
                                    {
                                        component.set("v.blankShift",false);
                                        var res = result.getReturnValue();
                                        if(res === "success")
                                        {
                                            component.set("v.blankShift",false);
                                            helper.showToastMessage(component, event, helper,"Hurrah! 🥳","Case Transition created! Here's a 🍪","success","dismissable"); 
                                            $A.get('e.force:refreshView').fire();
                                        }
                                        else
                                        {
                                            helper.showToastMessage(component, event, helper,"Oops!",res,"error","dismissable"); 
                                            component.set("v.spinner",false);
                                        } 
                                    });
            $A.enqueueAction(saveCT);
        }
    }
})