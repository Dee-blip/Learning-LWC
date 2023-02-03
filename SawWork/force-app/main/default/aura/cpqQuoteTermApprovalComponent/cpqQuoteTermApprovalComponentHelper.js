({
    /**
     * showNotifaction method is used to display messages to users
     * @param {string} type success/error
     * @param {string} message custom message displayed to user
     */
    showNotification : function(component, type, message) {
        component.find('notifLib').showToast({
           
            "variant": type,
            "message": message,
                
        });
    },
    
})