({
    init: function(component, event, helper) 
    {
        var workspaceAPI = component.find("workspace");
        
        workspaceAPI.getFocusedTabInfo().then(function(response) 
                                              {
                                                  var focusedTabId = response.tabId;
                                                  workspaceAPI.setTabLabel({
                                                      tabId: focusedTabId,
                                                      label: "AMG Escalation"
                                                  });
                                                  workspaceAPI.setTabIcon({
                                                      tabId: focusedTabId,
                                                      icon: "standard:data_integration_hub",
                                                      iconAlt: "AMG Escalation"
                                                  });
                                              })
        .catch(function(error) {
            console.log(error);
        });
        
        component.set('v.loading', true);
        
        console.log('RECORD ID : ' + component.get("v.recordId"));
        
        if(typeof component.get("v.recordId") !== 'undefined')
        {
            component.set("v.newEscRec",false);
        }
        
        var amgEscRecTypeId = component.get("c.amgEscalationRecTypeId");
        amgEscRecTypeId.setCallback(this, function(response) 
        {
            if(response.getState() == "SUCCESS") 
            {
                var recTypeId = response.getReturnValue();
                component.set("v.amgEscRT",recTypeId);
            }
        });
        
    },
    
    afterRender: function(component,event,helper)
    {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) 
                                              {
                                                  var focusedTabId = response.tabId;
                                                  workspaceAPI.setTabLabel({
                                                      tabId: focusedTabId,
                                                      label: "AMG Escalation"
                                                  });
                                                  workspaceAPI.setTabIcon({
                                                      tabId: focusedTabId,
                                                      icon: "standard:data_integration_hub",
                                                      iconAlt: "AMG Escalation"
                                                  });
                                              })
        .catch(function(error) {
            console.log(error);
        });
        if(typeof component.get("v.recordId") !== 'undefined')
        {
            component.set("v.newEscRec",false);
            var sysVal = component.find("systemValEsc").get("v.value");
            if(sysVal === "JIRA")
                component.set("v.isJIRASystem",true);
            else
                component.set("v.isJIRASystem",false);
        }
    },
    
    systemChange: function(component,event,helper)
    {
        if(typeof component.get("v.recordId") !== 'undefined')
            var sysVal = component.find("systemValEsc").get("v.value");
        else
            var sysVal = component.find("systemVal").get("v.value");
            
        if(sysVal === "JIRA")
            component.set("v.isJIRASystem",true);
        else
            component.set("v.isJIRASystem",false);
    },
    
    handleLoad: function(component, event, helper) {
        component.set('v.loading', false);
    },
    
    handleError: function(component,event,helper)
    {
        component.set('v.loading', false);  
        //console.log(event.getParam('ouput')['errors'][0]['message']);
        //console.log(event.getParam("message"));
    },
    
    handleSuccess: function (component, event, helper) 
    {
        var param = event.getParams(); //get event params
        var payload = event.getParams();
        var fields = param.response.fields; //get all field info
        console.log(fields);
        var recordId = param.response.id; //get record id
        console.log('Record Id - ' + JSON.stringify(recordId)); 
        console.log('Record Id JUST ID- ' + recordId); 
        console.log(payload.id);
        
        component.set("v.newEscRecId",recordId);
        console.log("RECORD ID" + component.get("v.recordId"));
        
        if(typeof component.get("v.recordId") !== 'undefined')
            component.set("v.newEscRecId",component.get("v.recordId"));
        else
            component.set("v.newEscRecId",recordId);
        
        console.log('NEW ESC ID : ' +  component.get("v.newEscRecId"));
        
        $A.get('e.force:showToast').setParams({
            "title": "Success",
            "message": "Escalation saved!",
            "type": "success",
        }).fire();
        
        /*
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                "recordId": escId,
                "objectApiName": "Engagement_Request__c",
                "actionName": "view"
            }
        }
        */
        //var navService = component.find("navService");
        //event.preventDefault();
        //navService.navigate(pageReference);
        //helper.closeTab(component, event);
        
        helper.closeFocusedTabAndOpenNewTab(component,event);
    },
    
    
    closeFocusedTab : function(component, event, helper) 
    {
        helper.closeTab(component, event);
    },
    
    handleSubmit: function(component, event, helper) 
    {
        component.set('v.loading', true);
        event.preventDefault();
        component.find('newEscForm').submit();
        
        //component.find('newEscForm').submit();
        
        /*
        var escFieldValues = event.getParam("fields");
        event.preventDefault();
        console.log(JSON.stringify(escFieldValues));
        
        var newEsc = component.get("c.createEscalation");
        newEsc.setParams({
            escFields: JSON.stringify(escFieldValues)
        });

        newEsc.setCallback(this, function(result)
                              {
                                  var state = result.getState();
                                  if (state === "SUCCESS") 
                                  {
                                      //console.log('RETURN VALUE' + result.getReturnValue());
                                  }
                                  
                              }); 
        $A.enqueueAction(newEsc);
        */
    }
})