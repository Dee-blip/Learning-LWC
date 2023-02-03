({
    
    doInit : function(component, event, helper) {
       var action = component.get("c.getIncident"); 
       
        action.setParams({ incidentId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            
         if(response.getState() == 'SUCCESS'){   
        component.set("v.incident", response.returnValue);
            
            if (response.returnValue.BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c
 == 'Closed'  || response.returnValue.BMCServiceDesk__Status_ID__c == "RESOLVED" ){
                component.set("v.shownote","false");
            }
            helper.showNote();
         }   
         else if(response.getState() == 'ERROR'){
                console.log('Failed to get initialized in Add Note');
                var errors = response.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false);
                return;
            }
        });
        
        
        
        var action1 = component.get("c.isAccessableRecord"); 
       
        action1.setParams({ incidentId : component.get("v.recordId") });
        action1.setCallback(this, function(response) {
        
            var state = response.getState()
            if(state == 'SUCCESS'){
                if (response.returnValue != true){
                   component.set("v.shownote","false");
                }
                helper.showNote();
            }else if( state == 'ERROR'){
                console.log('Failed to get initialized in Add Note Accessable');
                var errors = response.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false);
                return;
            }
        });
        
        $A.enqueueAction(action); 
        $A.enqueueAction(action1); 
		
	},
    
    //to focus on timestamp and note when tab is pressed
    tabhandler : function(component, event, helper) {
        
         var charCode = event.keyCode;
        // charector code 9 is for tab key
         if (charCode == 9) {
             event.preventDefault();
             $A.util.getElement("timespent").focus();   
         }
        
    },
    
	countnotechar : function(component, event, helper) {
     
        var val = $A.util.getElement("free_note").value;
        var trimmed_val = val.trim();
        if(val.length > 3 && trimmed_val != ''){
            
            $A.util.getElement("note_button").disabled = false;
        }	else
        {
            $A.util.getElement("note_button").disabled = true;
        }
        
        var char_ct = 2000 - val.length
        if(char_ct < 0){
            char_ct = 0 
        }
            
        $A.util.getElement("char_count_msg").innerHTML = "&nbsp;&nbsp; "+char_ct+" charecters left &nbsp;&nbsp;";

     
        
        if(char_ct < 0){
           $A.util.getElement("char_count_msg").innerHTML = "&nbsp;&nbsp; Only 2000   &nbsp;&nbsp;";
 
        }
        	},
    
    submitnote: function(component, event, helper) {

        var msgspace = component.find('a_msg_space');
        var msgdescr = component.find('a_msg_descr');
        var msgspinner = component.find('a_msg_spinner');
        
        var n_text = $A.util.getElement("free_note").value;
        var ts_mm = $A.util.getElement("timespent").value;
      
        var re = /^([0-9])$|^([0-5][0-9])$|^(60)$/g;  // Verify time stamp syntax
        ts_mm.trim();
        if( ts_mm == '' || !ts_mm.match(re)){
          
            var  msg = "Enter minutes value from 00 to 60  '"+ts_mm+"' is not valid.";
            helper.ShowMessage(component,msg,true);
            return;
        }
        
        var t_val = '';
        t_val = "00:"+ts_mm;
        if (ts_mm == '60'){
            t_val = "01:00";
        }
        
        if (ts_mm.length == 1){
            t_val = "00:0"+ts_mm;
        }
        $A.util.getElement("msg_descr").innerText = ' Saving Staff Note ..'
        
        $A.util.addClass(msgdescr, "waitmsg");
        $A.util.removeClass(msgspace, "slds-hide");
        $A.util.removeClass(msgspinner, "slds-hide");
       
	    var rerender = component.get("v.rerender"); 
        var inciId = component.get("v.recordId"); 
        var action = component.get("c.saveActionNote"); 
       
        action.setParams({ incidentId : inciId, txt: n_text, timespent : t_val  });

        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("response"+response.returnValue);
            var  rval = response.returnValue
            
            if( state == "SUCCESS" ){
                
                if(rval.indexOf('SUCCESS')> -1){
                    if (rerender == true){
                       component.set("v.rerender", false);
                    }else{
                        component.set("v.rerender", true);
                    }
                    
                    $A.util.getElement("msg_descr").innerText = '';
                    helper.ShowMessage(component,"Note saved successfully !",false);
                    $A.util.getElement("timespent").value = "";
                    $A.util.getElement("free_note").value = "";
                    $A.util.getElement("note_button").disabled = true;
                    $A.util.getElement("char_count_msg").innerHTML = "&nbsp;&nbsp;2000 charecters left &nbsp;&nbsp;";

                    $A.get('e.force:refreshView').fire();
                
                }else{
                    throw new Error(response.returnValue);
                }
            
            } else if( state == 'ERROR'){
                console.log('Failed to get initialized in Add Note Accessable');
                var errors = response.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false);
                $A.util.getElement("msg_descr").innerText = '';
            }
             $A.util.addClass(msgspinner, "slds-hide");
         
        });

        $A.enqueueAction(action); 
   
	},
    
   
})