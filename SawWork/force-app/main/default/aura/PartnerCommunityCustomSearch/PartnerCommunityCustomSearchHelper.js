({
    handleClick : function(component, event, helper) {
        console.log('handle click');
        component.set('v.loaded', !component.get('v.loaded'));
        var searchText = component.get('v.searchText');
        if (searchText == "" || searchText.length < 3) {
            console.log('search text less than 3');
            component.set('v.loaded',!component.get('v.loaded'));
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "mode" : 'dismissible',
                "type" : 'info', 
                "message": "Please enter at least 3 characters."
            });
            toastEvent.fire();
        } else {
            var action = component.get('c.searchForRecords');
            action.setParams({searchText: searchText});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    console.log('Reponse received for search');
                    var resultObj = response.getReturnValue();
                    console.log(resultObj);
                    //sessionStorage.setItem('customSearch--recordIds', JSON.stringify(ids));
                    sessionStorage.setItem('customSearch--records', resultObj);
                    component.set('v.loaded', !component.get('v.loaded'));
                    var navEvt = $A.get('e.force:navigateToURL');
                    navEvt.setParams({url: '/custom-search-results'});
                    navEvt.fire();
                }
            });
            $A.enqueueAction(action);
        }
    }
})