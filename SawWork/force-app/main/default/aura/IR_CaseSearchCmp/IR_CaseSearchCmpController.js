({
    init : function(component, event, helper){
        helper.init(component, event, helper);
    },

    clearFilter : function(component, event, helper) {
        var caseTable = component.find('caseTable');
        caseTable.clearFilter(); 
    },

    applyFilter: function(component, event, helper){
        component.set('v.applyFilter', true);
        var caseTable = component.find('caseTable');
        caseTable.applyFilter();
    }
})