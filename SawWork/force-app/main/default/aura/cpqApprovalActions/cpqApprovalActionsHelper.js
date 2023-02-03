({
    /**
     * navigateToApprovalPage method is called to navigate the user to provided URL along with requested action type
     * @param {String} pageUrl : URL of the page to navigate
     * @param {String} actionType : Approve, Reject
     */
    navigateToApprovalPage: function (component, pageUrl, actionType) {

        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation()
            .then(consoleResponse => {
                if (consoleResponse) {
                    return workspaceAPI.getFocusedTabInfo();
                } else {
                    // Handle non-console user
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": pageUrl,
                    });
                    urlEvent.fire();
                }
            })
            .then(tabResponse => {
                var currentTabId = tabResponse.tabId;
                var currentTitle = tabResponse.title;
                var parentTabId = tabResponse.parentTabId;
                var isSubtab = tabResponse.isSubtab;
                // console.log("--Current Tab: ", currentTabId + " | " + currentTitle);
                // console.log("--Is Sub: ", isSubtab, " ParentId: ", parentTabId);

                component.set('v.currentTabId', currentTabId);

                // Open Visualforce Page in a new tab
                if (isSubtab) {
                    return workspaceAPI.openSubtab({
                        parentTabId: parentTabId,
                        url: pageUrl,
                        focus: true
                    });
                } else {
                    return workspaceAPI.openTab({
                        url: pageUrl,
                        focus: true
                    });
                }
            })
            .then(openSubResponse => {
                // console.log("--New SubTab Id: ", openSubResponse);
                component.set('v.newApprovalTabId', openSubResponse);
                return workspaceAPI.setTabLabel({
                    tabId: openSubResponse,
                    label: actionType
                });
            })
            .then(tabLabel => {
                console.log("-->tab label: " + tabLabel);
            })
            .catch(error => {
                console.log(error);
            });

    }
})