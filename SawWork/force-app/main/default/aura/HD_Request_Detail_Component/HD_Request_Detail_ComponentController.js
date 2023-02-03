({
    doInit : function(component, event, helper) {
        var action = component.get("c.getDetails");

         // Added for PRTORES-686 SR Edit
          var edtlnk = component.find('ar_sr_edit_link');
          $A.util.addClass(edtlnk, 'hideMe');
          component.set("v.srdt_mode",true);

           var spinner = component.find("mySpinner_head");
            $A.util.toggleClass(spinner, "slds-hide");

         // End of PRTORES-686


        action.setParams({
            incidentID : component.get("v.recordId")
        });



        action.setCallback(this,function(data){
            component.set("v.placeholder",false);
            var data = data.getReturnValue();

            if(data == null){

                var cmpTarget = component.find('serviceRequestComponent');
                $A.util.addClass(cmpTarget, 'hideMe');
                var cmpTarget = component.find('incidentComponent');
                $A.util.addClass(cmpTarget, 'showMe');


            } else{
                var cmpTarget = component.find('serviceRequestComponent');
                $A.util.addClass(cmpTarget, 'showMe');
                var cmpTarget = component.find('incidentComponent');
                $A.util.addClass(cmpTarget, 'hideMe');



            //var p =data.srInputDetails;
            var inputDetails =data.srInputDetails;
            //var q = data.srInformation.BMCServiceDesk__FKClient__r;
            var srClient = data.srInformation.BMCServiceDesk__FKClient__r;
            //var sc = data.dataDisplayInSecondColumn;
            var secondColDisplay = data.dataDisplayInSecondColumn;
            //console.log(secondColDisplay);
            var srdetails = [];

            var srinformations = [];


                if(!secondColDisplay){
                    for (var key in inputDetails) {
                        if (inputDetails.hasOwnProperty(key)) {
                            //console.log(key);
                            //console.log(inputDetails[key]);
                            //console.log(key + " -> " + inputDetails[key].BMCServiceDesk__Input__c);
                            //console.log(key + " -> " + inputDetails[key].BMCServiceDesk__Response__c);
                            //console.log(key + " -> " + inputDetails[key].HD_Ffi_Response_Type__c );
                            var additionalInfo = inputDetails[key].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c;
                            //[0] - prompt | [1] - Response | [2] - Response Type | [3] - additionalInfo | [4] - tooltip
                            srdetails.push(new Array(inputDetails[key].BMCServiceDesk__Input__c,
                                inputDetails[key].BMCServiceDesk__Response__c,
                                inputDetails[key].HD_Ffi_Response_Type__c,
                                additionalInfo,
                                inputDetails[key].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c ));

                        }

                    }
                }

                if(secondColDisplay){

                    var masterArr =[];

                    var col1 = [];

                    var col2 = [];
                    var tempArr = new Array();
                    for(var key in inputDetails){
                        if(inputDetails.hasOwnProperty(key)){

                            var temp = inputDetails[key].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__DisplayInSecondColumn__c ;

                            if(inputDetails[key].HD_Ffi_Response_Type__c != 'Header Section'){
                                if(!temp){
                                    col1.push(inputDetails[key]);
                                } else {
                                    col2.push(inputDetails[key]);
                                }
                            }else{

                                var mergeArry = [];
                                var index =0;

                                mergeArry = helper.mergeArray(component,col1,col2);

                                col1 =[];
                                col2 =[];
                                for(let x in mergeArry){
                                    masterArr.push(mergeArry[x]);
                                }

                                masterArr.push(new Array(inputDetails[key].BMCServiceDesk__Input__c,
                                    inputDetails[key].BMCServiceDesk__Response__c,
                                    inputDetails[key].HD_Ffi_Response_Type__c,
                                    inputDetails[key].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c,
                                    inputDetails[key].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c));

                            }

                        }
                    }
                    // to add details after end of input
                    mergeArry = helper.mergeArray(component,col1,col2);
                    for(let x in mergeArry){
                        if(mergeArry[x]) {
                            masterArr.push(mergeArry[x]);
                        }
                     }


                    srdetails = masterArr;
                }
            for (var key in srClient) {
              if (srClient.hasOwnProperty(key) && key !='Id') {



                srinformations.push(new Array(key,srClient[key]));
              }
            }

            component.set("v.displayInSecondColumn",secondColDisplay);
            //component.set("v.test",data.srInformation);
            component.set("v.srInfoMap",data.srInformation);
            component.set("v.srdetails",srdetails);
            component.set("v.srinformation",srinformations);

            // Added for PRTORES-686 SR Edit
            if (data.isEditableSR == true){
                    $A.util.addClass(edtlnk, 'showMe');
                }
                 $A.util.toggleClass(spinner, "slds-hide");
           //End 686

            }

            //component.set("v.srinformation",data.srInformation);
        });
        $A.enqueueAction(action);
    },



    edit_sr : function(component, event, helper){
        component.set("v.sredit_mode",true);
        component.set("v.srdt_mode",false);

    },

    cancel_sr_form : function(component, event, helper){
        component.set("v.sredit_mode",false);
        component.set("v.srdt_mode",true);

    },


    updateEditForm : function(component, event, helper){
        var frmRendering = event.getParam("form_rendering");
        component.set("v.sredit_mode",false);
        component.set("v.srdt_mode",false);
        if(frmRendering == "reload"){
           var a = component.get('c.doInit');
            $A.enqueueAction(a);

        }
         component.set("v.srdt_mode",true);

    }

})