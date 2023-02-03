public class PLM_LaunchItemApprovalDataClass extends GenericDataClass{
	
   private static String sfHostname;
  
  // Bulk delegation page variables
  private List<Launch_Item_Approval__c> approvalsToDelegate;
  private List<PLM_LaunchItemApprovalWrapperClass> approvalsToDelegateWrapper;
  private PLM_LaunchItemApprovalWrapperClass approvalWrapperClass;
  private  String userName;
  private  String userId;
  private  Boolean IsAllSelected;
  private  Boolean isReassigned;
  
  // Set Functional Approver page Varibales
  private Boolean showWarning;
  private Boolean isApplyToExisting;
  private Boolean isEditPage;
  private Boolean IsAllFunctionsSelected;
  private Boolean IsAllDivisionsSelected ;
  private String  idToRender;
  private List<PLM_LaunchItemApprovalWrapperClass> launchTeamFunctionalMemberList;
  private List<PLM_LaunchItemApprovalWrapperClass> launchTeamDivisionalMemberList;
  private List<PLM_LaunchItemApprovalWrapperClass> launchTeamFunctionalDivisionalList;
  private Map<Id,Launch_Item_Approval__c> existingTeamMemberMap;
  private String launchItemId;
  private Boolean isGlobalSetting;
  private String warningMsg;
  private Boolean isLaunchItemApprovalEnabled;
  private String featureDisabledMessage;
  private String retURL;
  private Set<String> divisionSet;
  private Set<String> functionSet;
  
  // Launch Item Approval Page variables
  private String launchItemApprovalId;
  private Launch_Item_Approval__c launchItemApproval ;
  private Boolean isApproved ;
  private String backToLinkName ;
  private Boolean isRejected;
  //private String retUrl { get; set; }
  private String fromWhere ;
  private Boolean userDelegated;
 
  private String comments;
  private String delgateApprover;
  private List<User> userList;
  //private Boolean isUserListSizeGTZero;
  private Map<Id,User> IdUserMap;
  
  private Boolean userSelected;
  private Boolean isApprovalApproved;
  private Boolean isApprovalRejected;
  private String approveButtonName;
  private String rejectButtonName;
  private String approveRejectReassignMessage;
  private Attachment approvalAttachment;
  // custom user lookup popup page
  private String query;
    
  // Launch Item Approval related List page variables
  //public String launchItemId;
  //public List<PLM_LaunchItemApprovalWrapperClass> launchItemFunctionApprovalWrapperList { get; set; }
  //public List<PLM_LaunchItemApprovalWrapperClass> launchItemDivisionApprovalWrapperList { get; set; }
  private String noActiveApprovalsExistMsg;
  private String noActiveFunctionApprovalExists;
  private String noActiveDivisionApprovalExists;
  private Boolean isDelegatePM;
  private String messagePMBulkDlegation{get;set;}
  public PLM_LaunchItemApprovalDataClass()
  {
	
  }
  //Hitesh -CR 1594363 Feb Launch Approvals visible to users in the 'My Launch Item Approvals’ list view.
  //isDelegatePM variable takes care of showing message to PMs on BulkDelegation page
  public Boolean getIsDelegatePM()
  {
  	return this.isDelegatePM;
  }
  public void setIsDelegatePM(Boolean isDelegatePM )
  {
  	this.isDelegatePM=isDelegatePM;
  }
  public String getMessagePMBulkDlegation()
  {
  	return this.messagePMBulkDlegation;
  }
  public void setMessagePMBulkDlegation(String messagePMBulkDlegation )
  {
  	this.messagePMBulkDlegation=messagePMBulkDlegation;
  }
  
  public List<Launch_Item_Approval__c> getApprovalsToDelegate()
  {
  	return this.approvalsToDelegate;
  }
  
  public void  setApprovalsToDelegate(List<Launch_Item_Approval__c> approvalsToDelegate)
  {
  	this.approvalsToDelegate=approvalsToDelegate;
  }
  
  public List<PLM_LaunchItemApprovalWrapperClass> getApprovalsToDelegateWrapper()
  {
  	return this.approvalsToDelegateWrapper;
  }
  
  public void  setApprovalsToDelegateWrapper(List<PLM_LaunchItemApprovalWrapperClass> approvalsToDelegateWrapper)
  {
  	this.approvalsToDelegateWrapper=approvalsToDelegateWrapper;
  }
  
  public PLM_LaunchItemApprovalWrapperClass getApprovalWrapperClass()
  {
  	return this.approvalWrapperClass;
  }
  
  public void  setApprovalWrapperClass(PLM_LaunchItemApprovalWrapperClass approvalWrapperClass)
  {
  	this.approvalWrapperClass=approvalWrapperClass;
  }
  
  public String getUserName()
  {
  	return this.userName;
  }
  public void setUserName(String userName)
  {
  	this.userName=userName;
  }
  
  public String getUserId()
  {
  	return this.userId;
  }
  public void setUserId(String userId)
  {
  	this.userId=userId;
  }
  
  public Boolean getIsAllSelected()
  {
  	return this.IsAllSelected;
  }
  public void setIsAllSelected(Boolean isAllSelected)
  {
  	this.IsAllSelected=isAllSelected;
  }
  
  public Boolean getIsReassigned()
  {
  	return this.isReassigned;
  }
  public void setIsReassigned(Boolean isReassigned)
  {
  	this.isReassigned=isReassigned;
  }
 
  public Boolean getShowWarning()
  {
  	return this.showWarning;
  }
  public void setShowWarning(Boolean showWarning)
  {
  	this.showWarning=showWarning;
  }
  
  public Boolean getIsApplyToExisting()
  {
  	return this.isApplyToExisting;
  }
  public void setIsApplyToExisting(Boolean isApplyToExisting)
  {
  	this.isApplyToExisting=isApplyToExisting;
  }
  
  public Boolean getIsEditPage()
  {
  	return this.isEditPage;
  }
  public void setIsEditPage(Boolean isEditPage)
  {
  	this.isEditPage=isEditPage;
  }
  
  public Boolean getIsAllFunctionsSelected()
  {
  	return this.IsAllFunctionsSelected;
  }
  public void setIsAllFunctionsSelected(Boolean IsAllFunctionsSelected)
  {
  	this.IsAllFunctionsSelected=IsAllFunctionsSelected;
  }
  
  public Boolean getIsAllDivisionsSelected()
  {
  	return this.IsAllDivisionsSelected;
  }
  public void setIsAllDivisionsSelected(Boolean IsAllDivisionsSelected)
  {
  	this.IsAllDivisionsSelected=IsAllDivisionsSelected;
  }
  
  public String getIdToRender()
  {
  	return this.idToRender;
  }
  public void setIdToRender(String idToRender)
  {
  	this.idToRender=idToRender;
  }
  
  public List<PLM_LaunchItemApprovalWrapperClass> getLaunchTeamFunctionalMemberList()
  {
  	return this.launchTeamFunctionalMemberList;
  }
  public void setLaunchTeamFunctionalMemberList(List<PLM_LaunchItemApprovalWrapperClass> launchTeamFunctionalMemberList)
  {
  	this.launchTeamFunctionalMemberList=launchTeamFunctionalMemberList;
  }
  
  public List<PLM_LaunchItemApprovalWrapperClass> getLaunchTeamDivisionalMemberList()
  {
  	return this.launchTeamDivisionalMemberList;
  }
  public void setLaunchTeamDivisionalMemberList(List<PLM_LaunchItemApprovalWrapperClass> launchTeamDivisionalMemberList)
  {
  	this.launchTeamDivisionalMemberList=launchTeamDivisionalMemberList;
  }
  
  public List<PLM_LaunchItemApprovalWrapperClass> getLaunchTeamFunctionalDivisionalList()
  {
  	return this.launchTeamFunctionalDivisionalList;
  }
  public void setLaunchTeamFunctionalDivisionalList(List<PLM_LaunchItemApprovalWrapperClass> launchTeamFunctionalDivisionalList)
  {
  	this.launchTeamFunctionalDivisionalList=launchTeamFunctionalDivisionalList;
  }
  
  public Map<Id,Launch_Item_Approval__c> getExistingTeamMemberMap()
  {
  	return this.existingTeamMemberMap;
  }
  public void setExistingTeamMemberMap(Map<Id,Launch_Item_Approval__c> existingTeamMemberMap)
  {
  	this.existingTeamMemberMap=existingTeamMemberMap;
  }
  
  
  public String getLaunchItemId()
  {
  	return this.launchItemId;
  }
  public void setLaunchItemId(String launchItemId)
  {
  	this.launchItemId=launchItemId;
  }
  
  public Boolean getIsGlobalSetting()
  {
  	return isGlobalSetting;
  }
  public void setIsGlobalSetting(Boolean isGlobalSetting)
  {
  	this.isGlobalSetting=isGlobalSetting;
  }
  
  public String getWarningMsg()
  {
  	return warningMsg;
  }
  public void setWarningMsg(String warningMsg)
  {
  	this.warningMsg=warningMsg;
  }
  
  public Boolean getIsLaunchItemApprovalEnabled()
  {
  	return this.isLaunchItemApprovalEnabled;
  }
  public void setIsLaunchItemApprovalEnabled(Boolean isLaunchItemApprovalEnabled)
  {
  	this.isLaunchItemApprovalEnabled=isLaunchItemApprovalEnabled;
  }
  
  public String getFeatureDisabledMessage()
  {
  	return this.featureDisabledMessage=featureDisabledMessage;
  }
  public void setFeatureDisabledMessage(String featureDisabledMessage)
  {
  	this.featureDisabledMessage=featureDisabledMessage;
  }
  
  public String getRetURL()
  {
  	return this.retURL;
  }
  public void setRetURL(String retURL)
  {
  	this.retURL=retURL;
  }
  
  public Set<String> getDivisionSet()
  {
  	return this.divisionSet;
  }
  public void setDivisionSet (List<Schema.PicklistEntry> divisionList)
  {
  	this.divisionSet=setDivisionFunctionSet(divisionList);
  }
  
  public Set<String> getFunctionSet()
  {
  	return this.functionSet;
  }
  public void setFunctionSet (List<Schema.PicklistEntry> functionList)
  {
  	this.functionSet=setDivisionFunctionSet(functionList);
  }
   
   public String getLaunchItemApprovalId()
   {
   	return this.launchItemApprovalId;
   }
   public void setLaunchItemApprovalId(String launchItemApprovalId)
   {
   	this.launchItemApprovalId=launchItemApprovalId;
   }
   
   public Launch_Item_Approval__c getLaunchItemApproval()
   {
   	return this.launchItemApproval;
   }
   public void setLaunchItemApproval(Launch_Item_Approval__c launchItemApproval)
   {
   	this.launchItemApproval=launchItemApproval;
   }
   
   public Boolean getIsApproved()
   {
   	return this.isApproved;
   }
   public void setIsApproved(Boolean isApproved)
   {
   	this.isApproved=isApproved;
   }
   
   public String getBackToLinkName()
   {
   	return this.backToLinkName;
   }
   public void setBackToLinkName(String backToLinkName)
   {
   	this.backToLinkName=backToLinkName;
   }
   
   public Boolean getIsRejected()
   {
   	return this.isRejected;
   }
   public void setIsRejected(Boolean isRejected)
   {
   	this.isRejected=isRejected;
   }
   
   public String getFromWhere()
   {
   	return this.fromWhere;
   }
   public void setFromWhere(String fromWhere)
   {
   	this.fromWhere=fromWhere;
   }
   
   public Boolean getUserDelegated()
   {
   	return this.userDelegated;
   }
   public void setUserDelegated(Boolean userDelegated)
   {
   	this.userDelegated=userDelegated;
   }
   
   public static String getSfHostname()
   {
   	if(sfHostname ==null)
   	{
   		sfHostname=[select Division from Organization][0].Division;
   	}
   	return sfHostname;
   }
      
   public String getComments()
   {
   	return this.comments;
   }
   public void setComments(String comments)
   {
   	this.comments=comments;
   }
   
   public String getDelgateApprover()
   {
   	return this.delgateApprover;
   }
   public void setDelgateApprover(String delgateApprover)
   {
   	this.delgateApprover=delgateApprover;
   }
   
   public List<User> getUserList()
   {
   	return this.userList;
   }
   public void setUserList(List<User> userList)
   {
   	this.userList=userList;
   }
   
  /* public Boolean getIsUserListSizeGTZero()
   {
   	return this.isUserListSizeGTZero;
   }
   public void setIsUserListSizeGTZero(Boolean isUserListSizeGTZero)
   {
   	this.isUserListSizeGTZero=isUserListSizeGTZero;
   }*/
   
   public Map<Id,User> getIdUserMap()
   {
   	return this.IdUserMap;
   }
   public void setIdUserMap(Map<Id,User> IdUserMap)
   {
   	this.IdUserMap=IdUserMap;
   }
   
   public Boolean getUserSelected()
   {
   	return this.userSelected;
   }
   public void setUserSelected(Boolean userSelected)
   {
   	this.userSelected=userSelected;
   }
   
   public Boolean getIsApprovalApproved()
   {
   	return this.isApprovalApproved;
   }
   public void setIsApprovalApproved(Boolean isApprovalApproved)
   {
   	this.isApprovalApproved=isApprovalApproved;
   }
   
   public Boolean getIsApprovalRejected()
   {
   	return this.isApprovalRejected;
   }
   public void setIsApprovalRejected(Boolean isApprovalRejected)
   {
   	this.isApprovalRejected=isApprovalRejected;
   }
   
   public String getApproveButtonName()
   {
   	return this.approveButtonName;
   }
   public void setApproveButtonName(String approveButtonName)
   {
   	this.approveButtonName=approveButtonName;
   }
   
   public String getRejectButtonName()
   {
   	return this.rejectButtonName;
   }
   public void setRejectButtonName(String rejectButtonName)
   {
   	this.rejectButtonName=rejectButtonName;
   }
   
   public String getApproveRejectReassignMessage()
   {
   	return this.approveRejectReassignMessage;
   }
   public void setApproveRejectReassignMessage(String approveRejectReassignMessage)
   {
   	this.approveRejectReassignMessage=approveRejectReassignMessage;
   }
   
   public Attachment getApprovalAttachment()
   {
   	if(approvalAttachment==null)
   	{
   		approvalAttachment=new Attachment();
   	}
   	return this.approvalAttachment;
   }
   
   public void setApprovalAttachment(Attachment approvalAttachment)
   {
   	 this.approvalAttachment=approvalAttachment;
   }
   
   public String getNoActiveApprovalsExistMsg()
   {
   	return this.noActiveApprovalsExistMsg;
   }
   public void setNoActiveApprovalsExistMsg(String noActiveApprovalsExistMsg)
   {
   	this.noActiveApprovalsExistMsg=noActiveApprovalsExistMsg;
   }
   
   public String getNoActiveFunctionApprovalExists()
   {
   	return this.noActiveFunctionApprovalExists;
   }
   public void setNoActiveFunctionApprovalExists(String noActiveFunctionApprovalExists)
   {
   	this.noActiveFunctionApprovalExists=noActiveFunctionApprovalExists;
   }
   
   public String getNoActiveDivisionApprovalExists()
   {
   	return this.noActiveDivisionApprovalExists;
   }
   public void setNoActiveDivisionApprovalExists(String noActiveDivisionApprovalExists)
   {
   	this.noActiveDivisionApprovalExists=noActiveDivisionApprovalExists;
   }
   
   public String getQuery()
   {
   	return this.query;
   }
   public void setQuery(String query)
   {
   	this.query=query;
   }
   /*
     setDivisionFunctionSet()
      - internal method called from other methods
   */
    
    private Set<String> setDivisionFunctionSet(List<Schema.PicklistEntry> divisionFunctionList)
    {
     
     Set<String> functionDivisionSet=new Set<String>();
     for(Schema.PicklistEntry p: divisionFunctionList)
     {
      functionDivisionSet.add(p.getValue());
      }
      return functionDivisionSet;
    }
}