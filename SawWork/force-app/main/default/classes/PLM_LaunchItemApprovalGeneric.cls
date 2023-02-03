global class PLM_LaunchItemApprovalGeneric extends GenericControllerClass{
        
        public PLM_LaunchItemApprovalDataClass dataClass{get;set;}
        public static Boolean launchItemInsertFirstRunFlag=true;
        public static Boolean launchItemRemoveApprovalSubscriptions=true;
        private static String sfHostName;
     
                          
        public PLM_LaunchItemApprovalGeneric()
        { 
           super('PLM_LaunchItemApprovalGeneric');
           if(dataObject instanceof PLM_LaunchItemApprovalDataClass)
           {
             this.dataClass=(PLM_LaunchItemApprovalDataClass) dataObject;
           }
           dataClass.setIsLaunchItemApprovalEnabled(getFeatureToggleCustomSettings('LaunchItemApproval').Toggle__c);
           dataClass.setFeatureDisabledMessage(getFeatureToggleCustomSettings('LaunchItemApproval').Disabled_Alert_Message__c);
           PageReference pageref=ApexPages.currentPage();
           if(pageref!=null)
           {
             String pageName=null;
             if(pageref.getUrl()!=null)
             {
               pageName=dataClass.getPageName(pageref.getUrl());
             }
             
             if(pageName!=null && pageName.equals('PLM_LIABulkDelegationPage'))
             {
                initBulkDelegationPage();
             }
             else if(pageName!=null && pageName.equals('PLM_SetFunctionalDivisionalApprovers'))
             {
                initSetFunctionalDivisionalApproverPage();
             }
             else if(pageName!=null && pageName.equals('PLM_LIApprovalPage'))
             {
                initLIApprovalPage();
             }
             else if(pageName!=null && pageName.equals('PLM_LIARelatedList'))
             {
                initLIARelatedList();
             }
             else if(pageName!=null && pageName.equals('PLM_CustomUserLookup'))
             {
                dataClass.setQuery(Apexpages.currentpage().getParameters().get('query'));
                runQuery();
             }
             else
             {
              initialize();
             }
           }
          else
            initialize();
                
        }
    public PLM_LaunchItemApprovalGeneric(String triggerName)
    {
        super('PLM_LaunchItemApprovalGeneric');
        if(dataObject instanceof PLM_LaunchItemApprovalDataClass)
         {
           this.dataClass=(PLM_LaunchItemApprovalDataClass) dataObject;
         }
         dataClass.setIsLaunchItemApprovalEnabled(getFeatureToggleCustomSettings('LaunchItemApproval').Toggle__c);
         dataClass.setFeatureDisabledMessage(getFeatureToggleCustomSettings('LaunchItemApproval').Disabled_Alert_Message__c);
         initialize();      
    }    

    public PLM_LaunchItemApprovalGeneric(ApexPages.StandardSetController controller) 
    {
          this();     
    }
    
    public PLM_LaunchItemApprovalGeneric(ApexPages.StandardController controller) 
    {
          this();
    }
    
    private void initialize()
    {
        if(sfHostName== null)
        {
         GetOrganizationDetails orgDetail=new GetOrganizationDetails();
         sfHostName=orgDetail.getOrganizationDivision();
        }
    }
    //Added by Hitesh Chawda CR 1592464
    //called when a PLU is archived from PLU trigger
    public void processArchivedPLU(List<PLU__c> archivedPLU)
    {
     Set<Id> pluidset = new Set<Id>();
     
     List<Launch_Item__c> archivedLaunchItems = new List<Launch_Item__c>();
     
     for(PLU__c plu : archivedPLU)
        {
            pluidset.add(plu.Id);
        }
     for(Launch_Item__c li: [select Id,Archive__c from Launch_Item__c where PLU__c IN :pluidset])
        
        {
            archivedLaunchItems.add(li);
        }
     if(archivedLaunchItems.size()>0)
     {
        for(Launch_Item__c li: archivedLaunchItems)
         {
            li.Archive__c = true; 
         }
         update archivedLaunchItems;
     }
    }
    //Added by Hitesh CR 1633675
    //This method is called from LI trigger when PLU is changed for a launch item
    public void disableLIApprovalonPLUchange(List<Launch_Item__c> liList,Boolean isBefore, Boolean isAfter)
    { 
         //Retreiving all the approvals for the LI and making the isVisible field false to disable the approvals.
         if(isBefore)
           {
            for(Launch_Item__c li: liList)
               {
                li.IsFunctionalApprovalNotificationsSent__c = false ;
                li.isDivisionalApprovalNotificationsSent__c = false ;
               }
           }
           
           if(isAfter)
           {
            
             List<Launch_Item_Approval__c> launchApprovalList = [select Id,isVisible__c  from Launch_Item_Approval__c where Launch_Item__c IN : liList];
             
             for(Launch_Item_Approval__c lia : launchApprovalList)
                 {
                     if(lia.isVisible__c == true)
                        {
                            lia.isVisible__c = false;
                        }
                 }
            update launchApprovalList;
           }
         
          
       }
    public void processLaunchItemApprovals(List<Launch_Item_Approval__c> liaNewList,Map<Id,Launch_Item_Approval__c> liaOldMap,Boolean isInsert,Boolean isUpdate, Boolean isBefore, Boolean isAfter)
    {
      Boolean standingDelegationEmailCheck = false;
      if(getPLMCustomSettingValue('LaunchItemAprvlCls#StDelegationEmail').equals('1'))
         {
            standingDelegationEmailCheck = true;
         }  
      List<Launch_Item_Approval__c> launchItemApprovalList=new List<Launch_Item_Approval__c>();
      List<Launch_Item_Approval__c> launchApprovalList=new List<Launch_Item_Approval__c>();
      List<Launch_Item_Approval__c> reassignedLaunchApprovalList=new List<Launch_Item_Approval__c>();
      List<Launch_Item_Approval__c> statusChangeApprovedLaunchApprovalList=new List<Launch_Item_Approval__c>();
      List<Launch_Item_Approval__c> statusChangeRejectedLaunchApprovalList=new List<Launch_Item_Approval__c>();
        for(Launch_Item_Approval__c lia: liaNewList)
        {
          if(isInsert)
          {
            if(isBefore)
            {
                launchItemApprovalList.add(lia);
            }
            if(isAfter)
            {
                if(lia.isVisible__c)
                {
                    launchApprovalList.add(lia);
                }
                
            }
          }
          if(isUpdate && isAfter)
           {
            Boolean isApproverChanged=lia.Approver__c != null && lia.Approver__c!=liaOldMap.get(lia.Id).Approver__c;
            Boolean isDelegateApproverChanged =lia.Delegate_Approver__c != null && lia.Delegate_Approver__c!=liaOldMap.get(lia.Id).Delegate_Approver__c && standingDelegationEmailCheck;
            Boolean isStatusChangedToApproved=lia.status__c != null && lia.status__c!=liaOldMap.get(lia.Id).status__c && lia.status__c=='Approved';
            Boolean isStatusChangedToRejected=lia.status__c != null && lia.status__c!=liaOldMap.get(lia.Id).status__c && lia.status__c=='Rejected';
            
                if(lia.isVisible__c && isApproverChanged )
                 {
                   launchApprovalList.add(lia);
                 }
                if(lia.isVisible__c && isDelegateApproverChanged)
                 {
                   reassignedLaunchApprovalList.add(lia);
                 }
                 
                 if(lia.Division__c!=null && isStatusChangedToApproved)
                 {
                    statusChangeApprovedLaunchApprovalList.add(lia);
                 }
                 if(lia.Division__c!=null && isStatusChangedToRejected)
                 {
                    statusChangeRejectedLaunchApprovalList.add(lia);
                 }
          }
               
        }
        
        if(launchApprovalList.size()>0 )
        {       
            sendEmailNotificationToNewApprover(launchApprovalList,false);
        }
        if(reassignedLaunchApprovalList.size()>0)
        {
           // throw new CustomException('email list size '+reassignedLaunchApprovalList.size());
            sendEmailNotificationToNewApprover(reassignedLaunchApprovalList,true);
        }
        if(launchItemApprovalList.size()>0)
        {
            checkAndUpdateIfApprovalNotificationsSent(launchItemApprovalList);
        }
        if(statusChangeApprovedLaunchApprovalList.size()>0)
        {
            updateLaunchItemStatus(statusChangeApprovedLaunchApprovalList,true);
        }
        if(statusChangeRejectedLaunchApprovalList.size()>0)
        {
            updateLaunchItemStatus(statusChangeRejectedLaunchApprovalList,false);
        }
    
    }
    //Hitesh -CR 1594363 Feb Launch Approvals visible to users in the 'My Launch Item Approvals’ list view.
    //change in the query to match the view filter for the Launch approval view 
    private void initBulkDelegationPage()
    {
      dataClass.setIsReassigned(false);
      dataClass.setRetURL(getPLMCustomSettingValue('LaunchItemAprvlCls#MyViewId'));
      dataClass.setApprovalWrapperClass(new PLM_LaunchItemApprovalWrapperClass()); 
      dataClass.setApprovalsToDelegate([select Id
                                 ,Name
                                 ,Approver__c
                                 ,PLU__c
                                 ,Launch_Item__c
                                 ,Delegate_Approver__c
                                 ,Delegate_Approver__r.Name
                                 //,Temp_Delegate_To__c
                              from Launch_Item_Approval__c
                              where isVisible__c = true and
                                    PLU__c != null and
                                    Launch_Item__c !=null and
                                    LaunchItemArchived__c = 0 and 
                                    StandingDelegationCheck__c = false and
                                    isCurrentUserApprover__c = 1
                            /*  where isVisible__c = true
                              and isCurrentUserApprover__c =1*/
                                ]);
      dataClass.setApprovalsToDelegateWrapper(new List<PLM_LaunchItemApprovalWrapperClass>());
      List<PLM_LaunchItemApprovalWrapperClass> wrapperClassList=dataClass.getApprovalsToDelegateWrapper();
      // adding logic to not to show the bulk delegation page to PMs
      // Setting the message to be shown to PMs
      dataClass.setMessagePMBulkDlegation(PLM_Custom_Settings__c.getInstance('PLUViewPage#MessagePMBulkDlegation').value__C);
      dataClass.setIsDelegatePM(true);
      
      if(dataClass.getApprovalsToDelegate() == null || dataClass.getApprovalsToDelegate().size()== 0)
      {
            dataClass.setIsDelegatePM(false);
      }
      
      for(Launch_Item_Approval__c lia: dataClass.getApprovalsToDelegate())
      {
       PLM_LaunchItemApprovalWrapperClass litmClass=new PLM_LaunchItemApprovalWrapperClass();
       litmClass.teamMember=lia;
       wrapperClassList.add(litmClass);
      }
    }
    //Added for standing delegation
    //make it to work at without any list of functions.just call it and while retrieveing the map do it through the function value.
    private Map<String,List<Launch_Item_Approval__c>> functionToliaMapMethod()
     {  
        
        Map<String,List<Launch_Item_Approval__c>>  functionToliaMap = new Map<String,List<Launch_Item_Approval__c>>();
        for(String function : dataClass.getFunctionSet())
        {
          List<Launch_Item_Approval__c> delegationLIAList = new List<Launch_Item_Approval__c>();
          for(String div : dataClass.getDivisionSet())
          {
            Launch_Item_Approval__c lia = new Launch_Item_Approval__c(Function__c = function,Division__c = div);
            delegationLIAList.add(lia);
          } 
         functionToliaMap.put(function,delegationLIAList);
        }
        
        return  functionToliaMap;    
     }
    
    private void initSetFunctionalDivisionalApproverPage()
    {
     List<Schema.PicklistEntry> divisionPickList=Schema.Launch_Item_Approval__c.Division__c.getDescribe().getPicklistValues();
     List<Schema.PicklistEntry> functionPickList=Schema.Launch_Item_Approval__c.Function__c.getDescribe().getPicklistValues();
     dataClass.setIsAllFunctionsSelected(false);
     dataClass.setIsAllDivisionsSelected(false);
     dataClass.setWarningMsg(getPLMCustomSettingValue('SetApprovers#WarningMessage'));
     dataClass.setDivisionSet(divisionPickList);
     dataClass.setFunctionSet(functionPickList);
     dataClass.setShowWarning(false);
     dataClass.setIsEditPage(false);
     dataClass.setIsApplyToExisting(false);
     dataClass.setLaunchTeamFunctionalMemberList(new List<PLM_LaunchItemApprovalWrapperClass>());
     dataClass.setLaunchTeamDivisionalMemberList(new List<PLM_LaunchItemApprovalWrapperClass>());
     dataClass.setLaunchTeamFunctionalDivisionalList(new List<PLM_LaunchItemApprovalWrapperClass>());
     dataClass.setRetURL(ApexPages.currentPage().getParameters().get('retURL'));
     dataClass.setExistingTeamMemberMap(new Map<Id,Launch_Item_Approval__c>());
     
     if(dataClass.getRetURL()!=null && !dataClass.getRetURL().equals(''))
     {
      dataClass.setRetURL(EncodingUtil.urlDecode(dataClass.getRetURL(),'UTF-8'));
     }
     dataClass.setLaunchItemId(ApexPages.currentPage().getParameters().get('launchItemId'));
     
     List<Launch_Item_Approval__c> existingGlobalLaunchTeam=null;
     List<Launch_Item_Approval__c> standingDelegationGlobalLaunchTeam = null;
     if(dataClass.getLaunchItemId()!=null && !dataClass.getLaunchItemId().equals(''))
     {
      existingGlobalLaunchTeam=[select  Id
                                       ,Name
                                       ,Function__c
                                       ,Global_Setting_Id__c
                                       ,Division__c
                                       ,Approver__C 
                                       ,Delegate_Approver__c
                                  from Launch_Item_Approval__c 
                                  where Launch_Item__c =:dataClass.getLaunchItemId()
                                  and   StandingDelegationCheck__c = false];
                                    
      dataClass.setIsGlobalSetting(false);                                  
     }
     else
     {
      existingGlobalLaunchTeam = [select  Id
                                       ,Name
                                       ,Function__c
                                       ,Global_Setting_Id__c
                                       ,Division__c
                                       ,Approver__c
                                       ,Delegate_Approver__c 
                                   from Launch_Item_Approval__c 
                                  where Global_Setting_Id__c =:''
                                    and StandingDelegationCheck__c = false
                                    and Launch_Item__c =:''];
      standingDelegationGlobalLaunchTeam = [select  Id
                                       ,Name
                                       ,Function__c
                                       ,Global_Setting_Id__c
                                       ,Division__c
                                       ,Approver__c
                                       ,Delegate_Approver__c 
                                   from Launch_Item_Approval__c 
                                  where Global_Setting_Id__c =:''
                                    and StandingDelegationCheck__c = true
                                    and Launch_Item__c =:''];
      dataClass.setIsGlobalSetting(true);                                    
     }
    List<PLM_LaunchItemApprovalWrapperClass>  launchTeamFunctionalMemberList=dataClass.getLaunchTeamFunctionalMemberList();
    List<PLM_LaunchItemApprovalWrapperClass>  launchTeamDivisionalMemberList =dataClass.getLaunchTeamDivisionalMemberList();
    List<PLM_LaunchItemApprovalWrapperClass>  launchTeamFunctionalDivisionalList=dataClass.getLaunchTeamFunctionalDivisionalList(); 
    Map<String,List<Launch_Item_Approval__c>> standingDelMap=null;
    
    if(standingDelegationGlobalLaunchTeam == null || standingDelegationGlobalLaunchTeam.size()==0)
        
        {   
            standingDelMap = functionToliaMapMethod();
        }
    if(existingGlobalLaunchTeam!=null && existingGlobalLaunchTeam.size()>0)
    {
     Integer functionalIndex=0;
     Integer divisionalIndex=0;
     
     Map<Id,Launch_Item_Approval__c> existingTeamMap=dataClass.getExistingTeamMemberMap();
     //List<Launch_Item_Approval__c> delegationLIAList = new List<Launch_Item_Approval__c>();
     for(Launch_Item_Approval__c litm:existingGlobalLaunchTeam)
      {
       PLM_LaunchItemApprovalWrapperClass litmClass=null;
       List<Launch_Item_Approval__c> delegationLIAList = new List<Launch_Item_Approval__c>();
       if(litm.Division__c != null)
       {
        litmClass=new PLM_LaunchItemApprovalWrapperClass(litm,false,true,false,divisionalIndex++,litm.Id);
        launchTeamDivisionalMemberList.add(litmClass);
        launchTeamFunctionalDivisionalList.add(litmClass);
       }
       else
       {
        /*litmClass=new PLM_LaunchItemApprovalWrapperClass(litm,false,true,false,functionalIndex++,litm.Id);
        launchTeamFunctionalMemberList.add(litmClass);
        launchTeamFunctionalDivisionalList.add(litmClass);*/
        
        
      if(standingDelegationGlobalLaunchTeam!=null && standingDelegationGlobalLaunchTeam.size()>0)
       {  
        for(Launch_Item_Approval__c lia : standingDelegationGlobalLaunchTeam)
          {
            
            if(lia.Function__c == litm.Function__c)
            {
                //Map<String,List<Launch_Item_Approval__c>> standingDelMap = functionToliaMapMethod();
                delegationLIAList.add(lia);// = standingDelMap.get(lia.Function__c);
            }
          } 
       }
       else
       {
               delegationLIAList= standingDelMap.get(litm.Function__c);
       }
        litmClass=new PLM_LaunchItemApprovalWrapperClass(delegationLIAList,litm,false,true,false,functionalIndex++,litm.Id);
        launchTeamFunctionalMemberList.add(litmClass);
        launchTeamFunctionalDivisionalList.add(litmClass);
        
     
      }

       
       Launch_Item_Approval__c lia=new Launch_Item_Approval__c(Function__c=litm.Function__c,Division__c=litm.Division__c,Approver__c=litm.Approver__c);
       existingTeamMap.put(litm.Id,lia);
      }
      
      dataClass.setExistingTeamMemberMap(existingTeamMap);
    }
    else
    {
   
     Integer functionalIndex=0;
     Integer divisionalIndex=0;
     Launch_item__c li=null;
     //List<Launch_Item_Approval__c> delegationLIAList = new List<Launch_Item_Approval__c>();
     if(dataClass.getLaunchItemId()!=null && !dataClass.getLaunchItemId().equals(''))
     { li=[select Id,Division__c from Launch_Item__c where id=:dataClass.getLaunchItemId()][0];    }
         for(Schema.PicklistEntry p: divisionPickList)
         {
          Launch_Item_Approval__c litm=null;
          if(li!=null )
          {
           if(li.Division__c == p.getValue())
           {
            litm=new Launch_Item_Approval__c(Division__c=p.getValue(),Launch_Item__c=dataClass.getLaunchItemId());
           }
          }
          else
          {
           litm=new Launch_Item_Approval__c(Division__c=p.getValue(),Launch_Item__c=dataClass.getLaunchItemId());
          }
          if(litm!=null)
          {
          PLM_LaunchItemApprovalWrapperClass litmClass=new PLM_LaunchItemApprovalWrapperClass(litm,false,false,false,divisionalIndex++,null);
          launchTeamDivisionalMemberList.add(litmClass);
          launchTeamFunctionalDivisionalList.add(litmClass);
          }
         }
     
     for(Schema.PicklistEntry p: functionPickList)
     {
      Launch_Item_Approval__c litm=new Launch_Item_Approval__c(function__c=p.getValue());
      if(dataClass.getLaunchItemId()!=null && !dataClass.getLaunchItemId().equals(''))
      {litm.Launch_Item__c=dataClass.getLaunchItemId();}
      List<Launch_Item_Approval__c> delegationLIAList = null;
     // Map<String,List<Launch_Item_Approval__c>> standingDelMap = functionToliaMapMethod();
      if(dataClass.getLaunchItemId()==null || dataClass.getLaunchItemId().equals(''))
      {
       delegationLIAList = standingDelMap.get(p.getValue());
      }
      
      PLM_LaunchItemApprovalWrapperClass litmClass=new PLM_LaunchItemApprovalWrapperClass(delegationLIAList,litm,false,false,false,functionalIndex++,null);
      launchTeamFunctionalMemberList.add(litmClass);
      launchTeamFunctionalDivisionalList.add(litmClass);
      
      
     }
    
    } 
    } 
            
    /*
    private void standingDelegation(List<Launch_Item_Approval__c> liaRecordList)
    {       
            
            PLM_LaunchItemApprovalWrapperClass litmClassStandingDelegation = new PLM_LaunchItemApprovalWrapperClass(liaRecordList,litms,litm,false,true,false,functionalIndex++,litm.Id);
            launchTeamFunctionalMemberList.add(litmClassStandingDelegation);
            launchTeamFunctionalDivisionalList.add(litmClassStandingDelegation);
            
    }
    */
    private void initLIApprovalPage()
    {
     dataClass.setFromWhere(Apexpages.currentpage().getParameters().get('fromWhere'));
     dataClass.setUserList(new List<User>());
      String userDelegatedSrting =Apexpages.currentpage().getParameters().get('userDelegated');
      if(dataClass.getFromWhere()!=null && !dataClass.getFromWhere().equals('') && dataClass.getFromWhere()=='LaunchItemApprovalView')
      {
       dataClass.setBackToLinkName('<< Back To Launch Item Approvals');
      }
      else
      {
       dataClass.setBackToLinkName('<< Back To Launch Item');
      }
      dataClass.setLaunchItemApprovalId(Apexpages.currentpage().getParameters().get('id'));
      String retUrlString=Apexpages.currentpage().getParameters().get('retURL');
      
      if(dataClass.getLaunchItemApprovalId() !=null && dataClass.getLaunchItemApprovalId() !='' )
        {
         dataClass.setLaunchItemApproval([select Id
                                          , Name
                                          , Comments__c
                                          , Status__c
                                          , Function__c
                                          , Division__c
                                          , Approver__c 
                                          , Approver__r.Name //Added by hITESH
                                          , Launch_Item__c
                                          , Launch_Item__r.Name
                                          , Launch_Item__r.Product_Line_Picklist__c
                                          , Launch_Item__r.Product_Manager__r.Name
                                          , Launch_Item__r.Plu__r.Name
                                          , Launch_Item__r.Division__c
                                          , Delegate_Approver__c
                                          , Delegate_Approver__r.Name
                                          , isCurrentUserApprover__c
                                       from Launch_Item_Approval__c 
                                      where id =: dataClass.getLaunchItemApprovalId()
                                       and   StandingDelegationCheck__c = false][0]
                                     );
         }
       if(dataClass.getLaunchItemApproval()!=null)
       {
        if(dataClass.getLaunchItemApproval().Status__c=='Approved' || dataClass.getLaunchItemApproval().Status__c=='Pass')
          dataClass.setIsApproved(true);
        else if(dataClass.getLaunchItemApproval().Status__c=='Rejected' ||dataClass.getLaunchItemApproval().Status__c=='Fail')
          dataClass.setIsRejected(true);
        else
         {
          dataClass.setIsApproved(false);
          dataClass.setIsRejected(false);
         }
         dataClass.setComments(dataClass.getLaunchItemApproval().comments__c);
         
         if(dataClass.getLaunchItemApproval().Function__c != null)
         {
            dataClass.setApproveButtonName('Pass');
            dataClass.setRejectButtonName('Fail');
         }
         else
         {
            dataClass.setApproveButtonName('Approve');
            dataClass.setRejectButtonName('Reject');
         }
       }
       else
       {
        dataClass.setIsApproved(false);
        dataClass.setIsRejected(false);
       }
            
      if(retUrlString!=null && !retUrlString.equals(''))
      {
       dataClass.setRetURL(EncodingUtil.urlDecode(retUrlString,'UTF-8'));
      }
      else
      {
       dataClass.setRetURL('/'+dataClass.getLaunchItemApproval().Launch_Item__c);
      }
      dataClass.setUserDelegated(false);
      dataClass.setIsApprovalApproved(false);
      dataClass.setIsApprovalRejected(false);
      dataClass.setApproveRejectReassignMessage('');
    }
    
    private void initLIARelatedList()
    {
     dataClass.setLaunchItemId(ApexPages.currentPage().getParameters().get('id'));
     dataClass.setLaunchTeamFunctionalMemberList(new List<PLM_LaunchItemApprovalWrapperClass>());
     dataClass.setLaunchTeamDivisionalMemberList(new List<PLM_LaunchItemApprovalWrapperClass>());
     dataClass.setNoActiveApprovalsExistMsg(getPLMCustomSettingValue('LaunchApprvl#NoActiveApprvlMsg'));
     dataClass.setNoActiveFunctionApprovalExists(getPLMCustomSettingValue('LaunchApprvl#NoFuncApprvlMsg'));
     dataClass.setNoActiveDivisionApprovalExists(getPLMCustomSettingValue('LaunchApprvl#NoDivApprvlMsg'));
     List<Launch_Item_Approval__c> launchItemApprovalList=null;
     
     
     if(dataClass.getLaunchItemId()!=null && !dataClass.getLaunchItemId().equals(''))
     {
                                  launchItemApprovalList=[select Id,Name,Status__c,
                                                                 Function__c,
                                                                 Division__c,
                                                                 isCurrentUserApprover__c ,
                                                                 Approved_By__c,
                                                                 Approved_Date__C,
                                                                 Approver__c,
                                                                 Approver__r.Name,
                                                                 Delegate_Approver__r.Name,
                                                                 Delegate_Approver__c,
                                                                 Comments__c 
                                                           from  Launch_Item_Approval__c 
                                                          where  Launch_Item__c =:dataClass.getLaunchItemId()
                                                          and    isVisible__c=:true
                                                          and   StandingDelegationCheck__c = false
                                                           ];
                                                        
                                    
      Set<Id> liaIdSet=new Set<Id>();
      
      
     for(Launch_Item_Approval__c lia: launchItemApprovalList)
     {
      liaIdSet.add(lia.Id);
     }
     List<Attachment> attachmentList=null;
     Set<Id> attachmentParentIdSet=new Set<Id>();
     if(liaIdSet.size()>0)
     {
         attachmentList=[select Id,ParentId from Attachment where parentId IN : liaIdSet];
         for(Attachment a: attachmentList)
         {
          attachmentParentIdSet.add(a.parentId);
         }
     }
     for(Launch_Item_Approval__c lia: launchItemApprovalList) 
     {
       PLM_LaunchItemApprovalWrapperClass liaClass=new PLM_LaunchItemApprovalWrapperClass();
       liaClass.teamMember=lia;
      if(attachmentParentIdSet.contains(lia.Id))
      {
       liaClass.isAttchmentExists=true;
      }
      else
      {
       liaClass.isAttchmentExists=false;
      }
      if(lia.Function__c !=null)
      {
        dataClass.getLaunchTeamFunctionalMemberList().add(liaClass); 
       }
      if(lia.Division__c !=null)
      {
       dataClass.getLaunchTeamDivisionalMemberList().add(liaClass);
      }
     } 
    }
              
    }
    public PageReference reassignAll()
    {
     try
     {
         List<Launch_Item_Approval__c> launchItemAppovalsList=new List<Launch_Item_Approval__c>();
         
         Boolean isAllNotChecked=false;
         for(PLM_LaunchItemApprovalWrapperClass litmClass: dataClass.getApprovalsToDelegateWrapper())
         {
          if(litmClass.isChecked)
          {
              if(dataClass.getApprovalWrapperClass().userId!=null && !dataClass.getApprovalWrapperClass().userId.equals(''))
              {
               litmClass.teamMember.Delegate_Approver__c=dataClass.getApprovalWrapperClass().userId;
              }
              else if(litmClass.userId !=null && !litmClass.userId.equals(''))
              {
               litmClass.teamMember.Delegate_Approver__c=litmClass.userId;
              }
              else
              {
               throw new CustomException('Please select a user');
              }
            launchItemAppovalsList.add(litmClass.teamMember);   
          }
            
         }
         if(launchItemAppovalsList.size()>0)
         {
          upsert launchItemAppovalsList;
          initBulkDelegationPage();
          dataClass.setIsReassigned(true);
         }
         else
         {
          throw new CustomException('Please select a record to reassign');
         }
     }
     catch(Exception e)
     {
      ApexPages.addMessages(e);
     }

     return null;
    }
    public PageReference selectAll() 
     {
        List<PLM_LaunchItemApprovalWrapperClass> tempList=dataClass.getApprovalsToDelegateWrapper();
        
        if(tempList!=null && tempList.size()>0)
        {
          for(PLM_LaunchItemApprovalWrapperClass ltm: tempList)
          {
           if(!ltm.isChecked && dataClass.getIsAllSelected())
            {
             ltm.isChecked=true;
            }
           else if(!dataClass.getIsAllSelected()&& ltm.isChecked)
            {
            ltm.isChecked=false;
            }
          }
        }
       return null;
    }
    
    /*
     cancel()
      - Will be called from page when user clicks on Cancel button.
      - Will be redirected to Previous page if page is not in Edit mode (isEditPage=false)
      - Will be redirected to Non Edit mode page if current page mode is Edit(isEditPage=true)
    */
    public PageReference cancel() 
    {
      PageReference pageRef=null;
      if(dataClass.getPageName().equals('PLM_SetFunctionalDivisionalApprovers') && dataClass.getIsEditPage())
      {
       dataClass.setIsEditPage(false);
       initSetFunctionalDivisionalApproverPage();
      }
      else
      {
       pageRef=new PageReference(dataClass.getRetURL());
      }
        return pageRef;
    }
   
    
     /*
     checkIfChanged()
      - Will be called internally from other method when user clicks on save button.
      - Will check Which record got changed in user operation.
    */
    
    public void checkIfChanged()
    {
       
       for(PLM_LaunchItemApprovalWrapperClass litmClass :dataClass.getLaunchTeamFunctionalDivisionalList())
         {
                
             if(litmClass.isExisting && !litmClass.isDeleted)
             {
               Launch_Item_Approval__C li=dataClass.getExistingTeamMemberMap().get(litmClass.teamMember.Id);
              if(litmClass.teamMember.Function__c !=li.Function__c || litmClass.teamMember.Division__c !=li.Division__c || litmClass.teamMember.Approver__c!=li.Approver__c)
              {
               
                litmClass.isChanged=true;
              }
             }
             else if(!litmClass.isExisting)
             {
              litmClass.isChanged=true;
             }
            
         }
    }
    
     /*
     refreshLaunchTeamFunctionalDivisionalList()
      - Will be called internally from other method when user clicks on save button.
      - Will refresh launchTeamFunctionalDivisionalList list with union of current launchTeamFunctionalMemberList and launchTeamDivisionalMemberList.
    */
    
    private void refreshLaunchTeamFunctionalDivisionalList()
    {
     for(PLM_LaunchItemApprovalWrapperClass litmClass :dataClass.getLaunchTeamFunctionalDivisionalList())
     {
       for(PLM_LaunchItemApprovalWrapperClass litmClassF: dataClass.getLaunchTeamFunctionalMemberList())
       {
        if(litmClass.isExisting && litmClass.launchItemApprovalId==litmClassF.launchItemApprovalId )
        {
         litmClass.teamMember=litmClassF.teamMember;
         
        }
        if(!litmClass.isExisting && litmClass.teamMember.Function__c==litmClassF.teamMember.Function__c )
        {
         litmClass.teamMember=litmClassF.teamMember;
         //litmClass.func_div_StandingDelegation=litmClassF.func_div_StandingDelegation;
        }
       }
       for(PLM_LaunchItemApprovalWrapperClass litmClassD: dataClass.getLaunchTeamDivisionalMemberList())
       {
        if(litmClass.isExisting && litmClass.launchItemApprovalId==litmClassD.launchItemApprovalId)
        {
         litmClass.teamMember=litmClassD.teamMember;
        }
        if(!litmClass.isExisting && litmClass.teamMember.Division__c==litmClassD.teamMember.Division__c)
        {
         litmClass.teamMember=litmClassD.teamMember;
        }
       }
       
       
       
     }
    }
    
    /*
     checkIfMultipleFunctionDivision()
      - Will be called internally from other method when user clicks on save button.
      - Will Check if user has defined same division/function more than once
    */
    private void checkIfMultipleFunctionDivision()
    {
     
     Map<String,Integer> functionDivisionMap=new Map<String,Integer>();
     for(String function: dataClass.getFunctionSet())
     {
      Integer count=0;
      for(PLM_LaunchItemApprovalWrapperClass litmClass: dataClass.getLaunchTeamFunctionalMemberList())
      {
       if(function==litmClass.teamMember.Function__c)
       {
        functionDivisionMap.put(function,++count);
       }
      }
     }
     for(String division: dataClass.getDivisionSet())
     {
      Integer count=0;
      for(PLM_LaunchItemApprovalWrapperClass litmClass: dataClass.getLaunchTeamDivisionalMemberList())
      {
       if(division==litmClass.teamMember.Division__c)
       {
        functionDivisionMap.put(division,++count);
       }
      }
     }
     for(String key: functionDivisionMap.keySet())
     {
      Integer i= functionDivisionMap.get(key);
      if(i!=null && i>1)
      {
        throw new CustomException(getPLMCustomSettingValue('SetApprovers#ErrorMessage'));
      }
     }
    }
    
    /*
     save()
      - Will be called when user clicks on save button.
      - Will Check if user has defined same division/function more than once.
      - Will refresh launchTeamFunctionalDivisionalList
      - Will check fo which records are modified
      - Update only those records which are either Changed, not existing(insert)
      - Delete all those which were marked for delete
      - call another function applyToExistingLaunchItems which will apply changes to existing launch Items also
    */
    public PageReference save() 
    {
     try
         { 
           checkIfMultipleFunctionDivision();
           refreshLaunchTeamFunctionalDivisionalList();
           checkIfChanged();
           List<Launch_Item_Approval__c> upsertGlobalTeamList=new List<Launch_Item_Approval__c>();
           List<Launch_Item_Approval__c> deleteGlobalTeamList=new List<Launch_Item_Approval__c>();
           List<Launch_Item_Approval__c> standingDelegateList=new List<Launch_Item_Approval__c>();
           List<Launch_Item_Approval__c> upsertGlobalTeamListnew=new List<Launch_Item_Approval__c>();
           
         // throw new CustomException('getLaunchTeamFunctionalDivisionalList size'+dataClass.getLaunchTeamFunctionalDivisionalList().size());
           
           for(PLM_LaunchItemApprovalWrapperClass litmClass :dataClass.getLaunchTeamFunctionalDivisionalList())
           {
             if(litmClass.isDeleted && litmClass.isExisting)
             {
              deleteGlobalTeamList.add(litmClass.teamMember);
             }
             else if(!litmClass.isDeleted && litmClass.isChanged)
             {
              upsertGlobalTeamListnew.add(litmClass.teamMember ); //adding to save one DML 
              
             } 
            if(litmClass.teamMember.function__c!=null) 
            {
               
               if(litmClass.func_div_StandingDelegation.size()>0 && dataClass.getIsGlobalSetting())
               {
                
                for(Launch_Item_Approval__c lia : litmClass.func_div_StandingDelegation)
                {
                    
                    lia.StandingDelegationCheck__c = true;
                    standingDelegateList.add(lia);
                    
                
                }
                
              }
              
            }
            
           }
           for(Launch_Item_Approval__c lia : upsertGlobalTeamListnew)
               upsertGlobalTeamList.add(lia);
            for(Launch_Item_Approval__c lia : standingDelegateList)
               upsertGlobalTeamList.add(lia);
          // throw new CustomException('Stand Del list size,upsertGlobalTeamListnew,upsertGlobalTeamList '+standingDelegateList.size()+'-'+upsertGlobalTeamListnew.size()+'-'+upsertGlobalTeamList.size());
           
           if(upsertGlobalTeamList.size()>0)
           {
            
           
             upsert upsertGlobalTeamList;
            
           }
           if(deleteGlobalTeamList.size()>0)
           {
            delete deleteGlobalTeamList;
           }
           PLM_Custom_Settings__c stDel = PLM_Custom_Settings__c.getInstance('LaunchItemAprvlCls#StDelegationEmail');
           if(dataClass.getIsApplyToExisting())
           {
            stDel.value__c = '0';
            update stDel;
            applyToExistingLaunchItems(upsertGlobalTeamListnew,deleteGlobalTeamList,standingDelegateList);
           }
           if(dataClass.getIsEditpage())
           {
            dataClass.setIsEditpage(false);
           }
          
          initSetFunctionalDivisionalApproverPage(); 
          
          stDel.value__c = '1';
          update stDel;   
         }
         catch(Exception e)
         {
          ApexPages.addMessages(e);
         }
        
      return null;
    }
    /*
    Recieves a list of LIA and based on the division,map is created
    called internally
    Added by - Hitesh Chawda CR 2071774
    Keeping all division values in CS with : separated strings. Extracting that into division list.
    For every Division value cretae a Map of 'Division to a Map of Function To Delegate Approver add all these Maps into a List of Maps.
    */
    private Map<String,Map<String,String>> divisionMapMethod(List<Launch_Item_Approval__c> standingDelegateList)
    {
       
       String str = PLM_Custom_Settings__c.getValues('LaunchApprvl#Division').value__c;
       List<String> divisionList = str.split(':', 0) ;
       
       //Throw New CustomException ('Division List '+divisionList) ;
       Map<String,Map<String,Id>> funcToDelegateMap = new Map<String,Map<String,Id>>();
       
       List<Map<String,Map<String,Id>>> funcToDivisionMapList = new List<Map<String,Map<String,Id>>>();
       
       for(String str1 : divisionList)
       		{
       			Map<String,Id> funcToDivisionMap  = new Map<String,Id>();
       			Map<String,Map<String,Id>> divisionTofuncToDivisionMap = new Map<String,Map<String,Id>>();
       			divisionTofuncToDivisionMap.put(str1,funcToDivisionMap);
       			funcToDivisionMapList.add(divisionTofuncToDivisionMap);
       		}
       /*
       Go through all the LIA records, for every division value, if it matches to lia record Division Value,
       choose the correct Map from the funcToDivisionMapList list and get the equivalent Map of Function To Delegate Approver 
       and put the required value into that Map.
       */		
       for(Launch_Item_Approval__c lia :standingDelegateList)
        {
      //Checking for division and based on division map between division and function
        	if(lia.Division__c!=null)
        
        		{
            		for(String str2 : divisionList)
            			{
            				if(lia.Division__c == str2)
            					{
            	  					for(Map<String,Map<String,Id>> divTofuncToDivMap : funcToDivisionMapList)
            	  					{
            	  						if(divTofuncToDivMap.get(str2)!= null)
            	  						{
            	  							divTofuncToDivMap.get(str2).put(lia.Function__c,lia.Delegate_Approver__c);
            	  							funcToDelegateMap.put(lia.Division__c,divTofuncToDivMap.get(str2));
            	  						}
            					    }
            					}
        				}
        		}
        }  
      
       return  funcToDelegateMap;
    }
    
    /*
    Commenting the whole function and replaced with above function
    Recieves a list of LIA and based on the division,map is created
    called internally
    */
    /*private Map<String,Map<String,String>> divisionMapMethod(List<Launch_Item_Approval__c> standingDelegateList)
    {
       PLM_Custom_Settings__c carrierProdDiv = PLM_Custom_Settings__c.getValues('LaunchApprvl#CarrierProductsDiv');
       PLM_Custom_Settings__c emergingProdDiv = PLM_Custom_Settings__c.getValues('LaunchApprvl#EmergingProductsDiv');
       PLM_Custom_Settings__c mediaDiv = PLM_Custom_Settings__c.getValues('LaunchApprvl#MediaDiv');
       PLM_Custom_Settings__c servicenSupDiv = PLM_Custom_Settings__c.getValues('LaunchApprvl#ServicenSupportDiv');
       PLM_Custom_Settings__c webExpDiv = PLM_Custom_Settings__c.getValues('LaunchApprvl#WebExpDiv');
       
       Map<String,Map<String,String>> funcToDelegateMap = new Map<String,Map<String,String>>();
       Map<String,Id> funcToService_SupportDiv = new Map<String,Id>();
       //Map<String,Id> funcToSiteDiv = new Map<String,Id>();
       Map<String,Id> funcToMediaDiv = new Map<String,Id>();
       //Map<String,Id> funcToEnterpriseCloudDiv = new Map<String,Id>();
       Map<String,Id> funcToEmergingProducts =new Map<String,Id>();
       Map<String,Id> funcToCarrierProducts = new Map<String,Id>();
      // Map<String,Id> funcToServiceandSupport = new Map<String,Id>(); 
       Map<String,Id> funcToWebExperience = new Map<String,Id>();
       for(Launch_Item_Approval__c lia :standingDelegateList)
        {
      //Checking for division and based on division map between division and function
        if(lia.Division__c!=null)
        
        {
            if(lia.Division__c == servicenSupDiv.value__c)
                {
                    funcToService_SupportDiv.put(lia.Function__c,lia.Delegate_Approver__c);
                    funcToDelegateMap.put(lia.Division__c,funcToService_SupportDiv);
                }
            
            else if(lia.Division__c == mediaDiv.value__c)
                {
                funcToMediaDiv.put(lia.Function__c,lia.Delegate_Approver__c);
                funcToDelegateMap.put(lia.Division__c,funcToMediaDiv);
                }
            
            else if(lia.Division__c == webExpDiv.value__c)
                {
                funcToWebExperience.put(lia.Function__c,lia.Delegate_Approver__c);
                funcToDelegateMap.put(lia.Division__c,funcToWebExperience);
                }
            else if(lia.Division__c == emergingProdDiv.value__c)
                {
                funcToEmergingProducts.put(lia.Function__c,lia.Delegate_Approver__c);
                funcToDelegateMap.put(lia.Division__c,funcToEmergingProducts);
                }
            else if(lia.Division__c == carrierProdDiv.value__c)
                {
                funcToCarrierProducts.put(lia.Function__c,lia.Delegate_Approver__c);
                funcToDelegateMap.put(lia.Division__c,funcToCarrierProducts);
                }  
                /*else if(lia.Division__c == 'Site')
                {
                funcToSiteDiv.put(lia.Function__c,lia.Delegate_Approver__c);
                funcToDelegateMap.put(lia.Division__c,funcToSiteDiv);
                }*/  
                /*else if(lia.Division__c == 'Enterprise Cloud')
                { 
                funcToEnterpriseCloudDiv.put(lia.Function__c,lia.Delegate_Approver__c);
                funcToDelegateMap.put(lia.Division__c,funcToEnterpriseCloudDiv);
                }*/    
                    
      //  }
       //}
       //return  funcToDelegateMap;
   // }
    /*
     applyToExistingLaunchItems()
      - Will be called internally from other method when user clicks on save button.
      - Will apply changes to existing launch Items also
      - Will delete the approvals records of existing launch items if related Global record got deleted.
      - Will upsert the approvals reocrds of existing launch items if related global reocrd is updated/created
    */
    private void applyToExistingLaunchItems(List<Launch_Item_Approval__c> upsertGlobalTeamList,List<Launch_Item_Approval__c> deleteGlobalTeamList,List<Launch_Item_Approval__c> standingDelegateList )
    {
       //Creating a map of map to include the standig delegation logic
       //Map between function and delegate approver and 4 maps for 4 different divisions
       Map<String,Map<String,String>> funcToDelegateMap = divisionMapMethod(standingDelegateList);
       
       
       List<Launch_Item__c> launchItemList=[select Id,Division__c from Launch_Item__c where Archive__c =false];
       
       Set<Id> launchItemIdSet=new Set<Id>();
       for(Launch_Item__c lia: launchItemList)
       {
        launchItemIdSet.add(lia.Id);
       }
       List<Launch_Item_Approval__c> currentLaunchItemApprovals=[select Id,Function__c,Division__c,Approver__c,Delegate_Approver__c,Global_setting_id__c,Launch_Item__c from Launch_Item_Approval__C where Launch_Item__c IN :launchItemIdSet ];
       
       
       
       Set<Id> launchItemGlobalSettingIdSet=new Set<Id>();
       
       Map<Id,List<Launch_Item_Approval__C>> LaunchItemIdLaunchApprovalList=new Map<Id,List<Launch_Item_Approval__C>>();
       Map<Id,Set<Id>> launchItemIdGlobalSettingIdSetMap=new Map<Id,Set<Id>>();
       
       List<Launch_Item_Approval__C> allUpsertLaunchItemApproval=new List<Launch_Item_Approval__C>();
       List<Launch_Item_Approval__C> allDeleteLaunchItemApproval=new List<Launch_Item_Approval__C>();
     
       
       for(Id launchId: launchItemIdSet) 
       {
        List<Launch_Item_Approval__C> singleLaunchItemApprovals=new List<Launch_Item_Approval__C>();
        for(Launch_Item_Approval__C lia: currentLaunchItemApprovals)
        {
         if(launchId==lia.Launch_Item__c)
         {
          singleLaunchItemApprovals.add(lia);
          launchItemGlobalSettingIdSet.add(lia.global_setting_id__c);
         }
        }
        LaunchItemIdLaunchApprovalList.put(launchId,singleLaunchItemApprovals);
        launchItemIdGlobalSettingIdSetMap.put(launchId,launchItemGlobalSettingIdSet);
       }
       
       for(Launch_Item__c launchItem : launchItemList)
        {
         List<Launch_Item_Approval__c> launchItemApprovalList=LaunchItemIdLaunchApprovalList.get(launchItem.Id);
         Set<Id> globalSettingIdSet=launchItemIdGlobalSettingIdSetMap.get(launchItem.Id);
         Map<Id,Launch_Item_Approval__c> idToRecordMap = new Map<Id,Launch_Item_Approval__c>();
        // throw new CustomException('GlobalTeamList'+launchItemApprovalList);
         //'GlobalTeamList'+launchItemApprovalList+'DelList'+standingDelegateList.size()
         for(Launch_Item_Approval__c litm: upsertGlobalTeamList)
           {
             
            Launch_Item_Approval__c launchItemApproval=null;
             
            if(launchItemApprovalList==null)
            {
             if(litm.Function__c!=null)
             {
             Id delId = null;   
             delId = funcToDelegateMap.get(launchItem.Division__c).get(litm.Function__c);
                
                
              launchItemApproval=new Launch_Item_Approval__c(Launch_Item__c=launchItem.Id,Delegate_Approver__c=delId,Approver__c=litm.Approver__c,Global_Setting_Id__c=litm.Id,Function__c=litm.Function__c);
              allUpsertLaunchItemApproval.add(launchItemApproval);
             }
             else if(litm.Division__c!=null && launchItem.Division__c==litm.Division__c)
             {
              launchItemApproval=new Launch_Item_Approval__c(Launch_Item__c=launchItem.Id,Approver__c=litm.Approver__c,Global_Setting_Id__c=litm.Id,Division__c=litm.Division__c);
              allUpsertLaunchItemApproval.add(launchItemApproval);
             }
             
            }
            else
            {
             if(globalSettingIdSet!=null && globalSettingIdSet.contains(litm.Id))
             {
                 for(Launch_Item_Approval__c lia: launchItemApprovalList)
                 {
                  if(litm.Id == lia.Global_Setting_id__c)
                  {
                     lia.Approver__c=litm.Approver__c;
                     //lia.Delegate_Approver__c=litm.Delegate_Approver__c;
                     if(litm.Function__c!=null)
                     {
                      lia.Function__c=litm.Function__c;
                     // lia.Delegate_Approver__c = funcToDelegateMap.get(litm.Division__c).get(litm.Function__c);
                    
                     }
                     else if(litm.Division__c!=null)
                     {
                      lia.Division__c=litm.Division__c;
                     }
                      //allUpsertLaunchItemApproval.add(lia);
                      idToRecordMap.put(lia.Id,lia);
                   }
                  }
             }
             else
             {
               if(litm.Function__c!=null)
                 {
                  Id liaId = funcToDelegateMap.get(launchItem.Division__c).get(litm.Function__c);
                  launchItemApproval=new Launch_Item_Approval__c(Launch_Item__c=launchItem.Id,Approver__c=litm.Approver__c,Delegate_Approver__c=liaId,Global_Setting_Id__c=litm.Id,Function__c=litm.Function__c);
                  allUpsertLaunchItemApproval.add(launchItemApproval);
                 }
                 else if(litm.Division__c!=null && launchItem.Division__c==litm.Division__c)
                 {
                  launchItemApproval=new Launch_Item_Approval__c(Launch_Item__c=launchItem.Id,Approver__c=litm.Approver__c,Delegate_Approver__c=litm.Delegate_Approver__c,Global_Setting_Id__c=litm.Id,Division__c=litm.Division__c);
                  allUpsertLaunchItemApproval.add(launchItemApproval);
                 }                  
             } 
            }        
           }           
           for(Launch_Item_Approval__c litm: deleteGlobalTeamList)
           {
            if(globalSettingIdSet!=null && globalSettingIdSet.contains(litm.Id))
            {
             for(Launch_Item_Approval__c lia: launchItemApprovalList)
             {
              if(litm.Id == lia.Global_Setting_id__c)
              {
               allDeleteLaunchItemApproval.add(lia);
              }
             }
            }
           }
           
            //Map<String,Map<String,String>> divisionMap = divisionMapMethod.get(launchItem);
            for(Launch_Item_Approval__c lia : launchItemApprovalList)
            {
                 
                Set<Id> idset = idToRecordMap.KeySet();
                if(lia.Function__c!=null &&  idset.contains(lia.Id))
                {
                    Launch_Item_Approval__c liaRecord = idToRecordMap.get(lia.Id);
                    liaRecord.Delegate_Approver__c = funcToDelegateMap.get(launchItem.Division__c).get(lia.Function__c);
                    idToRecordMap.put(liaRecord.Id,liaRecord);
                }
                else if(lia.Function__c!=null && !idset.contains(lia.Id))
                {
                    lia.Delegate_Approver__c = funcToDelegateMap.get(launchItem.Division__c).get(lia.Function__c);
                    idToRecordMap.put(lia.Id,lia);
                }
                //allUpsertLaunchItemApproval.add(lia);
            }
        for(Launch_Item_Approval__c lia :idToRecordMap.values())
        {
         allUpsertLaunchItemApproval.add(lia);
        }
           }
        
        
        if(allUpsertLaunchItemApproval.size()>0)
        {
         upsert allUpsertLaunchItemApproval;
        }
        
        if(allDeleteLaunchItemApproval.size()>0)
        {
         delete allDeleteLaunchItemApproval;
        }
     
    }
   
     /*
     edit()
      - Will be called when user clicks on edit button.
      - Will update page edit mode to true
    */
    public PageReference edit() 
    {
      if(!dataClass.getIsEditPage())
      {
       dataClass.setIsEditPage(true);
      }
        return null;
    }
    
    public PageReference reassign() 
    {
        PageReference pageRef=null;
      try
        {
          if(dataClass.getLaunchItemApproval().Delegate_Approver__c == null)
          {
           throw new CustomException('Please select a user to reassign the approval.');
          }
          else
          {
           upsert dataClass.getLaunchItemApproval();
           initLIApprovalPage();
           dataClass.setUserDelegated(true);
           dataClass.setIsApprovalApproved(false);
           dataClass.setIsApprovalRejected(false);
           dataClass.setApproveRejectReassignMessage(getPLMCustomSettingValue('LaunchApprvl#ReassignedMsg'));
          }
        }
        catch(Exception e)
        {
         ApexPages.addMessages(e);
        }
        return pageRef;
    }
    /*
      reject()
      - Will be called when User clicks on 'Reject' button on page.
      - Will Update Launch Approval status as 'Rejected'.
      - Once rejected approval can not be reassigned and can only be Approved. 
    */
    
    public PageReference reject() 
    {
      try
       {
         if(dataClass.getLaunchItemApproval().Division__c!=null)
         {
          dataClass.getLaunchItemApproval().status__c='Rejected';
         }
         else
         {
          dataClass.getLaunchItemApproval().status__c='Fail';
         }
         
         dataClass.getLaunchItemApproval().comments__c=dataClass.getComments();
         if(dataClass.getApprovalAttachment().body!=null)
          {
             if(dataClass.getApprovalAttachment().Name==null || dataClass.getApprovalAttachment().Name=='')
             {
              throw new CustomException('Please enter a Name for Attachment.');
             }
             else
             {
              dataClass.getApprovalAttachment().parentId= dataClass.getLaunchItemApproval().Id;
             }
          }
         
         upsert dataClass.getLaunchItemApproval();
         if(dataClass.getApprovalAttachment().body!=null && dataClass.getApprovalAttachment().Name!=null && dataClass.getApprovalAttachment().Name!='')
         {
          insert dataClass.getApprovalAttachment();
         }
         dataClass.setIsApproved(false);
         dataClass.setIsRejected(true);
         dataClass.setApproveRejectReassignMessage(getPLMCustomSettingValue('LaunchApprvl#RejectedMsg'));
         dataClass.setIsApprovalApproved(false);
         dataClass.setIsApprovalRejected(true);
         dataClass.setUserDelegated(false);
         dataClass.setApprovalAttachment(null);
       }
       catch(Exception e)
      {
        ApexPages.addMessages(e);
      }
       return null;
    }

    /*
      approve()
      - Will be called when User clicks on 'Approve' button on page.
      - Will Update Launch Approval status as 'Approved'.
      - Once Approve approval can not be reassigned and can only be Rejected. 
    */
    public PageReference approve() 
    {
     try
       {
         Datetime currentDateTime = DateTime.now();
         String LongDate = currentDateTime.format();
         if(dataClass.getLaunchItemApproval().Division__c!=null)
         {
          dataClass.getLaunchItemApproval().status__c='Approved';
         }
         else
         {
          dataClass.getLaunchItemApproval().status__c='Pass';
         }
         dataClass.getLaunchItemApproval().comments__c=dataClass.getComments();
         dataClass.getLaunchItemApproval().Approved_Date__c=DateTime.parse(LongDate);
         dataClass.getLaunchItemApproval().Approved_By__c=UserInfo.getName();
         if(dataClass.getApprovalAttachment().body!=null)
           {
             if(dataClass.getApprovalAttachment().Name==null || dataClass.getApprovalAttachment().Name=='')
             {
              throw new CustomException('Please enter a Name for Attachment.');
             }
             else
             {
              dataClass.getApprovalAttachment().parentId= dataClass.getLaunchItemApproval().Id;
             }
           }
          upsert dataClass.getLaunchItemApproval();
         if(dataClass.getApprovalAttachment().body!=null && dataClass.getApprovalAttachment().Name!=null && dataClass.getApprovalAttachment().Name!='')
         {
          insert dataClass.getApprovalAttachment();
         }  
           dataClass.setIsApproved(true);
           dataClass.setisRejected(false);
           dataClass.setUserDelegated(false);
           dataClass.setApproveRejectReassignMessage(getPLMCustomSettingValue('LaunchApprvl#ApprovedMsg'));
           dataClass.setIsApprovalApproved(true);
           dataClass.setIsApprovalRejected(false);
           dataClass.setApprovalAttachment(null);
       }
       catch(Exception e)
      {
        ApexPages.addMessages(e);
      }
        
     return null;
    }
    
    /*
      searchUser()
      - Will be called when User clicks on 'Search' button on page under Reasiign section.
      - Will take up the input and search against User Name.
    */
    public PageReference searchUser()
    {
      dataClass.setUserList([select Id,Name from User where Name Like : '%'+dataClass.getDelgateApprover()+'%' and isActive=true]);
      if(dataClass.getUserList()==null)
      {
      dataClass.setUserList(new List<User>());
      }
      dataClass.setIdUserMap(new Map<Id,User>());
      if(dataClass.getUserList()!=null && dataClass.getUserList().size()>0)
      {
       //dataClass.setIsUserListSizeGTZero(true);
       for(User u: dataClass.getUserList())
       {
        dataClass.getIdUserMap().put(u.Id,u);
        }
      }
       
      return null;
    }
    
     /*
      selectUser()
      - Will be called when User selects user by clicking on user name.
      - Updates Delgate Approver field on launch Approval and wipe out the user search results.
    */
    
     public PageReference selectUser()
    {
        String userId=Apexpages.currentpage().getParameters().get('userId'); 
        User user= dataClass.getIdUserMap().get(userId);
        dataClass.getLaunchItemApproval().Delegate_Approver__c=user.Id;
        dataClass.setDelgateApprover(user.Name);
        dataClass.setUserList(new List<User>());
        return null;
    }
    /*
     This method will be called when user cilcks on 'Go' button on lookup page
    */
    public PageReference runQuery()
    {
    try
      {
        if(dataClass.getQuery()!=null && !dataClass.getQuery().equals(''))
       {
       if(dataClass.getQuery().length() > 2)
       {
        dataClass.setUserList([select Id,Name,Phone,Email,UserRole.Name,Title from User where Name like : '%'+dataClass.getQuery()+'%' and isActive=true]); 
       }
       else
        throw new CustomException('Please use more than two letters in search');
       }
      }
      catch(Exception e)
      {
       ApexPages.addMessages(e);
      }
        //accounts=searchResults[0];
        return null;
    }
    
 // Methods called from Triggers and visulaforce page methods and cron jobs
 
    /*
      makeVisibleAndSendEmailNotifiations
      - This method will be called when Product Operations click 'Notify Function Representative' button on PLU View page.
      - This method also will be called when Product Operations/PM/Owner of Launch item click on 'Notify Division GM' buttton on Launch Item View page.
      - This function does following:
        -> When 'Notify Function Representative' is clicked, it enables(updates visible__c=true) all the Functional Approvals of all launch Items for that PLU.
        -> When 'Notify Division GM' is clicked, it enables(updates visible__c=true) divisional approval of the Launch Item.
        -> Sends out consolidated mail in both cases to respective approvers.
     */ 
     public void makeVisibleAndSendEmailNotifiations(List<Launch_Item__c>  launchItemList,Boolean isFunction, String pluId)
     {
                           
        //String approvalInitiatedRecordTypeName=getPLMCustomSettingValue('LaunchItemApprvlInitiatedRecordType');
        //Id approvalInitiatedRecordTypeId=getRecordTypeId(approvalInitiatedRecordTypeName);
        List<Launch_Item__c> launchItemUpsertList=new List<Launch_Item__c> ();
        Set<Id> activeLaunchItemsIdSet=new Set<Id>();
        
        //Filtering active launch Item List and updating Launch items to store Approvals Initialization information.
        for(Launch_Item__c li: launchItemList)
        {
         if(!li.Archive__c)
         {
          activeLaunchItemsIdSet.add(li.Id);
          if(isFunction)
          {
            li.IsFunctionalApprovalNotificationsSent__c=true;
            //li.RecordTypeId=approvalInitiatedRecordTypeId;
          }
          else
          {
            li.isDivisionalApprovalNotificationsSent__c=true;
          }
          
          launchItemUpsertList.add(li);
         }
        }
        // Getting all Launch Item Approvals for active launch Items
        List<Launch_Item_Approval__c> launchItemApprovalList=null;
        String eventType='';
        if(isFunction)
        {
         launchItemApprovalList=[select Id
                                       ,Name
                                       ,isVisible__c
                                       ,Approver__c
                                       ,Approver__r.Name
                                       ,Delegate_Approver__c
                                       ,Delegate_Approver__r.Name
                                       ,Launch_Item__c
                                       ,Launch_Item__r.Product_Manager__c
                                       ,Launch_Item__r.Product_Manager__r.Name
                                       ,Launch_Item__r.Product_Manager__r.Email 
                                       ,Launch_Item__r.Name
                                       ,Launch_Item__r.PLU__r.Id
                                       ,PLU__C
                                       ,Approval_Due_date__c  
                                  from Launch_Item_Approval__c 
                                 where Launch_Item__c IN : activeLaunchItemsIdSet
                                   and Function__c != : ''
                                   and isVisible__c=:false
                                   and StandingDelegationCheck__c = false
                                   ];
          eventType='Initiate';   
       // throw new CustomException('launchItemApprovalList size inside if'+launchItemApprovalList.size());
                                         
        }  
        else
        {
         launchItemApprovalList=[select Id
                                       ,Name
                                       ,isVisible__c
                                       ,Approver__c
                                       ,Approver__r.Name
                                       ,Delegate_Approver__c
                                       ,Delegate_Approver__r.Name
                                       ,Launch_Item__c
                                       ,Launch_Item__r.Product_Manager__c
                                       ,Launch_Item__r.Product_Manager__r.Name
                                       ,Launch_Item__r.Product_Manager__r.Email
                                       ,Launch_Item__r.Name
                                       ,Launch_Item__r.PLU__r.Id
                                       ,PLU__C
                                       ,Approval_Due_date__c
                                       ,PM_Comments__c   
                                  from Launch_Item_Approval__c 
                                 where Launch_Item__c IN : activeLaunchItemsIdSet
                                   and Division__c != : ''
                                   and StandingDelegationCheck__c = false
                                   //and isVisible__c=:false
                                   ];
          eventType='Notify GM';                                   
        }
                                        
       for(Launch_Item_Approval__c lia: launchItemApprovalList)
        {
         lia.isVisible__c=true;
         if(!isFunction)
         {
            lia.PM_Comments__c=this.dataClass.getComments();
         }
        }
        upsert launchItemApprovalList;
        
       // throw new CustomException('launchItemApprovalList size + launchItemUpsertList'+launchItemApprovalList.size()+'-'+launchItemUpsertList.size());
        
        if(launchItemApprovalList!=null && launchItemApprovalList.size()>0)
       {
         sendEmailNotificationMessage(launchItemApprovalList,eventType);
       }
        if(launchItemUpsertList.size()>0 && launchItemApprovalList!=null && launchItemApprovalList.size()>0)
       {
          upsert launchItemUpsertList;
          makeProductManagerFollowApprovals(launchItemUpsertList,launchItemApprovalList);
       }
     }
     /*
      makeVisibleAndNotifyDivisionApprover
      - This method will be called when when Product Operations/PM/Owner of Launch item click on 'Notify Division GM' buttton on Launch Item View page.
      - It will call makeVisibleAndSendEmailNotifiations method which does the rest.
     */
     Webservice static String makeVisibleAndNotifyDivisionApprover(String launchItemId,String comment)
     {
        //throw new CustomException('Inside makeVisibleAndNotifyDivisionApprover Comment : '+comment);
        String result='';
        try
        {
          List<Launch_Item__c> liList=[select Id,Archive__c,Product_Manager__c,PLU__c,isDivisionalApprovalNotificationsSent__c,IsFunctionalApprovalNotificationsSent__c from Launch_Item__C where Id =:launchItemId and Archive__c =:false];
          PLM_LaunchItemApprovalGeneric plmClass=new PLM_LaunchItemApprovalGeneric();
          plmClass.dataClass.setComments(comment);
          plmClass.makeVisibleAndSendEmailNotifiations(liList,false,liList[0].PLU__c);
          result=PLM_Custom_Settings__c.getInstance('LaunchItem#NotifyGMConfirmMsg').value__c;
        }
        catch(Exception e)
        {
            result='An unexpected error occurred while processing your request.\n\nError: '+ e.getMessage();
        }
        
        return result;
     }
     
     /*
      makeProductManagerFollowApprovals
      - This method will make Product Manager follow all launch Approvals of a Launch Item.
      - When Product Operations click on 'Notify Function Representative', it will make Product manager of a launch item follow all related Functional approvals.
      - When Product Manager/Product Operations/Owner click on 'Notify DIvision GM', it will make PM follow Division Approval.  
         
     */
     private void makeProductManagerFollowApprovals(List<Launch_Item__c> liList,List<Launch_Item_Approval__c> liaList)
     {
        List<EntitySubscription> entitySubscriptionList=new List<EntitySubscription>();
        for(Launch_Item__c li: liList)
        {
            List<Launch_Item_Approval__c> launchItemApprovalsList=new List<Launch_Item_Approval__c>();
            for(Launch_Item_Approval__c lia: liaList)
            {
                if(lia.Launch_Item__c==li.Id)
                {
                    launchItemApprovalsList.add(lia);
                }
            }
            for(Launch_Item_Approval__c lia: launchItemApprovalsList)
            {
             EntitySubscription ent=new EntitySubscription(parentId=lia.Id,SubscriberId=li.Product_Manager__c);
             entitySubscriptionList.add(ent);
            }
        }
        Database.SaveResult[] entityInsertResult = Database.Insert(entitySubscriptionList, false);//upsert entitySubscriptionList;
     }
     
     /*
     removeApprovalSubscriptions
     - This method will be called from Launch Item Trigger when Launch Item is getting archived.
     - This method will Make PM unfollow all related Launch Approvals.
      
     */
     public void removeApprovalSubscriptions(List<Launch_Item__c> launchItemList)
     {
      if(launchItemRemoveApprovalSubscriptions)
        {
            Set<Id> subscriberIdSet=new Set<Id>();
            Set<Id> parentIdSet=new Set<Id>();
            for(Launch_Item__c li : launchItemList)
            {
                subscriberIdSet.add(li.Product_Manager__c);
            }
            
            List<Launch_Item_Approval__c> launchItemApprovalList=[select Id from Launch_Item_Approval__c where Launch_Item__c IN : launchItemList];
            
            for(Launch_Item_Approval__c lia: launchItemApprovalList)
            {
                parentIdSet.add(lia.Id);
            }
            
            List<EntitySubscription> entitiesToDelete=[select Id from EntitySubscription where parentId IN : parentIdSet and subscriberId IN :subscriberIdSet];
            if(entitiesToDelete!=null && entitiesToDelete.size()>0)
            {
                delete entitiesToDelete;
            }
            launchItemRemoveApprovalSubscriptions=false;
        }
        
     }
     /*
     checkAndUpdateIfApprovalNotificationsSent
     - This method will be called from PLM_LaunchItemApprovalTrigger when a new Launch Approval Created after Approvals have been initiated.
     - This method make newly created Approvals visible if Launch Approvals already being started.
     */
     public void checkAndUpdateIfApprovalNotificationsSent(List<Launch_Item_Approval__c> launchItemApprovalList)
     {
      Set<Id> pluIdSet=new Set<Id>();
      Set<Id> launchItemIdSet=new Set<Id>();
      
      Map<Id,Boolean> launchItemIdFunctionalNotificationSentMap=new Map<Id,Boolean>();
      Map<Id,Boolean> launchItemIdDivisionalNotificationSentMap=new Map<Id,Boolean>();
      for(Launch_Item_Approval__c lia: launchItemApprovalList)  
      {
            launchItemIdSet.add(lia.Launch_Item__c);
      }
       
      List<Launch_Item__c> launchItemList=[select Id
                                                 ,Name
                                                 ,isDivisionalApprovalNotificationsSent__c
                                                 ,IsFunctionalApprovalNotificationsSent__c
                                            from Launch_Item__c
                                           where Id IN : launchItemIdSet];
      for(Launch_Item__c li: launchItemList)
      {
        launchItemIdFunctionalNotificationSentMap.put(li.Id,li.IsFunctionalApprovalNotificationsSent__c);
        launchItemIdDivisionalNotificationSentMap.put(li.Id,li.isDivisionalApprovalNotificationsSent__c);
      }
      
      for(Launch_Item_Approval__c lia: launchItemApprovalList)  
      {
        Boolean isFunctionalNotificationSent=launchItemIdFunctionalNotificationSentMap.get(lia.Launch_Item__c);
        Boolean isDivisionalNotificationSent=launchItemIdDivisionalNotificationSentMap.get(lia.Launch_Item__c);
        if(isFunctionalNotificationSent!=null && isFunctionalNotificationSent && lia.Function__c!=null)
        {
            lia.isVisible__c=true;
        }
        if(isDivisionalNotificationSent!=null && isDivisionalNotificationSent && lia.Division__c!=null)
        {
            lia.isVisible__c=true;
        }
        
      }                                         
     }
     
     /*
     sendNotificationReminders
     - This methoda will be called from cron Batch Job 'Launch Approval Notification Reminder'.
     - This job runs every day.
     - This job does following:
        -> This will send notification reminders for all pending approvals to respective approvers/delegate approvers.
        -> For Function Representative: 6 days before,1 Day before and i day after PLU Date
        -> For Division GM: 1 Day after PLU Date.
     */
     public String sendNotificationReminders()
     {
      String res='1:';
      
      try
       {
         if(dataClass.getIslaunchItemApprovalEnabled())
         { 
          List<Launch_Item__c> activeLaunchItems=[select Id
                                                        ,Name
                                                    from Launch_Item__c
                                                   where Archive__c =: false];
          if(activeLaunchItems!=null && activeLaunchItems.size()>0)
          {
           List<Launch_Item_Approval__c> pendingLaunchApprovals=[select Id
                                                                       ,Name
                                                                       ,Approval_Due_Date__c
                                                                       ,Approver__c
                                                                       ,Approver__r.Name
                                                                       ,Delegate_Approver__c
                                                                       ,Delegate_Approver__r.Name
                                                                       ,Status__c
                                                                       ,Function__c
                                                                       ,Division__c
                                                                       ,PLU__c
                                                                       ,Launch_Item__r.Product_Manager__c
                                                                       ,Launch_Item__r.Product_Manager__r.Name
                                                                       ,Launch_Item__r.PLU__c
                                                                  from Launch_Item_Approval__c
                                                                 where Launch_Item__c IN : activeLaunchItems
                                                                   and isVisible__c=:true
                                                                   and Status__c =:'pending'
                                                                   and   StandingDelegationCheck__c = false];
           
          Map<Id,String> userIdNameMap=new Map<Id,String>();
           
           
           Map<String,List<Launch_Item_Approval__c>> pluNameLaunchItemApprovalListMap=getPluNameLaunchItemApprovalListMap(pendingLaunchApprovals);
           Set<String> pluNameSet=pluNameLaunchItemApprovalListMap.keySet();
           for(String pluName: pluNameSet)
           { 
               List<Launch_Item_Approval__c> pendingPLULaunchApprovals=pluNameLaunchItemApprovalListMap.get(pluName);
              
               String res1='';
               String res2='';
               List<Launch_Item_Approval__c> pendingLIAListOneDayBefore=new List<Launch_Item_Approval__c>();
               List<Launch_Item_Approval__c> pendingLIAListOneDayAfter=new List<Launch_Item_Approval__c>();
               for(Launch_Item_Approval__c lia: pendingPLULaunchApprovals)
               {
                 if(pluName==lia.PLU__c)
                   {
                    if(Date.today().addDays(6)== lia.Approval_Due_Date__c && lia.Function__c!=null)
                    {
                       
                    }
                    else if(Date.today().addDays(1)== lia.Approval_Due_Date__c && lia.Function__c!=null)
                    {
                       pendingLIAListOneDayBefore.add(lia);
                       
                    }
                    else if(Date.today().addDays(-1)== lia.Approval_Due_Date__c )
                    {
                       pendingLIAListOneDayAfter.add(lia);
                        
                    }
                    
                  }
               }
               if(pendingLIAListOneDayBefore.size()>0)
               {
                res1=sendEmailNotificationMessage(pendingLIAListOneDayBefore, 'Reminder 1 Day before');
               }
               
               if(pendingLIAListOneDayAfter.size()>0)
               {
                res2=sendEmailNotificationMessage(pendingLIAListOneDayAfter, 'Reminder 1 Day before');
               }
               
          res=res+res1+res2;
          }
           
         }
         else
         {
            res=res+'There are no active launch Items to process';
         } 
        }
        else
        {
            res=res+dataClass.getFeatureDisabledMessage();
        }                                                             
       }
       catch (Exception e)
       {
           res='0#'+e.getMessage();
       }
                                                            
     return res;
     }
     
     private String sendEmailNotificationMessage(List<Launch_Item_Approval__c> launchItemApprovalList, String eventType)
     {
        String response='';
        String message='';
        String subject='';
        String prodOpsEmailId=getPLMCustomSettingValue('LaunchItemAprvlCls#replyTo');
        Set<Id> userIdSet=new Set<Id>();
        Set<Id> pmUserIdSet=new Set<Id>();
        Map<Id,String> userIdNameMap=new Map<Id,String>();
        String pluName=null;
        Date pluDate=null;
        String pluId=null;
        String pmName=null;
        String liName=null;
        //String sfHostName=PLM_LaunchItemApprovalDataClass.getSfHostName();
        Map<Id,String> userIdFunctionDivisionMap=new Map<Id,String>();
        Map<Id,List<String>> userIdPMEmailAddressListMap=new Map<Id,List<String>>();
        if(eventType != null)
        {
            for(Launch_Item_Approval__c lia: launchItemApprovalList)
            {
             if(lia.Approver__c!=null)
             {
               userIdSet.add(lia.Approver__c);
               userIdNamemap.put(lia.Approver__c,lia.Approver__r.Name);
             }
             if(lia.Delegate_Approver__c!=null)
             {  userIdSet.add(lia.Delegate_Approver__c);
                userIdNamemap.put(lia.Delegate_Approver__c,lia.Delegate_Approver__r.Name); 
             }
             if(lia.Launch_Item__r.Product_Manager__c!=null)
             { if(eventType.equals('Initiate')|| eventType.equals('Reminder 1 Day before')|| eventType.equals('Reminder 1 Day after'))
                {
                userIdSet.add(lia.Launch_Item__r.Product_Manager__c);
                userIdNamemap.put(lia.Launch_Item__r.Product_Manager__c,lia.Launch_Item__r.Product_Manager__r.Name);
                pmUserIdSet.add(lia.Launch_Item__r.Product_Manager__c); 
                }
              }
             pluName=lia.PLU__c;
             pluId=lia.Launch_Item__r.PLU__c;
             pluDate=lia.Approval_Due_Date__c;
             if(eventType.equals('Notify GM'))
             {
                liName=lia.Launch_Item__r.Name;
                pmName=lia.Launch_Item__r.Product_Manager__r.Name;
             }
            }
        List<Messaging.SingleEmailMessage> emailMessageList=new List<Messaging.SingleEmailMessage>();
        
          String htmlMessage='';
          if(eventType.equals('Initiate'))
           {
            message=getMessageForEvent(eventType,pluName,pluDate,null,null);
            subject=pluName+ ' Launch Approvals';
            Messaging.SingleEmailMessage pOpsMessage=new Messaging.SingleEmailMessage();
            htmlMessage=message+'<br></br>Please <a href='+sfHostName+getPLMCustomSettingValue('LaunchItemAprvlCls#OPSView')+pluId+'>click here</a> to view the '+pluName+' launch</p>';
            pOpsMessage.setToAddresses(new String[]{prodOpsEmailId});
            pOpsMessage.setHtmlBody(htmlMessage);
            pOpsMessage.setSubject(subject);
            pOpsMessage.setUseSignature(false);
            pOpsMessage.setSaveAsActivity(false);
            pOpsMessage.setReplyTo(prodOpsEmailId);
            emailMessageList.add(pOpsMessage);
           }
           else if(eventType.equals('Notify GM'))
           {
            message=getMessageForEvent(eventType,pluName,pluDate,pmName,liName);
            subject='Requesting Launch Approval';
            userIdPMEmailAddressListMap=getUserIdPMEmailAddressListMap(launchItemApprovalList,eventType);
           }
           else if(eventType.equals('Reminder 1 Day before') || eventType.equals('Reminder 1 Day after'))
           {
            subject='REMINDER: '+pluName+' Launch Approvals';
            message=getMessageForEvent('Reminder',pluName,pluDate,pmName,liName);
            if(eventType.equals('Reminder 1 Day before'))
            {
                subject=subject+' due tomorrow.';
                message='<p style="font-family:Tahoma;font-size:13Px;">Just a reminder that launch approvals for '+pluName+' are due tomorrow.<br></br><br></br>'+message;
            }
            else
            {
                subject=subject+' were due yesterday.';
                message='<p style="font-family:Tahoma;font-size:13Px;">Just a reminder that launch approvals for '+pluName+' were due yesterday.<br></br><br></br>'+message;
            }
           }
          Integer totalEmailCount= userIdSet.size();
          response='Total Email Count: '+totalEmailCount+' Email Sent to Ids: ';
         for(Id userId: userIdSet)
         {
            Messaging.SingleEmailMessage eMessage=new Messaging.SingleEmailMessage();
            List<String> emailCCList=null;
            response=response+ userId+ ', ';
           if(eventType.equals('Initiate'))
            {
              if(pmUserIdSet!=null && pmUserIdSet.contains(userId))
              {              
               htmlMessage=message+'<br></br>Please <a href='+sfHostName+getPLMCustomSettingValue('LaunchItemAprvlCls#PMViewId')+'>click here</a> to view the launch item approvals for the '+pluName+' launch</p>';
              }
              else
              {
                htmlMessage=message+'<br></br>Please <a href='+sfHostName+getPLMCustomSettingValue('LaunchItemAprvlCls#MyViewId')+'>click here</a> to view all the launch item ratings for the '+pluName+' launch</p>';
              }
            }
            else if(eventType.equals('Notify GM'))
            {
                String message1='<p style="font-family:Tahoma;font-size:13Px;">Hello '+userIdNamemap.get(userId);
                /*if(eventType.equals('Approver Changed'))
                {
                    message1=message1+'<br></br><br></br>You have been assigned pass/fail responsibility for the '+userIdFunctionDivisionMap.get(userId);
                }*/
                htmlMessage=message1+message;
            }
            else 
            {
                htmlMessage=message;
            }
            
            eMessage.setTargetObjectId(userId);
            if(eventType.equals('Notify GM'))
            {
                emailCCList=userIdPMEmailAddressListMap.get(userId);
                if(emailCCList!=null & emailCCList.size()>0)
                {
                 eMessage.setCcAddresses(emailCCList);
                }
            }
            
            eMessage.setHtmlBody(htmlMessage);
            eMessage.setSubject(subject);
            eMessage.setUseSignature(false);
            eMessage.setSaveAsActivity(false);
            eMessage.setReplyTo(prodOpsEmailId);
            emailMessageList.add(eMessage);
         }
        if(emailMessageList.size()>0)
        Messaging.sendEmail(emailMessageList);
        
      }
        return response;
     }
     
     private Map<Id,List<String>> getUserIdPMEmailAddressListMap(List<Launch_Item_Approval__c> liaList,String eventType)
     {
        Map<Id,List<String>> userIdPMEmailAddressListMap=new Map<Id,List<String>>();
        Set<Id> userIdset=new Set<Id>();
        for(Launch_Item_Approval__c lia : liaList)
        {
            if(lia.Approver__c!=null && !eventType.equals('Delegate'))
            {
                userIdSet.add(lia.Approver__c);                 
            }
            if(lia.Delegate_Approver__c!=null && !eventType.equals('Approver Changed'))
            {
                userIdSet.add(lia.Delegate_Approver__c);                
            }
        }
        for(Id userId: userIdSet)
        {
           List<String> emailAddressList=new List<String>();
           for(Launch_Item_Approval__c lia : liaList)
           {
            if(!eventType.equals('Delegate'))
            {
                if(userId==lia.Approver__c )
                {
                    emailAddressList.add(lia.Launch_Item__r.Product_Manager__r.Email);
                }
            }
            else if(!eventType.equals('Approver Changed'))
            {
                if(userId==lia.Delegate_Approver__c)
                {
                    emailAddressList.add(lia.Launch_Item__r.Product_Manager__r.Email);
                }
            }
           }
           userIdPMEmailAddressListMap.put(userId,emailAddressList);
        }
        return userIdPMEmailAddressListMap;
     }
  
     /*
     getPluNameLaunchItemApprovalListMap
     - This method is called internally by another methods of this class
     - This takes launch Item Approvals List and returns a map of PLU name and Launch Item Approvals
     */
     private Map<String,List<Launch_Item_Approval__c>> getPluNameLaunchItemApprovalListMap(List<Launch_Item_Approval__c> launchItemApprovalList)
     {
        Set<String> pluNameSet=new Set<String>();
        Map<String,List<Launch_Item_Approval__c>> pluNameLaunchItemApprovalListMap=new Map<String,List<Launch_Item_Approval__c>>();
        for(Launch_Item_Approval__c lia: launchItemApprovalList)
        {
            pluNameSet.add(lia.Plu__c);
        }
        for(String pluName : pluNameSet)
        {
            List<Launch_Item_Approval__c> tempLaunchItemApprovalList=new List<Launch_Item_Approval__c>();
            for(Launch_Item_Approval__c lia: launchItemApprovalList)
            {
                if(lia.PLU__c==pluName)
                {
                    tempLaunchItemApprovalList.add(lia);
                }
            }
            pluNameLaunchItemApprovalListMap.put(pluName,tempLaunchItemApprovalList);
        }
        return pluNameLaunchItemApprovalListMap;
     }
     
     /*
     sendEmailNotificationToNewApprover
     - This method is called from PLM_LaunchItemApprovalTrigger.
     - This will send email to new approver or delegated approver
     */
     public void sendEmailNotificationToNewApprover(List<Launch_Item_Approval__c> launchItemApprovalList,Boolean isReassigned)
     {Set<Id> launchItemApprovalIdSet=new Set<Id>();
        for(Launch_Item_Approval__c lia: launchItemApprovalList)
            {
              launchItemApprovalIdSet.add(lia.Id);
            }
         List<Launch_Item_Approval__c> liaList=[select Id
                                               ,Name
                                               ,isVisible__c
                                               ,Approver__c
                                               ,Approver__r.Name
                                               ,Delegate_Approver__c
                                               ,Delegate_Approver__r.Name
                                               ,Approval_Due_Date__c
                                               ,Function__c
                                               ,Launch_Item__c
                                               ,PLU__c
                                               ,Launch_Item__r.Product_Manager__c
                                               ,Launch_Item__r.Product_Manager__r.Name
                                               ,Launch_Item__r.PLU__c
                                               ,Launch_Item__r.Product_Manager__r.Email  
                                          from Launch_Item_Approval__c 
                                         where Id IN : launchItemApprovalIdSet
                                         and   StandingDelegationCheck__c = false];
        Map<String,List<Launch_Item_Approval__c>> pluNameLaunchItemApprovalListMap=getPluNameLaunchItemApprovalListMap(liaList); 
        Set<String> pluNameSet=pluNameLaunchItemApprovalListMap.keySet();                                           
        List<Messaging.SingleEmailMessage> emailMessageList=new List<Messaging.SingleEmailMessage>();
        for(String pluName: pluNameSet)
        {
            List<Launch_Item_Approval__c> approvalList=pluNameLaunchItemApprovalListMap.get(pluName);
            List<Messaging.SingleEmailMessage> pluEmailMessageList=null;
            if(isReassigned)
            {
             pluEmailMessageList=createEmailMessageListForNewApprover(approvalList,'Delegate',pluName);
            }
            else
            {
             pluEmailMessageList=createEmailMessageListForNewApprover(approvalList,'Approver Changed',pluName); 
            }
          if(pluEmailMessageList!= null && pluEmailMessageList.size()>0)
          {
            for(Messaging.SingleEmailMessage emsg: pluEmailMessageList )
            {
                emailMessageList.add(emsg);
            }
          } 
        }
       if(emailMessageList.size()>0)
       {
        Messaging.sendEmail(emailMessageList);
       }
      }
  private List<Messaging.SingleEmailMessage> createEmailMessageListForNewApprover(List<Launch_Item_Approval__c> launchApprovalList,String eventType,String pluName)
   {
    List<Messaging.SingleEmailMessage> pluMessageList=new List<Messaging.SingleEmailMessage>();
    Set<Id> delegatedUserIdSet=new Set<Id>();
    Set<Id> approverChangedUserIdSet=null;
    Map<Id,List<String>> userIdEmailCCListMap=null;
    Map<Id,String> userIdNameMap=new Map<Id,String>();
    String message=getMessageForEvent(eventType,pluName,null,null,null);
    String subject='';
    if(eventType.equals('Delegate'))
    {
        subject='Launch rating delegated to you';
        userIdEmailCCListMap=getUserIdPMEmailAddressListMap(launchApprovalList,eventType);
        for(Launch_Item_Approval__c lia : launchApprovalList)
       {
        if(eventType.equals('Delegate'))
        {
            if(lia.Delegate_Approver__c!=null && !delegatedUserIdSet.contains(lia.Delegate_Approver__c))
            {
             delegatedUserIdSet.add(lia.Delegate_Approver__c);
             userIdNameMap.put(lia.Delegate_Approver__c,lia.Delegate_Approver__r.Name);
            }
        }
       }
      for(Id userId : delegatedUserIdSet)
     {
        Set<String> emailCCAdderessSet=new Set<String>();
        emailCCAdderessSet.addAll(userIdEmailCCListMap.get(userId));
        List<String> emailAddressCCList=new List<String>();
        emailAddressCCList.addAll(emailCCAdderessSet);
        Messaging.SingleEmailMessage singleMsg=new Messaging.SingleEmailMessage();
        String message1='<p style="font-family:Tahoma;font-size:13Px;">Hello '+userIdNameMap.get(userId);
        String htmlMessage=message1+message;
        singleMsg.setTargetObjectId(userId);
        singleMsg.setHtmlBody(htmlMessage);
        singleMsg.setCcAddresses(emailAddressCCList);
        singleMsg.setSubject(subject);
        singleMsg.setUseSignature(false);
        singleMsg.setSaveAsActivity(false);
        //singleMsg.setReplyTo(prodOpsEmailId);
        pluMessageList.add(singleMsg);
     } 
    }
    else if(eventType.equals('Approver Changed'))
    {
        subject='PLM role assignment';
        Map<String,List<Launch_Item_Approval__c>> functionDivisionLaunchApprovalListMap=getFunctionDivisionNameLaunchApprovalsMap(launchApprovalList);
        Set<String> functionDivisionSet=functionDivisionLaunchApprovalListMap.keySet();
        for(String functionDivisionName : functionDivisionSet)
       {
        List<Launch_Item_Approval__c> approvalList=functionDivisionLaunchApprovalListMap.get(functionDivisionName);
        approverChangedUserIdSet=new Set<Id>();
        userIdEmailCCListMap=getUserIdPMEmailAddressListMap(launchApprovalList,eventType);
        for(Launch_Item_Approval__c lia: approvalList)
        {
            if(lia.Approver__c!=null)
            {
             approverChangedUserIdSet.add(lia.Approver__c);
             userIdNameMap.put(lia.Approver__c,lia.Approver__r.Name);
            }
        }
        for(Id approverId: approverChangedUserIdSet)
        {
          Messaging.SingleEmailMessage singleMsg=new Messaging.SingleEmailMessage();
          String message1='<p style="font-family:Tahoma;font-size:13Px;">Hello '+userIdNameMap.get(approverId);
          message1=message1+'<br></br><br></br>You have been assigned pass/fail responsibility for the '+functionDivisionName;
          String htmlMessage=message1+message;
          singleMsg.setTargetObjectId(approverId);
          singleMsg.setHtmlBody(htmlMessage);
          singleMsg.setCcAddresses(userIdEmailCCListMap.get(approverId));
          singleMsg.setSubject(subject);
          singleMsg.setUseSignature(false);
          singleMsg.setSaveAsActivity(false);
            //singleMsg.setReplyTo(prodOpsEmailId);
          pluMessageList.add(singleMsg);
        }
       } 
     }
    
    return pluMessageList;
   }
   private Map<String, List<Launch_Item_Approval__c>> getFunctionDivisionNameLaunchApprovalsMap(List<Launch_Item_Approval__c> launchApprovalList)
   {
    Map<String, List<Launch_Item_Approval__c>> temMap=new Map<String, List<Launch_Item_Approval__c>>();
    Set<String> liaNameSet=new Set<String>();
    for(Launch_Item_Approval__c lia: launchApprovalList)
    {
        liaNameSet.add(lia.Name);
    }
    for(String name: liaNameSet)
    {
      List<Launch_Item_Approval__c> launchApprovalListForSingleFunctionDivision=new List<Launch_Item_Approval__c>();
      for(Launch_Item_Approval__c lia: launchApprovalList)
        {
         if(lia.Name==name)
         {
            launchApprovalListForSingleFunctionDivision.add(lia);
         }
        }
      temMap.put(name,launchApprovalListForSingleFunctionDivision);  
    }
    return temMap;
   }
    /*
     getMessage
     - This method is used internally by methods of this class
     - This method returns Email message body.
   */
     private String getMessageForEvent(String eventType,String pluName,Date pluDate,String pmName,String liName)
     {
        String message='';
        String myLaunchApprovalsViewLink=getPLMCustomSettingValue('LaunchItemAprvlCls#MyViewId');
        //String sfHostName=PLM_LaunchItemApprovalDataClass.getSfHostname();
        if(eventType!=null)
        {
          if(eventType.equals('Initiate'))
          { 
            //throw new CustomException('PluName: ' + pluName+ ' PluDate : '+pluDate);
            System.debug('PLUDate: '+pluDate + 'pluName : '+pluName);
            message='<p style="font-family:Tahoma;font-size:13Px;">Product Managers and Business Function Representatives –<br></br><br></br>The due date for the '+pluName
                           +' launch approvals is '+pluDate.format() //Product Managers - please post links to your launch slide decks to your respective launch items on the Product Lifecycle'
                           +'<br></br><br></br>Key Points<br></br><br></br>' //Management (PLM) Tracking tool so they are available during the launch approval process next week.
                           +'•       Product Managers are responsible for ensuring that launch ratings are recorded by '+pluDate.format()+'<br></br><br></br>'
                           +'•       Business Function are responsible for providing Pass/Fail ratings<br></br><br></br>'
                           +'•       General Managers/delegates will be contacted when their products are ready for launch approval.<br></br><br></br>'
                           +'If you have questions or concerns, please contact the Product Operations team at props@akamai.com, or your division’s operations lead for support.<br></br>';
          }
          else if(eventType.equals('Notify GM'))
          {
            message=',<br></br>'+pmName+' is requesting your launch approval for '+liName +' which is part of the '+pluName+' launch cycle.<br></br><br></br>'
                        +'Please <a href='+sfHostName+myLaunchApprovalsViewLink+'>click here</a> to view the details of this launch and to record your approval or rejection in the Product Lifecycle Management Tool.<br></br><br></br>';
            if(this.dataClass.getComments()!=null && !((this.dataClass.getComments()).equals('')))
            {
             message=message+'Note : PM Comments - '+this.dataClass.getComments()+'<br></br><br></br>';
            }
            message=message+'In case of any questions, please contact '+ pmName+' or the Product Operations team at props@akamai.com.'
                        +'<br></br><br></br>Thanks<br></br>Product Operations Team</p>';        
          }
          else if(eventType.equals('Delegate'))
          {
            message=',<br></br>A launch rating has been delegated to you by '+UserInfo.getName()+'.<br></br>Please <a href='+sfHostName+myLaunchApprovalsViewLink+'>click here</a> to view all the approvals for '
                    +pluName+' launch.<br></br><br></br>In case of any questions, please contact the Product Operations team at props@akamai.com.<br></br><br></br>Regards<br></br>Product Operations Team<p>';
          }
          else if(eventType.equals('Reminder'))
          {
            message='Business Function representatives - Please enter your ratings and comments on the Product Lifecycle Management (PLM) Tracking tool as soon as possible if you have not already done so.<br></br><br></br>'
                    +'Product Managers - Please be sure that prior to requesting launch approval from the General Manager/delegate, you have done the following:<br></br><br></br>'
                    +'1)          Ensured that all launch ratings have been provided by the Business Functions<br></br><br></br>'
                    +'2)          Provided advanced notice to the General Manager/delegate about your upcoming launch approval request, along with all of the necessary project detail to make aninformed approval decision<br></br><br></br>'
                    +'If you have questions or concerns, please contact the Product Operations team at props@akamai.com, or your division’s operations lead for support.</p>';
          }
          else if(eventType.equals('Approver Changed'))
          {
            message=' for the '+pluName+' launch by '+UserInfo.getName()+'.<br></br><br></br>In case of any questions, please contact the Product Operations team at props@akamai.com.';
          }
        }
        return message; 
     }
     
   /*
    addDefaultLaunchApprovalTeam
     - This method is called from PLM_Launch_Item_trigger
     - This method adds default launch Team to launch Item when it is created.
    */
     public void addDefaultLaunchApprovalTeam(List<Launch_Item__c> launchItemList)
     {  
        Set<String> LIdivSet = new Set<String>();
        for(Launch_Item__c li : launchItemList)
        {
            if(LIdivSet.contains(li.Division__c)==false)
               LIdivSet.add(li.Division__c);
        } 
        if(launchItemInsertFirstRunFlag)
        {
            List<Launch_Item_Approval__c> globalLaunchTeam=[select Id
                                                                 ,Name
                                                                 ,Function__c
                                                                 ,Division__c
                                                                 ,Approver__c
                                                            from Launch_Item_Approval__c
                                                           where Global_Setting_Id__c =:''
                                                             and StandingDelegationCheck__c = false
                                                             and Launch_Item__c =:''];
            List<Launch_Item_Approval__c> standingDelegationLaunchTeam=[select Id
                                                                 ,Name
                                                                 ,Function__c
                                                                 ,Division__c
                                                                 ,Approver__c
                                                                 ,Delegate_Approver__c
                                                            from Launch_Item_Approval__c
                                                           where Global_Setting_Id__c =:''
                                                             and StandingDelegationCheck__c = true
                                                             and Launch_Item__c =:''
                                                             and Division__c IN :LIdivSet];
            List<Launch_Item_Approval__c> launchItemTeamList=new List<Launch_Item_Approval__c>();
            Set<Id> launchItemIdSet= new Set<Id>();
            Map<String,Map<String,String>> funcToDelegateMap = divisionMapMethod(standingDelegationLaunchTeam);
           
           if(globalLaunchTeam!=null && globalLaunchTeam.size()>0)
            {
                for(Launch_Item__c li: launchItemList)
                {
                    for(Launch_Item_Approval__c lia: globalLaunchTeam)
                    {
                        Launch_Item_Approval__c liaNew=new Launch_Item_Approval__c();
                        liaNew.Approver__c=lia.Approver__c;
                        liaNew.Global_Setting_Id__c=lia.id;
                        liaNew.Launch_Item__c=li.id;
                        
                        if(lia.Function__c!=null && lia.Division__c==null)
                        {
                            liaNew.Function__c=lia.Function__c;
                            liaNew.Delegate_Approver__c = funcToDelegateMap.get(li.Division__c).get(lia.Function__c);
                            if(li.IsFunctionalApprovalNotificationsSent__c)
                            {
                                liaNew.isVisible__c=true;
                            }
                            
                            launchItemTeamList.add(liaNew);
                        }
                        else if(lia.Division__c != null && lia.Division__c==li.Division__c)
                        {
                            liaNew.Division__c=lia.Division__c;
                            if(li.isDivisionalApprovalNotificationsSent__c)
                           {
                            liaNew.isVisible__c=true;
                           }
                            launchItemTeamList.add(liaNew);
                        }
                        
                    }
                    
                }
            }
            
            if(launchItemTeamList.size()>0)
            {
                upsert launchItemTeamList;
            } 
           launchItemInsertFirstRunFlag=false;
        }
                                                                 
     }  
     
     /*
     updateExistingDivisionalApprovals
      - This method is called from PLM_Launch_Item_Trigger when Division of a Launch Item is changed.
      - This method will delete any existing Division approval and create a new Division approval according to global launch team.
     */
     public void updateExistingDivisionalApprovals(List<Launch_Item__c> launchItemList)
     {
        Set<String> divisionSet=new Set<String>();
        Set<Id> launchItemIdSet=new Set<Id>();
        
        for(Launch_Item__c li: launchItemList)
        {
            divisionSet.add(li.Division__c);
            launchItemIdSet.add(li.Id);
        }
        
       List<Launch_Item_Approval__c> launchItemApprovalListToUpsert=new List<Launch_Item_Approval__c>();
        
        List<Launch_Item_Approval__c> launchItemApprovalListToDelete=[select Id
                                                                            ,Name
                                                                            ,Division__c
                                                                        from Launch_Item_Approval__c
                                                                       where Launch_Item__c IN : launchItemIdSet
                                                                         and Division__c != :''];
        if(launchItemApprovalListToDelete!=null && launchItemApprovalListToDelete.size()>0)
        {
         delete launchItemApprovalListToDelete;
        }
        
        List<Launch_Item_Approval__c> globalLaunchItemApprovalList=[select Id
                                                                          ,Name
                                                                          ,Division__c
                                                                          ,Approver__c
                                                                      from Launch_Item_Approval__c
                                                                      where Global_Setting_Id__c =null
                                                                      and Launch_Item__c = :''
                                                                      and StandingDelegationCheck__c= false] ;
        
        if(globalLaunchItemApprovalList!=null && globalLaunchItemApprovalList.size()>0)
        {
            for(Launch_Item__c li: launchItemList)
            {
             Launch_Item_Approval__c liaNew=new Launch_Item_Approval__c();
             for(Launch_Item_Approval__c lia: globalLaunchItemApprovalList)
              {
                if(lia.Division__c==li.Division__c)
                {
                    liaNew.Division__c=lia.Division__c;
                    liaNew.Name=lia.Division__c;
                    liaNew.Approver__c=lia.Approver__c;
                    liaNew.Global_Setting_Id__c=lia.id;
                    liaNew.Launch_Item__c=li.id;
                    if(li.isDivisionalApprovalNotificationsSent__c)
                     {
                       liaNew.isVisible__c=true;
                     }
                    launchItemApprovalListToUpsert.add(liaNew);
                }
              }
            }
        }    
        
        if(launchItemApprovalListToUpsert.size()>0)
        {
            upsert launchItemApprovalListToUpsert;
        }                                                                                                                                
        
     }  
     
     /*
     updateLaunchItemStatus
      - This method is called from PLM_LaunchItemApprovalTrigger when Division approval is approved.
      - This method will change staus of launch Item to 'PLU - Approved' when division GM approves it.
     */
     public void updateLaunchItemStatus(List<Launch_Item_Approval__c> launchApprovalList,Boolean isApproved)
     {
        Set<Id> launchItemIds=new Set<Id> ();
        
        for(Launch_Item_Approval__c lia: launchApprovalList)
        {
            launchItemIds.add(lia.Launch_Item__c);
        }
        
        List<Launch_Item__c> launchItemList=[select Id
                                                  , Phase_Status__c
                                                  , Activity_Status__c 
                                             from Launch_Item__c 
                                             where Id IN : launchItemIds];
        if(launchItemList!=null && launchItemList.size()>0)
        {
            for(Launch_Item__c li: launchItemList)
            {
                li.Phase_Status__c='Launch Tracking';
                if(isApproved)
                li.Activity_Status__c='PLU - Approved';
                else
                li.Activity_Status__c='PLU - Rejected';
            }
            update launchItemList;
        }                                            
     }
    public Id getRecordTypeId(String recordTypeName)
    {
        List<Schema.RecordTypeInfo> RecordTypeList=Schema.Sobjecttype.Launch_Item__c.getRecordTypeInfos();
        Id recordTypeId=null;
        for(Schema.RecordTypeInfo r: RecordTypeList)
        {
            if(r.getName()==recordTypeName)
            {
                recordTypeId=r.getRecordTypeId();
            }
        }
        return recordTypeId;
    }
    //Hitesh-added to set the record type for archived PLU
    public Id getRecordTypeIdPLU(String recordTypeName)
    {
        List<Schema.RecordTypeInfo> RecordTypeList=Schema.Sobjecttype.PLU__c.getRecordTypeInfos();
        Id recordTypeId=null;
        for(Schema.RecordTypeInfo r: RecordTypeList)
        {
            if(r.getName()==recordTypeName)
            {
                recordTypeId=r.getRecordTypeId();
            }
        }
        return recordTypeId;
    }
 // Below methods are commented because of add and remove buttons and all checkboxes and action column has been removed from page.
    /*
     checkIsDeleted()
      - Will be called internally from other methods when user clicks on save button.
      - Will check if user has deleted any existing Record.
    * /

    public PageReference checkIsDeleted()
    {
     / *if(isApplyToExisting)
     {
        for(PLM_LaunchItemApprovalWrapperClass litmC: launchTeamFunctionalDivisionalList)
         {
          if(litmc.isDeleted)
          {
           showWarning=true;
           break;
          }
         }
       }
     if(!(showWarning))
     {
       save();
     }* /
     return null;
    }
     / *
      identifyLaunchTeamMemberIndex()
      - Will be called internally by other methods while initializing PLM_LaunchItemApprovalWrapperClass object.
    
    private Integer identifyLaunchTeamMemberIndex(List<PLM_LaunchItemApprovalWrapperClass> memberList)
    {
      Integer maxIndex=0;
      if(memberList.size()==0)
      {
       return maxIndex;
      }
      else
      {
       maxIndex= memberList[memberList.size()-1].index + 1;
      }
      return maxIndex;
    }*/
     
     /*
      selectAll()
      - Will be called when user clicks on chaeckbox at header of each table.
      - It check and uncheck all checkbox for all rows of each table.
    * /
     public PageReference selectAll() 
     {
        
        String category=ApexPages.currentPage().getParameters().get('category');
        Boolean isAllSelected=false;
        List<PLM_LaunchItemApprovalWrapperClass> tempList=null;
        if(category.equals('Function'))
        {
         tempList=launchTeamFunctionalMemberList;
         isAllSelected=IsAllFunctionsSelected ;
        }
        else if(category.equals('Division'))
        {
         tempList=launchTeamDivisionalMemberList;
         isAllSelected=IsAllDivisionsSelected; 
        }
        if(tempList!=null && tempList.size()>0)
        {
          for(PLM_LaunchItemApprovalWrapperClass ltm: tempList)
          {
           if(!ltm.isChecked && isAllSelected)
            {
             ltm.isChecked=true;
            }
           else if(!isAllSelected && ltm.isChecked)
            {
            ltm.isChecked=false;
            }
          }
        }
    * /
      
       return null;
    }

    /*
      addMemberRow()
      - Will be called when user clicks on 'Add Function' or 'Add Division' buttons when page in edit mode.
      - When 'Add Function' is clicked it will add another row to function table.
      - When 'Add Division' is clicked it will add another row to division table.
    * /
    public PageReference addMemberRow() 
    {
       / * String category=ApexPages.currentPage().getParameters().get('category');
        Integer index=0;
        Launch_Item_Approval__c teamMember=new Launch_Item_Approval__c();
        if(launchItemId!=null && !launchItemId.equals(''))
        {
          teamMember.Launch_Item__c=launchItemId;
        }
        if(category.equals('Function'))
        {
            index=identifyLaunchTeamMemberIndex(launchTeamFunctionalMemberList);            
            PLM_LaunchItemApprovalWrapperClass teamMemberClass=new PLM_LaunchItemApprovalWrapperClass(teamMember,false,false,false,index,null);
            launchTeamFunctionalMemberList.add(teamMemberClass);
            launchTeamFunctionalDivisionalList.add(teamMemberClass);
        }
        else if(category.equals('Division'))
        {
            index=identifyLaunchTeamMemberIndex(launchTeamDivisionalMemberList);
            PLM_LaunchItemApprovalWrapperClass teamMemberClass=new PLM_LaunchItemApprovalWrapperClass(teamMember,false,false,false,index,null);
            launchTeamDivisionalMemberList.add(teamMemberClass);
            launchTeamFunctionalDivisionalList.add(teamMemberClass);
        }
        return null;
    }*/
    
      /*
      removeMemberRow()
      - Will be called when user clicks on 'Remove Function' or 'Remove Division'.
      - It will mark that record for deletion if record is already existing.
    * /
    public PageReference removeMemberRow() 
    {
        / *String category=ApexPages.currentPage().getParameters().get('category');
        String index=ApexPages.currentPage().getParameters().get('index');
        //System.debug('++++++++++++++++++++++Category+++++++++++++++++'+category);
        List<PLM_LaunchItemApprovalWrapperClass> tempList=new List<PLM_LaunchItemApprovalWrapperClass>();
        if(index!=null && !index.equals(''))
        {
           if(category!=null && !category.equals('') && category.equals('Function'))
           {
            for(PLM_LaunchItemApprovalWrapperClass litmClass: launchTeamFunctionalMemberList)
            {
             if(litmClass.index==Integer.valueOf(index))
             {
              //if(litmClass.isExisting)
              //{
               litmClass.isDeleted=true;
              //}
             }
             else
             {
              tempList.add(litmClass);
             }
            }
            launchTeamFunctionalMemberList=tempList;
           }
           else if(category!=null && !category.equals('') && category.equals('Division'))
           {
            for(PLM_LaunchItemApprovalWrapperClass litmClass: launchTeamDivisionalMemberList)
            {
             if(litmClass.index==Integer.valueOf(index))
             {
              //if(litmClass.isExisting)
              //{
               litmClass.isDeleted=true;
              //}
             }
             else
             {
              tempList.add(litmClass);
             }
            }
            launchTeamDivisionalMemberList=tempList;
           }
        }
       else
       {
        if(category!=null && !category.equals('') && category.equals('Function'))
            {
             for( PLM_LaunchItemApprovalWrapperClass litmClass: launchTeamFunctionalMemberList)
             {
              if(!litmClass.isChecked)
              {
               tempList.add(litmClass);
              }
              else
              {
               //if(litmClass.isExisting)
                //{
                 litmClass.isDeleted=true;
                //}
              }
             }
             launchTeamFunctionalMemberList=tempList;
            }
            else if (category!=null && !category.equals('') && category.equals('Division'))
            {
             for( PLM_LaunchItemApprovalWrapperClass litmClass: launchTeamDivisionalMemberList)
             {
              if(!litmClass.isChecked)
              {
               tempList.add(litmClass);
              }
              else
              {
               //if(litmClass.isExisting)
                //{
                 litmClass.isDeleted=true;
                //}
              }
             }
             launchTeamDivisionalMemberList=tempList;
            }
       }
        return null;
    }*/
    public without sharing class GetOrganizationDetails
    {
    	public String getOrganizationDivision()
    	{
    		return [select Division from Organization][0].Division;
    	}
    }
}