/***
    PLM_PLUViewController
    @author : Chandra Lohani(clohani@akamai.com)
    @Description : This class is used as controller for following two Visualforce pages:
                   PLM_PLUHomePage
                   PLM_PLUViewPage
   
    @History
    --Developer             --Date          --Change
    Chandra Mohan Lohani   04-10-2011       Created the class.
    Hitesh Chawda          08-03-2012       CR 1559830 "Initiate Launch Approvals" button functionality                                                                                                                                                                       
                                                                                           
*/
public class PLM_PLUViewController {
    //public boolean isFirstRedirect=true;
    public String pluTabId{get;set;}
    public String pluId{get;set;}
    public String backToListLink{get;set;}
    public Integer pageSize{get;set;}
    public Integer pageSizeArchive{get;set;}
    public Integer launchItemCount{get;set;}
    public Boolean isArchivedVisible{get;set;}
    
    //public Integer initiateLaunchItemcount{get;set;}
    
    //public List<PLU__c> defaultPLUList=null;
    List<PLU__c> paginatedPLUList{get;set;}
    List<PLU__c> paginatedArchivedPLUList{get;set;}
  
    List<PLU__c> activePLUList{get;set;}
   
    
    public String pluPageSize{get;set;}
    public String archivedPluPageSize{get;set;}
  
    public List<SelectOption> defaultActivePageSizeOptionsList=null;
    public List<SelectOption> defaultArchivePageSizeOptionsList=null;
  
    public String defaultPLUPageSize{get;set;}
    public String defaultArchivedPLUPageSize{get;set;}
    public Boolean isCreateNewButtonVisible{get;set;}
    public List<Launch_Item__c> launchItemList{get;set;}
    public List<Launch_Item__c> PLUlaunchItemList{get;set;}
    public String confirmationMessage{get;set;}
    public Boolean isNotificationsSent{get;set;}
    public Boolean islaunchItemApprovalEnabled{get;set;} 
    public Boolean isApprovalInitiated{get;set;}
    public Boolean isArchived{get;set;}
    public PLU__c archivedPLU{get; set;}
    public PLM_PLUViewController ()
    {
     init();
    }
     
    public ApexPages.StandardSetController paginationController=null;
    public ApexPages.StandardSetController paginationArchivedController=null;
    
    //Querying for all the active PLUs based on all LI under that PLU being active
    public ApexPages.StandardSetController getPaginationController()
    {
     if(paginationController == null) {
         
                /*List<Launch_Item__c> activeliList=[select PLU__c from Launch_Item__c where Archive__c=true];
                Set<Id> activePluIdSet=new Set<Id>();
                for(Launch_Item__c li: activeliList)
                {
                 activePluIdSet.add(li.PLU__c);
                }
                paginationController = new ApexPages.StandardSetController(Database.getQueryLocator([select Id,Name,PLU_Date__c from PLU__c where ID NOT IN : activePluIdSet order by PLU_Date__c ASC]));
                */
                //Queiries all the active PLUs
                paginationController = new ApexPages.StandardSetController(Database.getQueryLocator([select Id,Name,PLU_Date__c from PLU__c where Archive__c = false order by PLU_Date__c ASC]));
                // sets the number of records in each page set
                paginationController.setPageSize(Integer.valueOf(defaultPLUPageSize));
            }
            return paginationController ;
    }
    //Querying for all the archived PLUs based on all LI under that PLU are archived   
   public ApexPages.StandardSetController getPaginationArchivedController()
    {
     if(paginationArchivedController== null) {
         
                /*List<Launch_Item__c> activeliList=[select PLU__c from Launch_Item__c where Archive__c=true];
                Set<Id> activePluIdSet=new Set<Id>();
                for(Launch_Item__c li: activeliList)
                {
                 activePluIdSet.add(li.PLU__c);
                }
                
                paginationArchivedController= new ApexPages.StandardSetController(Database.getQueryLocator([select Id,Name,PLU_Date__c from PLU__c where ID IN : activePluIdSet order by PLU_Date__c ASC]));
                */
                //Queiries all the active PLUs
                paginationArchivedController = new ApexPages.StandardSetController(Database.getQueryLocator([select Id,Name,PLU_Date__c from PLU__c where Archive__c = true order by PLU_Date__c DESC]));
                // sets the number of records in each page set
                paginationArchivedController.setPageSize(Integer.valueOf(defaultArchivedPLUPageSize));
            }
            return paginationArchivedController;
    }
    
    public PLM_PLUViewController (ApexPages.StandardController controller) {
    
    
    init();

    }
    
