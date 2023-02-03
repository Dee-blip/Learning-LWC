/***
    
    Pramod Kamath Voderbet      Release 3.33        This class is the controller for the page OnlineChannelAccountAdd. Going in as a prt of OnlineChannelBeta Requirements. 
                                                    CR2379747.
                                                    
    Pramod Kamath Voderbet      Release 3.38        CR to add blacklisting and secibdary search. Created  a wrapper class . If blacklist and Account selected, Blacklist gets priority.                                              
    
    
   Pramod Kamath Voderbet       Release 3.39        CR 2525466 :- Online Channel: Un-blacklisting accounts and CR 2547993 - Online Channel: Logs and comments for account addition
   
   Pramod Kamath Voderbet        3.41                CR 2562375 - Online Channel: Modifications to Account Filter page 
   
   Pramod Kamath Voderbet        3.43                Added a filter condition. 
   
    ***/
    public with sharing class OnlineChannelAccountAddController extends IR_PageControllerBase {
    
        public class AccountWrapperForChannels
{
    
    public Account  acc { get; set;}
    public Boolean blacklistflag { get; set;}
    
    public Boolean addAcc { get; set;}
   
}
 public class applicationException extends Exception {} 
  
      List<Campaign_Account__c> OCAToSave= new List<Campaign_Account__c>();
      List<Online_Channel_Account_Blacklist__c> BLtoSave= new List<Online_Channel_Account_Blacklist__c>();  
      List<Campaign_AkamOnline__c> CapaignsOfThisPackage=new  List<Campaign_AkamOnline__c>();
      List<id> AccountsNotToDisplay=new List<id>();
        
          
         Public String outputcheck{get;set;}    
         public String campId { get; set;}
         // Sonali Tandon : CR 3333741 :: Remove geography filter from Online channel bulk account search.
         //public String geo { get; set;}
         public String pkg { get; set;}
         public Boolean selectAll{get;set;}
          public Boolean blselectAll{get;set;}
          public String status { get; set;}
           public String status2 { get; set;}
            
         public String status3 { get; set;}
         public Database.SaveResult[] sr{get;set;}
         //3.39 pramod.
             public Online_Channel_Account_History__c ocah { get; set;}
             
                public void setOcah() {
                ocah.Comments__c ='testtest';
                 
             }
            
        
             public OnlineChannelAccountAddController() 
        {      
         //3.39 Pramod  
           ocah=new Online_Channel_Account_History__c();
           campId = ApexPages.currentPage().getParameters().get('cId');  
          // Sonali Tandon : CR 3333741 :: Remove geography filter from Online channel bulk account search.
           //geo = ApexPages.currentPage().getParameters().get('geo');  
           pkg=   ApexPages.currentPage().getParameters().get('pkg'); 
           status='Direct Customer - Active'; 
           status2='Multiple w ISP - Active';
           status3='Multiple wo ISP - Active';
       
           Set<String> statusrecords = new Set<String>{ 'Direct Customer - Active','Multiple w ISP - Active','Multiple wo ISP - Active'};
          
           
           for(Online_Channel_Account_Blacklist__c ocbtemp:[select id,account__r.id from Online_Channel_Account_Blacklist__c where Online_Channel_Package__c=:pkg])
          {
          AccountsNotToDisplay.add(ocbtemp.account__r.id);
          }
                         
        }   
    
      public IR_Filter myComponentController { get; set; }
      
      public override void setComponentController(IR_ComponentControllerBase compController) {
        myComponentController = (IR_Filter)compController;
      }
        
      public override IR_ComponentControllerBase getMyComponentController() {
        return myComponentController;
      }
    
      //BillingCountry Field is Primary Country on UI. 
    //ShippingCountry Field Billing Country on UI. 
 
    // The Query has a condition to fecth only ONE geography mentioned in the OC campaign.
    // The query cannot handle multiple string paramaters as evident for account_status. This is because the SOQL below is a string which in turn is in single quotes. 
    // Sonali Tandon : CR 3333741 :: Remove geography filter from Online channel bulk account search.
    public string inputQuery {get{ if(inputQuery ==null) { inputQuery = 'SELECT Name,AKAM_Account_ID__c,id,owner.name,BillingCountry,Account_Status__c,Parent_Division__c, Division__c , Area__c , Region__c ,AnnualRevenue,Customer_Tier__c,Geography_Formula__c,Vertical__c FROM Account where id!=null' + //and Geography_Formula__c=:geo 
    +' and id NOT IN :AccountsNotToDisplay and (Account_Status__c=:status or Account_Status__c=:status2 or Account_Status__c=:status3) ' ; } return inputQuery;}set;}
    // add this and Account_Status__c =:status
    
    
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
      
      
          searchFields.AddField('string','Account Name','Name','True');
     
     // Commenting on behalf of Rahul Gaira : CR 3333741
    //  searchFields.AddField('string','Country','BillingCountry','True');
       
      //BillingCountry Field is Primary Country on UI. 
    //ShippingCountry Field Billing Country on UI. 
    
    
  //  List<string> verticalinput = new List<String>();  
  //  verticalinput=getPicklistValues('Account','Vertical__c');
  //  searchFields.AddField('PickList','Vertical','Vertical__c','False',verticalinput);
    
  //  List<string> ctierinput = new List<String>();  
  //  ctierinput=getPicklistValues('Account','Customer_Tier__c');
  //  searchFields.AddField('PickList','Customer Tier','Customer_Tier__c','False',ctierinput);
    
  //   List<string> geodivinput = new List<String>();  
  //  geodivinput=getPicklistValues('Territory_Mapping__c','Parent_Division__c');
  // searchFields.AddField('PickList','Geo-Div','Parent_Division__c','False',geodivinput);
    
  //    List<string> regioninput = new List<String>();  
  //  regioninput=getPicklistValues('Territory_Mapping__c','Division__c');
  //  searchFields.AddField('PickList','Region','Division__c','False',regioninput);
    
  //       List<string> areainput = new List<String>();  
  //  areainput=getPicklistValues('Territory_Mapping__c','Region__c');
  //  searchFields.AddField('PickList','Area','Region__c','False',areainput);
    
    
  //   List<string> terinput = new List<String>();  
  //  terinput=getPicklistValues('Territory_Mapping__c','Area__c');
  //searchFields.AddField('PickList','Territory','Area__c','False',terinput);
    
    
    
        
    
     
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
        }    }
    
    
    
    
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
    
    //changed here MyAccounts

  
    
       List<AccountWrapperForChannels> awfc ;
       
       
       public Integer getRecordCount ()      {
      
       return objController.getResultSize() ;
       
       
       }
       
       
       
       
    public List<AccountWrapperForChannels> getMyAccounts() {
    
        awfc =new List<AccountWrapperForChannels>();
    
   // List<Account> acc= new List<Account>();
               try{
                for(Account a : (List<Account>)objController.getRecords()){ 
                
                AccountWrapperForChannels tempacwfc=new AccountWrapperForChannels();               
                tempacwfc.addAcc=true;
                tempacwfc.blacklistflag=false;
                tempacwfc.Acc=a;
                awfc.add(tempacwfc);
                }
                
                }
                catch(QueryException q){
    
                }
                catch(Exception e){
                }    
    
            return awfc;
                 
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
    
   //---------------- save  
    
     public PageReference save() { 
    
       //3.39 Pramod 
    ocah.Online_Channel_Campaign__c=campId;
 /** 
  try
  {  
 if(ocah.Comments__c==null || ocah.Comments__c=='')
  { 
throw new applicationException('You cant do that here');  
     } 

}

catch(applicationException e)
{
ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter Comments'); 
ApexPages.addMessage(myMsg);
return null;
}
**/
   insert ocah;
    
      
    
    for ( AccountWrapperForChannels awfctemp : awfc)
    {
    
    if( awfctemp.addAcc == true && awfctemp.blacklistflag == false )
    {
     Campaign_Account__c tempOCA = new Campaign_Account__c();
       tempOCA.Campaign_AkamOnline__c=campId;
      tempOCA.Account__c=awfctemp.Acc.Id;
      OCAToSave.add(tempOCA);
          }
    
    if( awfctemp.blacklistflag == true)
    {
    Online_Channel_Account_Blacklist__c tempOCAB = new Online_Channel_Account_Blacklist__c();     
       tempOCAB.Online_Channel_Package__c=pkg;
       tempOCAB.Account__c=awfctemp.Acc.Id;      
      BLtoSave.add(tempOCAB);
    }
    
    } 
     //jan 2014 changes end 
            
    //comment starts here
    /*
            List<Account> OCAfiltered = Database.query(myComponentController.OutputQuery);  
             for(Account a : OCAfiltered){
                    //acc.add(a);
                   Campaign_Account__c tempOCA = new Campaign_Account__c();
                    tempOCA.Account__c=a.Id;
                    tempOCA.Campaign_AkamOnline__c=campId;
                    OCAToSave.add(tempOCA);
       
                }
    
    */  //comment ends here
    sr= Database.insert (OCAToSave,false);
    sr=Database.insert(BLtoSave,false);
     
                  String rUrl = '/' + ApexPages.currentPage().getParameters().get('cId');
                PageReference rPage = new PageReference(rUrl);
                rPage.setRedirect(true);
                return rPage; 
        
      }

    //CR2525466 start
    public class BlacklistAccountWrapperForChannels {
        public Online_Channel_Account_Blacklist__c  blAcc { get; set;}
        public Boolean unblacklistflag { get; set;}   
    }
    List<BlacklistAccountWrapperForChannels> bawfc ;
    List<Online_Channel_Account_Blacklist__c> BLtoDelete= new List<Online_Channel_Account_Blacklist__c>(); 
    public transient Database.DeleteResult[] dr{get;set;} 
      
    public ApexPages.StandardSetController blAccController {
        get{
            if(blAccController == null){
                try{
                                 
                 blAccController = new ApexPages.StandardSetController(Database.getQueryLocator(
                                      [SELECT Id, Account__r.Id, Account__r.Name, Account__r.BillingCountry, Account__r.Account_Status__c, Account__r.AnnualRevenue, Account__r.Customer_Tier__c, Account__r.Geography_Formula__c, Account__r.Vertical__c 
                                       FROM Online_Channel_Account_Blacklist__c where id!=null and Account__r.Id IN :AccountsNotToDisplay AND Online_Channel_Package__r.Id = :pkg 
                                       ORDER BY Account__r.Name LIMIT 10000]));               
                 blAccController.setPageSize(10);
                         }catch(Exception e){
                 system.debug('________________Inside Exception'+ e);
                }
            }
            return blAccController;
        }
        set;
    }
       
    public Boolean hasNextBlAcc {
        get {
            try{
            if(blAccController != null){
                return blAccController.getHasNext();
            }
            else
                return null;
            }
            catch(Exception e){
                return null;
            }
        }
        set;
    }
    
    
    public Boolean hasPreviousBlAcc {
        get {
            try{
            if(blAccController != null){
                return blAccController.getHasPrevious();
            }
            else
                return null;
            }
            catch(Exception e) {
                return null;
            }
        }
        set;
    }
    
    public Integer pagenumberBlAcc {
        get {
            try{
                if(blAccController != null){
                    return blAccController.getPageNumber();
                }
                else
                    return null;
            }
            catch(Exception e) {
                return null;
            }
        }
        set;
    }
    
    public void firstBlAcc() {
        if(blAccController != null){
            blAccController.first();
        }
    }
    
    public void lastBlAcc() {
        if(blAccController != null){
            blAccController.last();
        }
    }
    
    public void previousBlAcc() {
        if(blAccController != null){
            blAccController.previous();
        }
    }
    
    public void nextBlAcc() {
        if(blAccController != null){
            blAccController.next();
        }
    }
        
    public List<BlacklistAccountWrapperForChannels> getBlacklistAccounts() {
        bawfc = new List<BlacklistAccountWrapperForChannels>();
        try{
            //for(Account a : [SELECT Id, Account__r.Name, Account__r.BillingCountry, Account__r.Account_Status__c, Account__r.AnnualRevenue, Account__r.Customer_Tier__c, Account__r.Geography_Formula__c, Account__r.Vertical__c FROM Online_Channel_Account_Blacklist__c where id!=null and Account__r.Id IN :AccountsNotToDisplay]){ 
            //for(Online_Channel_Account_Blacklist__c ocab : [SELECT Id, Account FROM Online_Channel_Account_Blacklist__c where id!=null and Account__r.Id IN :AccountsNotToDisplay AND Online_Channel_Package_r.Id = :pkg]){
            for(Online_Channel_Account_Blacklist__c ocab : (List<Online_Channel_Account_Blacklist__c>)blAccController.getRecords()) {
                BlacklistAccountWrapperForChannels tempbawfc = new BlacklistAccountWrapperForChannels();               
                tempbawfc.unblacklistflag = false;
                tempbawfc.blAcc = ocab;
                bawfc.add(tempbawfc);
            }
        } catch(QueryException q){

        } catch(Exception e){
        
        }    
        return bawfc;          
    }
    
    public Integer getBlAccRecordCount () {
        return blAccController.getResultSize() ;
    }
       
    public PageReference unBlacklist() { 
    
    //ocah.Online_Channel_Campaign__c=campId; 
      // insert ocah;
   
        for ( BlacklistAccountWrapperForChannels bawfctemp : bawfc) {
            if( bawfctemp.unblacklistflag == true) {
                Online_Channel_Account_Blacklist__c tempOCAB = new Online_Channel_Account_Blacklist__c();     
                tempOCAB.Id = bawfctemp.blAcc.Id;      
                BLtoDelete.add(tempOCAB);
            }
        }
        dr= Database.delete(BLtoDelete,false);
        String rUrl = '/' + ApexPages.currentPage().getParameters().get('cId');
        PageReference rPage = new PageReference(rUrl);
        rPage.setRedirect(true);
        return rPage; 
        //return null;
    }  
    //CR2525466 end
    }