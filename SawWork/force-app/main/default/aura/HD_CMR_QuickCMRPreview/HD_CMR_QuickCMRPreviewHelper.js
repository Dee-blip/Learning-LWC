({
    helperMethod : function() {
        
    },
    
    showActions : function(component) {
        var change = component.get("v.change");
        
    },
    
    showhide : function(cmp){
        var el = document.getElementById('infodiv');
        if(el.style.display == 'none'){
            el.style.display = "block";
        }else{
            el.style.display = 'none'
        }
    },
    
    
    
    getApprovalHistory: function(cmp,event,helper){
        
            var change=cmp.get("v.change");
            
            try{
            var Id=change.Id;
            
            var link="https://contacts.akamai.com/photos/";
            var intiatior=link+change.BMCServiceDesk__FKInitiator__r.Alias+".jpg";
            var sponsor=link+change.HD_Sponsor__r.Alias+".jpg";
            
            cmp.set("v.intiatiorImageLink",intiatior.toLowerCase());
            cmp.set("v.sponsorImageLink",sponsor.toLowerCase());
            }catch(Exception){
            //call error logger
        }
            var action = cmp.get("c.getApprovalHistory");
            var response="";
            
            action.setParams({
                "currentCMRId" : change.Id
            });
        
        var arrayOfApprovedMapKeys=[];
        var arrayOfRejectedMapKeys=[];
        var arrayOfPendingMapKeys=[];
        var listOFActionsWhichCurrentUserCanPerform=[];
        var showOrNotApprovalHistory;
        
        action.setCallback(this,function(data){
            var state=data.getState();
            if(state==="SUCCESS"){
                var result=data.getReturnValue();
                
                for(var key in result){
                    
                    var tempValue=result[key].status;
                    if(tempValue=="Approved"||tempValue=="Submitted"){
                        arrayOfApprovedMapKeys.push(key);
                    }else if(tempValue=="Rejected"){
                        arrayOfRejectedMapKeys.push(key);
                    }else if(tempValue=="listOFActionsWhichCurrentUserCanPerform"){
                        listOFActionsWhichCurrentUserCanPerform=result[key].utilityList;
                    }else{
                        arrayOfPendingMapKeys.push(key);
                    }
                }
                var flag=arrayOfApprovedMapKeys.length;
                var arrayOfKeys;
                if(!(flag<=1 && arrayOfRejectedMapKeys.length==0 && arrayOfPendingMapKeys==0)){
                    cmp.set("v.showOrNotApprovalHistory",true);
                    var arrayOfKeys=arrayOfApprovedMapKeys.concat(arrayOfRejectedMapKeys,arrayOfPendingMapKeys)
                    }else{
                        cmp.set("v.showOrNotApprovalHistory",false);
                    }                
                try{
                    var listOfAllActions=listOFActionsWhichCurrentUserCanPerform;
                    var numberOfActions=listOfAllActions.length;
                    if(numberOfActions>4){
                        cmp.set("v.isDropDownMenuAvailable",true);
                        var listOfActionsDisplay=listOfAllActions.slice(0,3);
                        var listOfActionsMenuDisplay=listOfAllActions.slice(3,numberOfActions);
                        cmp.set('v.listOfActionsDisplay',listOfActionsDisplay);
                        cmp.set('v.listOfActionsMenuDisplay',listOfActionsMenuDisplay);
                    }else{
                        cmp.set('v.listOfActionsDisplay',listOfAllActions);
                    }
                }catch(Exception){
                    
                }
                console.log(' ALL VALUES');
                console.log(result);
                console.log(arrayOfKeys);
                 console.log(flag);
                cmp.set('v.approvalsProgress',result);
                cmp.set('v.listOfActions',listOFActionsWhichCurrentUserCanPerform);
                cmp.set('v.lstKey',arrayOfKeys);
                cmp.set('v.flag',flag);

                //if approval is pending or rejected then expand approval bar else collapse
               

                /*if(arrayOfRejectedMapKeys.length!=0 || arrayOfPendingMapKeys!=0){
                    var secId="articleOne";
                    var acc = cmp.find(secId);
                    for(var temp in acc) {
                        $A.util.toggleClass(acc[cmp], 'slds-hide');  
                        $A.util.toggleClass(acc[cmp], 'slds-show');
                    }
                } */     
            }
        });
        $A.enqueueAction(action);
    },
    helperFun : function(component,event,secId) {
	  var acc = component.find(secId);
        	for(var cmp in acc) {
        	$A.util.toggleClass(acc[cmp], 'slds-show');  
        	$A.util.toggleClass(acc[cmp], 'slds-hide');  
       }
	}
    
    
})