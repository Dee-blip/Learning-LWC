({
    /**
     * This function calls subscribe method of empApi component
     * to receive events
     * 
     * */
    subscribe: function(component, event, helper) {
        
        // Get the empApi component.
        var empApi = component.find("empApi");
        // Get the channel name from attribute
        var channel = component.get("v.channelName");
        //fetch latest events
        var replayId = -1;
        
        // Callback function to be passed in the subscribe call.
        // After an event is received, this callback fire a custom
        // event to notify parent component and pass payload object
        var subscribeCallback = function (message) {
            //Fire the component event to notify parent component
            var messageEvent = component.getEvent("onEmpEvent");
            if(messageEvent!=null) {
                messageEvent.setParam("empData", message.data);
                messageEvent.fire();                            
            }
            //Display event data in browser console
            console.log("Received [" + message.channel +
                        " : " + message.data.event.replayId + "] payload=" +
                        JSON.stringify(message.data.payload));
        }.bind(this);
    
        
        
        // Register error listener and pass in the error handler function.
        empApi.onError(function(error){
            console.log("Received error ", error);
        }.bind(this));
        
        // Subscribe to the channel and save the returned subscription object.
        empApi.subscribe(channel, replayId, subscribeCallback).then(function(value) {
            console.log("Subscribed to channel " + channel);
            component.set("v.subscription", value);
        });
    },
    
    /**
     * This function will be fired once the component is destroyed
     * It will call unsubscribe method of empApi component
     * 
     * */
    unsubscribe : function (component, event, helper) {
        // Get the empApi component.
        var empApi = component.find("empApi");
        // Get the channel name from attribute
        var channel = component.get("v.channelName");
        
        // Callback function to be passed in the unsubscribe call.
        var unsubscribeCallback = function (message) {
            console.log("Unsubscribed from channel " + channel);
        }.bind(this);
        
        // Error handler function that prints the error to the console.
        var errorHandler = function (message) {
            console.log("Received error ", message);
        }.bind(this);
        
        // Object that contains subscription attributes used to
        // unsubscribe.
        var subscription = {"id": component.get("v.subscription")["id"],
                            "channel": component.get("v.subscription")["channel"]};
        
        // Register error listener and pass in the error handler function.
        empApi.onError(function (error) {
            console.log("Received error ", error);
        }.bind(this));
        
        // Unsubscribe from the channel using the sub object.
        empApi.unsubscribe(subscription, unsubscribeCallback);
    },
})