    public void init()
    {
       isArchived = false;
       launchItemList = new List<Launch_Item__c>();
       PLUlaunchItemList = new List<Launch_Item__c>();
       islaunchItemApprovalEnabled=Features_Toggle__c.getInstance('LaunchItemApproval').Toggle__c;
       String pageSizeString=GSM_Custom_Settings__c.getInstance('PLULaunchItemsPageSize').value__c;
       pageSize=Integer.valueOf(pageSizeString);
       
       backToListLink=GSM_Custom_Settings__c.getInstance('PLUViewController#BackLinkName').value__c;
       pluTabId=GSM_Custom_Settings__c.getInstance('PLUViewController#PLUTabId').value__c;
       pluId =ApexPages.currentPage().getParameters().get('id');
       String currentUserProfileId=UserInfo.getProfileId();
       String profileIdString =GSM_Custom_Settings__c.getInstance('PLUViewController#ProfileIds').value__c;
       List<String> profilesToVisible=profileIdString.split(',');
       for(String profileId: profilesToVisible)
       {
         if(currentUserProfileId.equals(profileId))
           {
            isCreateNewButtonVisible=true;
            break;
            }
       }
       if(pluId!=null && pluId!='')
        {
            for(Launch_Item__c li: [select id
                                   ,Name
                                   ,Final_Order_Forms_and_Invoice_Items__c
                                   ,Product_Phase__c
                                   ,Product_Design_Document__c 
                                   ,Archive__c
                                   ,Product_Manager__c
                                   ,IsFunctionalApprovalNotificationsSent__c
                                   ,isDivisionalApprovalNotificationsSent__c
                                   ,PLU__c 
                              from  Launch_Item__c where PLU__c =:pluId])
                {   
                 launchItemList.add(li);
                 }
            
           
                           
             launchItemCount=launchItemList.size();
        //If there are no LI then keep the button invisible
             if(launchItemList.size()== 0)
               {
                    isApprovalInitiated = false;
                    isCreateNewButtonVisible = false;
               }
        
             if(launchItemList.size()>0)
               {
        
            //Only if Approval is initaed once,isApprovalInitiated gets set 
            isApprovalInitiated = true;
            //Check if the PLU is archived then archive the launch items too
            archivedPLU = [select Archive__c from PLU__c where ID =:pluId];
           /* if(archivedPLU.Archive__c == true)
            {
                for(Launch_Item__c lia :launchItemList)
                   { 
                      lia.Archive__c = true;
                   }
                  
            }
            */   
            for(Launch_item__C li: launchItemList)
            { 
            //Only if notification sent,button is made visible 
             if(!li.IsFunctionalApprovalNotificationsSent__c)
              {
                isApprovalInitiated=false;
                break ;
              }
              
            }
         }
       }
      //Default PLU view same for both active and archived 
      defaultPLUPageSize=GSM_Custom_Settings__c.getInstance('PLUViewController#PLUPageSize').value__c;
      defaultArchivedPLUPageSize= GSM_Custom_Settings__c.getInstance('PLUViewController#APLUPageSize').value__c;    
       confirmationMessage='';
       isNotificationsSent=false;
       }
    
    public void showArchived() {
        isArchived= true;        
    }
    
     public List<PLU__c> getPaginatedPLUList()
    {
        //Added to avoid null pointer exception
       // if(getPaginationController().size() > 0)
        //{ 
           // update launchItemList;
            getPaginationController();
            paginatedPLUList=paginationController.getRecords();
            return paginatedPLUList;
        //}
    }
    
     public List<PLU__c> getPaginatedArchivedPLUList()
    {
        //Added to avoid null pointer exception
        //if(getPaginationArchivedController().size() > 0)
        //{ 
           
            
            getPaginationArchivedController();
            paginatedArchivedPLUList=paginationArchivedController.getRecords();
            return paginatedArchivedPLUList;
        //}
    }
     public PageReference createNewPLU()
    {
        String prefix=Schema.SobjectType.PLU__c.getKeyPrefix();
        String url='/'+ prefix+ '/e?';
        PageReference pageRef=new PageReference(url);
        return pageRef;
    }
    
