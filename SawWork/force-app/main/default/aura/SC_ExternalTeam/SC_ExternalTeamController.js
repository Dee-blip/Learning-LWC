({
	init : function(component, event, helper) 
    {
        //Aditi - added code for passing console/non-console to lwc for ESESP-5423
        var workspaceAPI = component.find("workspace");
        
        //var para = component.get("v.pageReference").state.additionalParams;
        //console.log('PARA : ' + component.get("v.pageReference").state);
        
        var escId = component.get("v.recordId");

        if(typeof(component.get("v.recordId")) !== 'undefined')
        {
            component.set("v.escRecordId", escId);

            //if(typeof(para) !== 'undefined' && component.get("v.pageReference").state !== 'undefined')
            console.log(component.get("v.pageReference"));

            if(component.get("v.pageReference") !== 'undefined' && component.get("v.pageReference") != null)
            {
                var a = component.get("v.pageReference").state.c__caseRecId;
                component.set("v.caseRecId", a);
                console.log('CASE REC ID : ' + a);
            }
        }
       /* else
        if(typeof(para) !== 'undefined' && component.get("v.pageReference").state !== 'undefined')
        {
            console.log('2');
            var a = component.get("v.pageReference").state.c__caseRecId;
            component.set("v.caseRecId", a);
        }*/


        //Aditi - added code for passing console/non-console to lwc for ESESP-5423
        workspaceAPI.isConsoleNavigation().then(function(consoleResponse) {
            console.log("IsConsole: ", consoleResponse);
            if (consoleResponse) {
                component.set("v.isConsole", true);
            }
            else{
                component.set("v.isConsole", false);
            }
        });
        console.log("isConsole ::"+component.get("v.isConsole"));
    },

    //Aditi - added extra event to get the url from lwc to close previous tab and open the created record when clicked on save button
    getDatafromEvent : function(component,event){

        console.log("value of url from lwc ::"+event.getParam("baseURL"));
        component.set("v.urltoGoTo",event.getParam("baseURL")); //storing the url passed in custom event

    },
    
    handleFilterChange : function(component){

        console.log("value of url from lwc ::"+component.get("v.urltoGoTo"));

        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response){
            var focusedTabId = response.tabId;
            //aditi - at first we are opening the new tab and then closing the previous tab in case of success from returned promise
            workspaceAPI.openTab({
                url: component.get("v.urltoGoTo"),
                focus: true
            })
            .then(function(){
                workspaceAPI.closeTab({tabId: focusedTabId});
            })
            .catch(function(error){
                console.log(error);
            });
        })
        .catch(function(error){
            console.log(error);
        });
    }
})