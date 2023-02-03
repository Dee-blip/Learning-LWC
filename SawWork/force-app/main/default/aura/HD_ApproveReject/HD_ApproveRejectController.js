({
    
 
   doInit: function (cmp, event, helper) {
        
        helper.getData(cmp);
       
    },

    showApprovalPage: function(component,event,helper){
        
            //component.set("v.isFirefox","false");
            var id = event.currentTarget.dataset.id;
            //var url ="https://"+window.location.hostname+"/one/one.app#/sObject/"+id+"/view";
           	var url ="/lightning/r/BMCServiceDesk__Incident__c/"+id+"/view";
          
            component.set("v.ifmsrc",encodeURI(url));
            var cmp=component.find("modalId");
            $A.util.removeClass(cmp,"slds-hide");
        
    },
    
    hideModal: function(component,event,helper){
        var cmp=component.find("modalId");
        $A.util.addClass(cmp,"slds-hide");
     	
    }
})