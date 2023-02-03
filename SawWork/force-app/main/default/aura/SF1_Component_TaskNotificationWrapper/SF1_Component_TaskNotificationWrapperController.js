({
    doInit : function(component)
    {
        $A.createComponent("c:SF1_Component_TaskInterface", {
            "taskId":component.get("v.taskId"),

        }, function(newCmp) {
            if (component.isValid()) {
                component.set("v.body", newCmp);
            }
        });
    }
    ,
    navigateToAllTask: function(component, event, helper)
    {
        console.log('navigateToAllTask ');
        var attributes = event.getParam('paramMap');
        var nameOfCmp = event.getParam('nameOfCmp');
        console.log('attributes :',attributes);
        console.log('nameOfCmp :',nameOfCmp);

        if(nameOfCmp === 'c:SF1_TaskCmpParent')
        {
            $A.createComponent(nameOfCmp,
                               {
                                   'paramMap' :attributes
                               },
                               function(newComponent){
                                   component.set("v.body",newComponent);

                               });
        }
    }
})