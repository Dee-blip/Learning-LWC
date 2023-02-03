({
     init : function(component, event, helper) {
         var today = new Date();
         component.set('v.year', today.getFullYear());
    }
})