({
    doInit : function(component, event, helper) {
        helper.getApprovalHistory(component,event, helper);  
    },
    updateQuickCMR : function (component, event, helper) {
        var show = event.getParam("showQuick");
        if( show != false){
            var change = component.get("v.change");
            var changecmr = event.getParam("changecmr");
            component.set("v.change",changecmr);
            helper.getApprovalHistory(component,event, helper);
            helper.showActions(component);
            
        }
        
    },refreshPreviewCMR : function (component, event, helper) {
        //get the latest change data from event

        if (event !== null && typeof event.getParam === 'function' && event.getParam("quickAction") && event.getParam("quickAction") !== 'updateAndRefreshRecords') {
            return;
        }

        var updatedChange=event.getParam("change");
        if(updatedChange!="Undefined" && updatedChange!=null){
            component.set("v.change",updatedChange);
        }
        //set that data to change variable
        helper.getApprovalHistory(component,event, helper);  
    },hideQuickView :function(component, event, helper){
        var cmpEvent = component.getEvent('showPreview');
        cmpEvent.setParams({"showPreview":false}).fire();
        var showcmr = $A.get("e.c:HD_CMR_UpdateCMRID");
        showcmr.setParams({"showQuick": false}).fire();
    },showhide_info : function(component, event, helper){
        helper.showhide(component);
    },sectionOne : function(component, event, helper) {
       helper.helperFun(component,event,'articleOne');
    } 
})