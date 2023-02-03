({
    ButtonMethod: function(component, event, helper) {
        var label = event.getSource().get("v.label");
        console.log(label);
        if(label=='Mapping')
        {
            component.set("v.IsButton1",true);
             component.set("v.IsButton2",false);
             component.set('v.IsButton3',false);
    
            console.log('inside Button1');

        } 
        else
            if(label=='Script')
        {
            component.set('v.IsButton2',true);
            component.set('v.IsButton1',false);
            component.set('v.IsButton3',false);
             console.log('inside Button2');

        }
        
         else
            if(label=='SFDC - EDW')
        {
            component.set('v.IsButton2',false);
            component.set('v.IsButton1',false);
            component.set('v.IsButton3',true);
             console.log('inside Button3');

        }    
    }
})