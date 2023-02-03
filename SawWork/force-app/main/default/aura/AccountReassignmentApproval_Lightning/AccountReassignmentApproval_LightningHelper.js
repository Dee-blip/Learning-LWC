({
  getLightningTableData: function(component) {
    var sColumn = component.get("v.fields");
    var sObject = component.get("v.object");
    var action = component.get("c.getReassignableData");

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state == 'SUCCESS') {
        var returnVal = response.getReturnValue();
        var returnValObj = JSON.parse(returnVal);
        var myApprovalList = JSON.parse(returnValObj.myApprovalList);
        var delegatedApprovalList = JSON.parse(returnValObj.delegatedApprovalList);
        console.log(delegatedApprovalList);

        var displayMyApprovalList = [];
        for (var index in myApprovalList) {
          if (index > Number(returnValObj.rowsToDisplay) - 1) {
            break;
          }
          var eachMyApproval = {
            id: index,
            reassignApproveReject: 'reassignApproveReject',
            actionLabel: 'Reassign | Approve/ Reject',
            requestID: '/' + myApprovalList[index].requestId,
            requestLabel: myApprovalList[index].requestName,
            submittedDate: myApprovalList[index].submittedDate,
            accountId: '/' + myApprovalList[index].accountId,
            accountName: myApprovalList[index].accountName,
            targetCategory: myApprovalList[index].targetCategory,
            accountStatus: myApprovalList[index].accountStatus,
            accountOwner: '/' + myApprovalList[index].accountOwnerId,
            accountOwnerName: myApprovalList[index].accountOwner,
            assignTo: '/' + myApprovalList[index].assignToUserId,
            assignToName: myApprovalList[index].assignToUser,
            changeLevel: myApprovalList[index].changeLevel,
            reasonCode: myApprovalList[index].reasonCode,
            reasonForChange: myApprovalList[index].reasonForChange,
            approvalId: '/' + myApprovalList[index].approvalid
          };
          displayMyApprovalList.push(eachMyApproval);
        }

        var displayDelegatedApprovalList = [];
        for (var index in delegatedApprovalList) {
          if (index > Number(returnValObj.rowsToDisplay) - 1) {
            break;
          }
          var eachDelegatedApproval = {
            id: index,
            actionLabel: 'Reassign | Approve/ Reject',
            requestID: '/' + delegatedApprovalList[index].requestId,
            requestLabel: delegatedApprovalList[index].requestName,
            submittedDate: delegatedApprovalList[index].submittedDate,
            accountId: '/' + delegatedApprovalList[index].accountId,
            accountName: delegatedApprovalList[index].accountName,
            targetCategory: delegatedApprovalList[index].targetCategory,
            accountStatus: delegatedApprovalList[index].accountStatus,
            accountOwner: '/' + delegatedApprovalList[index].accountOwnerId,
            accountOwnerName: delegatedApprovalList[index].accountOwner,
            assignTo: '/' + delegatedApprovalList[index].assignToUserId,
            assignToName: delegatedApprovalList[index].assignToUser,
            changeLevel: delegatedApprovalList[index].changeLevel,
            reasonCode: delegatedApprovalList[index].reasonCode,
            reasonForChange: delegatedApprovalList[index].reasonForChange,
            approvalId: '/' + delegatedApprovalList[index].approvalid
          };
          displayDelegatedApprovalList.push(eachDelegatedApproval);
        }

        component.set("v.myApprovalData", displayMyApprovalList);
        component.set("v.delegatedApprovalData", displayDelegatedApprovalList);
        console.log('displayDelegatedApprovalList');
        console.log(displayDelegatedApprovalList);
      }
    });
    $A.enqueueAction(action);
  },

  showSearchResults: function(component, fromWhere) {
    var searchData;

    if (fromWhere == 'myApprovals') {
      searchData = component.get("v.myApprovalData");
    } else if (fromWhere == 'delegatedApproval') {
      searchData = component.get("v.delegatedApprovalData");
    }

    var searchText = component.get("v.searchText");

    var searchedResults = [];
    for (var eachData in searchData) {
       // || eachData.submittedDate.includes(searchText) || eachData.targetCategory.includes(searchText) || eachData.accountStatus.includes(searchText) || eachData.accountOwnerName.includes(searchText) || eachData.assignToName.includes(searchText) || eachData.changeLevel.includes(searchText) || eachData.reasonCode.includes(searchText) || eachData.reasonForChange.includes(searchText)
       var requestLabel = (eachData.requestLabel);
       console.log(requestLabel);
      // if () {
      //   searchedResults.push(eachData);
      // }
    }

    if (fromWhere == 'myApprovals') {
      component.set("v.myApprovalData", searchedResults);
    } else if (fromWhere == 'delegatedApproval') {
      component.set("v.delegatedApprovalData", searchedResults);
    }

  },

  setDataTableData: function(component) {
    var actions = [{
        label: 'Reassign',
        name: 'reassign'
      },
      {
        label: 'Approve/ Reject',
        name: 'approveReject'
      }
    ];
    component.set('v.myApprovalColumns', [{
        label: 'Action',
        fieldName: 'approvalId',
        type: 'url',
        sortable: 'true',
        // initialWidth: '400px',
        typeAttributes: {
          label: 'Reassign | Approve/ Reject'
        }
      },
      {
        label: 'Request ID',
        fieldName: 'requestID',
        type: 'url',
        sortable: 'true',
        typeAttributes: {
          label: {
            fieldName: 'requestLabel'
          }
        }
      },
      {
        label: 'Submitted Date',
        fieldName: 'submittedDate',
        sortable: 'true',
        type: 'text',
      },
      {
        label: 'Account',
        fieldName: 'accountId',
        sortable: 'true',
        type: 'url',
        sortable: 'true',
        typeAttributes: {
          label: {
            fieldName: 'accountName'
          }
        }
      },
      {
        label: 'Target Category',
        fieldName: 'targetCategory',
        sortable: 'true',
        type: 'text'
      },
      {
        label: 'Account Status',
        fieldName: 'accountStatus',
        sortable: 'true',
        type: 'text'
      },
      {
        label: 'Account Owner',
        fieldName: 'accountOwner',
        type: 'url',
        sortable: 'true',
        typeAttributes: {
          label: {
            fieldName: 'accountOwnerName'
          }
        }
      },
      {
        label: 'Assign To',
        fieldName: 'assignTo',
        type: 'url',
        sortable: 'true',
        typeAttributes: {
          label: {
            fieldName: 'assignToName'
          }
        }
      },
      {
        label: 'Change Level',
        fieldName: 'changeLevel',
        sortable: 'true',
        type: 'text'
      },
      {
        label: 'Reason Code',
        fieldName: 'reasonCode',
        sortable: 'true',
        type: 'text'
      },
      {
        label: 'Reason For Change',
        fieldName: 'reasonForChange',
        sortable: 'true',
        type: 'text'
      },
      // {
      //   type: 'action',
      //   typeAttributes: {
      //     rowActions: actions
      //   }
      //}
    ]);
    component.set("v.delegatedApprovalColumns", component.get("v.myApprovalColumns"));
  },

  sortData: function(component, fieldName, sortDirection) {
    var data = component.get("v.myApprovalData");
    var reverse = sortDirection !== 'asc';
    data.sort(this.sortBy(fieldName, reverse))
    component.set("v.myApprovalData", data);
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