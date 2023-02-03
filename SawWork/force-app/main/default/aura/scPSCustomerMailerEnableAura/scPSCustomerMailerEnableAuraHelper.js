({
    doInit : function(component) {
        var action = component.get('c.getRecDetail'); 
        var action1;
        action.setParams({
            "recId" : component.get('v.recordId') 
        });
        action.setCallback(this, function(a){
           // alert(a.getReturnValue().Is_Master_Record__c);
            var state = a.getState(); // get the response state
            
            if(state === 'SUCCESS') {
                if(a.getReturnValue() === null){
                    this.showToast('You are not SSP role team member on Account.','error','dismissable');
                    $A.get("e.force:closeQuickAction").fire();
                }
                else if(a.getReturnValue().Is_Master_Record__c){
                    this.showToast('Master Customer Mailer can not be Enabled.','error','dismissable');
                    $A.get("e.force:closeQuickAction").fire();
                }else if($A.util.isUndefinedOrNull(a.getReturnValue().Disabled_On__c)){
                    this.showToast('Customer Mailer is already enabled.','error','dismissable');
                    $A.get("e.force:closeQuickAction").fire();
                }/*else if(!a.getReturnValue().Team_Member_Id__c.includes($A.get("$SObjectType.CurrentUser.Id"))){
                    this.showToast('You are not authorized to do it.','error','dismissable');
                    $A.get("e.force:closeQuickAction").fire();
                }*/else{
                    action1 = component.get('c.enableMailerRecord'); 

                    action1.setParams({
                            "recId" : component.get('v.recordId') 
                        });
                        action1.setCallback(this, function(b){
                        
                            var state1 = b.getState(); // get the response state
                            if(state1 === 'SUCCESS') {
                                if(b.getReturnValue() === ''){
                                    this.showToast('Customer Mailer Record is marked enabled.','Success','dismissable');
                                $A.get("e.force:closeQuickAction").fire();
                                window.location.reload(true);
                                }else{
                                    this.showToast(b.getReturnValue(),'Success','dismissable');
                                    $A.get("e.force:closeQuickAction").fire();
                                }
                            }
                            else if(state1 === 'ERROR') {
                            this.showToast('Please contact System Administrator.','error','dismissable');
                            $A.get("e.force:closeQuickAction").fire();
                            }
                            else if(state1 === 'INCOMPLETE') {
                                this.showToast('Please contact System Administrator.','error','dismissable');
                                $A.get("e.force:closeQuickAction").fire(); 
                            }
                        });
                        $A.enqueueAction(action1);
                }
            }
            else if(state === 'ERROR') {
               this.showToast('Please contact System Administrator.','error','dismissable');
               $A.get("e.force:closeQuickAction").fire();
            }
            else if(state === 'INCOMPLETE') {
                this.showToast('Please contact System Administrator.','error','dismissable');
                $A.get("e.force:closeQuickAction").fire(); 
            }
        });
        $A.enqueueAction(action);
    },

       

    showToast :function(msg,type,mode){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            
            message: msg,
            
            
            type: type,
            mode: mode
        });
        toastEvent.fire();
    }
})