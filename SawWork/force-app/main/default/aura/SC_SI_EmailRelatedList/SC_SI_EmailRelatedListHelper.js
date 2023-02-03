({
	helperMethod : function(component,event,helper) {
       // var i=0;
        var itr=0;
         var action = component.get("c.getEmailRelatedListData");
        action.setParams({ "serviceIncidentId" : component.get("v.recordId") });

       
        action.setCallback(this, function(response) {
            var state = response.getState();
           
            if (state === "SUCCESS") {
               debugger; 
               var res = response.getReturnValue();
               component.set("v.title",component.get("v.title")+' ('+res.length+')');
               if(res.length == 0){
                    component.set("v.showToast",true);
                }  
               var tempList = [];
                // Showing View All button if total recs are more than 3
                if(res.length > 3){
                    component.set("v.showViewAll",true);
                }
                
                res.forEach(loadType);

                // Setting type=Incomg/Outgoing mail type
                function loadType(item) {
                    if(item.Incoming){
                        item.type = 'Incoming';
                    }else{
                        item.type='Outgoing';
                    }
                    item.recordLink = "/" +  item.Id;
                }
                //Pushing first 3 recs. to show on default load
                if(res.length > 0){
                    var iterateTill =3;
                    if(res.length == 1){
                        iterateTill =1;
                    }
                    for(itr=0;itr<iterateTill;itr++){
                    
                        tempList.push(res[itr]);
                    }
                }
                component.set("v.initialData",tempList);
                component.set("v.data",res);
            }
            else if (state === "INCOMPLETE") {
                
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
		
	}
})