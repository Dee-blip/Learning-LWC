({
	reopenTicketHandle : function(component,event) {
        console.log('i fired');
		var action = component.get("c.reopenTicket");
        var recordId = component.get("v.recordId");
        action.setParams({incId:recordId });
        action.setCallback(this, function(response){
            this.doneWaiting(component);
            var state=response.getState();
            if(state=='SUCCESS'){
                $A.get('e.force:refreshView').fire();
            }else if(state == 'ERROR'){
                var errors = response.getError();
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, this, errors[0].message,errors[0].message,false, 'error');
            }
            $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
        });
        $A.enqueueAction(action);
        this.waiting(component);
	},
    
    waiting: function(component) {
        var ele = component.find("Accspinner");
        console.log(ele);
        $A.util.addClass(ele,"slds-show");
        $A.util.removeClass(ele,"slds-hide");
        //document.getElementById("Accspinner").style.display = "block";
     },
     
      doneWaiting: function(component) {
            var ele = component.find("Accspinner");
            $A.util.addClass(ele,"slds-hide");
            $A.util.removeClass(ele,"slds-show");
     }
    
    
})