({
    //Method 1: Called on component load.
    loadApprovalDetails: function(component, event, helper) {
        helper.getCtrlPLValues(component, event);//to fetch the controlling picklist value 'Case_Record_type__c'
        helper.getDepenPLValues(component, event);//to fetch the controlling picklist value 'Approval_Status__c'
        helper.getIcon(component, event);//to fetch the controlling picklist value 'Approval_Status__c'
        helper.onLoad(component, event);//to fetch the approval details records of the case
    	helper.showEscalateButton(component, event);//to show the Escalate button only for case owner, for DD and Legal Case 
    },
    
    //Method 2: Called when each checkbox is checked, For counting the selected checkboxes. 
    checkboxSelect: function(component, event, helper) {
        //Show the spinner
        component.set("v.Spinner", true);
        // get the selected checkbox value  
        var selectedRec = event.getSource().get("v.value");
        // get the selectedCount attrbute value(default is 0) for add/less numbers. 
        var getSelectedNumber = component.get("v.selectedCount");
        // check, if selected checkbox value is true then increment getSelectedNumber with 1 
        // else Decrement the getSelectedNumber with 1     
        if (selectedRec == true) {
            getSelectedNumber++;
        } else {
            component.find("box3").set("v.value", false);
            getSelectedNumber--;
        }
        component.set("v.selectedCount", getSelectedNumber);
        //dont show the Status picklist values, if none of the check box is selected
        component.set("v.showStatus", false);
        //dont enable the Change Status button, if none of the check box is selected
        component.set("v.disableStatusChange", true);
        if(getSelectedNumber >=1 ){
            //fetches the dependent picklist values of Approval Status field based on Case_Record_type__c field
            helper.fetchDependentStatusValues(component,event);
            //show the Status picklist values, if either one of the check box is selected
            component.set("v.showStatus", true);
        }
        else{
            //Hide the spinner
            component.set("v.Spinner", false);
        }
    },
    
    //Method 3: Called when the header checkbox is checked. 
    selectAll: function(component, event, helper) {
        //Show the spinner
        component.set("v.Spinner", true);
        //get the header checkbox value  
        var selectedHeaderCheck = event.getSource().get("v.value");
        // get all checkbox on table with "boxPack" aura id (all iterate value have same Id)
        // return the List of all checkboxs element 
        var getAllId = component.find("boxPack");
        // If the local ID is unique[in single record case], find() returns the component. not array   
        if(! Array.isArray(getAllId)){
            if(selectedHeaderCheck == true){ 
                //fetches the dependent picklist values of Approval Status field based on Case_Record_type__c field
                helper.fetchDependentStatusValues(component,event);
                component.find("boxPack").set("v.value", true);
                component.set("v.selectedCount", 1);
                component.set("v.showStatus", true);//show the Status picklist values.
            }else{
                component.set("v.Spinner", false);//Hide the spinner
                component.find("boxPack").set("v.value", false);
                component.set("v.selectedCount", 0);
                component.set("v.showStatus", false);//dont show the Status picklist values.
                component.set("v.disableStatusChange", true);//dont enable the Change Status button
            }
        }else{
            // check if select all (header checkbox) is true then true all checkboxes on table in a for loop  
            // and set the all selected checkbox length in selectedCount attribute.
            // if value is false then make all checkboxes false in else part with play for loop 
            // and select count as 0 
            if (selectedHeaderCheck == true) {
                //fetches the dependent picklist values of Approval Status field based on Case_Record_type__c field
                helper.fetchDependentStatusValues(component,event);
                for (var i = 0; i < getAllId.length; i++) {
                    component.find("boxPack")[i].set("v.value", true);
                    component.set("v.selectedCount", getAllId.length);
                    component.set("v.showStatus", true);//show the Status picklist values.
                }
            } else {
                component.set("v.Spinner", false);//Hide the spinner
                for (var i = 0; i < getAllId.length; i++) {
                    component.find("boxPack")[i].set("v.value", false);//uncheck all the checkboxes
                    component.set("v.selectedCount", 0);
                    component.set("v.showStatus", false);//dont show the Status picklist values.
                    component.set("v.disableStatusChange", true);//dont enable the Change Status button
                }
            } 
        }  
    },
    
    //Method 4: Called when the Change Status button is clicked and displays the Popup window for confirmation.
    showChangeStatus: function(component, event, helper) {
        component.set("v.showStatusBox", true);
        component.set("v.isStatusChange", true);
        component.set("v.isDetailDelete", false);
    },
    //Method 5: Show/Hide the Change Status button based on the Status value Selected
    statusChanged: function(component, event, helper) {
        var valSelected = component.get("v.selectedStatus");
        component.set("v.disableStatusChange", true);
        if(valSelected != '--None--'){
            component.set("v.disableStatusChange", false);
        }
    },
    //Method 6: Called when the Yes button is clicked on the Popup window and updates the records.
    changeStatus: function(component, event, helper) {
        //Show the spinner
        component.set("v.Spinner", true);
        var valSelected = component.get("v.selectedStatus");
        // create var for store record id's for selected checkboxes  
        var recIds = [];
        // get all checkboxes 
        var getAllId = component.find("boxPack");
        // If the local ID is unique[in single record case], find() returns the component. not array
        if(! Array.isArray(getAllId)){
            if (getAllId.get("v.value") == true) {
                recIds.push(getAllId.get("v.text"));
            }
        }else{
            // play a for loop and check every checkbox values 
            // if value is checked(true) then add those Id (store in Text attribute on checkbox) in recId var.
            for (var i = 0; i < getAllId.length; i++) {
                if (getAllId[i].get("v.value") == true) {
                    recIds.push(getAllId[i].get("v.text"));
                }
            }
        } 
        //call the helper function and pass all selected record id's.    
        helper.updateSelectedHelper(component, event, recIds,valSelected);
    },
    
    //Method 7: Called to close the popup window
    closeModal: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "False"  
      component.set("v.showStatusBox", false);
    },
    
    //Method 8: Called to navigate to detail page of the approval detail record.
    navigateToDetail: function (component, event, helper) {
        var convoId = event.target.getAttribute("data-id");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": convoId
        });
        navEvt.fire();
    },
    
    //Method 9: Called to navigate to related list page of the approval detail records on case.
    openRelatedList: function(component, event){
        var relatedListEvent = $A.get("e.force:navigateToRelatedList");
        relatedListEvent.setParams({
            "relatedListId": "Approval_Details__r",
            "parentRecordId": component.get("v.recordId")
        });
        relatedListEvent.fire();
    },
    
    //Method 10: Shows all the records in the table
    showMore: function(component, event){
        component.set('v.approvalDetailsList', component.get('v.allApprovalDetailsList'));
        component.set("v.isShowMore", false);
        component.set("v.isShowLess", true);
        component.set('v.totalRecords', component.get('v.allApprovalDetailsList').length);
    },
    
    //Method 11: Hides all the records in the table, shows top 6 records
    showLess: function(component, event, helper){
        helper.displayRecords(component, event, component.get('v.allApprovalDetailsList'));
    },
    
    //Method 12: Performs edit/delete action based on the item clicked on each row
    performLineAction: function(component, event, helper){
        var menuValue = event.detail.menuItem.get("v.label");
        switch(menuValue) {
            case "Edit": helper.doEdit(component, event.detail.menuItem.get("v.value")); break;
            case "Escalate": helper.escalateCase(component, event.detail.menuItem.get("v.value")); break;
            case "Clone": helper.cloneAD(component,event.detail.menuItem.get("v.value")); break;
        }
    },
    
    //Method 13: Calls helper method to delete the record
    recordUpdated : function(component, event, helper) {
        helper.deleteUpdateRecord(component,event);
    },
    //Method 14: Change the icon to refresh icon on hover
    updateIcon: function(component, event, helper) {
        component.set("v.iconValue", "utility:refresh");
    },
    //Method 15: Revert the icon to refresh icon on hover
    revertIcon: function(component, event, helper) {
        component.set("v.iconValue", component.get("v.tempIconValue"));
    },
    //Method 16: Call the onLoad method to refresh the table
    refreshDetails: function(component, event, helper) {
        if(component.get("v.iconValue") == "utility:refresh")
            helper.onLoad(component, event);
    }
})