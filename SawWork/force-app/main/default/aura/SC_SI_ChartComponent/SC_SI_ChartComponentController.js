({ctr : function(cmp, event, helper) {
        var temp = [];
        var temp2 = [];
       // var action1 = cmp.get("c.getLineChartMap");
       // var action = cmp.get("c.getChartMap");
       var action = cmp.get("c.getAccChartMap");
    
    action.setParams({"SIrecId" : cmp.get("v.recordId")})
        action.setCallback(this, function(response){
            debugger;
            if(response.getState() === 'SUCCESS' && response.getReturnValue()){
                temp = response.getReturnValue();
                //temp = JSON.parse(response.getReturnValue());

                
                helper.createGraph(cmp, temp);
            }
        });      
     
       $A.enqueueAction(action);	
    
    }
 })