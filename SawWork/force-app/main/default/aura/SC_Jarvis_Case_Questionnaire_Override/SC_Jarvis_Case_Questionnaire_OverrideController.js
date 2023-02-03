({
    handleFilterChange: function(component,event,helper) {

        var parameter = event.getParam('record')? event.getParam('record') : event.getParam('object');
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if(isConsole)
            {
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    var urlToNavigate = parameter === "Case_Questionnaire__c" ? 
                    '/lightning/o/Case_Questionnaire__c/list?filterName=Recent'
                    :
                    '#/sObject/' + parameter + '/view';
    
                    workspaceAPI.openTab({
                        url: urlToNavigate,
                        focus : true
                    }).then(function(newTabId) {
                        workspaceAPI.focusTab({tabId : newTabId});
                    });            
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
    
            }
            else
            {
                if(parameter === "Case_Questionnaire__c")
                {
                    window.location = '/lightning/o/Case_Questionnaire__c/list?filterName=Recent';
                }
                else
                {
                    helper.navigateToObject(parameter);
                }
    
            }
        });

    },
})