({
    initAction : function(component, event, helper){
        var unifiedDate = component.get("v.undate");
        //debugger;
       //console.log('-->'+unifiedDate);
       //console.log('---> '+ helper.calculateDaysAgo(unifiedDate));
       component.set('v.days',helper.calculateDaysAgo(unifiedDate));
       
    },

})