({
    /*
    *  Fire page change event with new page number and current records counts
    *  This will be handled by Table and Footer component
    * */
	openthePage : function(component, event, helper) {
	    var myEvent = $A.get("e.c:CommunityBlogPageChangeEvt");
        var pageNumber = component.get("v.pageNumber");
        myEvent.setParams({
            "pageNumber": pageNumber,
            "currnetPagesCount": component.get("v.currnetPagesCount")
        });

        myEvent.fire();
	}
})