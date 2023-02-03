({  
    // Method - 1 : Gets the details of active record types from Apex . And gets the default record type .
    fetchListOfRecordTypes: function(component, event, helper) {
        
        //Code to check if the browser is chrome or Safari and applying corresponding CSS
        helper.Add_Browser_dependant_CSS(component);
        
        //Code to Call apex method to get the details of active record types
        helper.getRecordTypeDetails(component);      
    },
    
    // Method - 2 : Redirects to Case Creation Method
    NewCaseDetailPage: function(component, event, helper) {
        helper.Redirect_To_Case_Detail_Page(component, event,helper);
    },
    
    // Method - 3 : For Close record types modal box 
    close: function(component, event, helper) {
        // Closing Main Tab
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        });
    }
    
})