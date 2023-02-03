public class RSSFormSearchController extends SI_PageControllerBase {

//using the search component
public SI_QueryBuilder myComponentController { get; set; }

//Start of changes by shprasan
//public Boolean WriteAccessOfUser{get {if(WriteAccessOfUser==null){
//    WriteAccessOfUser =RSSUtility.FormWriteAccess(UserInfo.getUserId()); } return WriteAccessOfUser;} set; }
Public Map<String,Boolean> userPermissionMap{get{if(userPermissionMap==null){
userPermissionMap = RSSUtility.FormWriteAccess(UserInfo.getUserId());  } return userPermissionMap;} set; }
public Boolean WriteAccessOfUser{get {if(WriteAccessOfUser==null){WriteAccessOfUser = userPermissionMap.get('WriteAccessOfUser');} return WriteAccessOfUser;} set;}
public Boolean PreSales{
      get 
      {
          if(PreSales==null)
          {
              PreSales = userPermissionMap.get('Pre-sales');
              //system.assert(PreSales == true);
          }
          return PreSales;
      } 
      set;
}
public Boolean PostSales{get {if(PostSales==null){PostSales = userPermissionMap.get('Post-sales');} return PostSales;} set;}

public Boolean SuperUser
{
    get 
    {
        if(SuperUser==null)
        {
            SuperUser = userPermissionMap.get('SuperUser');
        } 
        return SuperUser;
    } 
    set;
}

public Boolean CCare
{
    get 
    {
        if(CCare==null)
        {
            CCare = userPermissionMap.get('CCare');
        } 
        return CCare;
    } 
    set;
}

//End of changes by shprasan

public String DeleteFormId {get;set;}
public String SelectedView 
{
  get
  {
    if(SelectedView==null) 
    {   //Changes by shprasan: setting the default view to Open Forms for PreSales and My Published Forms for PostSales
        if(PreSales || SuperUser)
        {
            SelectedView = 'My Open Forms';  
        } 
        else if(PostSales)
        {
            SelectedView = 'My Published Forms';  
        } 
        else if(!WriteAccessOfUser)
        {
            SelectedView = 'Published Forms';
        }
    
    } 
    return SelectedView;
  }
    set;
}
//Start of changes by shprasan
public String FieldToSort
{
    get
    { 
      if (FieldToSort == null) 
      {
        if (SelectedView == 'Submitted Forms' || SelectedView == 'My Submitted Forms' || (SelectedView == 'All' && PreSales) || (SelectedView == 'My Open Forms' && PreSales))
        {
            FieldToSort = 'Submittal_Date__c'; 
        }
        else if (SelectedView == 'Published Forms'|| SelectedView == 'My Published Forms')
        {
            FieldToSort = 'Published_Date__c'; 
        }
        else if (SelectedView == 'My Open Forms')
        {
            FieldToSort = 'CreatedDate'; 
        }
        else
        {
            FieldToSort = 'Published_Date__c';           
        }
        
         //FieldToSort = 'CreatedDate';       
      } 
      return FieldToSort; 
    }
    set;
}
//End of changes by shprasan
public String InputQuery {
    get
    {
        if(InputQuery==null)
        {    
            //TODO:
            //InputQuery = 'select RSS_Form_Header__r.name,RSS_Form_Header__r.Products__c, RSS_Published__c, Published_Date__c,RSS_Form_Header__r.AEName__c,RSS_Form_Header__r.CustomerName__c,RSS_Form_Header__r.DigitalProperty__c,CreatedDate , name,RSS_Form_PDF__c, RSS_Form_Edit__c,Id,RSS_Name__c, Owner.Name,Survey__c, Survey__r.Name,Version__c from SurveyTaker__c where id!=null ';
            ChangeInputString();//'select  Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name from RSS_Form__c where id!=null and Published__c = True';
        }
        return InputQuery;
    }
    set;
}
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
  //Start of changes by shprasan
  //Changing the default sort field based on the view
  public String sortField {
    get
    { 
      if (sortField == null) 
      {
        if (SelectedView == 'Submitted Forms' || SelectedView == 'My Submitted Forms' || (SelectedView == 'All' && PreSales) || (SelectedView == 'My Open Forms' && !PreSales))
        {
            sortField = 'Submittal_Date__c'; 
        }
        else if (SelectedView == 'Published Forms'|| SelectedView == 'My Published Forms')
        {
            sortField = 'Published_Date__c'; 
        }
        else if (SelectedView == 'My Open Forms' && PreSales)
        {
            sortField = 'CreatedDate'; 
        }
        else
        {
            sortField = 'Published_Date__c';           
        }
        //sortField = 'name'; 
      } 
      return sortField;  
    }
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
           
                                   system.debug('________________Inside Exception'+ e); 
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
//adding the fields to be searched
public EB_FilterObject getsearchFields()
{
  EB_FilterObject searchFields = new EB_FilterObject();  
  //TODO:
  searchFields.AddField('string','Form Name','Name','True');
  searchFields.AddField('string','Customer Name','Account__r.Name','True');
  searchFields.AddField('string','Owner','Owner.Name','True');
  searchFields.AddField('string','AE Name','AEName__r.Name','True');
  searchFields.AddField('Integer','Version','Version__c','True');
  searchFields.AddField('string','Products','Products__c','True');
  //searchFields.AddField('string','Products','RSS_Form_Header__r.Products__c','True');
//  searchFields.AddField('string','GDRAT','GDRAT__c','True');
  searchFields.AddField('string','Digital Property','DigitalProperty__c','True');
  searchFields.AddField('DateTime','Created Date','CreatedDate','True');
  //Changes by shprasan:Adding Submittal Date and Published date
  searchFields.AddField('DateTime','Submittal Date','Submittal_Date__c','True');
  searchFields.AddField('DateTime','Published Date','Published_Date__c','True');
  //searchFields.AddCustomBooleanField('Search across locked records',' Locked__c = false ',' Locked__c = true ');
  return searchFields;
  
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
public List< RSS_Form__c > getRSSForms() {
try{
    return (List< RSS_Form__c >)objController.getRecords();//[select name,RSS_Form_PDF__c, RSS_Form_Edit__c,Id,RSS_Name__c,Survey__c,Survey__r.Name,Version__c from SurveyTaker__c  ];
    }
    catch(Exception e)
    {
        return new List<RSS_Form__c>();
    }
}
public PageReference goToOUploadPage()
{
    PageReference pg = new PageReference('/apex/RSSFormOfflineUpload');
    pg.setRedirect(true);
    return pg;
}
public PageReference goToCreateNewRSSFormPage()
{
    PageReference pg = new PageReference('/apex/RSSForm?id=new');
    pg.setRedirect(true);
    return pg;
}
public PageReference goToDownloadOfflinePage()
{
    PageReference pg = new PageReference('/apex/RSSFormOfflineDOwnload');
    pg.setRedirect(true);
    return pg;
}
public void deleteRSSForm()
{

    try
    {
        RSS_Form__c st =  [select id,soft_delete__c from RSS_Form__c where id =:DeleteFormId limit 1];
        st.soft_delete__c = true;
        update st;
        objController=null;
    }
    catch(Exception e)
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Could not delete the RSS Form!'));
    }
    
}
public void ChangeInputString()
{
    //Changes by shprasan
    //My Open Forms view for PreSales: All the saved unsubmitted forms of the current user
    if(SelectedView == 'My Open Forms' && PreSales)
    {
        //select all the forms of the current user that are saved and not submitted     
        InputQuery = 'select  Locked__c,LastModifiedBy.Name, Submitted_By__r.Name,Submitted__c,Published__c,Published_Date__c,Submit_Locked__c,Submit_Version__c,Submittal_Date__c,Products__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name from RSS_Form__c where soft_delete__c = false and Submit_Locked__c = false and Submitted__c = false and Services_Form__c = false and OwnerId = \''+ UserInfo.getUserId() + '\'';    
        FieldToSort = 'CreatedDate';
        //myComponentController.setSortField('CreatedDate');
    }
    //My Open Forms view for PostSales: All the saved unpublished forms of the current user 
    else if(SelectedView == 'My Open Forms' && PostSales)
    {
        //select all the submitted forms that are saved and not published       
        InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c,Locked__c, Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Submitted__c = true and Locked__c = false and Published__c = false and Services_Form__c = false and (OwnerId = \''+ UserInfo.getUserId() + '\' or LastModifiedById = \'' + UserInfo.getUserId() + '\')';    
        FieldToSort = 'Submittal_Date__c';
        //myComponentController.setSortField('Submittal_Date__c');
    }
    //My Open Forms view for SuperUser: All the saved unpublished forms of the current user 
    else if(SelectedView == 'My Open Forms' && SuperUser)
    {
        //select all the submitted forms that are saved and not submitted and forms that are saved and not published       
        InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c,Locked__c, Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and ((Submit_Locked__c = false and Submitted__c = false) or (Submitted__c = true and Locked__c = false and Published__c = false)) and Services_Form__c = false and (OwnerId = \''+ UserInfo.getUserId() + '\' or LastModifiedById = \'' + UserInfo.getUserId() + '\')';    
        FieldToSort = 'CreatedDate';
        //myComponentController.setSortField('CreatedDate');
    }

    //Adding the two views: Submitted Forms and My Submitted Forms
    //All the submitted unpublished forms are visible

    else if(SelectedView == 'Submitted Forms' && PreSales)
    {
        //Select all the forms that have been submitted by all users. Also displaying the published forms.       
        Map<String,String> UniqueNameToIds = new Map<String,String>();
        String formIds = '(';
        for (RSS_Form__c form : [Select Id, UniqueName__c from RSS_Form__c where  Published__c = true])
        {
            UniqueNameToIds.put(form.UniqueName__c,form.Id);
        }
        for (RSS_Form__c form: [Select Id, LastModifiedById, Submitted_By__c from RSS_Form__c where  Submitted__c = True and Locked__c = false and UniqueName__c not in :UniqueNameToIds.keySet()])
        {
            if (form.LastModifiedById == form.Submitted_By__c)
            {
                formIds += '\'' + form.Id + '\',';
            }
        }
        formIds += '\'' + '\'' + ')';
        InputQuery = 'select  LastModifiedBy.Name,Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name from RSS_Form__c where soft_delete__c = false and  Services_Form__c = false and (id in '+ formIds + ' or Published__c = true)';    
        FieldToSort = 'Submittal_Date__c';
        //myComponentController.setSortField('Submittal_Date__c');
    }
    else if(SelectedView == 'Submitted Forms' && (PostSales || CCare))
    {
        //Select all the forms that have been submitted by all users.   
        Map<String,String> UniqueNameToIds = new Map<String,String>();
        String formIds = '(';
        for (RSS_Form__c form : [Select Id, UniqueName__c from RSS_Form__c where  Published__c = true])
        {
            UniqueNameToIds.put(form.UniqueName__c,form.Id);
        }
        for (RSS_Form__c form: [Select Id, LastModifiedById, Submitted_By__c from RSS_Form__c where  Submitted__c = True and Locked__c = false and UniqueName__c not in :UniqueNameToIds.keySet()])
        {
            if (form.LastModifiedById == form.Submitted_By__c)
            {
                formIds += '\'' + form.Id + '\',';
            }
        }
        formIds += '\'' + '\'' + ')';
             
        InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Submitted__c = True and Locked__c = false and Published__c = false and Services_Form__c = false and id in ' + formIds;    
        FieldToSort = 'Submittal_Date__c';
        //myComponentController.setSortField('Submittal_Date__c');
    }
    //All the current user's submitted unpublished forms are visible
    else if(SelectedView == 'My Submitted Forms')
    {
        //Select all the forms that have been submitted by the current user. Also displaying the published forms.              
        Map<String,String> UniqueNameToIds = new Map<String,String>();
        String formIds = '(';
        for (RSS_Form__c form : [Select Id, UniqueName__c from RSS_Form__c where  Published__c = true and Submitted_By__c = :UserInfo.getUserId()])
        {
            UniqueNameToIds.put(form.UniqueName__c,form.Id);
        }
        for (RSS_Form__c form: [Select Id, LastModifiedById, Submitted_By__c from RSS_Form__c where  Submitted__c = True and Locked__c = false and UniqueName__c not in :UniqueNameToIds.keySet() and  Submitted_By__c = :UserInfo.getUserId()])
        {
            if (form.LastModifiedById == form.Submitted_By__c)
            {
                formIds += '\'' + form.Id + '\',';
            }
        }
        formIds += '\'' + '\'' + ')';

        InputQuery = 'select  Submitted__c,Submit_Locked__c,Submitted_By__r.Name,Submittal_Date__c,Submit_Version__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name, LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Services_Form__c = false and (id in ' + formIds +  ' or Published__c = true) and Submitted_By__c = \''+ UserInfo.getUserId() + '\'';    
        FieldToSort = 'Submittal_Date__c';
        //myComponentController.setSortField('Submittal_Date__c');
    }    
    else if(SelectedView == 'Published Forms')
    {
        //select all the published forms of all the users
        InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c, Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Services_Form__c = false and Published__c = True ';    
        FieldToSort = 'Published_Date__c';
        //myComponentController.setSortField('Published_Date__c');
    }
    
    else if(SelectedView == 'My Published Forms')
    {
       //select all the published forms of the current user
        InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Published__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Published__c = True and Services_Form__c = false and (OwnerId = \''+ UserInfo.getUserId() + '\' or LastModifiedById = \'' + UserInfo.getUserId() + '\')';
        FieldToSort = 'Published_Date__c';
        //myComponentController.setSortField('Published_Date__c');
    }
    //If the selected view is All Forms and the user is PreSales, All users submitted, published forms and the older versions of the submitted forms are visible
    else if (SelectedView == 'All' && PreSales)
    {    //Select all the submitted versions of forms that were created by the current user and their published versions
         //InputQuery = 'select  Submitted__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name from RSS_Form__c where soft_delete__c = false and locked__c = true';   
          Map<String,String> UniqueNameToIds = new Map<String,String>();
          String formIds = '(';
          for (RSS_Form__c form : [Select Id, UniqueName__c from RSS_Form__c where  Published__c = true and Submitted_By__c = :UserInfo.getUserId()])
          {
              UniqueNameToIds.put(form.UniqueName__c,form.Id);
          }
          for (RSS_Form__c form: [Select Id, LastModifiedById, Submitted_By__c from RSS_Form__c where  Submitted__c = True and Locked__c = false and UniqueName__c not in :UniqueNameToIds.keySet() and  Submitted_By__c = :UserInfo.getUserId()])
          {
              if (form.LastModifiedById == form.Submitted_By__c)
              {
                  formIds += '\'' + form.Id + '\',';
              }
          }
          formIds += '\'' + '\'' + ')';

         InputQuery = 'select  LastModifiedBy.Name,Submitted__c,Submitted_By__r.Name,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name from RSS_Form__c where soft_delete__c = false and Services_Form__c = false and ((Submit_Locked__c = true and Submitted__c = false) or id in ' + formIds + ' or Published__c = true) and Submitted_By__c = \'' + UserInfo.getUserId() + '\'';
         FieldToSort = 'Submittal_Date__c';
         //myComponentController.setSortField('Submittal_Date__c');
    }
    //If the selected view is All Forms and the user is PostSales or SuperUser, All users submitted, published forms and the older versions of the published forms
    else if (SelectedView == 'All' && (PostSales || SuperUser))
    {
         //select all versions of the current user's published forms
         //InputQuery = 'select  Submitted__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name from RSS_Form__c where soft_delete__c = false and locked__c = true';   
         InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Submit_locked__c = true and Submitted__c = true and Locked__c = true and Services_Form__c = false and (OwnerId = \''+ UserInfo.getUserId() + '\' or LastModifiedById = \'' + UserInfo.getUserId() + '\')';
         FieldToSort = 'Published_Date__c';
         //myComponentController.setSortField('Published_Date__c');
    }
    //If the view is All Submitted and Published Forms: show all users submitted and published forms
    else if(SelectedView == 'All Submitted Published Forms')
    {
       //select all the published forms of the current user

        //InputQuery = 'select  LastModifiedBy.Name,Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name from RSS_Form__c where soft_delete__c = false and ((Submitted__c = True and Locked__c = false) or Published__c = true)';    
        //FieldToSort =  'Published_Date__c';  
        //myComponentController.setSortField('Published_Date__c');
        Map<String,String> UniqueNameToIds = new Map<String,String>();
        String formIds = '(';
        for (RSS_Form__c form : [Select Id, UniqueName__c from RSS_Form__c where  Published__c = true])
        {
            UniqueNameToIds.put(form.UniqueName__c,form.Id);
        }
        for (RSS_Form__c form: [Select Id, LastModifiedById, Submitted_By__c from RSS_Form__c where  Submitted__c = True and Locked__c = false and UniqueName__c not in :UniqueNameToIds.keySet()])
        {
            if (form.LastModifiedById == form.Submitted_By__c)
            {
                formIds += '\'' + form.Id + '\',';
            }
        }
        formIds += '\'' + '\'' + ')';
        InputQuery = 'select  LastModifiedBy.Name,Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name from RSS_Form__c where soft_delete__c = false and Services_Form__c = false and (id in '+ formIds + ' or Published__c = true)';    
        FieldToSort = 'Submittal_Date__c';

    }
    //Changes by Sharath: Creating new views for Services forms: The forms created by the Post-Sales
    else if(SelectedView == 'My Saved Services Forms')
    {
        //Select all the services forms saved by the current user
        InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c,Locked__c, Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Locked__c = false and Published__c = false and Services_Form__c = true and (OwnerId = \''+ UserInfo.getUserId() + '\' or LastModifiedById = \'' + UserInfo.getUserId() + '\')';    
        FieldToSort = 'Submittal_Date__c';

    } 
    else if (SelectedView == 'My Published Services Forms')
    {
        //Select all the services forms published by the current user
        InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Published__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Published__c = True and Services_Form__c = true and (OwnerId = \''+ UserInfo.getUserId() + '\' or LastModifiedById = \'' + UserInfo.getUserId() + '\')';
        FieldToSort = 'Published_Date__c';

    } 
    else if(SelectedView == 'All Services Forms')
    {
         //select all the Services forms of the current user
         InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c,Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Locked__c = true and Services_Form__c = true and (OwnerId = \''+ UserInfo.getUserId() + '\' or LastModifiedById = \'' + UserInfo.getUserId() + '\')';
         FieldToSort = 'Published_Date__c';

    } 
    else if (SelectedView == 'Published Services Forms')
    {
        //select all the published Services forms of all the users
        InputQuery = 'select  Submitted_By__r.Name,Submitted__c,Submit_Locked__c,Submittal_Date__c,Submit_Version__c, Published__c, Locked__c,Products__c, Published_Date__c, CreatedDate , name,Id, AEName__c,Account__c,Account__r.Name,DigitalProperty__c, Version__c, Owner.Name,LastModifiedBy.Name from RSS_Form__c where soft_delete__c = false and Services_Form__c = true and Published__c = True ';    
        FieldToSort = 'Published_Date__c';      
    } 
    //End of changes by shprasan
    //system.assert(FieldToSort != null);
    //toggleSortOrder();
     objController=null;
}





}