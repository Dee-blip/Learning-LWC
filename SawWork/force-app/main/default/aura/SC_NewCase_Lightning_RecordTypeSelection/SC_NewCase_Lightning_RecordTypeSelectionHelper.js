({
    // Method - 1 : Method to be invoked after recordtype Selection
    CallCaseCreationFromHomePageNewButton : function(component,event,userSelectedRecordTypeId) {
        //Variable for setting Navigation URL 
        var setNavigationURL;
        // Variable for Getting the PS Record Type Id
        var getPsRecTypeIdAction = component.get("c.getRecTypeId");
        getPsRecTypeIdAction.setParams({
            "recordTypeLabel": "Professional Services"
        });
        getPsRecTypeIdAction.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                userSelectedRecordTypeId = userSelectedRecordTypeId.substr(0,15);
                var getPsRecTypeId  = response.getReturnValue().substr(0,15); 
                // Logic for deriving Navigation URL
                if(userSelectedRecordTypeId == getPsRecTypeId){
                    setNavigationURL = '/apex/SC_EditCase?RecordType=' + getPsRecTypeId;
                    this.redirectCaseCreationLandingPage(component,event,setNavigationURL,'true');
                }
                else
                {
                    //setNavigationURL = '/one/one.app#/sObject/Case/new?recordTypeId='+userSelectedRecordTypeId+'&nooverride=1&retURL=/500';
                    this.redirectCaseCreationLandingPage(component,event,userSelectedRecordTypeId,'false');
                }
            }
            
        });
        $A.enqueueAction(getPsRecTypeIdAction);    
    },
    
    // Method - 2 : For Redirecting to Case Creation Page
    redirectCaseCreationLandingPage : function(component,event,navigationURL,isVFPageCall) {
        var delayInMilliseconds = parseInt ($A.get("$Label.c.SC_NewCase_Button_Delya_In_Milisecond"),10);
        var workspaceAPI = component.find("workspace");
        //Closing Main Tab
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
            
        });
        
        // If VF Page Call, then Call OpenTab function otherwise Call CreateRecord Method
        if(isVFPageCall == 'true'){
            workspaceAPI.openTab({
                url: navigationURL,
                label: 'New Case'
            }).then(function(response) {
                workspaceAPI.focusTab({tabId : response});
            });   
        }
        else{
            
            /* eslint-disable @lwc/lwc/no-async-operation */
            setTimeout(function() {
                $A.get("e.force:navigateToURL").setParams({ 
                    "url": '/one/one.app#/sObject/Case/new?recordTypeId='+navigationURL+'&nooverride=1&retURL=/500'
                }).fire();   
            }, delayInMilliseconds);   
        }
        
        //Closing Main Tab
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
            
        });
    },
    //Method - 3 : Code to check if the browser is chrome or Safari and applying corresponding CSS
    Add_Browser_dependant_CSS: function(component) {
    
            var GetUserAgentFromBrowser = navigator.userAgent.toLowerCase(); 
        if (GetUserAgentFromBrowser.indexOf('safari') != -1) 
        { 
            if (GetUserAgentFromBrowser.indexOf('chrome') > -1) 
            {
                var cmpTarget = component.find('footer');
                $A.util.removeClass(cmpTarget, 'changeSafari');
                $A.util.addClass(cmpTarget, 'changeChrome');
            } 
            else 
            {
                var cmpTarget = component.find('footer');
                $A.util.addClass(cmpTarget, 'changeSafari');
                $A.util.removeClass(cmpTarget, 'changeChrome');
            }
        }
        else
        {
             var cmpTarget = component.find('footer');
                $A.util.removeClass(cmpTarget, 'changeSafari');
                $A.util.addClass(cmpTarget, 'changeChrome');
        }
},
    
    //Code to Call apex method to get the details of active record types
    getRecordTypeDetails: function(component) {
        
        
        var action = component.get("c.fetchRecordTypeValues");
        action.setCallback(this, function(response) {
            
            var List_of_rec_type_label= response.getReturnValue();
            var generateJSON_For_RecordTypeSelection ='';
            var eachRecordType;  
            
            for (eachRecordType=0;eachRecordType<=List_of_rec_type_label.length-1;eachRecordType++)
            {
                generateJSON_For_RecordTypeSelection += ',{ \"value\":\"' + List_of_rec_type_label[eachRecordType] + '\" ,\"label\":\"' + List_of_rec_type_label[eachRecordType]+'\"}';
                
            }
            generateJSON_For_RecordTypeSelection=generateJSON_For_RecordTypeSelection.substring(1);
            generateJSON_For_RecordTypeSelection ='[ '+ generateJSON_For_RecordTypeSelection +']';
            component.set("v.lstOfRecordType", JSON.parse(generateJSON_For_RecordTypeSelection));
        	component.set("v.defaultRecordType", List_of_rec_type_label[0]);
            component.set("v.SaveDisabled",false);
        
        
        });
        
        $A.enqueueAction(action);
        
    
    },
    
    //Redirects to Case Creation Method
    Redirect_To_Case_Detail_Page: function(component, event,helper){
        
        // Getting User Selected RecordType Label Name
        var recordTypeLabel = component.get("v.defaultRecordType");
        
        // Getting User Selected RecordType Id from Apex
        var userSelectedRecordType;
        
        var action = component.get("c.getRecTypeId");
        action.setParams({
            "recordTypeLabel": recordTypeLabel.toString()
        });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                
                userSelectedRecordType  = response.getReturnValue();
                
                // Calling Case Creation Method
                helper.CallCaseCreationFromHomePageNewButton(component,event,userSelectedRecordType);
                
            }
        });
        
        $A.enqueueAction(action); 
    }
})