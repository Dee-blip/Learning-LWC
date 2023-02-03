// SFDC-2407 Added by Mayank Bansal 13th March 2018
({
    doInit: function (component,event,helper) {
    	helper.setActivityTableColumns(component);  
    	helper.setActivityTableData(component);  
    },
    updateColumnSorting: function(component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }

})