({
	mergeArray : function(component, c1, c2) {
        var mergeArry = [];
        var index =0;
        console.log(c1);
        console.log(c2);

        while(index < c1.length && index< c2.length){
                                    console.log('condition 1');
                                    console.log(c1);
                                    console.log(c2);
                                     mergeArry.push(
                                         new Array(
                                             c1[index].BMCServiceDesk__Input__c,
                                             c1[index].BMCServiceDesk__Response__c,
                                             c1[index].HD_Ffi_Response_Type__c,
                                             c1[index].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c,
                                             c1[index].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c,
                                             c2[index].BMCServiceDesk__Input__c,
                                             c2[index].BMCServiceDesk__Response__c,
                                             c2[index].HD_Ffi_Response_Type__c,
                                             c2[index].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c,
                                             c2[index].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c

                                             )
                                     );


                                        index++;

                                    }
                                    while(index <c1.length){
                                        console.log('condition 2');
                                        console.log(c1[0]);
                                        mergeArry.push(new Array(c1[index].BMCServiceDesk__Input__c,
                                            c1[index].BMCServiceDesk__Response__c,
                                            c1[index].HD_Ffi_Response_Type__c,
                                            c1[index].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c,
                                            c1[index].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c,
                                                      null,null,null,null,null));
                                        console.log('condition passed');

                                        index++;

                                    }
                                    while(index < c2.length){
                                        console.log('condition 3');
                                         mergeArry.push(new Array(
                                            null,null,null,null,null,
                                             c2[index].BMCServiceDesk__Input__c,
                                            c2[index].BMCServiceDesk__Response__c,
                                            c2[index].HD_Ffi_Response_Type__c,
                                            c2[index].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c,
                                            c2[index].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c
                                                      ));

                                        index++;

          }
        return mergeArry;
	}
















})