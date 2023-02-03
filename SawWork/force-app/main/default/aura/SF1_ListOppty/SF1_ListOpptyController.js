({

    renderOpportunities : function(component, event, helper) {
        //helper.getOpportunitiesByContractIds(component, event, component.get("v.page") || 0, helper.getSortOrder(component, true));
        helper.validateWithBaseLineEvent(component, event, helper);
    },

    handleOpptyTypeChange : function(component, event, helper) {
        helper.validateOpptyChangeEvent(component, event);
    },
    
    gotoRecord : function(component,event){
        //console.log('gotoRec:' + event.target.id);
        //var monkeyLove = event.getSource().getElement().getAttribute('name');
        
        var navigateToId = event.target.id;
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        console.log('sObjectEvent=' + sObjectEvent);
        sObjectEvent.setParams({
            "recordId": navigateToId,
            "slideDevName": 'detail'
        })
        sObjectEvent.fire();
    },
    

    gotoURL : function (component, event, helper) {
        var navigateToId = event.target.id;
        console.log('gotoRec:' + event.target.id);
        var urlEvent = $A.get("e.force:navigateToURL");
        console.log('sObjectEvent=' + sObjectEvent);
        urlEvent.setParams({
            "url": "/" + navigateToId
        });
        urlEvent.fire();
    },

    openModal2 : function(component, event, helper) {
// 006Q000000FLY9cIAH
        var opptyId = event.target.name;
        // var contractsMap = component.get("v.contractsMap");
        //var associatedContracts = [];
        var associatedContracts = helper.getAssociatedContracts(component, event, opptyId);
        console.log('listOppty:openModal=' + JSON.stringify(opptyId + '::' + JSON.stringify(associatedContracts)));

        $A.createComponent(
            "c:SF1_ViewContracts",
            {
                // "aura:id": "findableAuraId",
                "opptyId": opptyId,
                //"contracts": associatedContracts,
                "headerMsg": 'Associated Contracts'
             },
            function(msgBox){               
                if (component.isValid()) {
                    var targetCmp = component.find('OpptyModalPlaceholder');
                    var body = targetCmp.get("v.body");
                    body.push(msgBox);
                    targetCmp.set("v.body", body);
                }
            }
        );  
    },

    // automatically call when the component is done waiting for a response to a server request.  
    hideSpinner : function (component, event, helper) {
        var spinner = component.find('spinner3');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false }); 
        evt.fire();    
    },

 // automatically call when the component is waiting for a response to a server request.
    showSpinner : function (component, event, helper) {
        var spinner = component.find('spinner3');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();    
    },

    pagerecords : function (cmp,event,helper) {
        if (cmp.isValid()) { 
            cmp.set("v.page", event.getParam("pagevalue"));
            
            console.log('pagerecords:opptyMessageWithBaseline=' + cmp.get("v.opptyMessageWithBaseline"));
            (cmp.get("v.opptyMessageWithBaseline") ? helper.queryWithBaselineRows(cmp, cmp.get("v.page") || 0, helper.getSortOrder(cmp, true)) : helper.queryWithoutBaselineRows(cmp, cmp.get("v.page") || 0, helper.getSortOrder(cmp, true)));

        }
    },

    customSort : function(cmp,event,helper) {
        if (cmp.isValid()) {

            console.log('cmp-->' + JSON.stringify(cmp));
            var fieldAPIName = event.getParam("fieldid");
            cmp.set("v.sortField", fieldAPIName);
            cmp.set("v.page", event.getParam("pagevalue"));
            // helper.queryRows(cmp, cmp.get("v.page") || 0, helper.getSortOrder(cmp, true));
            // helper.getOpportunitiesByContractIds(cmp, event, cmp.get("v.page") || 0, helper.getSortOrder(cmp, true));

            console.log('customSort:opptyMessageWithBaseline=' + cmp.get("v.opptyMessageWithBaseline"));
            (cmp.get("v.opptyMessageWithBaseline") ? helper.queryWithBaselineRows(cmp, cmp.get("v.page") || 0, helper.getSortOrder(cmp, true)) : helper.queryWithoutBaselineRows(cmp, cmp.get("v.page") || 0, helper.getSortOrder(cmp, true)));
            
        }
    },
    
})