({
	doInit : function(cmp,event,helper){
		helper.queryAssociatedContracts(cmp,event,helper);
	},

	closeContractModal : function(cmp,event,helper){
        helper.closeModal(cmp);
    },

    gotoRecord : function(component,event){
        console.log('sf1_viewContracts:gotoRec:' + event.target.id);
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

})