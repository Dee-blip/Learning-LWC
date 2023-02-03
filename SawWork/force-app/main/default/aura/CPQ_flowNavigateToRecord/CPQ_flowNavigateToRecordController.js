({    
    invoke : function(component, event, helper) {
        // Get the record ID attribute
        var record = component.get("v.recordId");
        var actionType = component.get("v.type");
        console.log('new recordId: '+record);
        console.log('actionType: '+actionType);
        
        var navLink = component.find("navService");
        // console.log('navLink: '+navLink);
        var pageRef = {
            type: 'standard__recordPage',
            attributes: {
                actionName: 'view',
                objectApiName: 'SBQQ__Quote__c',
                recordId : record 
            },
        };
        navLink.navigate(pageRef, false);
    }
})