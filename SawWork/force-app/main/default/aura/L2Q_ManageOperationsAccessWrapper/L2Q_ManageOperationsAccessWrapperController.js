({
    init : function(component, event, helper) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1));
        var sURLVariables = sPageURL.split('&');
        var sParameterName;
        var contactId;
        var retUrl;
        for (var i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');
            if(sParameterName[0] === 'id') {
                contactId = sParameterName[1];
            }
        }
        console.log('contactId : ' + contactId);
        component.set("v.contactId", contactId);
    }
})