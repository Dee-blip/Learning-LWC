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

  startManualTrial: function(component) {
    component.set("v.hasReturnErrors", false);
    var action = component.get("c.createAdminOpportunityForManualTrial");
    action.setParams({
      "objectId": component.get("v.objectId")
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      console.log(state);
      if (state == 'SUCCESS') {
        var returnVal = response.getReturnValue();
        console.log(returnVal);
        console.log('returnVal');
        var toastTitle;
        var toastMessage;
        var toastType;
        if (returnVal != null && returnVal != '') {
          var returnValObj = returnVal.split(',');
            if(returnValObj[1] == 'Theme3') {
                window.open("/" + returnValObj[0], '_blank');
            } else {
                window.open("/" + 'lightning/r/Order_Approval__c/'+returnValObj[0]+'/view', '_blank');// added this URL hack inorder to tackle the unexpected redirection to classic from lightning on some occassions.
            }
        } else {
          window.scrollTo(0, 0);
          toastMessage = 'An unexpected error occurred. Please, contact your System Administrator';
          component.set("v.hasReturnErrors", true);
          component.set("v.returnErrorMessage", toastMessage);
        }
      }
    });
    $A.enqueueAction(action);
  },

  setDataTableRows: function(component) {
    var action = component.get("c.getBuyAkamaiSupportedProducts");
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

  closeModal: function(component, event) {
		var cmpTarget = component.find('Modalbox');
		var cmpBack = component.find('ModalClose');
		$A.util.removeClass(cmpBack, 'slds-backdrop--open');
		$A.util.removeClass(cmpTarget, 'slds-fade-in-open');
	},

  sortData: function(component, fieldName, sortDirection) {
    var data = component.get("v.myApprovalData");
    var reverse = sortDirection !== 'asc';
    data.sort(this.sortBy(fieldName, reverse))
    component.set("v.productDetailData", data);
  },

  sortBy: function(field, reverse, primer) {
    var key = primer ?
      function(x) {
        return primer(x[field])
      } :
      function(x) {
        return x[field]
      };
    reverse = !reverse ? 1 : -1;
    return function(a, b) {
      return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
    }
  }
})