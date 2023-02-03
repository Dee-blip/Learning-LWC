({
	setDataTableHeader: function(component) {
	    component.set('v.productDetailColumnNames', [{
	        label: 'Product Name',
	        fieldName: 'productName',
	        sortable: 'true',
	        type: 'text',
	      },
	      {
	        label: 'Account Type',
	        fieldName: 'accountType',
	        sortable: 'true',
	        type: 'text',
	      }
	    ]);
  	},
    
    setDataTableRows: function(component) {
        var action = component.get("c.getBuyAkamaiOrderFormProducts");
        action.setParams({});
        action.setCallback(this, function(response) {
          var state = response.getState();
          console.log(state);
          if (state == 'SUCCESS') {
            var returnVal = response.getReturnValue();
            console.log(returnVal);
            var productDetailData = [];
            for (var eachVal in returnVal) {
              var eachRow = {
                productName: eachVal,
                accountType: returnVal[eachVal]
              };
              productDetailData.push(eachRow);
            }
            component.set("v.productDetailData", productDetailData);
          }
        });
        $A.enqueueAction(action);
	},
})