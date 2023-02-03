// Controllor Class for - SC_NewCase_Lightning.cmp 
({
    // Method which will be Invoked on Component Load
    calculateLightningOverrideLogic: function(component, event, helper) {
        
        //Added by aditi for ESESP-3222 : getting the base64 inContextOfRef from the URL
        var pageReference = component.get("v.pageReference");
        
        // If the call is from Standard New Button, then it returns Recordtype Id Else returns Null
        var userSelectedRecordTypeId = pageReference.state.recordTypeId;
        //var regex = new RegExp('^1\..*');
        var regex = new RegExp('^1[.].*');
        
        var state = pageReference.state; // state holds any query params
        var base64Context = state.inContextOfRef;
        var addressableContext;
        if (typeof base64Context !== "undefined" && regex.test(base64Context)) {
            base64Context = base64Context.substring(2);
            addressableContext = JSON.parse(window.atob(base64Context));
        }
        //Aditi code ends here
        
        // To Get the Parent Case Id From Sub Tab
        helper.returnParentCaseId(component,event,helper);
        
        // If RecordType Id present, then Call Case Creation Method Else Call Component
        if(typeof userSelectedRecordTypeId !== "undefined") { 
             
            helper.calculateParentAccount_CaseId_FromURL(component,event,userSelectedRecordTypeId,addressableContext);
        }
        else
        {
            //Calling LC Component for Custom Recordtype Selection
            component.set("v.isRecTypeSelectionPageDisplay", true);
        }
        
        
    }
    
})