({
    init : function(component, event, helper){
        console.log("inside create edit init");
        //Getting parameters from the called/parent components
        let pdId = component.get("v.pdId");
        let escalationListId = component.get("v.escalationListId");
        let operation = component.get("v.operation");
        
        console.log('pdId : ' + pdId + '.');
        console.log('escalationListId : ' + escalationListId + '.');

        //Getting parameters from the called/parent components
        let myPageRef = component.get("v.pageReference");
        if(myPageRef){
            pdId = myPageRef && myPageRef.state && myPageRef.state.c__pdId ? myPageRef.state.c__pdId : pdId;
            operation = myPageRef && myPageRef.state ? myPageRef.state.c__operation : operation;
            component.set("v.pdId", pdId);
            component.set("v.operation", operation);
        }

		//making a server call and prepopulating the field values on Escalation List record
        helper.loadCompleteData(component, event, helper, pdId, escalationListId, operation);
        
    },

    // To handle change in URL from parent component
    handlePageChange: function(component, event, helper) {
        console.log("inside create edit handlePageChange");
        //var myPageRef = component.get("v.pageReference");
        //var pdId = myPageRef && myPageRef.state ? myPageRef.state.c__pdId : "World";
        //component.set("v.pdId", pdId);
    },
    
    
    //called from Child component SC_SOCC_EscalationContact_Edit via event SC_SOCC_SendSelectedEscCon
    //Saving Escalation List and all Related Escalation Contacts
    handleSelectedEscCon : function(component, event, helper){
        //let pdId = component.get("v.pdId");
        let pendingInstruction = component.get("v.pendingInstruction");
        

        //Check field validation
        if(helper.checkValidation(component, event, helper)){
            helper.showSpinner(component, event, helper);
            //get parameters from event 
            let lSelectedEscalationContacts = event.getParam("lSelectedEscalationContacts");
            let lEscConId = event.getParam("lEscConId");
            let lSelectedEscalationsViaCaseEmail = event.getParam("lSelectedEscalationsViaCaseEmail");
            let lEscConIdForEmail = event.getParam("lEscConIdForEmail");
            console.log("lSelectedEscalationContacts");
            console.log(lSelectedEscalationContacts);
            console.log(lEscConId);
            console.log("lSelectedEscalationsViaCaseEmail");
            console.log(lSelectedEscalationsViaCaseEmail);
            console.log(lEscConIdForEmail);

            
            //Server call to save Escalation List and related Escalation Contacts
            let action = component.get("c.saveCompleteEscalationList");
            action.setParams({
                "escRec" : component.get("v.escRec"),
                "lSelectedEscalationContactsJson" : JSON.stringify(lSelectedEscalationContacts),
                "lEscConId" : lEscConId,
                "lSelectedEscalationsViaCaseEmail" : lSelectedEscalationsViaCaseEmail,
                "lEscConIdForEmail" : lEscConIdForEmail,
                "pendingInstruction" : pendingInstruction
            });
            
            action.setCallback(this, function(response){
                helper.hideSpinner(component, event, helper);
                let state = response.getState();
                if(state === "SUCCESS"){
                    let escalationListReturnId = response.getReturnValue();
                    //making a server call and re-prepopulating the field values on Escalation List record
                    //helper.loadCompleteData(component, event, helper, pdId, escalationListReturnId);
                    helper.showToastMessage(component, event, helper,'Saved','Huzzah! Record is saved successfully! ‍🥳‍','success','dismissible', 5000);
                    helper.redirectToRecord(component, event, helper, escalationListReturnId);
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','dismissible', 5000);
                }
                else
                    helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','dismissible', 5000);
            });
            $A.enqueueAction(action);
        }

    },
    
    //Function to check validation on name input field
    // inputNameValidation : function(component, event, helper){
    // 	let escalationListName = component.find("escalationListName");
    //     console.log(escalationListName.get("v.value"));
	// 	$A.util.addClass(escalationListName,'slds-has-error');
    //     escalationListName.set("v.errors", [{message:"Input not a number: "}]);
	// },
    
    //Edit Escalation List
    // editEscalationList : function(component, event, helper){
    //     component.set("v.isEditPage", true);
    //     let escalationContactEditSection = component.find("escalationContactEditSection");
    //     escalationContactEditSection.makePageEditable(true);
    // },

    //Toggle tooltip on Pending Instruction label
    togglePendingInstructionToolTip : function(component, event, helper){
        let toggleText = component.find("pendingInstructionTooltipText");
        $A.util.toggleClass(toggleText, "toggle");
    }
    
    
    
})