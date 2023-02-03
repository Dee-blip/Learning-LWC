({
    doInit : function(component, event, helper) {
        helper.waiting(component, event, helper);   
        
        var recId = component.get("v.recordId");
        //document.getElementById("changePlaceHolder").placeholder = "Search and Add Accounts..";
        //document.getElementById("changePlaceHolder")[0].placeholder="Search and Add Accounts..";
        console.log("recId " + recId); 
        if (recId) {
            component.set("v.modalContext", "Edit");
            component.set("v.recordId",recId);
        } /*else {
            component.find("forceRecord").getNewRecord(
                "Investment_Workbox__c",//objectName
                null,// recordTypeId
                false,//skip Cache
                $A.getCallback(function() {
                    var rec = component.get("v.iwDetails");
                    console.log("vale from ctrl " + rec.Justification__c);
                    var error = component.get("v.recordError");
                    if (error || (rec === null)) {
                        console.log("Error initializing record template: " + error);
                        return;
                    }
                })
            );
        }*/
        helper.doneWaiting(component, event, helper); 
        let action = component.get('c.getProductValues');
        action.setStorable();
        action.setCallback(this,function(a){
                        
            component.set('v.productOptions', JSON.parse(a.getReturnValue()).filter(item => item.label !== "Internal") );
            
        });
        $A.enqueueAction(action);
    },
    
    onLoad : function(component, event, helper) {
        //alert('tets');
        var input = event.target.id; //this is = one-id
        console.log('input ::::::  ' +  input);
        //document.getElementById("changePlaceHolder")[0].placeholder="Search and Add Accounts..";
        //var inputValue = document.getElementById(input).value;
        //var output = document.getElementById(input + "-op");
        //var outputValue = output.value;
    },
    
    onRecordSubmit: function(component, event, helper) {
        //debugger;
        /*component.find('notifLib').showToast({
            "title": "Notif library Success!",
            "message": "The record has been updated successfully."
        });*/
        component.set("v.disableBtn","true");
        helper.waiting(component, event, helper);
        var status = component.find("statusField").get("v.value");
        var btnPressed = event.getSource().get("v.value");
        var btnErrorMsgText = "";

        console.log('chkk value 11:: ' , component.find("ProductBU1") );


        if(btnPressed === "submit"){
            btnErrorMsgText = "Submitted";
            component.find("statusField").set("v.value", 'Awaiting Approval');
            component.find("loeHrField").set("v.value", loeHrs);
        }
        else if(btnPressed === "save"){
            btnErrorMsgText = "Saved";
        }
        
        console.log("--status--"+status);
        if(status === "Saved" || status === "Awaiting Approval" ){
            
            //var watchersCmp = component.find("watchersField");
            var fieldValue = component.get("v.selectedProdOptions") != null ? component.get("v.selectedProdOptions").toString() : "";
            //added a variable that holds present value of the Picklist
            var loeMn = component.get("v.loeMinsPickList") != null ? component.get("v.loeMinsPickList") : 1;
            component.find("loeMinField").set("v.value", loeMn);
            component.find("loeHrField").set("v.value", loeHrs);
            console.log(typeof loeMn);
            console.log("----Prod Field Value ----"+fieldValue);
            var prodSelected = false;
            if(fieldValue === ""){
                console.log("----Prod Field Value If----"+fieldValue);
                component.find('isProdSelectedField').set('v.value', true);
                prodSelected = true;
            }
            else{
                console.log("----Prod Field Value Else ----"+fieldValue);
                component.find('isProdSelectedField').set('v.value', false);
                //prodSelected = false;
            }
            component.find('productsField').set('v.value', fieldValue); 
            console.log("----productsField ----"+component.find("productsField").get("v.value"));
            var workType = component.find("workTypeField").get("v.value");
            var accIds = component.get("v.selectedLookUpRecords");
            var userRec = component.get("{!v.userRec}") !== null ? component.get("{!v.userRec}").val : null;
            //var requestor = component.find("requestorField").get("v.value");
            var requestor = userRec;
            //19.1 : FFPSA-793 removing this field 
            //var timeToAction = component.find("timeToActionField").get("v.value");
            var justification = component.find("justificationField").get("v.value");
            //var loeMin = component.find("loeMinField").get("v.value");
            var loeHrs = component.find("loeHrField").get("v.value");
            loeHrs = loeHrs = Math.round(Number(loeHrs)).toString();
            var loeMin = component.get("v.loeMinsPickList");
            console.log(typeof loeHrs);
            var loeMin = component.find("loeMinField").get("v.value");
            var workType = component.find("workTypeField").get("v.value");
            var recordId = component.get("v.recordId");
            var totalLOEMin = parseInt(loeHrs*60) + parseInt(loeMin);
            if(component.find("othersField") !== undefined){
                var others = component.find("othersField").get("v.value");
            }
            var isError = "false";
            var validationErrorField = "";
            
            if(accIds.length === 0){
                //helper.setToastVar("Error: Please choose a work type.");
                isError = "true";
                validationErrorField += "Account, ";
            }
            
            if(workType === "" || workType === null){
                //helper.setToastVar("Error: Please choose a work type.");
                isError = "true";
                validationErrorField += "Work Type, ";
            }
            if(workType === "Other (Add Comment)" && (others === "" || others === null)){
                isError = "true";
                validationErrorField += "Others, ";
            }
            /*
             * if(timeToAction === "" || timeToAction === null){
                //helper.setToastVar("Error: Please choose a work type.");
                isError = "true";
                validationErrorField += "Time to Action, ";
            }*/
            /*if(account === "" || account === null){
                //helper.setToastVar("Error: Please select an Account.");
                isError = "true";
                validationErrorField += "Account, ";
            }*/
            if(requestor === "" || requestor === null){
                //helper.setToastVar("Error: Please select a Requestor.");
                isError = "true";
                validationErrorField += "Requestor, ";
            }
            if(justification === "" || justification === null){
                //helper.setToastVar("Error: Please choose a justification.");
                isError = "true";
                validationErrorField += "Justification, ";
            }
            if((loeHrs === "" && loeMin === "") ||(loeHrs === "0" && loeMin === "0") ){
                //helper.setToastVar("Error: Please populate LOE.");
                isError = "true";
                validationErrorField += "LOE, ";
            }
            if(loeHrs < 0 || loeMin < 0){
                isError = "true";
                validationErrorField += "LOE, ";
            }
            
            if(loeMin > 59){
                isError = "true";
                validationErrorField += "LOE, ";
            }
            
            if(isError ==="true"){
                var index = validationErrorField.lastIndexOf(",");
                validationErrorField = validationErrorField.substring(0, index) + validationErrorField.substring(index + 1)+".";
                if(loeHrs < 0 || loeMin < 0){
                    //helper.setToastVar("Error: LOE can't be a negative number.");
                    helper.setToastVar(component, "Error: LOE can't be a negative number.");
                }
                else if(loeMin > 59){
                    helper.setToastVar(component, "Error: LOE minutes can't be a greater than 59.");
                }
                else{
                    //helper.setToastVar("Error: Please populate field "+validationErrorField);
                    helper.setToastVar(component, "Error: Please populate field "+validationErrorField); 
                }
                helper.doneWaiting(component, event, helper);
                component.set("v.disableBtn","false");
            }
            
            if(isError === "false" && btnPressed === "submit"){
                var requestStatus = 'Awaiting Approval';
                component.find("statusField").set("v.value", 'Awaiting Approval');
                component.find("loeHrField").set("v.value", loeHrs);
                if(accIds.length !== 0){
                    var accountList = component.get("{!v.selectedLookUpRecords}") !== undefined ? component.get("{!v.selectedLookUpRecords}") : null;
                    var loeHrs = parseInt(loeHrs) + parseInt(loeMin/60);
                    if(accIds){
                        //component.set("v.accountId",accountid);
                        var getAvailableBudgetAction = component.get('c.getRgionAccountSlots');
                        getAvailableBudgetAction.setParams({
                            "watcherList": JSON.stringify(accountList),
                            "LOE" : loeHrs,
                            "Justification": JSON.stringify(justification),
                            "iwClassification" : component.find("iwClassificationCustom").get("v.value" )
                        });
                        
                        getAvailableBudgetAction.setCallback(this, function(result){
                            var state = result.getState();
                            if (component.isValid() && state === "SUCCESS"){
                                var loeResult = result.getReturnValue();
                                console.log('::::::::::::'+ loeResult +'::::::::::::::');
                                if(loeResult !== 'success' && loeResult !== 'failure'){
                                    isError ="true";
                                    helper.setToastVar(component, "Error: slots are not available to selected Account: " + loeResult + ". An email has been sent for Investment Work Admins to address the situation. Please save your request and wait for the admins to respond.");
                                    component.set("v.disableBtn","false");
                                }
                                else if(loeResult === 'success'){
                                    //var requestStatus;
                                    /*if(isError === "false" && btnPressed === "submit"){
                                        requestStatus = 'Awaiting Approval';
                                        component.find("statusField").set("v.value", 'Awaiting Approval');
                                    }
                                    else if(isError === "false" && btnPressed === "save"){
                                        requestStatus = 'Saved';
                                    }*/
                                    
                                    var accIds = component.get("v.selectedLookUpRecords");
                                    for(var id in accIds){
                                        component.find("accountField").set("v.value", accIds[id].Id);
                                        component.find("requestorField").set("v.value", component.get("{!v.userRec}").val);
                                        component.find('isRequestModified').set('v.value', true);
                                        console.log("---Before Submit Action---");
                                        component.find('editFormAccount').submit();
                                    }
                                    //helper.setToastVarSuccess(component, "Success");
                                    //window.location.href = '/lightning/o/Investment_Workbox__c/list?filterName=Recent';
                                    /*var accountList = component.get("{!v.selectedLookUpRecords}") !== undefined ? component.get("{!v.selectedLookUpRecords}") : null;
                                var loeHrs = parseInt(loeHrs) + parseInt(loeMin/60);
                                if(accIds){
                                    //component.set("v.accountId",accountid);
                                    var insertRequests = component.get('c.insertWorkRequests');
                                    insertRequests.setParams({
                                        "watcherList": JSON.stringify(accountList),
                                        "workType" : workType,
                                        "requestor" : requestor,
                                        "timeToAction" : timeToAction,
                                        "justification" : justification, 
                                        "loeHrs" : loeHrs,
                                        "loeMin" : loeMin, 
                                        "others" : others,
                                        "productSelected" :prodSelected, 
                                        "products": fieldValue,
                                        "status" : requestStatus
                                    });
                                    
                                    insertRequests.setCallback(this, function(result){
                                        var state = result.getState();
                                        if (component.isValid() && state === "SUCCESS"){
                                            var loeResult = result.getReturnValue();
                                            console.log('::::::::::::'+ loeResult +'::::::::::::::');
                                            if(loeResult === 'Success'){
                                                helper.setToastVarSuccess(component, "Success");
                                                window.location.href = '/lightning/o/Investment_Workbox__c/list?filterName=Recent';
                                            }
                                            else if(loeResult === 'Failure'){
                                                helper.setToastVar(component, "Error: There was some problem inserting Work Requests.");
                                            }
                                        }
                                        else{
                                            helper.setToastVar(component, "Error: Process Failed due to unknown reason.");
                                        }
                                    });
                                    $A.enqueueAction(insertRequests);
                                }
                                else{
                                    component.set("v.availableLoeBud","0");
                                }
                                helper.setToastVarSuccess(component, "Success");*/
                                }
                                    else if(loeResult === 'failure'){
                                        isError ="true";
                                        helper.setToastVar(component, "Error: Failed to get available LOE for the selected Account.");
                                        component.set("v.disableBtn","false");
                                    }
                            }
                            else{
                                isError ="true";
                                helper.setToastVar(component, "Error: Failed to get available LOE for the selected Account.");
                                component.set("v.disableBtn","false");
                            }
                        });
                        $A.enqueueAction(getAvailableBudgetAction);
                    }
                    else{
                        component.set("v.availableLoeBud","0");
                    }
                }
                
                
                
            }
            else if(isError === "false" && btnPressed === "save"){
                var requestStatus = 'Saved';
                component.find("statusField").set("v.value", 'Saved');
                component.find("loeHrField").set("v.value", loeHrs);
                var accIds = component.get("v.selectedLookUpRecords");
                for(var id in accIds){
                    component.find("accountField").set("v.value", accIds[id].Id);
                    component.find("requestorField").set("v.value", component.get("{!v.userRec}").val);
                    console.log("---Before Submit Action---");
                    component.find('editFormAccount').submit();
                }
                component.set("v.disableBtn","false");
                //Test
                //helper.setToastVarSuccess(component, "Success");
                //window.location.href = '/lightning/o/Investment_Workbox__c/list?filterName=Recent';
            }
            
            
            
            
            
            /*else if (isError === "false"){
                
            }*/
        }
        
        
    },
    
    cancelDialog: function(component, event, helper) {
        //var recId = component.get("v.recordId");
        //if (!recId) {
        /*var homeEvt = $A.get("e.force:navigateToObjectHome");
            homeEvt.setParams({
                "scope": "Investment_Workbox__c"
            });
            homeEvt.fire();*/
        window.location.href = '/lightning/o/Investment_Workbox__c/list?filterName=Recent';
        //} else {
        //helper.navigateTo(component, recId);
        //}
    },
    
    onRecordSuccess: function(component, event, helper) {
        console.log("---After Submit Action onRecordSuccess---");
        //helper.setToastVarSuccess("Success");
        helper.setToastVarSuccess(component, "Success");
        /*component.find('notifLib').showToast({
            "title": "Notif library Success!",
            "message": "The record has been updated successfully."
        });*/
        /*var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.getParam("response").id,
            "slideDevName": "detail"
        });
        
        navEvt.fire();*/
        /*helper.navigateToDetail(event.getParam("response").id);
        $A.get('e.force:refreshView').fire();
        helper.doneWaiting(component, event, helper);*/
    },
    
    onRecordError : function(component, event, helper){
        /*component.find('notifLib').showToast({
            "title": "Notif library Success!",
            "message": "The record has been updated successfully."
        });*/
         console.log("---After Submit Action onRecordError---");
        helper.doneWaiting(component, event, helper);
        var eventName = event.getName();
        var eventDetails = event.getParam("error");
        console.log("--event--"+JSON.stringify(event));
        console.log("--eventDetails--"+JSON.stringify(eventDetails));
        console.log("--eventName--"+JSON.stringify(eventName));
        if(eventName === "error" && eventDetails.data !== undefined){
            var validationError = "";
            console.log(JSON.stringify(eventDetails.length));
            if(eventDetails.data.output.errors[0] !== undefined){
                //if(eventDetails.data.output.errors[0] !== undefined){
                validationError = eventDetails.data.output.errors[0].message;
                helper.setToastVar(component, validationError);
            }
            else if(eventDetails.data.output.fieldErrors.Opportunity__c[0] !== undefined){
                validationError = eventDetails.data.output.fieldErrors.Opportunity__c[0].message;
                helper.setToastVar(component, validationError);
                
            }
                else{
                    validationError = "Error: Failed to submit due to unknown error." 
                    helper.setToastVar(component, validationError);
                } 
            console.log("IW Submit onRecordError: "+JSON.stringify(eventDetails));
        }
        else if(event._name !== undefined && event._name === "error"){
            if(event._params.detail !== undefined){
               helper.setToastVar(component, event._params.detail); 
            }
        }
        else{
            helper.setToastVar(component, "IW DML Error : insert/update failed due to unknown error.");
        }
        component.set("v.disableBtn","false");
    },
    
    getLoeBudget: function(component, event, helper){
        console.log(' got vals : ' , component.get("v.accountInternal") );
        var accountid = event.getParams("Account__c").value;
        console.log("accountid----"+accountid); 
        if(accountid){
            component.set("v.accountId",accountid);
            var getAvailableBudgetAction = component.get('c.availableLoeBudget');
            getAvailableBudgetAction.setParams({
                "accountInfo":accountid
            });
            
            getAvailableBudgetAction.setCallback(this, function(result){
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){
                    var loeResult = result.getReturnValue();
                    component.set("v.availableLoeBud",loeResult);
                    console.log('availableLoeBud--: ' + loeResult);
                }
                else{
                    helper.setToastVar("Error: Failed to get available LOE for the selected Account.");
                }
            });
            $A.enqueueAction(getAvailableBudgetAction);
        }
        else{
            component.set("v.availableLoeBud","0");
        }
    },
    
    displayOtherField: function(component, event, helper){
        var workTypeVal = event.getParams("Work_Type__c").value;
        if(workTypeVal ==="Other (Add Comment)"){
            component.set("v.displayOtherField","true");
        }
        else{
            component.set("v.displayOtherField","false");
        }
    },
    handleChange: function (cmp, event) {
        // This will contain the string of the "value" attribute of the selected option
        var selectedOptionValue = event.getParam("value");
        console.log("Option selected with value: '" + selectedOptionValue + "'");
        console.log(typeof selectedOptionValue );
        if (selectedOptionValue) {
            //cmp.set("v.loeMinsPickList", parseInt(selectedOptionValue));
            cmp.set("v.loeMinsPickList", selectedOptionValue);
        } 
    },
    
    handleRecordUpdated: function(component, event, helper){
        var eventParams = event.getParams();
        var recId = component.get("v.recordId");
        if(eventParams.changeType === "LOADED" && recId) {
            console.log("iwDetails loaded:::::" + component.get("v.iwDetails.LOE_Minutes__c"));
            var loeMinutesLoad = component.get("v.iwDetails.LOE_Minutes__c");
            var loeMinutesString = loeMinutesLoad.toString();
            console.log(typeof(loeMinutesString));
            if(loeMinutesString != "0" && loeMinutesString != "15" && loeMinutesString != "30" && loeMinutesString != "45"){
                var optionsList = component.get("v.options");
                //optionsList.unshift({'SObjectType':'pse__region__c', 'id':'', 'type':event.target.id});
                optionsList.unshift({'label': loeMinutesString, 'value': loeMinutesString});
                component.set("v.options",optionsList);
            }
            component.set("v.hardcoded", loeMinutesString);
        }
    },
  
    //function to load values into custom input field on component load
    handleComponentEvent : function(component) {
        var action;

        console.log('evevnt lo', component.get("{!v.accountInternal}") );

        action = component.get('c.getProductValues');
        action.setStorable();
        action.setCallback(this,function(a){
                        
            //component.set('v.productOptions', JSON.parse(a.getReturnValue()).filter(item => item.label !== "Internal") );
            console.log(' prodd optiosn: :: ' , JSON.parse(a.getReturnValue()) );
            component.set('v.classificationOptions', JSON.parse(a.getReturnValue()) );
            component.set('v.allclassificationOptions', JSON.parse(a.getReturnValue()) );

            console.log(' acc int : condtn :' , ( component.get("{!v.accountInternal}") === 'false' ) );

            if( component.get("{!v.accountInternal}") === 'false' )
            {
                console.log('filter valss : ' , component.get('v.allclassificationOptions').filter(item => item.label !== "Product/Platform Work" ) ); 
                component.set('v.classificationOptions', component.get('v.allclassificationOptions').filter(item => item.label !== "Product/Platform Work" )  );

            } else if( component.get("{!v.accountInternal}") === 'true' )
            {
                component.set('v.classificationOptions', component.get('v.allclassificationOptions').filter(item => item.label !== "Planned Investment" && item.label !== "Unplanned Investment" )  );
                component.find("iwClassificationCustom").set("v.value","Product/Platform Work");
                component.find("iwClassification").set("v.value" , component.find("iwClassificationCustom").get("v.value" )  );
            }

            
        });
        $A.enqueueAction(action);

    },

    handleClassificationChange : function(component) {

        component.find("iwClassification").set("v.value" , component.find("iwClassificationCustom").get("v.value" )  );

    },
  
    //Function to show to select particular type of account for Bulk IW
    showMessage : function(component, event,helper) {
        console.log('inside show msg ');
        if(component.get("{!v.accountInternal}") === 'true')
        {
            helper.setToastVar(component ,"All the Accounts selected for the Bulk IW must be of same type, Please select all Internal Accounts");
            component.set("v.sendMsg",false);
        } else if(component.get("{!v.accountInternal}") === 'false')
        {
            helper.setToastVar(component ,"All the Accounts selected for the Bulk IW must be of same type, Please select all Non-Internal Accounts");
            component.set("v.sendMsg",false);
        }
        

    }
})