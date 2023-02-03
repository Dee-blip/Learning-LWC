({
    doInit : function(component, event, helper) {
        
        var action = component.get("c.getwebupdateTaskDetails");
        action.setParams({
            "caseId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var returnval = response.getReturnValue();
            if (returnval != "null") {
                
                component.set('v.mycolumns', [
                    {label: 'Who?', fieldName: 'linkName', type: 'url', 
                     typeAttributes: {label: { fieldName: 'ContactName' }, target: '_self'}},
                    {label: 'Description', fieldName: 'linkTask', type: 'url', 
                     typeAttributes: {label: { fieldName: 'Description' }, target: '_self'}}
                ]);
                returnval.forEach(function(record){
                    record.linkName = '/'+record.WhoId;
                });
                returnval.forEach(function(record){
                    record.linkTask = '/'+record.Id;
                });
                returnval.forEach(function(record){
                    record.ContactName = record.Who.Name;
                });
                component.set('v.TaskWebUpdateList',returnval);
                component.set('v.OpenCount',returnval.length);
            }
        });
        $A.enqueueAction(action);		
    },
    closesection: function(component, event, helper)
    {
        /***Getting relevant dom in iteration***/
        var selectedItem = event.currentTarget;
        var id = selectedItem.dataset.id;
        var Elements = component.find('testli');
        var Elements2 = component.find('subEle');
        var buttonlist = component.find('buttonli');
        
        /**Method to get Object Length since it returns undefined if only one element is There**/
        var ElementsLength = helper.getLength(Elements);
        var Elements2Length = helper.getLength(Elements2);
        var buttonlistLength = helper.getLength(buttonlist);
        
        /*** If else block to differentiate operation when only one element is there vs multiple
         elements in Iteration ***/
        if(ElementsLength===1)
        {
            $A.util.toggleClass(Elements, "slds-hide");
            $A.util.toggleClass(Elements2, "slds-hide");
            var currenticon = buttonlist[i].get("v.iconName");
            var checkicon ='utility:chevrondown';
            
             if(currenticon===checkicon)
                    {
                        buttonlist[i].set("v.iconName",'utility:chevronright');
                    }
                    else
                    {
                    buttonlist[i].set("v.iconName",'utility:chevrondown');
                    }
            
        }
        
        else
        {
            for (var i = 0; i < ElementsLength; i++) {
                var val = Elements[i].getElement().getAttribute('data-id');
                
                if(val===id)
                {
                    $A.util.toggleClass(Elements[i], "slds-hide");
                    var currenticon = buttonlist[i].get("v.iconName");
                    var checkicon ='utility:chevrondown';
                    if(currenticon===checkicon)
                    {
                        buttonlist[i].set("v.iconName",'utility:chevronright');
                    }
                    else
                    {
                    buttonlist[i].set("v.iconName",'utility:chevrondown');
                    }
                }
                
                
            }
            for (var i = 0; i < Elements2Length; i++) {
                var val = Elements2[i].getElement().getAttribute('data-id');
                
                if(val===id)
                {
                    $A.util.toggleClass(Elements2[i], "slds-hide");
                }
                
                
            }
            
            
        }
        
                
    },
     openNewTab:function(component, event, helper) {
        var ID = event.target.id;
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId":ID,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                tabId: response
            }).then(function(tabInfo) {
            });
        }).catch(function(error) {
            console.log(error);
        });
    }
})