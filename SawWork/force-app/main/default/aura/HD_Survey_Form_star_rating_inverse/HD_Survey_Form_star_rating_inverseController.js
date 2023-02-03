({
	starInitAction : function(cmp, event, helper) {
		var value = cmp.get('v.value');
        console.log('Current Value '+value);
        helper.IterateStarHelper(cmp,event,value);//function to render default value
	},
    getClickedValueHelper : function(cmp, event, helper)
    {
        var selected_value = event.getSource().get('v.value');
        cmp.set('v.value',selected_value);
        helper.IterateStarHelper(cmp,event,selected_value);
        console.log('clicked ',selected_value);
    }//
})