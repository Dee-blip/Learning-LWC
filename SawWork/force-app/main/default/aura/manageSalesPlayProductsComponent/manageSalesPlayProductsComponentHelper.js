({
  fetchProducts : function(component) {
        var action = component.get("c.fetchForecastingProducts");
        action.setParams({
          "recId": component.get("v.recordId"),
        });
    action.setCallback(this, function(response) {
          var state = response.getState();
          console.log(state);
          if (state == 'SUCCESS') {
            var returnVal = response.getReturnValue();
            var productsMap = JSON.parse(returnVal['ProductNamesMap']);
            var productSelectedMap = JSON.parse(returnVal['SelectedProdcuts']);
            component.set("v.productMap", productsMap);
            var productDetailData = [];
            var selectedValues = [];
            for (var eachVal in productsMap) {
              var eachRow = {
                "label": productsMap[eachVal],
                "value": eachVal
              };
              productDetailData.push(eachRow);
            }
              
            for (var eachVal in productSelectedMap) {
              selectedValues.push(eachVal);       
            }
            component.set("v.options", productDetailData);
            component.set("v.values", selectedValues);
            component.set("v.selectedvalues", selectedValues);
          }
        });
        $A.enqueueAction(action);
  },
    
    saveProducts : function(component) {
      var saveProdAction = component.get("c.saveForecastingProducts"); 
        var productsList = component.get("v.selectedvalues");
        var errorSection = component.find("errorId");
        var successSection = component.find("successId");
        $A.util.removeClass(errorSection, 'slds-show');
        $A.util.addClass(errorSection, 'slds-hide');
        $A.util.removeClass(successSection, 'slds-show');
        $A.util.addClass(successSection, 'slds-hide');
        saveProdAction.setParams({
          "salesPlayId": component.get("v.recordId"),
          "productNameMap": component.get("v.productMap"),
            "prodIds": productsList
      });
        saveProdAction.setCallback(this, function(response) {
          var state = response.getState();
            console.log('State in Save Products = '+state);
            if (state == 'SUCCESS') {
              var resp = response.getReturnValue(); 
                if(resp == 'success') {
                  component.set("v.successMessage",'Product(s) on the Sales Play updated successfully');
                    $A.util.removeClass(successSection, 'slds-hide');
              $A.util.addClass(successSection, 'slds-show');      
                } else {
                    component.set("v.errorMessage",resp);
                    $A.util.removeClass(errorSection, 'slds-hide');
              $A.util.addClass(errorSection, 'slds-show');
                }
            }
        });
        $A.enqueueAction(saveProdAction);
    }
})