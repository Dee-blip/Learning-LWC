/***
    page_SearchController Class. 
    @Author: Pramod Kamath Voderbet
    @Description : This Controller is for the IRSearch Page which provides advanced search Functionlaity for the IR cases
    
    
    @History
    --Developer           --Date            --Change
    Pramod              22nd April 2013      Creating new page and the Controler as per CR 2148103 - IR Case - Advance 
                                            Search Tab for IR Cases on Invoice Review Service Cloud App
    
    
    ***/


public class page_SearchController extends IR_PageControllerBase {

  public IR_Filter myComponentController { get; set; }
  
  public override void setComponentController(IR_ComponentControllerBase compController) {
    myComponentController = (IR_Filter)compController;
  }
    
  public override IR_ComponentControllerBase getMyComponentController() {
    return myComponentController;
  }


public string inputQuery {get{ if(inputQuery ==null) { inputQuery = 'select CaseNumber,CaseNumberHyperLink__c,Account.Name,IR_Parent_Account_Name__c,IR_Original_Contract_Id__r.Name,IR_Reporting_Region__c,IR_Invoice_Number__c,IR_Manual_Contract__c,IR_Invoice_Date__c,Description,Owner.Name,Status from Case where id!=null and (RecordType.Name=\'Invoice Review Read Only\' or RecordType.Name=\'Invoice Review Case\') '; } return inputQuery;}set;}



public static List<String> getPicklistValues(String ObjectApi_name,String Field_name){ 
  List<String> lstPickvals=new List<String>();
  lstPickvals.add('');  
  Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
    Sobject Object_name = targetType.newSObject();
  Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
    Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
    Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
    List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
    for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
      lstPickvals.add(a.getValue());//add the value  to our final list
   }
  return lstPickvals;
 }


public IR_FilterObject getFilterObject()
{
  IR_FilterObject searchFields = new IR_FilterObject();
  
  // old searchFields.AddField('date','Invoice Date','IR_Invoice_Date__c','False');
  // old searchFields.AddField('string','Manual Contract?(Yes or No)','IR_Manual_Contract__c','True');
   // old searchFields.AddField('string','Status','Status','True'); 
  searchFields.AddField('string','Case Number','CaseNumber','True');
  searchFields.AddField('string','Account Name','Account.Name','False');
  searchFields.AddField('string','Parent Account','IR_Original_Contract_Id__r.Parent_Account_Name__r.Name','False');
  searchFields.AddField('string','Original Contract ID','IR_Original_Contract_Id__r.Name','True');  
  searchFields.AddField('string','Reporting Region','IR_Reporting_Region__c','True');
  searchFields.AddField('string','Invoice Number','IR_Invoice_Number__c','True');  
  searchFields.AddField('sdate','Invoice Date','IR_Invoice_Date__c','False');
  searchFields.AddField('string','Owner','Owner.Name','True');


List<string> statusinput = new List<String>();  
statusinput=getPicklistValues('Case','Status');

  searchFields.AddField('PickList','Choose Status','Status','False',statusinput);

List<string> minput = new List<String>();  
minput.add('');
minput.add('Yes');
minput.add('No');
 searchFields.AddField('PickList','Manual Contract?','IR_Manual_Contract__c','False',minput);
 
 return searchFields;
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


public Integer pagenumber {
    get {
              try{
       if(objController != null){
            return objController.getPageNumber();
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




public ApexPages.StandardSetController objController
{
    get{
        if(objController == null){
           try{
                
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

//changed here
public List <Case> getMyCases() {

//return Database.query(myComponentController.OutputQuery);
List<case> cases= new List<case>();

           try{


            for(case a : (List<case>)objController.getRecords()){

                cases.add(a);
            }
            }
            catch(QueryException q){

            }
            catch(Exception e){
            }


        return cases;
             
}

public override void SetObjControllerNull()
    {


    objController=null;
    }
public override void PostProcessApplySearch()
{
objController=null;
}
public override void clearSearch()
{
 objController=null;
}

//CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
//@isTest(SeeAllData=false)
//static void unitTest()
//    {
//        page_SearchController search=new page_SearchController();
//        search.getFilterObject();       
        
//        IR_FilterObject filter=new IR_FilterObject();
//            }
        
        

}