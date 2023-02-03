({
  doInit: function(component, event, helper) {
    console.log(component.get("v.recordTypeModalRequired"));
    if (component.get("v.recordTypeModalRequired") == false) {
      helper.getRecordData(component, event, helper);
    } else {
      var recordTypeString = component.get("v.mapOfRecordTypeVsIdsString");
      var recordTypeList = recordTypeString.split(',');
      var recordTypeMap = [];
      for (var i = 0; i < recordTypeList.length; i++) {
        var rcTypeObj = recordTypeList[i].split(':');
        var eachRecordType = {
          label: rcTypeObj[0],
          value: rcTypeObj[1]
        };
        recordTypeMap.push(eachRecordType);
      }
      component.set("v.mapOfRecordTypeVsIds", recordTypeMap);
    }
  },

  assignSelectedValue: function(component, event, helper) {
    var target = event.getSource();
    var currentRecordTypeId = target.get("v.value");
    console.log(currentRecordTypeId);
    if (target.get("v.checked")) {
      component.set("v.currentRecordTypeId", currentRecordTypeId);
    }
  },

  moveBack: function(component, event, helper) {
    window.history.back();
  },

  moveToComponent: function(component, event, helper) {
    component.set("v.recordTypeModalRequired", false);
    helper.getRecordData(component, event, helper);
  },

  enableDependencies: function(component, event, helper) {
    var target = event.getSource();
    var txtVal = target.get("v.name");
    var selectedValue = target.get("v.value");
    var element = document.getElementById(txtVal);
    var dependencies = element.getAttribute('data-type');
    var listOfDependencies = dependencies.split(",");
    var dependencyMap = element.getAttribute('data-map');
    dependencyMap = JSON.parse(dependencyMap);
    console.log(dependencyMap);
    if (listOfDependencies != null && listOfDependencies.length > 0) {
      var listOfSectionDescribe = component.get("v.listOfSectionDescribe");
      for (var n = 0; n < listOfSectionDescribe.length; n++) {
        var listOfFieldDescribe = listOfSectionDescribe[n].listOfSectionFields;
        for (var i = 0; i < listOfFieldDescribe.length; i++) {
          if (listOfDependencies.includes(listOfFieldDescribe[i].fieldAPIName)) {
            var selectedValueMap = dependencyMap[listOfFieldDescribe[i].fieldAPIName];
            var picklistValsForSelectedValue = selectedValueMap[selectedValue];
            if (picklistValsForSelectedValue != undefined) {
              picklistValsForSelectedValue.splice(0, 0, '--None--');
              listOfFieldDescribe[i].pickListVals = picklistValsForSelectedValue;
              listOfFieldDescribe[i].isDependentField = false;
            } else {
              listOfFieldDescribe[i].pickListVals = ['--None--'];
              listOfFieldDescribe[i].isDependentField = true;
              listOfFieldDescribe[i].value = '--None--';
            }
          }
        }
      }
      component.set("v.listOfSectionDescribe", listOfSectionDescribe);
    }

  },

  populateWhereClause: function(component, event, helper) {
    var dependencyOn = event.currentTarget.dataset.type;
    console.log('dependencyOn: ' + dependencyOn);
    var currenctField = event.currentTarget.dataset.current;
    console.log('currenctField: ' + currenctField);
    var dynamicValue;
    var currentFieldPos1;
    var currentFieldPos2;
    var listOfSectionDescribe = component.get("v.listOfSectionDescribe");
    for (var n = 0; n < listOfSectionDescribe.length; n++) {
      var listOfFieldDescribe = listOfSectionDescribe[n].listOfSectionFields;
      for (var i = 0; i < listOfFieldDescribe.length; i++) {
        if (dependencyOn == listOfFieldDescribe[i].fieldAPIName) {
          dynamicValue = listOfFieldDescribe[i].value;
        }
        if (currenctField == listOfFieldDescribe[i].fieldAPIName) {
          currentFieldPos1 = n;
          currentFieldPos2 = i;
        }
      }
    }
    console.log('dynamicValue after: ' + dynamicValue);
    listOfSectionDescribe[currentFieldPos1].listOfSectionFields[currentFieldPos2].lookupFilterQuery = listOfSectionDescribe[currentFieldPos1].listOfSectionFields[currentFieldPos2].dynamicWhereClause.replace('/rep/' + dependencyOn + '/rep/', "'" + dynamicValue + "'");
    console.log(listOfSectionDescribe[currentFieldPos1].listOfSectionFields[currentFieldPos2].lookupFilterQuery);
    component.set("v.listOfSectionDescribe", listOfSectionDescribe);
  },

  handleClick: function(component, event, helper) {
    var divId = event.currentTarget.dataset.type;
    console.log(divId);
    var cmpTarget = document.getElementById(divId);
    $A.util.toggleClass(cmpTarget, 'slds-is-open');
  },

  updatedVals: function(component, event, helper) {
    if (component.get("v.isCreatable")) {
      component.set("v.hasError", false);
      component.set("v.errorMessage", '');
      window.scrollTo(0, 0);
      var listOfSectionDescribe = component.get("v.listOfSectionDescribe");
      var listOfJustObjectFields = helper.getListOfJustObjectFields(listOfSectionDescribe);
      console.log('listOfJustObjectFields');
      console.log(listOfJustObjectFields);
      if (helper.isObjectValidated(component, listOfJustObjectFields)) {
        console.log('Valid Object');
        helper.insertObject(component, event, helper, listOfJustObjectFields);
      } else {
        console.log('Invalid Object');
      }
    } else {
      component.set("v.hasError", false);
      component.set("v.errorMessage", "No Write Access On the Object");
    }
  },

  cancelAction: function(component, event, helper) {
    console.log('return URL = ' + component.get("v.returnURL"));
    window.history.back();
  }
})