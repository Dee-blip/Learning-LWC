({
	toggleProgressBar: function(component,event,helper) {
        console.log('Inside toggle');
        if (component.get('v.isProgressing')) {
            // start
            console.log('Adding progress');
            component._interval = setInterval($A.getCallback(function () {
                var progress = component.get('v.progress');
                component.set('v.progress', progress === 100 ? 0 : progress + 1);
            }), 200);
        } else {
            // stop
            //component.set('v.isProgressing', true);
            console.log('Removing progress');
            component.set('v.isProgressing', false);
            clearInterval(component._interval);
        }
    }
})