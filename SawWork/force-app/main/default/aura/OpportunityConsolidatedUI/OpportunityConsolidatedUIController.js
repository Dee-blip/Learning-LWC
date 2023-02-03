({
    //Initialize the view and fetch contact
	doInit : function(component, event, helper) {
		console.log("doInit entry in opptyconsolidateUIApp");
        //Setting the Apex Parameter
        
        //fetch contact from apex controller
        helper.getContact(component);
        helper.getsObjectRecords(component);
        //helper.getFields(component, event);
        console.log("doInit exit in opptyconsolidateUIApp");
        
	},
    pageChange: function(component, event, helper) {
         var page = component.get("v.page") || 1;
         var direction = event.getParam("direction");
         page = direction === "previous" ? (page - 1) : (page + 1);
         helper.getsObjectRecords(component,page);
    },
    previousPage : function(component, event, helper) {
        var myEvent = $A.get("e.c:PageChange");
        myEvent.setParams({ "direction": "previous"});
        myEvent.fire();
	},
	nextPage : function(component, event, helper) {
       var myEvent = $A.get("e.c:PageChange");
        myEvent.setParams({ "direction": "next"});
        myEvent.fire();
	},
    toggleSpinner: function(cmp) {
        var spinner = cmp.find('spinner');
        var evt = spinner.get("e.toggle");
        
        if(!$A.util.hasClass(spinner, 'hideEl')){
            evt.setParams({ isVisible : false });
         }    
        else {
            evt.setParams({ isVisible : true });
          }
        evt.fire();
    },
    showSpinner : function (component) {
     var toggleText = component.find('spinner');
                var evt = spinner.get("e.toggle");
              evt.setParams({ isVisible : true });
        evt.fire();
    //$A.util.removeClass(toggleText,'toggle');
},

 hideSpinner : function (component) {
   var toggleText = component.find('spinner');
      var evt = spinner.get("e.toggle");
     evt.setParams({ isVisible : false });
        evt.fire();
//   $A.util.addClass(toggleText,'toggle');
  },
    redirectToMicrosite: function(component, event, helper) {
        var alertId =  event.getSource().get("v.class");
          window.open("http://"+alertId);                
            return true;
    },
    saveObj : function(component, event, helper) {
        	console.log("save Entry in opptyconsolidateUIApp");
        	helper.saveContact(component);
        	//component.find("edit").get("e.recordSave").fire();
        }
})