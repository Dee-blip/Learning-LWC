({
    doInit : function(component,event,helper){
        console.log('in modal');
        console.log(component.get('v.cmpName'));
        console.log(component.get('v.content'));
        if(component.get('v.cmpName')==null || component.get('v.cmpName')=='undefined')
        {
           var cmp = component.find("xid-cmp-body");
    		$A.util.addClass(cmp, "slds-hide");
        }
    },
    handleClose : function(component, event, helper) {
    var container = component.find("xid-cmp-body");
    container.set("v.body",[]);
    component.set("v.showModal",false);

    if(component.get("v.refreshOnClose")) component.set("v.refresh",true);      

},
handleCancel : function(component, event, helper) {
    var myEvent = component.getEvent("myComponentEvent");
        myEvent.setParams({"param": "Cancel"});
        myEvent.fire();
        
    var container = component.find("xid-cmp-body");
    container.set("v.body",[]);
    component.set("v.showModal",false);   
},

handleSaveButton: function(component, event, helper) {      
    component.set("v.disableSave",component.get("v.inProgress"));
},
fireMyComponentEvent : function(component, event, helper) {
        var myEvent = component.getEvent("myComponentEvent");
        myEvent.setParams({"param": "Accept"});
        myEvent.fire();
    	var container = component.find("xid-cmp-body");
        container.set("v.body",[]);
        component.set("v.showModal",false);
	},
loadCmp : function(component, event, helper) {
    var container = component.find("xid-cmp-body");
    //console.log("container :",container);

    if(component.get("v.showModal")){
        console.log("starting loading component");
        //determine which component to load             
        $A.createComponent(component.get("v.cmpName"),
                       {"recordId": component.getReference("v.recordId"),
                        "actionInProgress" : component.getReference("v.disableSave")},
                       function(cmp) {                               
                            container.set("v.body", cmp);
                       });
    }

},
  handlePress : function(cmp) {
    console.log("button pressed");
  }
})