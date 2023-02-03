({
	doInit : function(component, event) {
            var sPageURL = decodeURIComponent(window.location.search.substring(1));
        	var sURLVariables = sPageURL.split('&');
        	var sParameterName ;
        	var contentVersionId;
        	for (var i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');
                if(sParameterName[0] === 'id') {
                    contentVersionId = sParameterName[1];
                }
            }
        	console.log("Param : " + contentVersionId);
			component.set("v.contentVersionId", contentVersionId);
    }
})