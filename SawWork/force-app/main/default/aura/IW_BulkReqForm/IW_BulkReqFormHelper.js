({
    navigateTo: function(component, recId) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId
        });
        navEvt.fire();
    },

    showError : function(sMsg){
        debugger;
        cmp.set("v.msgTheme",'slds-theme_success');                 
        //alert(document.getElementById("msgPanelComp").style.display);
        cmp.set("v.isDispMsg","block");
        document.getElementById("msgPanel").innerHTML = sMsg;
    },

    showSuccess : function(sMsg){
        debugger;
        cmp.set("v.msgTheme",'slds-theme_success');                 
        //alert(document.getElementById("msgPanelComp").style.display);
        cmp.set("v.isDispMsg","block");
        document.getElementById("msgPanel").innerHTML = sMsg;
    },

    setToastVar: function(component, sMsg){
        debugger;
        console.log('component :::::::::::::::' + component);
        component.set("v.msgTheme",'slds-theme_error');                 
        //alert(document.getElementById("msgPanelComp").style.display);
        component.set("v.isDispMsg","block");
        document.getElementById("msgPanel").innerHTML = sMsg;

        /*console.log("--sMsg--"+sMsg);
        var type = "Error"; 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'sticky',
            //mode: 'dismissible',
            message: sMsg,
            type : type
            //duration:'5000',
        });
        toastEvent.fire();*/
    },
    setToastVarSuccess: function(component, sMsg){
        debugger;
        console.log('component :::::::::::::::' + component);
        /*var type = "Success"; 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'sticky',
            //mode: 'dismissible',            
            message: sMsg,
            type : type
            //duration:'5000',
        });
        toastEvent.fire();*/
        
        component.set("v.msgTheme",'slds-theme_success');                 
        //alert(document.getElementById("msgPanelComp").style.display);
        component.set("v.isDispMsg","block");
        document.getElementById("msgPanel").innerHTML = sMsg;
        if(sMsg === 'Success'){
           window.location.href = '/lightning/o/Investment_Workbox__c/list?filterName=Recent'; 
        }
    },
    waiting: function(component, event, helper) {
        component.set("v.HideSpinner", true);
    },
    doneWaiting: function(component, event, helper) {
       component.set("v.HideSpinner", false);
    },
    navigateToDetail: function(recordId){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
    
})