public class RSSTemplateSearch extends SI_PageControllerBase{
//show only users templates templates
public Boolean ShowMyTemplates {get{if(ShowMyTemplates == null) {ShowMyTemplates =false;} return ShowMyTemplates;} set;}
public String SelectedView {get{
    if(SelectedView==null) 
    { 
        SelectedView = 'My Open Templates';
        if(!WriteAccessOfUser)
        {
            SelectedView = 'Published Templates';
        }
    
    } return SelectedView;}set;}
//using the search component
public SI_QueryBuilder myComponentController { get; set; }
public String DeleteTemplateId {get {if(DeleteTemplateId==null) { DeleteTemplateId = ''; } return DeleteTemplateId; }set;}
public EB_FilterObject searchFields {get { if(searchFields==null){ 
    searchFields = new EB_FilterObject();  
    searchFields.AddField('string','Template Name','Name','True');
    searchFields.AddField('Integer','Version','Version__c','True');
    searchFields.AddField('string','Owner','Owner.Name','True');
    // searchFields.AddField('Boolean','Locked','Locked__c');
    //searchFields.AddCustomBooleanField('Search Across Locked records',' Locked__c = false ',' Locked__c = true ');
    } return searchFields;}set;}
public Boolean getDebugRender()
{
    try
    {
    eRSS__c objApp = eRSS__c.getInstance('eRSS');
      
    Boolean renderRow = Boolean.valueOf(objApp.ShowDebug__c);
    
    return renderRow;    
    }
    catch(Exception e)
    {
       
        return false;
    }
}
    public Boolean WriteAccessOfUser{get {if(WriteAccessOfUser==null){
        WriteAccessOfUser = RSSUtility.TemplateWriteAccess(UserInfo.getUserId()); } return WriteAccessOfUser;} set; }
    
public PageReference changeCheckBoxValue()
{
    return null;
}
 public PageReference goToCreateNewSurveyPage()
 {
     String RecTId = '' ;
     for(RecordType rt: [select id from RecordType where name = 'RSS Template' limit 1])
     {
         RectId = rt.id;
     }
     PageReference pg = new PageReference('/apex/GSurveys?RecordType=' +RecTId);
     pg.setRedirect(true);
     return pg;
 }
 
public void ChangeInputString()
{
    if(SelectedView == 'My Open Templates')
    {
      
           InputQuery = 'select  name,Id,Owner.Name,Locked__c, Version__c, RSS_Published__c, UniqueName__c,LastModifiedDate  from Survey__c where soft_delete__c=false and locked__c = false and ownerId = \'' + UserInfo.getUserId() + '\' ';
        
        
    }
    else if(SelectedView == 'Published Templates')
    {
       
        InputQuery = 'select  name,Owner.Name,Id,Locked__c, Version__c, RSS_Published__c, UniqueName__c,LastModifiedDate from Survey__c where soft_delete__c=false and RSS_Published__c = true';
        
    }else
    {
         InputQuery = 'select  name,Owner.Name,Id,Locked__c, Version__c, RSS_Published__c, UniqueName__c,LastModifiedDate from Survey__c where soft_delete__c=false and locked__c = true ';
    }
    
     objController=null;
    
}

public String InputQuery {
    get
    {
        if(InputQuery==null)
        {
            ChangeInputString();
        }
        return InputQuery;
    }
    set;
}

   
   
public override void setComponentController(SI_ComponentControllerBase compController) {
    myComponentController = (SI_QueryBuilder)compController;
  }
    
  public override SI_ComponentControllerBase getMyComponentController() {
    return myComponentController;
  }
   
   
    public void toggleSortOrder()
  {
        
        myComponentController.toggleSortOrder();
  }
 
  // the current field to sort by. defaults to last name
  public String sortField {
    get  { if (sortField == null) {sortField = 'name'; } return sortField;  }
    set
    {    
         
        myComponentController.setSortField(value); 
        sortField = value;
       
    }
  }
  public ApexPages.StandardSetController objController
{
    get{
        if(objController == null){
           try
           {
               objController = new ApexPages.StandardSetController(Database.getQueryLocator(myComponentController.OutputQuery ));
               objController.setPageSize(25);
           }
           catch(Exception e){
           
                                   system.debug('________________Inside Exception'+ myComponentController.OutputQuery); 
           }
        }
        return objController;
    }
    set;
}
           

public Boolean hasNext {
    
    get {
    // indicates whether there are more records after the current page set.
        try{
        if(objController != null){
            return objController.getHasNext();
        }
        else 
            return null;
           }
        catch(Exception e)
        {
        return null;
        }
    }
    set;
}
 
 
public Boolean hasPrevious {
    get {
       // indicates whether there are more records before the current page set.
       try{
       if(objController != null){
            return objController.getHasPrevious();
       }
       else
            return null;
        }
        catch(Exception e)
        {
        return null;
        }
    }
    set;
}

public void first() {
// returns the first page of records
if(objController != null){
    objController.first();
    }
}
 
 public void last() {
    // returns the last page of records
 if(objController != null){
       objController.last();
 }
}
 
public void previous() {
    // returns the previous page of records
 if(objController != null){
       objController.previous();
    }
}
 
public void next() {
    // returns the next page of records  
 if(objController != null){
        objController.next();
    }
} 

public void deleteTemplate()
{
    if(DeleteTemplateId!=null&&DeleteTemplateId!='')
    {
        Survey__c tempToBeDeleted = [select id from Survey__c where id =:DeleteTemplateId limit 1];
        Boolean TemplateHasForms = false;
        
        for(SurveyTaker__c st:[select id from SurveyTaker__c where Survey__c = :DeleteTemplateId])
        {
            TemplateHasForms = true;
        }
        if(!TemplateHasForms)
        {
             tempToBeDeleted.soft_delete__c = true;
             update tempToBeDeleted;  
             SetObjControllerNull();
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ' Cannot Delete RSS Template which has forms associated with it.'));
        }
        
    }
    DeleteTemplateId = ''; 
}
    
public override void SetObjControllerNull()
{
objController=null;
}
public override void clearSearch()
{
 objController=null;
}
public override void PostProcessApplySearch()
{
objController=null;
}
public List< Survey__c > getRSSTemplates() {
try{
    return (List< Survey__c >)objController.getRecords();//[select name,RSS_Form_PDF__c, RSS_Form_Edit__c,Id,RSS_Name__c,Survey__c,Survey__r.Name,Version__c from SurveyTaker__c  ];
    }
    catch(Exception e)
    {
        return new List<Survey__c>();
    }
}
}