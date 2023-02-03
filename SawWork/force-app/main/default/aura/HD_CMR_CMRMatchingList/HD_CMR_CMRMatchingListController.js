({
    doInit: function(component, event, helper){
        var id = component.get("v.recordId");
        console.log(" INIT "+id);
        var action = null;
         action = component.get("c.getSOMatchingCMRList");
         action.setParams({recordId: component.get("v.recordId")});
         action.setCallback(this, function(data) {
             var  ret_cmrlist = data.getReturnValue();
             let state = data.getState();
            
               if (state === "SUCCESS") {
                    console.log(ret_cmrlist.length);
                      component.set('v.changerequests', ret_cmrlist);
               } else if (state === "ERROR") {
                   var errors = data.getError();
                   console.log(errors.message);
                  

               } 
        });

       $A.enqueueAction(action); 
        
    },
    
    handleOutageMatchingCMRList: function(component, event, helper){
    console.log("handle event "+event.getParam("e_conditions"));
        console.log(" event handle "+event.getParam("e_serviceoutage"));
        console.log(event.getParam("e_startdate"));
        var so = event.getParam("e_serviceoutage");
        console.log("so "+so);
     var action = null;
    if(so == null ){
      action = component.get("c.getMatchingCMRList"); 
      action.setParams({ 
                         startdate: event.getParam("e_startdate"),
                         enddate: event.getParam("e_enddate"),
                         services: event.getParam("e_services"),
                         subservices: event.getParam("e_subservices"),
                         
                         condition: ''
      });
       
    
    }else{
            action = component.get("c.getOutageMatchingCMRList");
            action.setParams({serviceoutage: event.getParam("e_serviceoutage")});
    }
       
        
        
      action.setCallback(this, function(data) {
             var  ret_cmrlist = data.getReturnValue();
             let state = data.getState();
            
               if (state === "SUCCESS") {
                    console.log(ret_cmrlist.length);
                      component.set('v.changerequests', ret_cmrlist);
               } else if (state === "ERROR") {
                   var errors = data.getError();
                   console.log(errors.message);
                  

               } 
        });

       $A.enqueueAction(action); 

    },
    
    sendNotification: function(component,event,helper){
       var recid =  event.currentTarget.dataset.changeid;
        console.log(" HERE recid "+recid);
        var action1 = component.get("c.notifyOwner");
        action1.setParams({ recId:recid });
        console.log(" GFGF "+action1);
        action1.setCallback(this, function(data) {
            console.log(" STATE123 ");
             var  resp = data.getReturnValue();
             let state = data.getState();
            console.log(" STATE "+resp);
            if (state === "SUCCESS") {
                alert(resp);
            } else if (state === "ERROR") {
                var errors = data.getError();
                console.log(errors.message);
            } 
        });
       console.log(" ACTION ");
       $A.enqueueAction(action1); 
        
        
    }
})