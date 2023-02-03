({
	initAction : function(cmp, event, helper) {
     console.log('Loaded the approval hist');	
     helper.getApprovalsHelper(cmp, event);   
        
 	},
    showApprovals: function(cmp, event, helper)
    {
      var showApprovalsFlag = cmp.get('v.showApprovalsflag');
      showApprovalsFlag === false ? cmp.set('v.showApprovalsflag',true):cmp.set('v.showApprovalsflag',false);
        
    }
})