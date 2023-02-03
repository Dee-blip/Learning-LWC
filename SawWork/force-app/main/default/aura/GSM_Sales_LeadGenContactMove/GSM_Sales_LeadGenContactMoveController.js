({
    doInit : function(component, event, helper) {
        
        component.set('v.mycolumns', [
            {label: 'Contact Name', fieldName: 'Name', type: 'text'},
            {label: 'Title', fieldName: 'Title', type: 'text'},
            {label: 'Email', fieldName: 'Email', type: 'Email'},
            {label: 'Phone', fieldName: 'Phone', type: 'Phone '}
        ]);
        helper.loadContacts(component, event, helper);
    },
    updateSelectedText: function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.selectedRowsCount', selectedRows.length);
        
        component.set('v.selectedContactList',JSON.parse(JSON.stringify(selectedRows)));
        
    },
    filter : function(component, event, helper) {
        component.set("v.pageNumber",1);    
        component.set("v.contactList",[]); 
        helper.loadContacts(component, event, helper);
    },
    clearContacts: function(component, event, helper) {
        component.set("v.pageNumber",1);    
        component.set("v.contactList",[]); 
        component.set("v.filterExp",'');
        helper.loadContacts(component, event, helper);
    },
    
    moveContacts: function(component, event, helper){
        var num = component.get('v.selectedRowsCount');
        var msg ='Are you sure you want to move '+num+' Contact(s)?';
        if (!confirm(msg)) {
            
            return false;
        } else {
            
            helper.moveContactsHelper(component, event, helper);
        }  
    },
    
    
    loadMore:function(component, event, helper) {
        component.set("v.pageNumber",component.get("v.pageNumber")+1);
        helper.loadContacts(component, event, helper);
    }
    
})