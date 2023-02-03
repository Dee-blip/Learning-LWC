({
    // This is responsible to displaying an already linked person record to live chat when user loads.
	doInit: function (component, event, helper) {
        var personrecord = component.get("v.personrecordId");
        if (personrecord.startsWith('003')) {
            component.set("v.isPersonContact", true);
        } else {
            component.set("v.isPersonContact", false);
        }
    },
    openSubTab : function(component) {
        var workspaceAPI = component.find("workspace");
        console.log("Record ID: " + component.get("v.personrecordId"));
        workspaceAPI.getEnclosingTabId().then(function(enclosingTabId) {
            workspaceAPI.openSubtab({
                parentTabId: enclosingTabId,
                recordId: component.get("v.personrecordId"),
                focus: true
            });
        });
    }
})