({
    navigateToObject : function(recordToNavigate) {

        var sObectEvent = $A.get("e.force:navigateToSObject");
        sObectEvent.setParams({
        "recordId": recordToNavigate,
        "slideDevName": "detail"
      });
        sObectEvent.fire();    

    }, 
})