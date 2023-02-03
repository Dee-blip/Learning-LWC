({
   
    adjust: function (cmp, event, helper){
        helper.adjustTableHeight(cmp);  
        helper.adjustTableWidth(cmp);
    },
    
    
    onSelect: function(component, event, helper)
    {
        var selectedItem = event.currentTarget; // Get the target object
        var index = selectedItem.dataset.record; // Get its value i.e. the index
        var recordRow = component.get("v.records")[index];
        component.set("v.previewFlag","true");
        component.set("v.selectedIncident",recordRow);
        
        var compEvent  = component.getEvent("showPreview");
        compEvent.setParams({
            "show-hide":true,
            "record": recordRow
        });
        compEvent.fire();
        
    },
    
    onClick : function(component,event){
        event.stopPropagation();
    },
    
    calculateWidth : function(component, event, helper) {
            var childObj = event.target
            var parObj = childObj.parentNode;
            var count = 1;
            while(parObj.tagName != 'TH') {
                parObj = parObj.parentNode;
                count++;
            }
            var mouseStart=event.clientX; 
            component.set("v.mouseStart",mouseStart);
            component.set("v.oldWidth",parObj.offsetWidth);
    },
     
    setNewWidth : function(component, event, helper) {
            var childObj = event.target
            var parObj = childObj.parentNode;
            var count = 1;
            while(parObj.tagName != 'TH') {
                parObj = parObj.parentNode;
                count++;
            }
            var mouseStart = component.get("v.mouseStart");
            var oldWidth = component.get("v.oldWidth");
            var newWidth = event.clientX- parseFloat(mouseStart)+parseFloat(oldWidth);
            if(newWidth>60)
            {
                parObj.style.width = newWidth+'px';
            }

    },
 
    sortColumn: function (cmp, event,helper) {
       var sortBy = event.currentTarget.dataset.field;
        var values = cmp.get("v.colApis");
        var labels = cmp.get("v.colLabels");
        var sortField ;
        if(sortBy<0)
        {
            cmp.set("v.selectedTabsoft", 'Name');
            sortField = 'Name';
        }
        else
        {
            cmp.set("v.selectedTabsoft", labels[sortBy]);  
            sortField = values[sortBy];
        }
        helper.sortHelper(cmp, event);
        var cmpEvent = cmp.getEvent("getChangeListEvent");
               
        var sortEvent = $A.get("e.c:HD_SortEvent");
        var sortDirection = cmp.get("v.sortDirection");
       
        cmpEvent.setParams({"sortBy":sortField,"sortDirection":sortDirection}).fire();       
  
    }    
    
})