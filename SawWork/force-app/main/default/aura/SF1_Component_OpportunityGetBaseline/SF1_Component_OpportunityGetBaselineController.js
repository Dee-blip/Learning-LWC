({
	
  doInit: function(component, event, helper) {
   
    var oppId = component.get('v.oppId');
    var action1 = component.get('c.checkOpportunity');
    action1.setParams({
      "oppId": oppId,

    });
    action1.setCallback(this, function(response) {
      var state1 = response.getState();
      //console.log(state);
      if (state1 === 'SUCCESS') {
      	if(response.getReturnValue() == "")
      	{
      	var accountId = component.get('v.accId');

    var action = component.get('c.getContractsFromAcount');
    action.setParams({
      "accountId": accountId,

    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      //console.log(state);
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
     
        component.set("v.listOfMergeContractHeader", results);
       

        if (results == null || results.length == 0) {
          component.set("v.displayErrorBox", true);
          component.set("v.message", "No Contract Record(s) found for the Associated Account.");

        }
        else {
        	var mapOfMCH = new Object();
        	 for(var i = 0; i < results.length; i++)
        	 {
        	 	mapOfMCH[results[i].Id] = results[i];
        	 }
        	
          component.set("v.mapOfMergeContractHeader", mapOfMCH); 
          component.set("v.displayInfoBox", false);
          component.set("v.displayErrorBox", false);
          component.set("v.message", "");
        }
       
      }
    });

    $A.enqueueAction(action);
}
else
{
	component.set("v.displayErrorBox", true);
    component.set("v.message", response.getReturnValue());
}
}
});

    $A.enqueueAction(action1);
  },

  toggleTheContract: function(component, event, helper) 
  {
  	
  	var selectedContractId =  event.target.name;
  	
    var selectedList = component.get("v.selectedContractIDs");
    
    if(selectedList.indexOf(selectedContractId) != -1)
    {
        selectedList.splice(selectedList.indexOf(selectedContractId), 1);
    }
    else
    {
    	selectedList.push(selectedContractId);
    }
  
    component.set("v.selectedContractIDs",selectedList);

    
    if(selectedList.length>0)
    {
    	component.find("gcbButton").set("v.disabled", false);
    }
    else
    {
    	component.find("gcbButton").set("v.disabled", true);
    }
  },

  openModal: function(component, event, helper) {
  	var a = event.target.name;
  	if(a!=null)
  	{

  	var plIdList = new Array();
  	for(var i=0; i<a.length;i++)
  	{
  		plIdList.push(a[i].Forecast_Product_Id__c);
  	     
  	}
  	
  	var action = component.get('c.productIdToName');
  	
    action.setParams({
      "productIdList": plIdList


    });
    
    action.setCallback(this, function(response) {
      var state = response.getState();
      
      if (state === 'SUCCESS') {
       var result = response.getReturnValue();
       
      for(var i=0; i<a.length;i++)
  	{

  		var f = a[i].Forecast_Product_Id__c;

  			a[i].Name = JSON.parse(result)[f];


 
  	     
  	}


  		  	component.set("v.productsToShow",a);
 component.set("v.showModal", true);
       
      }
      
    });

    $A.enqueueAction(action);
    
	}

  },
   closeModal: function(component, event) {
	
component.set("v.productsToShow","");
    
   
    component.set("v.showModal", false);
  },
  getContractBaselineFun: function(component, event, helper) {
  	
    var oppId = component.get('v.oppId');
    var currencyCode = component.get('v.currencyCode');
    var selectedMCHIDs = component.get("v.selectedContractIDs");
    var selectedMCHMap = component.get("v.mapOfMergeContractHeader");
    var selectedMCHs = new Array();
    var opptyCloseDate = component.get("v.closeDate");
    for(var i = 0; i < selectedMCHIDs.length; i++)
    {
selectedMCHs.push(selectedMCHMap[selectedMCHIDs[i]]);
    }

    var action = component.get('c.getContractBaseline');
    action.setParams({
      "mchList": selectedMCHs,
      "currencyCode":currencyCode,
      "oppId":oppId,
      "opptyCloseDate":opptyCloseDate


    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      //console.log(state);
      if (state === 'SUCCESS') {
        var result = response.getReturnValue();
       if(result.includes("error"))
       {
       	 component.set("v.displayErrorBox", true);
          component.set("v.message", result);

       }
       else
       {
       	 component.set("v.displayInfoBox", true);
          component.set("v.message", result);
          component.set("v.listOfMergeContractHeader",null);
          component.find("gcbButton").set("v.disabled", true);
       }
       
      }
    });

    $A.enqueueAction(action);

  },
  goToOpportunity : function(component, event, helper) 
  {

	sforce.one.back();

  }
})