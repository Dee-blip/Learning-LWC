({
    showButtonCheck: function (component, event) {

        // server call to check CPQ permission of user
        var action = component.get("c.checkCPQPermission");
        action.setParams({ customPermissionApiName: 'CPQ_Partner_Place_Order' });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log('permission: ', result);
                component.set('v.hasPlaceOrderPermission', result);


                // check if quote is valid to show button
                this.checkQuoteValidityForOrder(component, event);
                //


            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);

    },

    checkQuoteValidityForOrder: function (component, event) {
        var actionOrder = component.get("c.checkQuoteValidityForOrder");
        actionOrder.setParams({ quoteId: component.get('v.recordId') });
        actionOrder.setCallback(this, function (response) {
            var stateOrder = response.getState();

            if (stateOrder === "SUCCESS") {
                var resultOrder = response.getReturnValue();
                console.log('quote valid: ', resultOrder);

                if (component.get('v.hasPlaceOrderPermission') && resultOrder) {
                    component.set('v.showButton', true);
                }
            }
            else if (stateOrder === "INCOMPLETE") {
                // do something
            }
            else if (stateOrder === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }

        });
        $A.enqueueAction(actionOrder);
    },

    // disableButtonCheck: function (component, event) {
    //     // server call to check CPQ permission of user
    //     var action = component.get("c.checkdraftQuoteLapsed");
    //     action.setParams({ quoteId: component.get('v.recordId') });
    //     action.setCallback(this, function (response) {
    //         var state = response.getState();
    //         if (state === "SUCCESS") {
    //             var result = response.getReturnValue();
    //             console.log('buttonDisabled: ', result);
    //             component.set('v.buttonDisabled', result);

    //         }
    //         else if (state === "INCOMPLETE") {
    //             // do something
    //         }
    //         else if (state === "ERROR") {
    //             var errors = response.getError();
    //             if (errors) {
    //                 if (errors[0] && errors[0].message) {
    //                     console.log("Error message: " +
    //                         errors[0].message);
    //                 }
    //             } else {
    //                 console.log("Unknown error");
    //             }
    //         }
    //     });
    //     $A.enqueueAction(action);
    // }
    /**
     * 
     * @param {dom} component aura component element
     * @param {string} message custom message which needs to be parsed
     * @returns parsed message, which resolves for the api names retrieved in this component
     */
    getMessageString: function( component, message ){

        let findFieldName = /[A-Za-z][A-Za-z_]*__[cC]/g;
        
        let matchArray = message.match(findFieldName);
        if ( matchArray == null){
            return message;
        }
        for( let index = 0; index < matchArray.length; index++){  
            message = message.replace(matchArray[index], component.get('v.quoteRecord.' + matchArray[index]));
        }
        return message;
    }
})