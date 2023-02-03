({
	init : function(component, event, helper) {
		helper.getData(component, event, helper);
	},

    handleSort : function(component,event,helper){
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function 
        helper.sortData(component,sortBy,sortDirection);
    },

    handleNext : function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        component.set("v.pageNumber", pageNumber+1);
        helper.getData(component, event, helper);
    },

    handlePrev : function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        component.set("v.pageNumber", pageNumber-1);
        helper.getData(component, event, helper);
    },

    handleFirst: function(component, event, helper) {
    	component.set("v.pageNumber", 1);
        helper.getData(component, event, helper);
	},

    clearFilter : function(component, event, helper) {
        helper.setDefaults(component);
        component.set('v.filter', {});
        component.set('v.applyFilterClicked', false);
        console.log('After clear: ', component.get('v.filter'));
        helper.getData(component, event, helper);
    },

    applyFilter: function(component, event, helper){
        helper.setDefaults(component);
        if(JSON.stringify(component.get('v.filter')) != '{}'){
	        helper.getData(component, event, helper);
        }
    }
    /*,

    handleLast: function(component, event, helper) {
        var dataSize = component.get("v.dataSize");
        var pageSize = component.get("v.pageSize");
        var lastPage;
        if(dataSize % pageSize == 0)
            lastPage = dataSize/pageSize;
        else
            lastPage = (dataSize/pageSize) + 1;

    	component.set("v.pageNumber", lastPage);
        helper.getData(component, event, helper);
	}
    */
})