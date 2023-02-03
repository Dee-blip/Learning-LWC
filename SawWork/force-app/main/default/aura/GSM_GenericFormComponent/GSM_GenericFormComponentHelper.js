({
  preHandleData: function (component, event, listOfSectionDescribe) {
    for (var n = 0; n < listOfSectionDescribe.length; n++) {

      if (listOfSectionDescribe[n].editLayoutProperties != null && listOfSectionDescribe[n].editLayoutProperties) {
        console.log('editLayoutProperties');
        if (listOfSectionDescribe[n].layoutPropertiesDetails != null) {
          if (listOfSectionDescribe[n].layoutPropertiesDetails.caseAssignmentCheckboxDefaultValue != null && listOfSectionDescribe[n].layoutPropertiesDetails.caseAssignmentCheckboxDefaultValue) {
            component.set("v.caseAssignmentCheckboxValue", true);
          }
          if (listOfSectionDescribe[n].layoutPropertiesDetails.emailNotificationCheckboxDefaultValue != null && listOfSectionDescribe[n].layoutPropertiesDetails.emailNotificationCheckboxDefaultValue) {
            component.set("v.emailNotificationCheckboxValue", true);
          }
        }
      }

      var listOfFieldDescribe = listOfSectionDescribe[n].listOfSectionFields;
      for (var i = 0; i < listOfFieldDescribe.length; i++) {
        if (listOfFieldDescribe[i].fieldType == 'MULTIPICKLIST') {
          var plValues = [];
          if (listOfFieldDescribe[i].pickListVals != null) {
            for (var j = 0; j < listOfFieldDescribe[i].pickListVals.length; j++) {
              plValues.push({
                label: listOfFieldDescribe[i].pickListVals[j],
                value: listOfFieldDescribe[i].pickListVals[j]
              });
            }
            listOfFieldDescribe[i].pickListVals = plValues;
          }
        }
      }
      listOfSectionDescribe[n].listOfSectionFields = listOfFieldDescribe;
    }
    return listOfSectionDescribe;
  },

  getRecordData: function (component, event, helper) {
    //console.log('defaultValues');
    console.log(component.get("v.defaultValues"));
    if (component.get("v.defaultValues") != '') {
      //SFDC-6889
      var defaultValues = component.get("v.defaultValues");
      // @Nagaraj Desai - Removing code explicitly put in for SFDC-5903 and making it globally generic
      // Handle HTML4 Escaped data by unescaping them using textarea dynamic creation hack
      // This is to solve SFDC-5903 kind of special char input bugs
      var e = document.createElement('textarea');
      e.innerHTML = defaultValues;
      // handle case of empty input
      defaultValues = e.childNodes.length === 0 ? "" : e.childNodes[0].nodeValue;
      component.set("v.defaultValues", JSON.parse(defaultValues));
    }
    console.log('after');
    var action = component.get("c.getSectionValues");
    action.setParams({
      "sObjectName": component.get("v.sObjectName"),
      "defaultValues": component.get("v.defaultValues"),
      "customMetaDataObjName": component.get("v.customMetaDataObjName"),
      "currentRecordTypeId": component.get("v.currentRecordTypeId")
    });
    console.log("sObjectName = " + component.get("v.sObjectName"));
    action.setCallback(this, function (response) {
      var state = response.getState();
      console.log('state :', state);
      if (component.isValid() && state === "SUCCESS") {
        var responseVal = response.getReturnValue();
        console.log(JSON.parse(responseVal));
        var responseValObj = JSON.parse(responseVal);
        if (responseValObj.errorOccured == "false") {
          component.set("v.isCreatable", true);
          var listOfSectionDescribeJSON = responseValObj.returnMessage;
          var listOfSectionDescribeObj = JSON.parse(listOfSectionDescribeJSON);
          listOfSectionDescribeObj = helper.preHandleData(component, event, listOfSectionDescribeObj);
          console.log(listOfSectionDescribeObj);
          component.set("v.listOfSectionDescribe", listOfSectionDescribeObj);
        } else {
          component.set("v.isCreatable", false);
          component.set("v.hasError", true);
          component.set("v.errorMessage", responseValObj.returnMessage);
        }
      }
    });
    $A.enqueueAction(action);
  },

  containsValue: function (list1, var1) {
    for (var i = 0; i < list1.length; i++) {
      if (list1[i] == var1) {
        console.log('Equals');
        return true;
      }
    }
    return false;
  },

  getListOfJustObjectFields: function (listOfSectionDescribe) {
    var listOfJustObjectFields = [];
    for (var n = 0; n < listOfSectionDescribe.length; n++) {
      listOfJustObjectFields = listOfJustObjectFields.concat(listOfSectionDescribe[n].listOfSectionFields);
    }
    return listOfJustObjectFields;
  },

  isObjectValidated: function (component, fieldDescribe) {
    component.set("v.hasError", false);
    for (var i = 0; i < fieldDescribe.length; i++) {
      if (fieldDescribe[i].fieldType != 'MULTIPICKLIST' && fieldDescribe[i].isRequired != null && fieldDescribe[i].isRequired && ((fieldDescribe[i].value == null || fieldDescribe[i].value == '' || fieldDescribe[i].value == '--None--'))) {
        console.log(fieldDescribe[i].value);
        if (fieldDescribe[i].value == 0) {
          console.log('Zero Value');
        }
        console.log(fieldDescribe[i].label + '= ' + fieldDescribe[i].value);
        component.set("v.errorMessage", fieldDescribe[i].label + ' is a *Required Field');
        component.set("v.hasError", true);
        return false;
      } else if (fieldDescribe[i].fieldType == 'MULTIPICKLIST' && fieldDescribe[i].isRequired != null && fieldDescribe[i].isRequired && (fieldDescribe[i].selectedPickListValues == null || fieldDescribe[i].selectedPickListValues == '')) {
        console.log('Selected Picklist = ' + fieldDescribe[i].selectedPickListValues);
        component.set("v.errorMessage", fieldDescribe[i].label + ' is a *Required Field');
        component.set("v.hasError", true);
        console.log(fieldDescribe[i].label);
        return false;
      } else if (fieldDescribe[i].fieldType == 'DATETIME' && fieldDescribe[i].value != null) {
        fieldDescribe[i].value = $A.localizationService.formatDate(fieldDescribe[i].value, "yyyy-MM-ddTHH:mm:ss");
      }
    }
    return true;
  },

  insertObject: function (component, event, helper, fieldDescribe) {
    var action = component.get("c.insertObject");
    console.log(' Field Details in Helper ---');
    console.log(fieldDescribe);

    var plValues = {}
    for (var j = 0; j < fieldDescribe.length; j++) {
      var multipickValue = '';
      if (fieldDescribe[j].fieldType == 'MULTIPICKLIST' && fieldDescribe[j].selectedPickListValues != null) {
        for (var i = 0; i < fieldDescribe[j].selectedPickListValues.length; i++) {
          console.log('Multi Pick Value = ' + fieldDescribe[j].selectedPickListValues[i]);
          multipickValue += fieldDescribe[j].selectedPickListValues[i] + ';';
        }

        plValues[fieldDescribe[j].fieldAPIName] = multipickValue;

      } else if (fieldDescribe[j].fieldType == 'DATE') {
        plValues[fieldDescribe[j].fieldAPIName] = fieldDescribe[j].value;
      } else if (fieldDescribe[j].fieldType == 'DEPENDENTPICKLIST' || fieldDescribe[j].fieldType == 'PICKLIST') {
        if (fieldDescribe[j].value != '--None--') {
          plValues[fieldDescribe[j].fieldAPIName] = fieldDescribe[j].value;
        }
      } else {
        plValues[fieldDescribe[j].fieldAPIName] = fieldDescribe[j].value;
      }
    }

    console.log('plValues:');
    console.log(plValues);
    var recordTypeId = component.get("v.currentRecordTypeId");
    action.setParams({
      "fieldDetails": plValues,
      "sObjectName": component.get("v.sObjectName"),
      "recordTypeId": recordTypeId,
      "assignUsingActiveReassignmentRules": component.get("v.caseAssignmentCheckboxValue"),
      "sendNotificationEmailToContact": component.get("v.emailNotificationCheckboxValue")
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      console.log('state :', state);
      if (component.isValid() && state === "SUCCESS") {
        var fieldDes = response.getReturnValue();
        console.log('fieldDes: ' + fieldDes);
        if (fieldDes.includes('Failure')) {
          component.set("v.errorMessage", fieldDes);
          component.set("v.hasError", true);
        } else {
          if (component.get("v.redirectionRequired")) {
            var redirectionURL = '';
            if (component.get("v.returnValPrefix") != null && component.get("v.returnValPrefix") != '') {
              redirectionURL += component.get("v.returnValPrefix");
            }
            if (component.get("v.requiresSobjectId")) {
              redirectionURL += '/' + fieldDes;
            }
            if (component.get("v.returnValSuffix") != null && component.get("v.returnValSuffix") != '') {
              redirectionURL += component.get("v.returnValSuffix");
            }
            if (redirectionURL != '') {
              //SFDC-6889
              if (window.parent.location == undefined) {
                window.location = redirectionURL;
              } else {
                window.parent.location = redirectionURL;
              }
            }
          }
        }
      }
    });
    $A.enqueueAction(action);
  },
})