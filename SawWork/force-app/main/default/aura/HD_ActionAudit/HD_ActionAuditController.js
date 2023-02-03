({
	fireMe : function(component, event, helper){
       
      var endTime = new Date();
	console.log('window idle'+component.get('v.idleTime'));
        console.log('endTime'+endTime);
        var action = component.get('c.addActionAudit');
        action.setParams({
            recordId: component.get('v.recordId'),
            actionName:component.get('v.actionName'),
            startTime:component.get('v.startTime'),
            endTime:endTime,
            idleTime:component.get('v.idleTime'),
            status:event.getParam("state")
            
        });
        action.setCallback(this,function(resp){
           component.set("v.startTime",new Date());             
            
        });
        $A.enqueueAction(action);
        
        
    }
})