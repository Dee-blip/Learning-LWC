({
    doInit : function(component, event, helper) {
        
        helper.waiting(component, event, helper);       
        var recId = component.get("v.recordId");
        var action;
        
        console.log("recId " + recId); 
        if (recId) {
            component.set("v.modalContext", "Edit");
            component.set("v.recordId",recId);
            //20.5 un-setting project as default project is selected for security projects
            //helper.handleDoInit(component, event);
            console.log('entry ::');

            
        } 
        if (!recId) {
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
        }
        helper.doneWaiting(component, event, helper); 
        // CLassification options to be loaded dynamically on load of the component

        action = component.get('c.getProductValues');
        action.setStorable();
        action.setCallback(this,function(a){
                        
            //component.set('v.productOptions', JSON.parse(a.getReturnValue()).filter(item => item.label !== "Internal") );
            console.log(' prodd optiosn :: ' , JSON.parse(a.getReturnValue()) );
            component.set('v.classificationOptions', JSON.parse(a.getReturnValue()) );
            component.set('v.allclassificationOptions', JSON.parse(a.getReturnValue()) );
            

            if(component.find("iwClassificationCustom").get("v.value") === undefined && component.find("iwClassification").get("v.value" ) !== undefined )
            {
                component.find("iwClassificationCustom").set("v.value" , component.find("iwClassification").get("v.value" )  );
            }

            
        });
        $A.enqueueAction(action);

        // component.find("productBUCustom").set("v.value", component.get("v.iwDetails.Product_BU__c") );

        // console.log(' has vall : ' , component.get("v.iwDetails.Product_BU__c")  );

        // console.log(' this muchhst : ' , component.find("productBU").get("v.value") );

        // console.log(' get call order1: ? ' , component.find("productBUCustom").get("v.value") );
        
    },
    onRecordSubmit: function(component, event, helper) {
        helper.waiting(component, event, helper);
        component.set("v.disableBtn","true");
        console.log('rwachedd ');
        component.find("iwClassification").set("v.value" , component.find("iwClassificationCustom").get("v.value" )  );
        console.log('bit not here');
        var status = component.find("statusField").get("v.value");
        var btnPressed = event.getSource().get("v.value");
        var btnErrorMsgText = "";

        console.log(' not reach : ');
        if(btnPressed === "submit"){
            btnErrorMsgText = "Submitted";
        }
        else if(btnPressed === "save"){
            btnErrorMsgText = "Saved";
        }
        
        console.log("--status--"+status);
        if(status === "Saved" || status === "Escalated" || status === "Awaiting Approval" ){
            
            //var watchersCmp = component.find("watchersField");
            var fieldValue = component.get("v.selectedProdOptions") != null ? component.get("v.selectedProdOptions").toString() : "";
            //added a variable that holds present value of the Picklist
            var loeMn = component.get("v.loeMinsPickList") != null ? component.get("v.loeMinsPickList") : 1;
            component.find("loeMinField").set("v.value", loeMn);
            console.log(typeof loeMn);
            console.log("----Prod Field Value ----"+fieldValue);
            if(fieldValue === ""){
                console.log("----Prod Field Value If----"+fieldValue);
                component.find('isProdSelectedField').set('v.value', true);
            }
            else{
                console.log("----Prod Field Value Else ----"+fieldValue);
                component.find('isProdSelectedField').set('v.value', false);
            }
            //console.log(' failll here ' , failher);
            component.find('productsField').set('v.value', fieldValue); 
            console.log("----productsField ----"+component.find("productsField").get("v.value"));
            component.find("isModifyField").set("v.value", true);
            //20.5 setting opportunity Id
            console.log(' test reachh :: js aft');
            var oppRec = component.get("{!v.oppRec}") !== null ? component.get("{!v.oppRec}").val : null;
            component.find("opportunityField").set("v.value", oppRec);

            console.log(' test reachh :: ');

            //19.5 Adding Project for security Project
            var projRec = component.get("{!v.projRec}") !== null ? component.get("{!v.projRec}").val : null;
            console.log(' test reachh 1::11 ');
            //var securitychk = component.find("securityCheckId").get("v.value"); 
            console.log(' test reachh 1:: 23');
            // if(projRec && securitychk){
            //    component.find("projectField").set("v.value", projRec); 
            // }

            console.log(' test reachh 1:: ');
            
            var workType = component.find("workTypeField").get("v.value");
            var account = component.find("accountField").get("v.value");
            var requestor = component.find("requestorField").get("v.value");
            //var timeToAction = component.find("timeToActionField").get("v.value");
            var justification = component.find("justificationField").get("v.value");
            var loeHrs = component.find("loeHrField").get("v.value");
            loeHrs = Math.round(Number(loeHrs)).toString();
            //var loeMin = component.find("loeMinField").get("v.value");
            var loeMin = component.get("v.loeMinsPickList");
           
            console.log(typeof loeHrs);
            var workType = component.find("workTypeField").get("v.value");
            var recordId = component.get("v.recordId");
            var totalLOEMin = parseInt(loeHrs*60) + parseInt(loeMin);
            // if(component.find("othersField") !== undefined){
            //     var others = component.find("othersField").get("v.value");
            // }
            var comment = component.find("commentField").get("v.value");
            
            //console.log("----others field ----");
            console.log("----loeHrs field ----"+loeHrs);
            console.log("----loeMin field ----"+loeMin);
            
            var isError = "false";
            var validationErrorField = "";

            // if(securitychk && (account === "" || account === null)){
            //     isError = "true";
            //     validationErrorField += "Account, ";
            // }
            // if(securitychk && (projRec === "" || projRec === null)){
            //     isError = "true";
            //     validationErrorField += "Project, ";
            // }
            
            if(workType === "" || workType === null){
                //helper.setToastVar("Error: Please choose a work type.");
                isError = "true";
                validationErrorField += "Work Type, ";
            }
            // if(workType === "Other (Add Comment)" && (others === "" || others === null)){
            //     isError = "true";
            //     validationErrorField += "Others, ";
            // }
            /* 19.1
             * if(timeToAction === "" || timeToAction === null){
                //helper.setToastVar("Error: Please choose a work type.");
                isError = "true";
                validationErrorField += "Time to Action, ";
            }*/
            if(account === "" || account === null){
                //helper.setToastVar("Error: Please select an Account.");
                isError = "true";
                validationErrorField += "Account, ";
            }
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
            if(loeHrs === undefined && loeMin === undefined){
                loeHrs = "0";
                loeMin = "0"; 
            }
            if(loeHrs === undefined || loeHrs === ""){
                loeHrs = "0";
            }
            if(loeMin === undefined || loeMin === ""){
                loeMin = "0";
            }
            console.log("--Loe Hrs---"+loeHrs)
            console.log("--Loe Mins---"+loeMin)
            if((loeHrs === "" && loeMin === "") || (loeHrs === "0" && loeMin === "0") || (loeHrs === "" && loeMin === "0") || (loeHrs === "0" && loeMin === "")){
                //helper.setToastVar("Error: Please populate LOE.");
                isError = "true";
                validationErrorField += "LOE, ";
            }
            if(loeHrs < 0 || loeMin < 0 || loeMin > 59 || loeHrs > 9999){
                isError = "true";
                validationErrorField += "LOE, ";
            }
            
            console.log("----isError ----"+isError);
            if(isError ==="true"){
                var index = validationErrorField.lastIndexOf(",");
                validationErrorField = validationErrorField.substring(0, index) + validationErrorField.substring(index + 1)+".";
                if(loeHrs < 0 || loeMin < 0){
                    helper.setToastVar("Error: LOE can't be a negative number.");
                }
                else if(loeMin > 59){
                    helper.setToastVar("Error: LOE minutes can't be a greater than 59.");
                }
                    else if(loeHrs > 9999){
                        helper.setToastVar("Error: LOE Hours can't be a greater than 9999.");
                    }
                        else{
                            helper.setToastVar("Error: Please populate field "+validationErrorField);
                        }
                helper.doneWaiting(component, event, helper);
                console.log('button : re enabling button befor?');
                component.set("v.disableBtn","false");
            }
            else{
                if(btnPressed === "submit" || btnPressed === "save"){
                    var recId = component.get("v.recordId");
                    var RecordId = "";
                    if(recId !== undefined && recId !== null){
                        RecordId = recId;
                    }
                    if(totalLOEMin <= 240 ){
                        component.set("v.disableBtn","true");
                        helper.doneWaiting(component, event, helper);
                    }
                    
                    var submitAction = component.get("c.handleButtonEvent");
                    submitAction.setParams({
                        "recordIWID" : RecordId,
                        "buttonEvent" : btnPressed,
                        "LOEHrs":loeHrs,
                        "LOEMins":loeMin,
                        "Account":account,
                        "Comment":comment,
                        "internalProd": component.find("productBU").get("v.value") === "Internal" ? true : false,
                        "iwClassification" :  component.find("iwClassificationCustom").get("v.value" )
                    });
                    submitAction.setCallback(this, function(result){
                        var state = result.getState();
                        if (component.isValid() && state === "SUCCESS"){
                            console.log("---Save Callback success---");
                            var showComp = result.getReturnValue();
                            if(showComp === 'true' && btnPressed === "submit"){
                                console.log("---Save Callback response true---");
                                component.find("statusField").set("v.value", "Awaiting Approval");
                                component.find("loeHrField").set("v.value", loeHrs);
                                component.find('editFormAccount').submit();
                                
                            }
                            else if(showComp === 'NoPermission'){
                                console.log("---Submit/Save Callback response NoPermission---");
                                helper.setToastVar("Error: You don't have permission to submit this request.");
                                helper.doneWaiting(component, event, helper);
                            }
                            else if(showComp === 'false' && btnPressed === "submit"){
                                console.log("---Submit Callback response false ---");
                                //var recId = component.get("v.recordId");
                                //if(!recId){
                                console.log(' vals being passed : ' , component.find("iwClassificationCustom").get("v.value") );
                                let mailAction = component.get("c.calculateValueforNotifyLowSlot");
                                mailAction.setParams({
                                    "LOEHrs":loeHrs,
                                    "LOEMins":loeMin,
                                    "Account":account,
                                    "Justification":justification,
                                    "Requestor":requestor,
                                    "iwClassification": component.find("iwClassificationCustom").get("v.value")
                                });
                                mailAction.setCallback(this, function(response){
                                    console.log("trying to logg",response);
                                });
                                $A.enqueueAction(mailAction);   
                                //}
                                helper.setToastVar("Error: Request can't be submitted. Requested LOE exceeds the available LOE budget for the selected account. An email has been sent for Investment Work Admins to address the situation. Please save your request and wait for the admins to respond.");
                                helper.doneWaiting(component, event, helper);
                                console.log('button : re enabling button ? on loe err' , component.get("v.disableBtn") );
                                component.set("v.disableBtn","false");
                            }
                            else if(btnPressed === "save"){
                                console.log("---Save Callback response---");
                                component.find("loeHrField").set("v.value", loeHrs);
                                component.find('editFormAccount').submit();
                                //helper.setToastVar("Error: Request can't be submitted. Requested LOE exceeds the available LOE budget for the selected account.");    
                            }
                            if(isError === "false"){
                                
                                //console.log("---Before Submit Action---");
                                // component.find('editFormAccount').submit();
                            }

                            console.log(' in sub succ ');
                            
                        }
                        else if (state === "ERROR") {
                            helper.doneWaiting(component, event, helper);
                            var errors = result.getError();
                            console.log("Unknown error"+JSON.stringify(errors));
                            var errorMsg = "";
                            if (errors) {
                                if(errors[0].pageErrors[0].message !== undefined){
                                    helper.setToastVar("Error: "+errors[0].pageErrors[0].message); 
                                }
                                else if(errors[0].fieldErrors[0].message !== undefined){
                                    helper.setToastVar("Error: "+errors[0].fieldErrors[0].message); 
                                }
                                    else{
                                        helper.setToastVar("Error: Failed to submit due to unknown error.");
                                    }
                                
                            } 
                            else {                    
                                console.log("IW-Submit Button Unknown error");
                            }
                        }
                        
                    });
                    
                    $A.enqueueAction(submitAction);
                    
                }
                
                
                if(isError === "false"){
                    
                    //console.log("---Before Submit Action---");
                    //component.find('editFormAccount').submit();
                }
            }
        }
        else if(status === "Approved" || status === "Auto-Approved" || status === "Escalate Approved"){
            console.log('button : re enabling button 1 ?');
            component.set("v.disableBtn","true"); 
            helper.doneWaiting(component, event, helper);
            helper.setToastVar("Error: This Investment Work Request cannot be Edited/"+btnErrorMsgText+" as it has already been Approved.");
            component.set("v.disableBtn","false");
            console.log('button : re enabling button 11?');
        }
        // Disabling buttons on submit until reponse is received and processed
        else if(status === "Rejected" || status === "Escalate Reject"){
            component.set("v.disableBtn","true");
            helper.doneWaiting(component, event, helper);
            helper.setToastVar("Error: This Investment Work Request cannot be Edited/"+btnErrorMsgText+" as it has been Rejected.");
            component.set("v.disableBtn","false");
        }
        else if(status === "Cancelled"){
            component.set("v.disableBtn","true");
            helper.doneWaiting(component, event, helper);
            helper.setToastVar("Error: This Investment Work Request cannot be Edited/"+btnErrorMsgText+" as it has been Cancelled.");
            component.set("v.disableBtn","false");
        }
        
    },
    
    cancelDialog: function(component, event, helper) {
        var recId = component.get("v.recordId");
        if (!recId) {
            var homeEvt = $A.get("e.force:navigateToObjectHome");
            homeEvt.setParams({
                "scope": "Investment_Workbox__c"
            });
            homeEvt.fire();
        } else {
            helper.navigateTo(component, recId);
        }
    },
    
    onRecordSuccess: function(component, event, helper) {
        console.log("---After Submit Action onRecordSuccess---");
        helper.setToastVarSuccess("Success");
        
        /*var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.getParam("response").id,
            "slideDevName": "detail"
        });
        
        navEvt.fire();*/
        helper.navigateToDetail(event.getParam("response").id);
        $A.get('e.force:refreshView').fire();
        helper.doneWaiting(component, event, helper);
        console.log('button : re enabling button ?' , component.get("v.disableBtn") );
        component.set("v.disableBtn","false");
    },
    
    onRecordError : function(component, event, helper){
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
                helper.setToastVar(validationError);
            }
            else if(eventDetails.data.output.fieldErrors.Opportunity__c[0] !== undefined){
                validationError = eventDetails.data.output.fieldErrors.Opportunity__c[0].message;
                helper.setToastVar(validationError);
                
            }
                else{
                    validationError = "Error: Failed to submit due to unknown error." 
                    helper.setToastVar(validationError);
                } 
            console.log("IW Submit onRecordError: "+JSON.stringify(eventDetails));
        }
        else if(event._name !== undefined && event._name === "error"){
            if(event._params.detail !== undefined){
                helper.setToastVar(event._params.detail); 
            }
        }
            else{
                helper.setToastVar("IW DML Error : insert/update failed due to unknown error.");
            }
        console.log('button : re enabling button ?on error' , component.get("v.disableBtn") );
        component.set("v.disableBtn","false");
    },
    
    getLoeBudget: function(component, event, helper){
        var accountid = "";
        var prodValues;
        var action;
        accountid = event.getParams("Account__c").value;
        component.set("v.AccId", accountid);
        console.log("accountid----"+accountid); 
        //Added checks to fetch account LOE and change field values depending on account after account is changed
        console.log(' ano account : ' , component.get('v.accountId') );
        console.log(' evevnt : ' , !accountid.includes("001") + ' accc : ' + accountid );

        if(component.find("iwClassificationCustom").get("v.value") === undefined )
        {
            component.find("iwClassificationCustom").set("v.value" , component.find("iwClassification").get("v.value" )  );
            
        } else { component.find("iwClassification").set("v.value" , component.find("iwClassificationCustom").get("v.value" )  );  }
        
        if(accountid !== null && accountid !== undefined && accountid.length > 0){

            console.log('bevoe method call :: ' , component.get("v.showBudget") );

            action = component.get('c.getAccountIdInternal');
            action.setParams({
                "accountId" :accountid.toString()
            });
            
            action.setStorable();
            action.setCallback(this,function(a){

                console.log( ' cndtm :: ' , JSON.parse(a.getReturnValue()) === 'true' , 'nextt : ' , JSON.parse(a.getReturnValue())  );

                if( JSON.parse(a.getReturnValue()) === 'true' )
                {
                    component.set('v.classificationOptions', component.get('v.allclassificationOptions').filter(item => item.label !== "Planned Investment" && item.label !== "Unplanned Investment" )  );
                    component.find("iwClassificationCustom").set("v.value","Product/Platform Work");
                    component.find("iwClassification").set("v.value" , component.find("iwClassificationCustom").get("v.value" )  );
                    prodValues = component.get('v.classificationOptions');
                    console.log('got the previous values ' , prodValues);

                    //19.5 toggle Account Presence
                    component.set("v.toggleSecurity",true); 
                    component.set("v.accountId",accountid.toString());
                    helper.getAccountDetailsHelper(component, event, helper,accountid).then(function(resp){
                        console.log("---getLoeBudget Resp--"+resp);
                        component.set("v.showBudget",true);  
                        
                    }).catch(function(err){
                        helper.setToastVar("Error: Failed to get available LOE for the selected Account.");
                        console.log('err :: ' + err);
                    });


                } else 
                {
                    component.set('v.classificationOptions', component.get('v.allclassificationOptions').filter(item => item.label !== "Product/Platform Work")  );  
                    if(component.find("iwClassificationCustom").get("v.value") === "Product/Platform Work")
                    {
                        component.find("iwClassificationCustom").set("v.value","Planned Investment");
                        component.find("iwClassification").set("v.value" , component.find("iwClassificationCustom").get("v.value" )  );
                    }
                    

                    //19.5 toggle Account Presence
                    component.set("v.toggleSecurity",true); 
                    component.set("v.accountId",accountid.toString());
                    helper.getAccountDetailsHelper(component, event, helper,accountid).then(function(resp){
                        console.log("---getLoeBudget Resp--"+resp);
                        component.set("v.showBudget",true);  
                        
                    }).catch(function(err){
                        helper.setToastVar("Error: Failed to get available LOE for the selected Account.");
                        console.log(' erroror : ' , err);
                    });
                }
                            
                
            });
            $A.enqueueAction(action);


            

            // console.log(' just before in here :: ' ,  accountid.toString() , ' andd :: ' , internalAccountid , ' constb :: ' , ( accountid.toString().includes( internalAccountid )) );

            
            /*
            console.log("availableLoeBud--accountid" + accountid);
            console.log(JSON.stringify(component.get("{!v.accountId}"))); 
            var getAvailableBudgetAction = component.get("c.availableLoeBudget");
            getAvailableBudgetAction.setParams({
                "accountInfo":accountid.toString()
            });
            
            getAvailableBudgetAction.setCallback(this, function(result){
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){
                    var loeResult = result.getReturnValue();
                    component.set("v.availableLoeBud",loeResult);
                    console.log('availableLoeBud--: ' + loeResult);
                }
                else if(component.isValid()){
                    var errors = result.getError();
                    console.log("getLoeBudget Unknown error"+JSON.stringify(errors[0]));
                    helper.setToastVar("Error: Failed to get available LOE for the selected Account.");
                }
            });
            $A.enqueueAction(getAvailableBudgetAction);*/
        }
        else{
            component.set("v.availableLoeBud","0");
            console.log(' setting thiss :: ' , component.get("v.showBudget") );
            component.set("v.showBudget",true);
        }
    },
  
    //Removed other field since this will be not be used after IW Revamp
    
    // displayOtherField: function(component, event, helper){
    //     var workTypeVal = event.getParams("Work_Type__c").value;
    //     if(workTypeVal ==="Other (Add Comment)"){
    //         component.set("v.displayOtherField","true");
    //     }
    //     else{
    //         component.set("v.displayOtherField","false");
    //     }
    // },

    /* displayProjForSecurity: function(component, event, helper){
        var securityChecked = component.find("securityCheckId").get("v.value");
        if(securityChecked){
            component.set("v.displayProjectForSecurity",true);
        }
        else{
            component.set("v.displayProjectForSecurity",false);
            component.set("v.toggleSecurity",false);
            //set project id also null
            //component.set("{!v.projRec}", null);
            //var proPresent = component.find("projectField").get("v.value");
            //if(!proPresent){
                //component.find("projectField").set("v.value", null);
            //}
            
        }
        var recordId = component.get("v.recordId");
        var accountid = recordId !== "" ? component.find("accountField").get("v.value") :  component.get("v.AccId")  ;
        accountid = (accountid !== null || accountid !== undefined ) && recordId !== "" ?  accountid : accountid[0];
        console.log("accountid----"+accountid); 
        if(accountid !== null && accountid !== undefined && accountid.length > 0){
            component.set("v.toggleSecurity",true);
            component.set("v.accountId",accountid.toString());
            helper.getAccountDetailsHelper(component, event, helper,accountid).then(function(resp){
                console.log("---getLoeBudget Resp--"+resp);
                }).catch(function(err){
                        helper.setToastVar("Error: Failed to get available LOE for the selected Account.");
                    });
            }
        else{
            component.set("v.availableLoeBud","0");
            console.log(' not heree?? : ' , component.get("v.showBudget") );
            component.set("v.showBudget",true);
        }

        


        var action = component.get('c.getSecurityProj');
        action.setStorable();
        action.setCallback(this,function(a){
            
            var retObj = JSON.parse(a.getReturnValue());
            component.set("v.projRec",retObj); 
            component.find("projectField").set("v.value", retObj.val); 
            
        });

        $A.enqueueAction(action);

    }, */
    
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
  
    //function to fetch LOE budget after classification change 
    handleClassificationChange: function (cmp,event,helper) {
        var accountid =  cmp.get('v.accountId');

        //this.getLoeBudget(cmp, event , helper);
        // console.log('after ? ');

        // var a = cmp.get('c.getLoeBudget');
        // console.log('after ? here  ');
        // $A.enqueueAction(a);

        // console.log('after ? any');
        // console.log('bfre methos');

        //$A.enqueueAction(cmp.get('c.getLoeBudget'));
        

        console.log('aftr methos 11' , cmp.get("v.availableLoeBud") , ' acc :  ' ,  cmp.get('v.accountId') );

        cmp.find("iwClassification").set("v.value" , cmp.find("iwClassificationCustom").get("v.value" )  );
        if(accountid === undefined)
        {
            console.log(' acc isid : ' , cmp.get("v.iwDetails.Account__c") );
            accountid = cmp.get("v.iwDetails.Account__c") ;
        }


        if(accountid !== null && accountid !== undefined && accountid.length > 0){

            console.log('bevoe method call :11: ' , cmp.get("v.showBudget") );

            helper.getAccountDetailsHelper(cmp, event, helper,accountid).then(function(resp){
                console.log("---getLoeBudget Resp--11"+resp);
                cmp.set("v.showBudget",true);  
                
            }).catch(function(err){
                helper.setToastVar("Error: Failed to get available LOE for the selected Account.");
                console.log('err :: ' + err);
            });

        }
        else{
            cmp.set("v.availableLoeBud","0");
            console.log(' setting thiss :: ' , cmp.get("v.showBudget") );
            cmp.set("v.showBudget",true);
        }
        
    },
    
    handleRecordUpdated: function(component, event, helper){
        var eventParams = event.getParams();
        var recId = component.get("v.recordId");
        var accountid = component.get("v.iwDetails.Account__c") ; 
        var action;
      
        // added changes for checking the account type and loading values into custom field 
        
        var iwStatus = component.get("v.iwDetails.Status__c") ;

        console.log('in int ' , component.find("accountField").get("v.value") , ' nxt:: ' ,  component.find("iwClassification").get("v.value" ) );

        console.log(' chk option1 : ' ,  component.get("v.iwDetails.IW_Classification__c") );

        console.log(' statuss ::  ', component.get("v.iwDetails.Status__c")  );

        if( iwStatus !== null && iwStatus !== '' && iwStatus !== undefined  && iwStatus !== 'Saved' && iwStatus !== 'Awaiting Approval' && iwStatus !== 'Escalated' )
        {
            component.set("v.disableBtn","true");
        }

        if(accountid !== null && accountid !== undefined)
        {
            action = component.get('c.getAccountIdInternal');
            action.setParams({
                "accountId" :accountid.toString()
            });
            
            action.setStorable();
            action.setCallback(this,function(a){

                console.log( ' cndtm 11:: ' , JSON.parse(a.getReturnValue()) === 'true' , 'nextt 1: ' , JSON.parse(a.getReturnValue())  );

                if( JSON.parse(a.getReturnValue()) === 'true' )
                {
                    component.set('v.classificationOptions', component.get('v.allclassificationOptions').filter(item => item.label !== "Planned Investment" && item.label !== "Unplanned Investment" )  );
                    component.find("iwClassificationCustom").set("v.value","Product/Platform Work");
                    component.find("iwClassification").set("v.value" , component.find("iwClassificationCustom").get("v.value" )  );
                    

                    component.set("v.accountId",accountid.toString());
                    helper.getAccountDetailsHelper(component, event, helper,accountid).then(function(resp){
                        console.log("---getLoeBudget Resp-11-"+resp);
                        component.set("v.showBudget",true);  
                        
                    }).catch(function(err){
                        helper.setToastVar("Error: Failed to get available LOE for the selected Account.");
                        console.log('err 11:: ' + err);
                    });


                } else 
                {
                    component.set('v.classificationOptions', component.get('v.allclassificationOptions').filter(item => item.label !== "Product/Platform Work")  );  
                    if(component.find("iwClassificationCustom").get("v.value") === "Product/Platform Work")
                    {
                        component.find("iwClassificationCustom").set("v.value","Planned Investment");
                        component.find("iwClassification").set("v.value" , component.find("iwClassificationCustom").get("v.value" )  );
                    }

                    component.set("v.accountId",accountid.toString());
                    helper.getAccountDetailsHelper(component, event, helper,accountid).then(function(resp){
                        console.log("---getLoeBudget Resp--11"+resp);
                        component.set("v.showBudget",true);  
                        
                    }).catch(function(err){
                        helper.setToastVar("Error: Failed to get available LOE for the selected Account.");
                        console.log(' erroror : ' , err);
                    });
                }
                            
                
            });
            $A.enqueueAction(action);

        }

        if(eventParams.changeType === "LOADED" && recId) {
            var iwDetails = component.get("v.iwDetails");
            component.find("iwClassificationCustom").set("v.value" ,  component.get("v.iwDetails.IW_Classification__c")  );
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
            
            
            //20.5 set Opportunity on load if its present
            if(component.get("v.iwDetails.Opportunity__c") !== undefined && component.get("v.iwDetails.Opportunity__c") !== '' && component.get("v.iwDetails.Opportunity__c") !== null){
                
                var oppRec = {};
                oppRec['SObjectType'] = 'Opportunity';                        
                oppRec['text'] = component.get("v.iwDetails.Opportunity_Name__c");                        
                oppRec['val'] = component.get("v.iwDetails.Opportunity__c");
                var accountIDonLoad = component.get("v.iwDetails.Account__c");
                component.set('v.oppRec',oppRec);
                component.set('v.accountId',accountIDonLoad);
            }
          
          // Removed security checks since security will not be used after IW revamp
            
            //20.5 set Project lookup if its a security project
            // if(component.get("v.iwDetails.Security__c")){
            //     var prjRec = {};
			// 	prjRec['SObjectType'] = 'pse__Proj__c';                        
			// 	prjRec['text'] = component.get("v.iwDetails.Project_Name__c");                        
			// 	prjRec['val'] = component.get("v.iwDetails.Project__c");                        
            //     component.set('v.projRec',prjRec);
            //     component.set('v.displayProjectForSecurity', true);
			// 	component.set('v.toggleSecurity',true);
            // }
        }

        
    }
    
})