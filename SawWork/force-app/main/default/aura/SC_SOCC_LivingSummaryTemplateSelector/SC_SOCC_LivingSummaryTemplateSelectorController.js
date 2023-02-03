({
    init : function(component) {
        var action = component.get("c.getLivingSummaryDetails");
        
        action.setCallback(this, function(response) {
            var returnval = response.getReturnValue();
            if (returnval !== "null" || returnval !== null) {
                
                returnval.forEach(function(record){
                    record.text = record.Name;
                });
                returnval.forEach(function(record){
                    record.value = record.Id;
                });
                component.set('v.options', returnval);
                component.set("v.SummaryID",returnval[0].Id);
                
            }
        });
        $A.enqueueAction(action);
    },
    
    showLivingSummaryTemplate:function(component) {
        var templateid=component.find('SummaryId').get('v.value');
        component.set("v.SummaryID",templateid);
        
        
    },
    ChooseLSTemplate:function(component, event, helper) {
        var LSData = component.find("input_LS").get("v.value");
        var action = component.get("c.getLivingSummaryBody");
        action.setParams({
            "LSid": component.get("v.SummaryID")
        });
        
        action.setCallback(this, function(response) {
            var lsbody=response.getReturnValue();
            if(LSData!=null){
                LSData=lsbody+LSData;}
            else
            {LSData=lsbody;}
            component.find("accordion").set('v.activeSectionName', 'LS');
            component.find("input_LS").set("v.value", LSData);
            helper.showToastMessage(component, event, helper,'Template Appended!','Please click on the save button to save the LS Template!','warning','dismissible');   
            
            
        });
        $A.enqueueAction(action);
    },
    update:function(component, event, helper) {
        component.find("editForm").submit();
        helper.showToastMessage(component, event, helper,'Saved!','Living Summary has been updated','success','dismissible');

    },
    ReloadPage:function() {
        $A.get('e.force:refreshView').fire();
    },
    updateandauthorize:function(component, event, helper) {
        var action;
        component.set("v.loaded","true");
        component.find("editForm").submit();
        action = component.get("c.UpdateImageBanner");
        action.setParams({
            "caseId": component.get("v.recordId"),
            "imageBanner":'Managed Security: Contact Authorized'
        });
        action.setCallback(this, function(response) {
            var returnval = response.getReturnValue();
            if (returnval === "success") {
                component.set("v.loaded","false");
                helper.showToastMessage(component, event, helper,'Done!','Case has been authorized.','success','dismissible');
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                helper.showToastMessage(component, event, helper,'Error',returnval,'error','dismissible');
                component.set("v.Spinner","false");
            }
        });
        $A.enqueueAction(action);

    },
    showSummaryEditorModal: function (cmp){
        cmp.set("v.showSummaryEditorModal",true);
        cmp.find("input_LS_Modal").set("v.value",cmp.find("input_LS").get("v.value"));
    },
    hideSummaryEditorModal: function (cmp){
        cmp.set('v.showSummaryEditorModal',false);
    },
    updateLivingSummaryFromModal : function (cmp,event,helper){
        cmp.find("editFormInModal").submit();
        helper.showToastMessage(cmp, event, helper,'Saved!','Living Summary has been updated','success','dismissible');
        cmp.set('v.showSummaryEditorModal',false);
    }
    
})