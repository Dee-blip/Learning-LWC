({
	addNote : function(component, event) {
		var action = component.get("c.addClientNote");
        var incId = component.get("v.recordId");
        var note = component.find("noteInput").get("v.value");
        action.setParams({"incidentID":incId,"note":note});
        action.setCallback(this,function(response){
            this.doneWaiting(component);
            component.find("noteInput").set("v.value","");
            var state = response.getState();
            if(state == 'SUCCESS'){
                console.log('successfully added client note');
            } else {
                console.log('failed to add client note');
                var errors = response.getError();
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, this, errors[0].message, errors[0].message,false, 'error');
                this.doneWaiting(component);
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire(); 
                return;
            }
            $A.get('e.force:refreshView').fire();
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