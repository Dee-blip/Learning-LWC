({
	gotoRecord : function(component, event, helper){
        console.log('inside gotorec');
    },
    selectList : function(component, event, helper) {
		helper.fetchDealDetails_dummy(component, event, false);
        console.log("inside navigateToListRecords");
        
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:SF1_ListView_Records",
            componentAttributes: {
                listName : component.get("v.listName"),
                sObjectName : component.get("v.sObjectName")
            }
        });
        evt.fire();
    }
})