({
    //init method
    init : function(component, event, helper) {
        let escalationListRec = component.get("v.escalationListRec");
        let lCopiedEscalationList = [];
        lCopiedEscalationList.push(JSON.parse(JSON.stringify(escalationListRec)));
        component.set("v.lCopiedEscalationList", lCopiedEscalationList);
    },

    //Close the modal and destroy the component
    closeModal : function(component, event, helper) {
        component.destroy();
    },

    //Copy the Escalation Lists to all the PDs
    save : function(component, event, helper) {
        var i;
        helper.showSpinner(component, event, helper);
        //copyAllEscaltionList SC_SOCC_Escalation_List__c escalationListRec, String lCopiedEscListJSON
        let action = component.get("c.copyAllEscaltionListFromAura");
        //Changes for ESESP-4955
        //let list1=component.get("v.lCopiedEscalationList");
        component.get("v.lCopiedEscalationList").forEach(function(x){ delete x.isNotCopiable });
        //console.log('test 111');
        //console.log(list1);
        //console.log('test 112');
        //console.log(component.get("v.lCopiedEscalationList"));
        //console.log('test 113');
        //console.log(component.get("v.escalationListRec"));
        action.setParams({
            "escalationListRec" : component.get("v.escalationListRec"),
            "lCopiedEscListJSON" : JSON.stringify(component.get("v.lCopiedEscalationList"))
        });

        action.setCallback(this, function(response){
            helper.hideSpinner(component, event, helper);
            let state = response.getState();
            if(state === "SUCCESS"){
                let validAndInvalidEscalationListWrapper= response.getReturnValue();
                let validDetails=validAndInvalidEscalationListWrapper.lValidEscalationList;
                //let invalidDetails=validAndInvalidEscalationListWrapper.lInvalidEscalationList;
                let invalidStr=validAndInvalidEscalationListWrapper.invalidDetails;
                let baseUrl=validAndInvalidEscalationListWrapper.urlDetails;
                
                for (i = 0; i < validDetails.length; i++) {
                    helper.showMultiToastMessage(component, event, helper,'Saved','Hurray! Escalation Lists are copied successfully!‍','success','dismissible', 10000, baseUrl+'/'+validDetails[i].Id, validDetails[i].Name);
                }
                
                helper.showToastMessage(component, event, helper,'Warning',invalidStr,'warning','dismissible', 5000);
                
                component.destroy();
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','dismissible', 5000);
            }
            else
                helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','dismissible', 5000);
        });
        $A.enqueueAction(action);
    },

    //View Invalid Escalation Contacts which will not be copied
    viewRow : function(component, event, helper) {
        let indexName = event.target.name;
        let index = indexName.split("-")[1];
        helper.setLInvalidEscalationCon(component, event, helper, index);
    },

    //Add row to copy to another PD
    addRow : function(component, event, helper) {
        let lCopiedEscalationList = component.get("v.lCopiedEscalationList");
        if(lCopiedEscalationList.length < 5){
            let escalationListRec = component.get("v.escalationListRec");
            lCopiedEscalationList.push(JSON.parse(JSON.stringify(escalationListRec)));
            component.set("v.lCopiedEscalationList", lCopiedEscalationList);
            //Setting color of the current row
            component.set("v.isRowAdded", true);
            let currentRow = component.get("v.currentRow");
            setTimeout(function(){
                helper.setSelectedRowColor(component, event, helper, currentRow);
            }, 500);
        }
        else
            helper.showToastMessage(component, event, helper,'Adding more than 5 rows is not allowed!',' ','Error','dismissible', 5000);
        
    },

    //Delete row from copying
    deleteRow : function(component, event, helper) {
        let indexName = event.target.name;
        let index = indexName.split("-")[1];
        let lCopiedEscalationList = component.get("v.lCopiedEscalationList");
        lCopiedEscalationList.splice(index, 1);
        component.set("v.lCopiedEscalationList", lCopiedEscalationList);
        //Change the color of row to previous if the selected row is deleted
        let currentRow = component.get("v.currentRow");
        if(currentRow == index)
            helper.setLInvalidEscalationCon(component, event, helper, currentRow-1);
    },

    //On Change of selected Policy Domain on a particular row
    changeRow : function(component, event, helper) {
        let indexName = event.getSource().get("v.name");
        let index = indexName.split("-")[1];
        helper.setLInvalidEscalationCon(component, event, helper, index);
    },
    
    viewWarning:function(component, event, helper){
        //let indexName = event.target.name;
        //let index = indexName.split("-")[1];
        //helper.setLInvalidEscalationCon(component, event, helper, index);
        helper.showToastMessage(component, event, helper,'Warning','Cannot Copy the Escalation List as Notify Via Case Email empty!','Warning','dismissible', 5000);

    }
})