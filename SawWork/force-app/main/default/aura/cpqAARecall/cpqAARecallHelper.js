({
    /**
     * showToast method is used to display toast messages to users
     * @param {string} title : specify title for a message to display
     * @param {string} message : custom message to display in the toast
     * @param {string} type : error, warning, success, or info
     * @param {string} mode : 'pester', 'sticky'. The default is 'dismissible'
     */
    showToast: function (title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            duration: ' 5000',
            key: 'info_alt',
            type: type,
            mode: mode
        });
        toastEvent.fire();
    }

})