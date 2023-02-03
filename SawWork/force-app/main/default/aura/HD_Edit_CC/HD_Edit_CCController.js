({
    doInit : function(component, event, helper){
       var action1 = component.get("c.getIncident"); 
       var self = this;
       action1.setParams({ incidentId : component.get("v.recordId") });
       var firstval = '';
       action1.setCallback(this, function(data) {
          if(data.getState() == 'SUCCESS'){
           var  rval = data.getReturnValue();
           component.set("v.incident",rval);
           var ccstr = '';
           var cc_arr = []
           helper.setCCtxt(component,event,rval.CCText__c);
          
          }else if(data.getState() == 'ERROR'){
                console.log('Failed to get initialized in Edit CC');
                var errors = data.getError();
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false, 'error');/* eslint-disable-line */
                return;
            }
            
        });

        $A.enqueueAction(action1); 
        
    },
    
    updateCC : function(component, event, helper){

        var incId = component.get("v.recordId");
        var errmsg = '';

        errmsg = helper.joinUpdateCC(component);
        
        console.log('After process');
        console.log('Error - '+errmsg);
        console.log(' CC '+component.get("v.cctext")) ; 
        var txt =    component.get("v.cctext");
        if(errmsg.trim() != ''){
            component.set("v.warnings",'Please enter valid email address for - '+errmsg);
        }
        
        if(txt.trim() == ''){
             component.set("v.warnings",'Please enter valid email address');
             return;
        }
        if(errmsg == ''){
            var action = component.get("c.updateCCText"); 
            var self = this;
           
            action.setParams({ incidentId : incId, CCText : component.get("v.cctext")  });
    
            action.setCallback(this, function(response) {
                var state = response.getState();
                helper.doneWaiting(component);
                if( state == "SUCCESS"){
                    component.set("v.warnings","");
                    helper.removeallnodes();
                    var  rval = response.getReturnValue();
                    helper.setCCtxt(component,event,rval.CCText__c);
                    $A.get('e.force:refreshView').fire();
                    
                 }else if(state == 'ERROR'){
                    console.log('Failed while updating CC');
                    var errors = response.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false, 'warning');
                    component.set("v.warnings","CC email(s) not updated. Please verify the email format");
                }
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
                
                
            });

            $A.enqueueAction(action);
            helper.waiting(component);
          
            
        }
    },
        
    addCC : function(component, event, helper){
        var btn = component.find("upbtn");
        btn.set("v.disabled",false);
        helper.addCCtextbox(component,'');
    },
    
    clear_cc:  function(component, event, helper){
        helper.clearCC();
        var btn = component.find("upbtn");
        btn.set("v.disabled",false);
    },
    
    enableUpdateBttn : function (component, event, helper){
    var btn = component.find("upbtn");
    btn.set("v.disabled",false);
   },
    
    
    
    removeCC : function(component, event, helper){

         var ctarget = event.currentTarget;
         var id_str = ctarget.dataset.value;
         var cctxt =  component.get("v.savedcc");
        console.log(" IDX -- "+id_str);
        
         var ucc = helper.removeCCtxt(component,event,id_str);
        
        
        if( ucc.trim() != cctxt.trim()){
            var incId = component.get("v.recordId");
            var action = component.get("c.updateCCText"); 
            var self = this;
           
            action.setParams({ incidentId : incId, CCText : ucc  });
    
            action.setCallback(this, function(response) {
               helper.doneWaiting(component);
               var state = response.getState();
                if( state == "SUCCESS"){
                component.set("v.warnings","");
                
                var  rval = response.getReturnValue();
                
               if(rval.CCText__c != null && rval.CCText__c != ''){
                   console.log("CC Text 1 "+rval.CCText__c);
                   component.set("v.savedcc",rval.CCText__c.replace(/;/g, ',').replace(/,\s*$/, ""));
               }else{
                   component.set("v.savedcc", '');
               }

                $A.get('e.force:refreshView').fire();
            }else if(state == 'ERROR'){
                    console.log('Failed while removing CC');
                    var errors = response.getError();
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false, 'error');
               }  
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
                
            });
            $A.enqueueAction(action);
            helper.waiting(component);
            helper.hideDiv(component,event,id_str);
        }
       
    }
   
})