     public PageReference createFunctionalApprovals() 
    {        
        //PLM_LaunchItemApprovalClass plmClass=new PLM_LaunchItemApprovalClass();
        PLM_LaunchItemApprovalGeneric plmClass=new PLM_LaunchItemApprovalGeneric();
        plmClass.makeVisibleAndSendEmailNotifiations(launchItemList,true,pluId);
        confirmationMessage=PLM_Custom_Settings__c.getInstance('PLUViewPage#ConfirmationMessage').value__C;
        isNotificationsSent=true;  
                                                                                       
         return null;
    }
    //Change the nuber of active PLUs to be displayed based on the parameter passed
    public PageReference changePLUPageSize()
    {
      String pageSize=ApexPages.currentPage().getParameters().get('activePageSize');
     
      if(pageSize.equals('default'))
       {
         pluPageSize=defaultPLUPageSize;
       }
      else
       {
         pluPageSize=pageSize;
       }
      
      paginationController.setPageSize(Integer.valueOf(pluPageSize));
     return null;
    }
    //Change the nuber of archived PLUs to be displayed based on the parameter passed

    public PageReference changeArchivedPLUPageSize()
    {
     String pageSize=ApexPages.currentPage().getParameters().get('pageSize');
     
     if(pageSize.equals('default'))
     {
      archivedPluPageSize=defaultArchivedPLUPageSize;
     }
     else
     {
      archivedPluPageSize=pageSize;
      }
       paginationArchivedController.setPageSize(Integer.valueOf(archivedPluPageSize));
      
     return null;
    }
  
    //Page changeList for active PLUs .Limiting the maximum size to 12
  /*  public List<SelectOption> getDefaultPageSizeOptionsList()
    {
      defaultActivePageSizeOptionsList=new List<SelectOption>();
      defaultActivePageSizeOptionsList.add(new SelectOption('default','default'));
      defaultActivePageSizeOptionsList.add(new SelectOption('10','10'));
      defaultActivePageSizeOptionsList.add(new SelectOption('12','12'));
     // defaultActivePageSizeOptionsList.add(new SelectOption('25','25'));
      return defaultActivePageSizeOptionsList;
    }
    */
   //Page changeList for archived PLUs .Limiting the maximum size to 25
   public List<SelectOption> getDefaultAPageSizeOptionsList()
    {
      defaultArchivePageSizeOptionsList=new List<SelectOption>();
      defaultArchivePageSizeOptionsList.add(new SelectOption('default','default'));
      defaultArchivePageSizeOptionsList.add(new SelectOption('10','10'));
      defaultArchivePageSizeOptionsList.add(new SelectOption('15','15'));
      defaultArchivePageSizeOptionsList.add(new SelectOption('20','20'));
      defaultArchivePageSizeOptionsList.add(new SelectOption('25','25'));

      return defaultArchivePageSizeOptionsList;
    }
    public PageReference setFunctionalApprovers()
    {
     String url='/apex/PLM_SetFunctionalDivisionalApprovers?retURL=';
     String retURL='/apex/PLM_PLUHomepage';
     return new PageReference(url+EncodingUtil.urlEncode(retURL,'UTF-8'));
    }
    
    Public PageReference showArhivedLaunches()
    {
     return null;
    }
     // indicates whether there are more records after the current page set.
    public Boolean hasActivePLUNext{
        get {
            return paginationController.getHasNext();
        }
        set;
    }
    public Boolean hasArchivedPLUNext{
        get {
            return paginationArchivedController.getHasNext();
        }
        set;
    }
 
    // indicates whether there are more records before the current page set.
    public Boolean hasActivePLUPrevious{
        get {
            return paginationController.getHasPrevious();
        }
        set;
    }
    public Boolean hasArchivedPLUPrevious{
        get {
            return paginationArchivedController.getHasPrevious();
        }
        set;
    }
 
    // returns the page number of the current page set
   /* public Integer pageNumber {
        get {
            return paginationController.getPageNumber();
        }
        set;
    }*/
 
    // returns the first page of records
    public void first() {
        isArchivedVisible=true;
        paginationArchivedController.first();
        
    }
    public void activeFirst() {
        paginationController.first();
        
    }
    // returns the last page of records
    public void last() {
        isArchivedVisible=true;
        paginationArchivedController.last();
       }
    public void activeLast() 
    {
        paginationController.last();
    }
 
    // returns the previous page of records
    public void previous() {
        isArchivedVisible=true;
        paginationArchivedController.previous();
       
    }
    public void activePrevious() {
        paginationController.previous();
       
    }
   
    // returns the next page of records
    public void next() {
       isArchivedVisible=true;
       paginationArchivedController.next();
       
    }
    public void activeNext() {
       paginationController.next();
       
    }
 
    // returns the PageReference of the original page, if known, or the home page.
    public void cancel() {
        paginationController.cancel();
    }
}