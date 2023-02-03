({
    doInit : function(component, event, helper) {
        var incId = component.get("v.recordId");
        var action = component.get("c.getIncident");
        action.setParams({
            incidentId : incId
        });
        action.setCallback(this,function(data){
            var state = data.getState();
            if(state == 'SUCCESS'){
                console.log("success");
                var retVal = data.getReturnValue();
                console.log(retVal);
                //Setting up pre existing value for the incident
                component.set("v.uiSbi",retVal.HD_System_Admin_Incident__c);
                if(retVal.HD_System_Admin_Incident__c==true){
                    component.set("v.sbi",true); 
                }
                if(retVal.Notify_dl_sysadmin_on_creation__c==true && retVal.Notify_dl_sysadmin_on_status_change__c == true && retVal.HD_Notify_DL_EIS_on_Notes_Update__c == true){
                    component.set("v.dlEIS",true);
                }
                if(retVal.Notify_dl_sysadmin_on_creation__c==true || retVal.Notify_dl_sysadmin_on_status_change__c == true || retVal.HD_Notify_DL_EIS_on_Notes_Update__c == true){
                    component.set("v.ntfy",true);
                }else{
                    component.set("v.dlEIS",false); 
                }
                
                component.set("v.whitehatincid",retVal.HD_WhiteHat_Incident__c); 
                component.set("v.ntfyCreation",retVal.Notify_dl_sysadmin_on_creation__c); 
                component.set("v.ntfyStatus",retVal.Notify_dl_sysadmin_on_status_change__c); 
                component.set("v.ntfyNotes",retVal.HD_Notify_DL_EIS_on_Notes_Update__c);  
                
                
            }
            else if(state == 'ERROR'){
                console.log('Failed to get sysAdmin Values values');
                var errors = data.getError();
                console.log("Error in Change Priority-init") 
                console.log("---->" + errors[0].message);
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false, 'error');
                return;
            }
        });
        $A.enqueueAction(action);
    },
    changeSbi : function(component,event,helper)
    {
        var flag = component.find("uiSbi").get("v.checked");
        component.set("v.sbi",flag);  
        console.log('flag sbi '+flag);
        if(flag == false)
        {
            component.set("v.ntfy",flag);
        }
    },
    changeNtfy : function(component,event,helper)
    {
        var flag = component.find("dlEIS").get("v.checked");
        component.set("v.ntfy",flag); 
        component.set("v.ntfyCreation",flag); 
        component.set("v.ntfyStatus",flag); 
        component.set("v.ntfyNotes",flag); 
        console.log('flag ntfy '+flag);
        
    } ,
    checkNtfy : function(component,event,helper)
    {
        var ntfyCreation = component.get("v.ntfyCreation");
        var ntfyStatus = component.get("v.ntfyStatus");
        var ntfyNotes = component.get("v.ntfyNotes");
        
        if(ntfyCreation==false||ntfyStatus==false||ntfyNotes==false){
            component.set("v.dlEIS",false); 
        }
        if(ntfyCreation==true&&ntfyStatus==true&&ntfyNotes==true){
            component.set("v.dlEIS",true); 
        }        
    } ,
    convertToSysAdminIncident : function(component, event, helper) {
        var warningMessages = [];
        var index = 0;
        component.set("v.warnings"," ");
        var uiSbi=component.get("v.uiSbi");
        var dlEIS = component.get("v.dlEIS");
        var ntfyCreation = component.get("v.ntfyCreation");
        var ntfyStatus = component.get("v.ntfyStatus");
        var ntfyNotes = component.get("v.ntfyNotes");
        var whitehatincid = component.get("v.whitehatincid");
        
        if(uiSbi==false){
            dlEIS=whitehatincid=ntfyCreation=ntfyStatus=ntfyNotes=false;
        }
        
        component.set("v.warnings",warningMessages);
        
        if(warningMessages.length==0){
            var incId = component.get("v.recordId");
            var action = component.get("c.convertIncidentToSysAdminIncident");
            action.setParams({
                incidentId : incId,
                uiSbi : uiSbi,
                dlEIS : dlEIS,
                ntfyCreation : ntfyCreation,
                ntfyStatus : ntfyStatus,
                ntfyNotes : ntfyNotes,
                whitehatincid : whitehatincid
            });
            action.setCallback(this,function(data){
                
                var state = data.getState();
                if(state == 'SUCCESS'){
                    var data = data.getReturnValue();
                    console.log("return value "+data);
                    console.log(data);
                    $A.get('e.force:refreshView').fire();
                    console.log("firing refresh view event");
                    
                }
                else if(state == 'ERROR')
                {
                    
                    var errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false, 'error');
                    helper.doneWaiting(component);
                    $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
                    return;
                }
                helper.doneWaiting(component);
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
            });
            $A.enqueueAction(action);
            helper.waiting(component);
        }
        
    }
})