({
    getApprovalsHelper : function(cmp,event) {
        var RecordId = cmp.get("v.recordId");
        var recordCount = cmp.get("v.rowCount");
        var targetObjectIdvalue = "a5U3D000000DHGoUAO";
        //console.log('-->'+RecordId);
        console.log('-->'+recordCount);
        if(RecordId != null)
        {
            targetObjectIdvalue = RecordId;
        }        
        var unifiedApprovalHistory = cmp.get("c.getApprovalHistory");
        unifiedApprovalHistory.setParams({
            targetObjectIdvalue : targetObjectIdvalue,
            rowCount : recordCount
        });
        
        unifiedApprovalHistory.setCallback(this,function(resp){
            var state = resp.getState();
            if( state === "SUCCESS"){ 
                var respo = resp.getReturnValue();
                respo.splice(0,1);
                console.log("-->"+JSON.stringify(respo));
                console.log(respo.length);
                //setting the array now
                cmp.set("v.unifiedApprovalHistory",respo);
            }
            else if(state === "RUNNING"){
                
            }
            else if(state === "ERROR"){
                
                var errors = resp.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else { console.log("Unknown error"); }
            }
        });//
                                     
     $A.enqueueAction(unifiedApprovalHistory);		
    }
})