({
	getOpportunitiesList : function(cmp) {
        console.log('inside helper getOpportunitiesList');
        var action = cmp.get("c.getOpportunities");

        action.setCallback(this, function(response) {
            var state = response.getState();
            var listOfOpptys = response.getReturnValue();
            console.log('listOfOpptys :',listOfOpptys);
						var opp;
						var string;

						for(let i in listOfOpptys)
						{
							opp = listOfOpptys[i];
							string = opp['Name'];
							
							if(string.length>28)
							{
								opp['Name']  = string.substring(0, 28);
								opp['Name'] = opp['Name']+'...';
							}
                            var stringAcc = opp.Account.Name;
							

							if(stringAcc.length>28)
							{
								opp['Account.Name']  = stringAcc.substring(0, 28);
								opp['Account.Name'] = opp['Account.Name']+'...';
							}
						}

            if (cmp.isValid() && state === "SUCCESS")
            {
                cmp.set("v.listOfOpptys", listOfOpptys);
                cmp.set("v.showopptyList", true);

								if(!listOfOpptys || listOfOpptys.length===0)
								{
									cmp.set("v.noOpptysPresent", true);
								}

            }
        });
        $A.enqueueAction(action);
    },

    navigateToCmp : function(component, event, helper ,name, attributes) {
    	/*console.log('inside controller navigateToCmp');
    	var evt = $A.get("e.force:navigateToComponent");
    	evt.setParams({
            componentDef : name,
            componentAttributes: attributes
        });

        evt.fire();
    }*/
			console.log('inside navigateToCmp');
			var e = $A.get("e.c:SF1_NavigationBetweenComponentsEvent");
			e.setParams({
					"paramMap" : attributes,
					"nameOfCmp":name
			});
			e.fire();
	}
})