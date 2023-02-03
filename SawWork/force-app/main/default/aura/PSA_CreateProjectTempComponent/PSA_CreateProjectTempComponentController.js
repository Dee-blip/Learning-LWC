({
    init : function(component, event, helper) {
        var rId;
        var pageRef = component.get("v.pageReference");
        console.log('pageRef: ' + JSON.stringify(pageRef));
        console.log('window.location.href: ' + window.location.href);
        var accountId;
        var oppId;
        if(pageRef != undefined)
        {   
            rId = pageRef.state.ws;
            console.log("pageRef.state.ws:"+ rId);
            if(rId != undefined)
            {
                rId = rId.substr(rId.indexOf("0"), 18);
                
            }
            else
            {
                console.log("In ELSE part");
                rId = pageRef.state.inContextOfRef;
                console.log("pageRef.state.inContextOfRef" + rId);
                rId = rId.split(".");
                if(rId != undefined)
                {
                    rId = rId[1];
                    if(rId != undefined)
                    {
                        rId = atob(rId);
                        rId = JSON.parse(rId);
                        console.log('RID: ' + rId.attributes);
                        rId = rId.attributes.recordId;
                    }
                }
                
            }
        }
        console.log('I AM HERE: ' + rId);
        
        if(rId != undefined)
        {
            console.log('HERE: ' + rId);
            
            if(rId.startsWith('001'))
            {
                accountId = rId;
                helper.navigateToCreatePage(accountId,oppId,component);
                
            }
            else if(rId.startsWith('006'))
            {
                oppId = rId;
                var action = component.get("c.getAccount");
                action.setParams
                (
                    {
                        oppId: rId
                    }                
                );
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    var messageToShow = '';
                    var toastType = '';
                    if (state === "ERROR") 
                    {
                            helper.showToastMessage('error','Error occured');                
                    }
                    else if (state === "SUCCESS")
                    {
                        console.log("state: " + state);
                        var result =response.getReturnValue(); 
                        if(result.startsWith('SUCCESS') )
                        {
                            console.log("result: " + result);
                            accountId = result.split(':')[1];
                            console.log("accountId: " + accountId);
                            helper.navigateToCreatePage(accountId,oppId,component);                            
                        }
                        else
                        {   
                            helper.showToastMessage('error',result);                
                        }
                        
                    }
                });
                $A.enqueueAction(action);     
            }
        }
        else
        {
            helper.showToastMessage('error','New projects must be created from an account or opportunity.');                
            helper.navigateToCreatePage(accountId,oppId,component);                            
        }
    },
})