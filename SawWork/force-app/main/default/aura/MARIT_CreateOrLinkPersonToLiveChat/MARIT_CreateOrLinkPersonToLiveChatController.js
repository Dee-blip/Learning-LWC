({
	doInit: function (component, event, helper) {
        helper.doInitHelper(component, event, helper);
    },
    FindOrCreatePerson: function (component, event, helper) {
        component.set("v.islistPopulated", true);
        component.set("v.isFindorLinkButtonVisible", false);
    },
    // generates the list of person records based on the search box input
    handleClick : function(component, event, helper) {
        helper.handleClickHelper(component, event, helper);
    },
    ListItemClicked: function (component, event, helper) {
        var index = event.target.dataset.index;
        var button = component.find("linkpersonbuttonId")
        var elements = component.find('listItemsId');
        var val, i;
        for (i = 0; i < elements.length; i++) {
            val = elements[i].getElement().getAttribute('data-index');
            if(val !== index){
                $A.util.removeClass(elements[i], "current");
            } else {
                $A.util.addClass(elements[i], "current");
            }
        }
        button.set('v.disabled',false);
        component.set('v.recordIndex', index);
    },
    backfromList: function (component, event, helper) {
        component.set("v.islistPopulated", false);
        component.set("v.isFindorLinkButtonVisible", true);
    },
    // Links the person record to live chat and displays it in the UI
    linkpersontolivechat: function (component, event, helper) {
        helper.linkpersontolivechatHelper(component, event, helper);
    },
    backTosearch: function (component, event, helper) {
        helper.backToSearchHelper(component, event, helper);
    },
    // shows up the record input form to create a new marketo lead.
    CreatePerson: function (component, event, helper) {
        component.set("v.isCreatePersonClicked", true);
        component.set("v.islistPopulated", false);
    },
    hideLeadSection: function (component, event, helper) {
        helper.hideLeadSection(component, event, helper);
    },
    cancelMarketoLeadCreation: function (component, event, helper) {
        component.set("v.isCreatePersonClicked", false);
        component.set("v.isFindorLinkButtonVisible", true);
    },
})