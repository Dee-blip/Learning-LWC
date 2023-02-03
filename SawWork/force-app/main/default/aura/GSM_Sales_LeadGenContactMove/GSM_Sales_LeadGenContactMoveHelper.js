({
    loadContacts : function(component, event, helper) {
        var filterQuery = component.get("v.filterExp");
        if(filterQuery == null ||filterQuery.length == 0 || filterQuery.length>1){
            var page = component.get("v.pageNumber");
            component.set("v.loading",true);
            var getLeadGenContactsAction = component.get("c.getLeadGenContacts");
            getLeadGenContactsAction.setParams({
                query : filterQuery,
                pageNumber : page,
                currentAccountId :component.get('v.recordId'),
            });
            getLeadGenContactsAction.setCallback(this, function(data) {
                var state = data.getState();
                
                if (component.isValid() && state == "SUCCESS"){
                    
                    var mergedContactList = component.get("v.contactList");
                    if(page == 1){
                        component.set("v.contactList",data.getReturnValue()); 
                    }else{
                        mergedContactList = mergedContactList.concat(data.getReturnValue()); 
                        component.set("v.contactList",mergedContactList); 
                    }
                    
                    if( data.getReturnValue().length ==20){
                        component.set("v.showLoadMore",true);
                    }
                    else{
                        
                        component.set("v.showLoadMore",false);
                    }
                    
                    
                    
                    
                }
                component.set("v.loading",false);
            });
            $A.enqueueAction(getLeadGenContactsAction);
        }
    },
    moveContactsHelper: function(component, event, helper) {
        component.set("v.loading",true);
        var contacts = component.get('v.selectedContactList');
        console.log(contacts);
        
        var moveContactsAction = component.get("c.moveLeadGenContacts");
        moveContactsAction.setParams({
            contactsToMove : contacts,
            newAccountId : component.get('v.recordId'),
        });
        
        moveContactsAction.setCallback(this, function(data) {
            var state = data.getState();
            
            if (component.isValid() && state == "SUCCESS"){
                var returnValue = data.getReturnValue();
                if(returnValue.includes("success")){
                    helper.showToast("Success", "Contact moved successfully","Success"); 
                }else{
                    helper.showToast("Error", returnValue,"Error");
                }     
                component.set("v.pageNumber",1);
                component.set('v.selectedRowsCount', 0);     
                component.set('v.selectedContactList',[]); 
                component.set("v.contactList",[]);
                component.set("v.filterExp",null);
                
                helper.loadContacts(component, event, helper);
                
            }
            else if (state === "ERROR") {
                helper.showToast("Error", JSON.stringify(data.getError()),"Error");
                
                component.set("v.loading",false);
            }
            
        });
        $A.enqueueAction(moveContactsAction);
        
    },
    
    showToast : function(title, message,type) {
        var toastEvent = $A.get("e.force:showToast");
        var mode = 'dismissible';
        
        toastEvent.setParams({
            "mode":  mode,
            "title": title,
            "message": message,
            type : type
        });
        toastEvent.fire();
        
    }
})