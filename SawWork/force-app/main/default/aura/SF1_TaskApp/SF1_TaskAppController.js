({
	doInit : function(cmp, event, helper) {
        console.log('inside controller doInit');
        helper.getOpportunitiesList(cmp);
        //helper.loadPickListValues(cmp); -- not needed here

    },

    goToSF1TaskAppOACmp : function(component, event, helper) {
        console.log('inside controller goToSF1TaskAppOACmp');
        var name = 'c:SF1_TaskApp_OA_Cmp';
        var opptyId = event.currentTarget.id;
        var attributes={
            'opptyId' :opptyId
        };
        helper.navigateToCmp(component, event, helper ,name ,attributes);

    },
    
    filterSearch : function(component, evento, helper) {
        var searchString = event.target.value;
        // Access the global variable 'listOfOpptys', defined in Helper
		var listOfOpptysLocal = listOfOpptys;
        if(searchString == '' || searchString == null)
        {
            component.set("v.listOfOpptys",listOfOpptysLocal);
        }
        else
        {
        	var newlist= new Array();;
        	var j=0;
        	for(let i in listOfOpptysLocal)
			{
        		var opp = listOfOpptysLocal[i];
				var stringOpp = opp['Name'].toUpperCase();
                var stringAcc = opp.Account.Name.toUpperCase();
				if(stringOpp.includes(searchString.toUpperCase()) || 
                   stringAcc.includes(searchString.toUpperCase()))
				{
					newlist[j] = opp;
                    j++;
				}
             }
        	 component.set("v.listOfOpptys",newlist);
    	}
    }
})