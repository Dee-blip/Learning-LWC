// Controller to Void Poa Documents. SDFC-7900 



    // onInit : function(component, event, helper) {
    //     console.log('in controller');
    //     var url = window.location.href;
    //     var id = url.split('/').reverse()[1];
    //     console.log(id);
    //     //return id;
    //    // $A.enqueueAction(str);
    // },
    ({
        voidDoc : function(component){
            //alert('cancelled');
            
           // var url = window.location.href;
            //var id = url.split('/').reverse()[1];
            var voidPoa;
            var returnParams;
            var toastEvent;
            var dismissActionPanel;
            var id = component.get("v.recordId");
            console.log('in void ' + id);
            voidPoa = component.get("c.voidPoaDocument");
            voidPoa.setParams({
                "poaId" : id
            });
            voidPoa.setCallback(this, function(response){
                console.log('response ' + response.getState());
                returnParams = response.getReturnValue();
                toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": returnParams[0],
                    "message": returnParams[1]
                });
                dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                toastEvent.fire();
            });
    
            $A.enqueueAction(voidPoa);
            },
        
    })