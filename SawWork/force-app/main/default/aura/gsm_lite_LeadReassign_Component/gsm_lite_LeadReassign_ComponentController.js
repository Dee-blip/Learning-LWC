({
    doInit : function(component, event, helper) {
        helper.performInit(component);
        //MARIT-934
        helper.reAssignCTAProfileCheck(component);
        //helper.nullifyCancellationFields(component,event);
//        helper.nullifyCancellationPicklistFields(component,event);
    },
    handleChange: function (component, event, helper) {
        var changeValue = event.getParam("value");
        /*component.set("v.ownerId","");
        component.set("v.fieldToShowInSuggestion","");
        console.log('fields to show');
        console.log(component.get("v.ownerId"));
        console.log(component.get("v.fieldToShowInSuggestion")); */       
        //alert(changeValue);
        
        if(changeValue=='assignUser' || changeValue=='assignQ' || changeValue=='assignPU')
            helper.showUserModal(component,event,changeValue);
        else{
            var userIdModal = component.find("userId");
            helper.hideShowModal(userIdModal,true);
        }
           
    },
    handleOwnerChange: function(component, event, helper){
        component.set("v.message","");
    },
    saveLead: function (component, event, helper) {
        helper.saveAction(component,event);
    },
    backToLead: function(component, event, helper) {
        window.history.back();
        //helper.backToLead(component, event);
    }
})