/*Customer Community Component*/
({
    /*
    *  Fire page change event with new page number and current records counts
    *  This will be handled by Table and Footer component
    * */
	playTheVideo : function(component, event, helper) {

	    var myEvent = $A.get("e.c:CommunityVideoEvt");
        var videoId = component.get("v.videoId");
        var videoTitle = component.get("v.videoTitle");

        myEvent.setParams({
            "videoId": videoId,
            "videoTitle": videoTitle
        });

        myEvent.fire();
	}
})