({
	doInit : function(component, event, helper) {
		var OppLine = component.get("v.oppLineItem");
        var netMRRVal = null;
        var netMonthlyUsageVal = null;
        var EMRIVal = null;
        component.set('v.baseLineProdValue',"color:black");
        if(OppLine.Average_Renewal_Commit_MRR__c  != null ||
           OppLine.Average_Renewal_Usage_MRR__c  != null){
            component.set('v.baseLineProd',"true");
            component.set('v.baseLineProdValue',"color:green");
        }
        if(OppLine.EMRI__c < 0) {
        	component.set('v.EMRI',"red");
        } 
            
        if(OppLine.Net_Non_Commit__c < 0) {
        	component.set('v.netMonthlyUsage',"red");
        } 
        
        if(OppLine.UnitPrice < 0) {
        	component.set('v.netMRR',"red");
        }
        netMRRVal = OppLine.Opportunity.CurrencyIsoCode + " "+parseFloat(component.get("v.oppLineItem.UnitPrice")).toFixed(2);
        netMonthlyUsageVal = OppLine.Opportunity.CurrencyIsoCode + " "+parseFloat(component.get("v.oppLineItem.Net_Non_Commit__c")).toFixed(2);
        EMRIVal = OppLine.Opportunity.CurrencyIsoCode + " "+parseFloat(component.get("v.oppLineItem.EMRI__c")).toFixed(2);
        component.set('v.netMRRValue',netMRRVal);
        component.set('v.netMonthlyUsageValue',netMonthlyUsageVal);
        component.set('v.EMRIValue',EMRIVal);
        component.set('v.CurrencyProdValue',OppLine.Opportunity.CurrencyIsoCode + " ");
	},
    
    navigateToRecordDetail : function(component, event, helper) {
    	var evt = $A.get("e.force:navigateToComponent");
    	evt.setParams({
            componentDef : "c:SF1_ProductDetailView",
            componentAttributes: {
            	OppId : component.get("v.parent_oppty_id"),
                OppLineItemId : component.get("v.oppLineItem.Id")
        	}
    	});
        evt.fire();
	},
    
    fireProductDetailViewEvent : function(component, event, helper) {
        console.log("Fire Product Detail View Event");
        var evnt = $A.get("e.c:goToProductDetail");//component.getEvent("e.c:productDetailViewEvent");
        evnt.setParams({ "OppLineItemId" : component.get("v.oppLineItem.Id") });
        console.log(evnt);
		evnt.fire();
	}
})