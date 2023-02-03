({
    
	onGroup: function(cmp,evt, helper) {

    	helper.updateState(cmp,evt);
	},
    handleAccountChange: function (cmp,evt,helper) {
        helper.updateAccount(cmp,evt);
    }

    // handleAccountChange: function (cmp,evt) {
    //     // render this component & set the AccIds
    //     var context = evt.getParams("acc"); 
    //     cmp.set("v.acc", context);

    //     var acc = cmp.get("v.acc");
    //     if((this.isEmpty(acc)) || (!acc.length>0)) {
    //         console.log('acc is empty.');
    //         cmp.set("v.doneLoading", false);
    //     } else {
    //         console.log('acc not empty.');
    //         cmp.set("v.doneLoading", true);                    
    //     }   
    //     console.log('acc=' + opptys);

    // }
    /* 
     * handleApplicationEventFired : function(cmp, event) {
        var context = event.getParam("context");
        cmp.set("v.mostRecentEvent",
            "Most recent event handled: APPLICATION event, from " + context);
        var numApplicationEventsHandled =
            parseInt(cmp.get("v.numApplicationEventsHandled")) + 1;
        cmp.set("v.numApplicationEventsHandled", numApplicationEventsHandled);
    	}
	*/
})