({
	closeQA : function() {
		// var urlEvent = $A.get("e.force:navigateToURL");
        // urlEvent.setParams({
        //   "url": "www.google.com"
        // });
		// urlEvent.fire();
		window.location.reload();

		$A.get("e.force:closeQuickAction").fire(); // trigger standard method to close the quick action popup
		$A.get('e.force:refreshView').fire(); 
	}
})