public virtual class EB_CtrlMailerWizard
{ 
    
   

    /* ========================================================================
    
    Authors: Jayalakshmi A, Sharath K & Vineet S
    Description: Main Controller for the Mailer Wizard
                    1. Provides option for Service Incident Notification/ General Incident Notification.
                    2. Renders the search criteria entered by users and displays relevant list of Accounts.
                    3. Allows users to select Accounts of their choice and create Mailers.
                    4. Allows navigation between the different pages of the Wizard.
    Created Date :
    Modification Date and modifications done:
    1. 6/23/2010 - Added the logic to include EB_UniqAccConList class for retreiving the correct Account records using database.getQueryLocator();
                 - Made changes in page2() function to form the queries right. (Satish & Sharath)
    2. 6/24/2010 - Cleaned the code to remove unnecessary comment lines, remove the getter/setter methods and replace them with Properties.(Satish & Sharath)
                 - Added the getAggregate function () and AccountProduct_Page().(Sharath) 
    3. 7/-/2010  - Removed dependency on UniqAccConList class, changed Page2() removed getAggregate(), added logiv for EnhancedSoqlBuilder
    4. 9/3/2010  -  CR-785460:Remove the Search Boxes by default and make this visible only if the user specifies
    5. 9/9/2010 - CR 791832: Customer Notification Accounts Pagination & Selection Fix - Added new function getAdded(), modified getAccounts(),getSelected()
    6. 9/14/2010- CR 794793: Implementing code review findings - Made the class virtual so that EB_CtrlMailerWizardByAccCPId can extend this class
    7. 9/18/2010- CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process - Included logic for tokenizing the process
    8. 10/1/2010- CR 819957: Making the Create Mailer Batchable 
    9. 3/25/2011 - CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation
    10.3/25/2011 - CR 1029711 CNotify: Standardize Action Poller Content, Create Mailer
    11. 8/26/2011 - CR 1279795  CNotify: Mnt-08/29 Account Entitled Product Search Code Fix
    12. 9/26/2011 - CR 1302518 CNotify: 10/10 Filtering out Contacts which have Email Id as null - Adding Email !='' and Email !=null conditions in all Contact queries.
    13. 11/11/2011 - CR 1403956: Include help text in the search page that informs the users about 24*7 condition.
        14. 14/11/2011 - CR 1378172 CNotify: Superficial Fix, Accepting Issue Details & SI# in the first step of Mailer Creation
                                   - CR 1403947 - CNotify: Enhancement, Navigate directly to the Mailer post Mailer Creation
    15. 06/25/2012 - CR 1733044 CNotify: Enhancing the existing Account Product Search to Incorporate New Prod Catg Search
    16. 07/06/2012 - CR 1753222 CNotify: 2012 Jul-2012 Setting Account Product Search as the Default
    17. 7/12/2013 - Sonia CR 2286623 CNotify: Filter Inactive Accounts - Adding Account_Status__c NOT LIKE '% - Inactive' condition in all Account queries.
    18. 12/02/2014 - ssawhney CR 2463078 - CNotify: Exception in Preview Search functionality
    19. 14/04/2014 - ssawhney CR 2499348 - Customer Notification app should not create mailer if customer-notifications@akamai.com is marked as bad
    20. 21/04/2014 - ssawhney CR 2611929 - Filter all Contacts that have Email Bounce set to true
    ======================================================================== */
    // CR 851564 - Start of changes - Added new functions getMailerStatus(),getMailerDetails(),getCurrentMailerLink(),getRenderMailerLink() and below 2 variables are the return values
    // CR 2852805 - Added check to avoid duplication of Selected ACcounts in CreateMailer method
    public string MailerStatus ='In Progress';
    public string MailerLink{get;set;}
    // CR 851564 - End of changes
    public boolean renderPreviwTemplate{get;set;}    
    protected String soql;
    public String debugAccountSQL {get;set;}
    public String debugProductSQL {get;set;}
    public String debugFinalSQL {get; set;}
    //Start of changes by samir to exclude Reseller Accounts.
    public list<Merge_Contract_Header__c> resellerparentcontracts= new List<Merge_Contract_Header__c>();
    public list<Merge_Contract_Header__c> resellerchildcontracts= new List<Merge_Contract_Header__c>();
    public list<Account> ResellerAccounts=new list<Account>();
    public list<EB_ResellerContractId__c > ContractIdsCustomSettings=new list<EB_ResellerContractId__c >();
    public list<String> ResellerContractIds=new list<String>();
    public list<Account> ResellerAccountsOmitted=new list<Account>();
    protected String final_query;
    private boolean isValidEmailId = true;
    
    //CR 2286623 : SQl changed by Sonia - Added condition to filter out Inactive accounts
    //String strSOQL='select Id, Name, AKAM_Account_ID__c, Phone, Customer_Tier__c, Support_Level__c, Type from Account where Account_Status__c != \'Lead\' limit 20'  ;    
    String strSOQL='select Id, Name, AKAM_Account_ID__c, Phone, Customer_Tier__c, Support_Level__c, Type from Account where Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\') limit 20'  ;
    
    protected String finalSOQLAccount;
    String finalSOQLProduct;
    Integer productFlag=0;
    //CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process
    public String token;
    public List<EB_AccountWrapper> accountList = new List<EB_AccountWrapper>();
    protected List<Account> selectedAccounts = new List<Account>();
    protected Set<Account> selectMore = new Set<Account>();
    List<Contact> selectedContacts = new List<Contact>();
    EB_EnhancedSoqlBuilder searchProduct = new EB_EnhancedSoqlBuilder();
    EB_EnhancedSoqlBuilder searchAccount = new EB_EnhancedSoqlBuilder();
    Boolean editFlagAccount = false;
    Boolean editFlagProduct = false;
   
    //start of changes by janantha for CR 1733044: sort 
    private Map<String, Integer> listPosition = null;  
    private Map<String, List<String>> sortedFieldValuesPerFieldName = null;  
    private Map<String, Map<String, List<String>>> sObjectIDsPerFieldNames = null;
    
    public List<sObject> originalList {get; set;}
    //End of changes by janantha for CR 1733044: sort
    
    //Vin Sorting Column Name
    //CR 1685569 - CNotify: 2012 Jun-2012 Enhancement to the existing lists of Selection of Customers functionality
    String strOriginalSOQL = strSOQL;
    protected String strOriginalResellerSOQL;
    public String customerTier {get;set;}
    public String supportLevel {get;set;}     
    public String abcde{get;set;}
    public String accountName {get;set;}
    public String accountId{get;set;}
    public String renderDebug{get;set;}
    public Boolean renderDebugBool{get;set;}
     // the soql without the order and limit
     
    //CR 2286623 : SQl changed by Sonia - Added condition to filter out Inactive accounts
    //private String strTempSoql ='select Id, Name, AKAM_Account_ID__c, Phone, Customer_Tier__c, Support_Level__c, Type from Account where Account_Status__c != \'Lead\''  ;
    private String strTempSoql ='select Id, Name, AKAM_Account_ID__c, Phone, Customer_Tier__c, Support_Level__c, Type from Account where Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\')'  ;
    public Boolean renderNewProductSearch{get;set;}
    public Boolean renderOldProductSearch{get;set;}
  
    //public boolean displayPopup {get; set;}  
  // the current sort direction. defaults to asc
    public String sortOrder {
      get  { if (sortOrder == null) {  sortOrder = 'asc'; } return sortOrder;  }
      set;
    }
 
  // the current field to sort by. defaults to last name
    public String sortField {
      get  { if (sortField == null) {sortField = 'Name'; } return sortField;  }
      set;
    }
 
  // format the soql for display on the visualforce page
    public String debugSoql {
      get { return strSOQL; }
      set;
    }
   //End CR 1685569 
   
   //Shardul 
  
   
    public String SearchFR1C1 {get;set;}
    public String SearchOR1C1 {get;set;}
    public String SearchVR1C1 {get;set;}
    public String SearchVR1C2 {get;set;}
    public String SearchVR1C3 {get;set;}
    public String SearchLR1C3 {get;set;}
    public String SearchFR2C1 {get;set;}
    public String SearchOR2C1 {get;set;}
    public String SearchVR2C1 {get;set;}
    public String SearchVR2C2 {get;set;}
    public String SearchVR2C3 {get;set;}
    public String SearchLR2C3 {get;set;}
/*SAJHA*/
 public String templateId {get;set;}
 
    public String SearchFR3C1 {get;set;}
    public String SearchOR3C1 {get;set;}
    public String SearchVR3C1 {get;set;}
    public String SearchVR3C2 {get;set;}
    public String SearchVR3C3 {get;set;}
    public String SearchLR3C3 {get;set;}

    public String SearchFR4C1 {get;set;}
    public String SearchOR4C1 {get;set;}
    public String SearchVR4C1 {get;set;}
    public String SearchVR4C2 {get;set;}
    public String SearchVR4C3 {get;set;}
    public String SearchLR4C3 {get;set;}

    public String SearchFR5C1 {get;set;}
    public String SearchOR5C1 {get;set;}
    public String SearchVR5C1 {get;set;}
    public String SearchVR5C2 {get;set;}
    public String SearchVR5C3 {get;set;}
    public String SearchLR5C3 {get;set;}

    public String PSearchFR1C1 {get;set;}
    public String PSearchOR1C1 {get;set;}
    public String PSearchVR1C1 {get;set;}
    public String PSearchVR1C2 {get;set;}
    public String PSearchVR1C3 {get;set;}
    public String PSearchLR1C3 {get;set;}

    public String PSearchFR2C1 {get;set;}
    public String PSearchOR2C1 {get;set;}
    public String PSearchVR2C1 {get;set;}
    public String PSearchVR2C2 {get;set;}
    public String PSearchVR2C3 {get;set;}
    public String PSearchLR2C3 {get;set;}

    public String PSearchFR3C1 {get;set;}
    public String PSearchOR3C1 {get;set;}
    public String PSearchVR3C1 {get;set;}
    public String PSearchVR3C2 {get;set;}
    public String PSearchVR3C3 {get;set;}
    public String PSearchLR3C3 {get;set;}
    public String mailchoice {get; set; }
    //CR 819957: Making the Create Mailer Batchable 
    public Boolean createMailerDirect {get; set;}
    public String SQLWhere {get;set;}
    public String PSQLWhere {get;set;}
    
    //Shardul
    public String XML{get;set;}
    public String XML1{get;set;}
// added below 2 lines of code for CR-785460 - 9/3/2010
    public Boolean buttonVisible=false;
    public Boolean VisibleOption {get { return buttonVisible; } set; }
    
    final String contact_type='\'Technical Primary - 24X7\', \'Tech Secondary - 24X7\'';
    public  String choice = 'allContacts';
    public String radioChoice {get; set;}
    public String disableStatus = 'false';
    public String disableProduct = 'true';
    public String disableMailerButton = 'true';
    protected Integer validateAccountFlag = 0;
    Integer validateProductFlag = 0; 
    //Shardul
   public String xmldone = '';
   public String strMailerId;
    //start of changes by janantha CR 1403956: Include help text in the search page that informs the users about 24*7 condition.
    public boolean getRenderHelpText()
    {
        String notificationType = '';
        notificationType = getChoice();
        if(notificationType == 'allContacts')
            return false;
        else if(notificationType == 'selectedContacts')
            return true;
        return false;
    }
    //end of changes by janantha CR 1403956: Include help text in the search page that informs the users about 24*7 condition.

    
    //newToken - this is just to capture the default values for the SI
    public EB_Token__c newtoken = new EB_Token__c();
    
    public EB_Token__c getNewtoken() { 
        return newtoken ;
    }
    
    //start of changes by janantha for CR 1733044
    public static integer firstTime = 0;
    public EB_ProductWrapper products{get;set;}
    public List<EB_ProductWrapper> wrappers{get;set;}
    public List<EB_ProductWrapper> legacyProductList{get;set;}
    
    private Map<String,Set<EB_Product__c>> productModules = new Map<String,Set<EB_Product__c>>();
    private Map<String,Set<EB_Product__c>> moduleSubModules = new Map<String,Set<EB_Product__c>>(); 
    private Set<EB_Product__c> selectedProductList = new Set<EB_Product__c>();
   
    
    private List<EB_Product__c> productsList = new List<EB_Product__c>();
    Set<EB_Product__c> sortedProductList = new Set<EB_Product__c>();
    static integer counter = 0;
    list<String>ChildContractAccountNames=new list<String>();
   // EB_Sort customSort = new EB_Sort();
    public EB_CtrlMailerWizard()
    {
        try
        {
            productModules = new Map<String,Set<EB_Product__c>>();
            moduleSubModules = new Map<String,Set<EB_Product__c>>();
            productsList = new List<EB_Product__c>();
            renderPreviwTemplate=False;
             //Start of changes by samir to exclude reseller accounts.
             
            ContractIdsCustomSettings= EB_ResellerContractId__c.getAll().values();//[select Original_Contract_Id__c,Name from EB_ResellerContractId__c];
            String s;
            for (EB_ResellerContractId__c RCId: ContractIdsCustomSettings)
            {
             s=RCId.Original_Contract_Id__c;
             ResellerContractIds.add(s);
            }
            Date T2day=Date.today();
            resellerparentcontracts=[select Id,Account_Name__c from Merge_Contract_Header__c where Active__c=TRUE and Effective_End_Date__c>=:T2day and Name in :ResellerContractIds];
            
            resellerchildcontracts=[select Id,Account_Name__c from Merge_Contract_Header__c where Active__c=TRUE and Effective_End_Date__c>=:T2day and Parent_Contract__c in :resellerparentcontracts];
            
            for(Merge_Contract_Header__c c:resellerchildcontracts)
            {
            ChildContractAccountNames.add(c.Account_Name__c);
            }
            
            ResellerAccounts=[Select Id,Name from Account where Id in :ChildContractAccountNames];
            
          
            if(EB_UtilApplication.getProperty_DebugSQL() == 'TRUE')
            renderDebugBool=true;
            else
            renderDebugBool=false;
            //CR 1753222 CNotify: 2012 Jul-2012 Setting Account Product Search as the Default
            //Author Vineet
             try
            {
                if(ApexPages.currentPage().getUrl().toLowerCase().contains('eb_vfpmailerwizard1'))

            {
                radioChoice='DefaultSearch';
            }
            }
            catch(Exception e)
            {
                
            }
            if(EB_UtilApplication.getProperty('ProductSearch') == 'Product Catalog')
            {
                renderNewProductSearch = true;
                renderOldProductSearch = false;
            }
            else
            {
                renderNewProductSearch = false;
                renderOldProductSearch = true;
            }
            if(EB_UtilApplication.getProperty('ProductSearch') == 'Product Catalog')
            {
                   
                products = new EB_ProductWrapper();
                Set<EB_Product__c> productModuleIds; 
                Set<EB_Product__c> productSet = new Set<EB_Product__c>();
                Set<EB_Product__c> moduleSet = new Set<EB_Product__c>();
                Set<EB_Product__c> productSubModuleIds;
                Set<EB_Product__c> legacyProducts = new Set<EB_Product__c>();
                        
                for(EB_Product__c product:[select EB_ProductId__c,Product_Name__c,EB_ParentId__c,EB_ProductType__c from EB_Product__c where EB_ProductType__c = 'Module'])
                {
                    productModuleIds = new Set<EB_Product__c>();
                    productSet = new Set<EB_Product__c>();
                    
                    if (productModules.containsKey(product.EB_ParentId__c) == true)
                    {  
                        productModuleIds=productModules.remove(product.EB_ParentId__c);                                      
                    }
                    
                    productSet.addAll(productModuleIds);
                    productSet.add(product);
                   
                    //TODO:remove the below line
                    //if(productModules.size()<50)
                        productModules.put(product.EB_ParentId__c, productSet); 
                                                    
                }
                
                for(EB_Product__c product:[select Id,EB_ProductId__c,Product_Name__c,EB_ParentId__c,EB_ProductType__c from EB_Product__c where EB_ProductType__c = 'Submodule'])
                {
                    productSubModuleIds = new Set<EB_Product__c>();
                    moduleSet = new Set<EB_Product__c>();
                    
                    if (moduleSubModules.containsKey(product.EB_ParentId__c) == true)
                    {
                        productSubModuleIds=moduleSubModules.remove(product.EB_ParentId__c);                               
                    }
                    moduleSet.addAll(productSubModuleIds);
                    moduleSet.add(product);
                    //TODO:remove the below line
                    //if(moduleSubModules.size()<50)
                        moduleSubModules.put(product.EB_ParentId__c, moduleSet);
                    
                }   
               
                productsList = new List<EB_Product__c>();
                for(EB_Product__c product:[select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c from EB_Product__c where EB_ProductType__c = 'Product'])
                { 
                    //if(productsList.size()<50)    
                        productsList.add(product);           
                }
                
                originalList = productsList;
                productsList = new List<EB_Product__c>();
                productsList = (List<EB_Product__c>)getSortedList('Product_Name__c', true);  
               
                getModuleForProduct();
                legacyProductList = new List<EB_ProductWrapper>();
                for(EB_Product__c product:[select Product_Name__c,EB_ProductType__c from EB_Product__c where EB_ProductType__c = 'Case Product'])
                {
                    EB_ProductWrapper legacyWrapper = new EB_ProductWrapper(product);
                    legacyProductList.add(legacyWrapper);           
                }
            }            
        }
        catch(Exception eCons){
                ApexPages.Message myMsg;                
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,eCons.getMessage());              
                ApexPages.addMessage(myMsg);
        } 
//system.assertEquals(ChildContractAccountNames,NULL);      
    }
    
    public List<sObject> getSortedList(String fieldName, Boolean ascending) {
            
        fieldName = fieldName.toUpperCase();       
        return makeSortedList(fieldName, ascending);
    }
    
    public List<sObject> getSortedList(List<sObject> originalList, String fieldName, Boolean ascending) {
        this.originalList = originalList;
        sortedFieldValuesPerFieldName = null;
        return getSortedList(fieldName, ascending);
    }
    

    private void InitializeFieldName(String fieldName) {
        String sObjectID;
        Integer position;
        String fieldValue;
        List<String> sObjectIDs = null;
        Set<String> valuesForFieldSet = null;   
        List<String> valuesForFieldList = null;
        Map<String, List<String>> sObjectIDsPerFieldValues = null;
        
        if (sortedFieldValuesPerFieldName == null) {
            listPosition = new Map<String, Integer>();
            sortedFieldValuesPerFieldName = new Map<String, List<String>>();
            sObjectIDsPerFieldNames = new Map<String, Map<String, List<String>>>();
        }
        
        sObjectIDsPerFieldValues = sObjectIDsPerFieldNames.get(fieldName);
        if (sObjectIDsPerFieldValues == null) {
            sObjectIDsPerFieldValues = new Map<String, List<String>>();
            /*<field name, <sObject id, field value>>*/
            sObjectIDsPerFieldNames.put(fieldName, sObjectIDsPerFieldValues);
        }
        if (!sortedFieldValuesPerFieldName.keySet().contains(fieldName)) {
            
            position = 0;
            valuesForFieldSet = new Set<String>();
            listPosition = new Map<String, Integer>();
            
            for (sObject sObj : originalList) {
                sObjectID = sObj.ID;
                fieldValue = getValue(sObj, fieldName);
                               
                listPosition.put(sObjectID, position++);
                
                valuesForFieldSet.add(fieldValue);
                
                sObjectIDs = sObjectIDsPerFieldValues.get(fieldValue);
                if (sObjectIDs == null) {
                    sObjectIDs = new List<String>();
                    sObjectIDsPerFieldValues.put(fieldValue, sObjectIDs);
                }
                
                sObjectIDs.add(sObjectID);
            }
            
            valuesForFieldList = new List<String>();
            valuesForFieldList.addAll(valuesForFieldSet);
            valuesForFieldList.sort();
            
            sortedFieldValuesPerFieldName.put(fieldName, valuesForFieldList);
            
        }
    }
    private List<sObject> makeSortedList(String fieldName, Boolean ascending) {
        Integer position;
        List<String> sObjectIDs = null;
        List<String> valuesForFieldList = null;      
        InitializeFieldName(fieldName);     
        List<sObject> outputList = originalList.clone();
        outputList.clear();       
        valuesForFieldList = sortedFieldValuesPerFieldName.get(fieldName);
        
        for (String fieldValue : valuesForFieldList) {       
            sObjectIDs = sObjectIDsPerFieldNames.get(fieldName).get(fieldValue);
          
            for (String ID : sObjectIDs) {                
                position = listPosition.get(ID);               
                if ((ascending) || (outputList.size()==0)) {
                    outputList.add(originalList[position]);
                } else {
                    outputList.add(0, originalList[position]);
                }
            }
        }
       
        return outputList;      
    }
    private static String getValue(sObject sObj, String fieldName) {
      
        Integer pieceCount;
        String[] fieldNamePieces;
        
        fieldNamePieces = fieldName.split('\\.');
        pieceCount = fieldNamePieces.size();
        for (Integer i = 0; i < (pieceCount-1); i++) {
            sObj = sObj.getSObject(fieldNamePieces[i]);
        }
        return String.valueOf(sObj.get(fieldNamePieces[pieceCount-1]));
    }
    
    public List<EB_ProductWrapper> getModuleForProduct() 
    {
        try
        {
            wrappers = new List<EB_ProductWrapper>();
            
            Set<EB_Product__c> modulesFor1Product = new Set<EB_Product__c>();
            Set<EB_Product__c> subModulesFor1Module = new Set<EB_Product__c>();
            
            for(EB_Product__c product:productsList)
            {
                EB_ProductWrapper wrapper = new EB_ProductWrapper(product);
                wrappers.add(wrapper);
                //changes for sort
                modulesFor1Product = productModules.get(product.EB_ProductId__c);
               
                if(modulesFor1Product!=null)
                {
                    for(EB_Product__c module:modulesFor1Product)
                    {
                        EB_ProductWrapper wrapper1 = new EB_ProductWrapper(module);
                        wrappers.add(wrapper1);
                        
                        subModulesFor1Module = moduleSubModules.get(module.EB_ProductId__c);
                        
                        if(subModulesFor1Module!=null)
                        {
                            for(EB_Product__c subModule:subModulesFor1Module)
                            {
                                EB_ProductWrapper wrapper2 = new EB_ProductWrapper(subModule);                          
                                wrappers.add(wrapper2);
                            }
                        }
                    }
                }               
            }
            return wrappers;
        }
        catch(Exception eWrapper){
                ApexPages.Message myMsg;                
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,eWrapper.getMessage());              
                ApexPages.addMessage(myMsg);
                return null;
        }
    }
    
    public PageReference getSelectedProducts()
    {   
        selectedProductList.clear();
        
        for(EB_ProductWrapper prdWrapper : wrappers)
        {
            Integer dup=0;
            if(prdWrapper.selected == true)
            {
                selectedProductList.add(prdWrapper.product);
            }
            else
            {
                selectedProductList.remove(prdWrapper.product);
            }
        }
        
        for(EB_ProductWrapper prdWrapper : legacyProductList)
        {
            Integer dup=0;
            if(prdWrapper.selected == true)
            {
                selectedProductList.add(prdWrapper.product);
            }
            else
            {
                selectedProductList.remove(prdWrapper.product);
            }
        }
        //System.assertEquals(selectedProductList,null);
        return null;
    }
      
    //End of changes by janantha for CR 1733044
    
    /* Start of changes 25/3/2011 
    CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation
    */
    /*
        14/11/2011 - Commented the following code for: CR 1378172 CNotify: Superficial Fix, Accepting Issue Details & SI# in the first step of Mailer Creation
                                        Using token and new fields in token for passing default values to mailer.
    // default email templte chosen by user = chosenTemplate
    public String chosenTemplate ;
    public void setDummyMailer(){
        chosenTemplate = dummyMailer.Email_Template__c;

        }
    */
    /* this property decides whether the Default Email Template feature should be visible on the UI or not */
    public Boolean showDefaultTemplate { 
    get{
        if (EB_UtilApplication.getProperty('DefaultEmailTemplate')=='Visible'){
        showDefaultTemplate = true;
        }
        else{
        showDefaultTemplate = false;
        }
        return showDefaultTemplate;
        }
         set; }
    /* End of changes 25/3/2011 
    CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation
    */
    
    /*
    Start of changes 25/3/2011
    CR 1029711 CNotify: Standardize Action Poller Content, Create Mailer
    */
    public String StatusMessage { get; set; }
    // function returns to the page EB_VfpNotifyUsersAboutMailerCreation whether mailer is of type Single Email or Mass Email
    public String MailerType { 
        get{
        MailerType = ApexPages.currentPage().getParameters().get('type');
        return MailerType;
        }
         set;
        }
    // function returns to the page EB_VfpNotifyUsersAboutMailerCreation whether mailer is of type Service Incident/General Incident
    public String MailerIncidentType { get{
         String service_Incident = ApexPages.currentPage().getParameters().get('incident_type');
         if(service_Incident == 'true'){
            MailerIncidentType = 'Service Incident';
         }
         else{
            MailerIncidentType = 'General Incident';
         }
         return MailerIncidentType;
        } 
        set; 
        }
    /*
    End of changes 25/3/2011
    CR 1029711 CNotify: Standardize Action Poller Content, Create Mailer
    */

    public String getdisableProduct()
    {
        return disableProduct;
    }
    public String getdisableMailerButton()
    {
        return disableMailerButton;
    }

    public void setdisableProduct(String p)
    {
        disableProduct = p;
    }
    public void setdisableMailerButton(String p)
    {
        disableMailerButton= p;
    }
    public void enableMailerButton()
    {
        disableMailerButton= 'false';
    }
    
    public void enableProduct()
    {
        editFlagProduct = true;
        disableProduct = 'false';
    }
 // added below code for CR-785460 - 9/3/2010
    public void enableButton()
    {
        buttonVisible = true;
    }
 // added below 2 lines of code for CR-785460 - 9/3/2010
    public void disableButton()
    {
        buttonVisible = false;
    }
    
    public String getdisableStatus()
    {
        return disableStatus;
    }
    
    public void setdisableStatus(String status)
    {
        disableStatus = status;
    }
    
    public void enable()
    {
        editFlagAccount = true;
        disableStatus = 'false';
    }  
        
   public String getchoice()
    {
        return choice;
    }
    
    public void setchoice(String option)
    {
        choice = option;
    }
    /* ========================================================================
    descripion: this function returns the list of options for the pick list in the first visualforce page
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
        2. Modified to take values from Custom settings
    code review:
    ======================================================================== */
    public List<SelectOption> getItems() 
    {
                List<SelectOption> options = new List<SelectOption>(); 
        for (EBCS_NotificationType__c objNotificationType : EBCS_NotificationType__c.getAll().values()){
            options.add(new SelectOption(objNotificationType.Name_API__c, objNotificationType.Name));
            
        }
        
        return options;
    }
    
    public List<SelectOption> getMailItems() 
    {
    /* Description: function to get the Type of mail functionality that user chooses
     Author : Sharath
     */
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('singleMail','Single Mails')); 
        options.add(new SelectOption('massMail','Mass mails')); 
        return options; 
    }
    
    public List<SelectOption> getRadioItems() 
    {
    /*
    Author: Sharath
    Description: This function retrieves values for search criteria from the custom settings and returns the user selected value
    */
        List<SelectOption> options = new List<SelectOption>(); 
        for (EBCS_SearchCriteria__c objSearchCriteria : EBCS_SearchCriteria__c.getAll().values()){
            options.add(new SelectOption(objSearchCriteria.Value__c, objSearchCriteria.Name));
        }

        return options; 
    }

  
    public ApexPages.StandardSetController objController
    {
        get{
            if(objController == null){
                try{
                    objController = new ApexPages.StandardSetController(Database.getQueryLocator(strSOQL));
                    objController.setPageSize(Integer.valueof(EB_UtilApplication.getProperty('RowsPerPage')));
                }
                catch(Exception e){
                    ApexPages.Message myMsg;
                    myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'No matching records were found ');
                    ApexPages.addMessage(myMsg);
                    throw e;
                }
            }
            return objController;
        }
        set;
    }

    public Boolean hasNext {
        get {
        // indicates whether there are more records after the current page set.
            if(objController != null){
                return objController.getHasNext();
            }
            else 
                return null;
        }
        set;
    }
 
 
    public Boolean hasPrevious {
        get {
           // indicates whether there are more records before the current page set.
           if(objController != null){
                return objController.getHasPrevious();
           }
           else
                return null;
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
   
    /* ========================================================================
    descripion: this function forms the where clause of the SOQL for the Account search.
     It is called on the click of a Build Search or Next on the VisualForce Search Page 
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    ======================================================================== */

    public void formSQLWhere()
    {
        String test='';
        XML='';

        searchAccount.clearSearchCriteria();
        if(SearchFR1C1!='' && SearchOR1C1!='' && SearchVR1C1!=''){
            addAccountSearchCriteria(SearchFR1C1, SearchOR1C1, SearchVR1C1, SearchVR1C2, SearchVR1C3, SearchLR1C3);
            addAccountSearchCriteria(SearchFR2C1, SearchOR2C1, SearchVR2C1, SearchVR2C2, SearchVR2C3, SearchLR2C3);
            addAccountSearchCriteria(SearchFR3C1, SearchOR3C1, SearchVR3C1, SearchVR3C2, SearchVR3C3, SearchLR3C3);
            addAccountSearchCriteria(SearchFR4C1, SearchOR4C1, SearchVR4C1, SearchVR4C2, SearchVR4C3, SearchLR4C3);
            addAccountSearchCriteria(SearchFR5C1, SearchOR5C1, SearchVR5C1, SearchVR5C2, SearchVR5C3, SearchLR5C3);
            
            SQLWhere = '(' + searchAccount.buildWhereClause() + ' )';
            
            //Start of changes CR 1816825, SHARDUL
            XML = searchAccount.Createxml(); 
            //Start of changes CR 1816825, SHARDUL
            test=EB_UtilApplication.getProperty_DebugSQL();
               if(test=='TRUE'){
                    searchAccount.setTableName('Account');
                    searchAccount.buildSelectClause();
                    debugAccountSQL=searchAccount.buildSQL(SQLWhere); 
                }
        }  
        else{
            SQLWhere='';  
           
        }
        formPSQLWhere();  
        XML = '<Search>'+XML+'</Search>';
        
    }  
    
    public String getDataType(String APIName){
    //Author: Sharath
    //Description : Gets the datatype String/Numeric from the custom setting AccountSearchFields, so that it is appropriately handled by EB_SoqlBuilder/EnhancedSoqlBuilder
    String cust_setting;
    for (EBCS_AccountSearchFields__c objAccSearchFields : EBCS_AccountSearchFields__c.getAll().values()){
        if(objAccSearchFields.Name_API__c== APIName){
              cust_setting=objAccSearchFields.Name;
              break;
              }
      }
      EBCS_AccountSearchFields__c objApp = EBCS_AccountSearchFields__c.getInstance(cust_setting);
      return objApp.EB_DataType__c;
      
    }  
    
    public String getPDataType(String APIName){
    //Author: Sharath
    //Description : Gets the datatype String/Numeric from the custom setting ProductSearchFields, so that it is appropriately handled by EB_SoqlBuilder/EnhancedSoqlBuilder
    String cust_setting;
    for (EBCS_ProductSearchFields__c objProdSearchFields : EBCS_ProductSearchFields__c.getAll().values()){
        if(objProdSearchFields.Name_API__c== APIName){
              cust_setting=objProdSearchFields.Name;
              break;
              }
      }
      EBCS_ProductSearchFields__c objProd = EBCS_ProductSearchFields__c.getInstance(cust_setting);
      return objProd.EB_Data_Type__c;
      
    }   
    
    /* ========================================================================
    descripion: this function forms the where clause of the SOQL for the Product search.
     It is called on the click of a Build Search or Next on the VisualForce Search Page 
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    Modified on: 06/25/2012 CR 1733044 CNotify: Enhancing the existing Account Product Search to Incorporate New Prod Catg Search
    code review:
    ======================================================================== */

    public void formPSQLWhere()
    {
        String debugsql='';
        XML1 = '';
        integer selectedProductSize = 0;
        integer i = 0;
        //start of changes by janantha for CR 1733044
        if(EB_UtilApplication.getProperty('ProductSearch')!='Product Catalog')
        {   
        //end of changes by janantha for CR 1733044
            
    
            searchProduct.clearSearchCriteria();
            if(PSearchFR1C1!='' && PSearchOR1C1!='' && PSearchVR1C1!=''){
                addProductSearchCriteria(PSearchFR1C1, PSearchOR1C1, PSearchVR1C1, PSearchVR1C2, PSearchVR1C3, PSearchLR1C3);
                addProductSearchCriteria(PSearchFR2C1, PSearchOR2C1, PSearchVR2C1, PSearchVR2C2, PSearchVR2C3, PSearchLR2C3);
                addProductSearchCriteria(PSearchFR3C1, PSearchOR3C1, PSearchVR3C1, PSearchVR3C2, PSearchVR3C3, PSearchLR3C3);
    
                PSQLWhere = '(' + searchProduct.buildWhereClause() + ' )';
                
                
                //Start of changes CR 1816825, SHARDUL
                XML1 = searchProduct.Createxml(); 
                XML= XML+XML1;
                //End of changes CR 1816825, SHARDUL
                
                debugsql=EB_UtilApplication.getProperty_DebugSQL();
                if(debugsql=='TRUE'){
                    searchProduct.setTableName('EB_AccountProductMap__c');
                    searchProduct.buildSelectClause();
                    debugProductSQL=searchProduct.buildSQL(PSQLWhere);
                } 
            }
            else{
                PSQLWhere='';  
            }
        }
        //start of changes by janantha for CR 1733044
        else
        {
            searchProduct.clearSearchCriteria();
            getSelectedProducts();
            
            selectedProductSize = selectedProductList.size();
            if(selectedProductSize>0)
            {
                for(EB_Product__c selectedProduct:selectedProductList)
                {
                    if(selectedProduct.EB_ProductType__c == 'Case Product')
                    {
                        if(selectedProductSize>=1 && i<(selectedProductSize))
                        {                       
                            addProductSearchCriteria(' (EB_Product__c', '=', selectedProduct.Product_Name__c, '', '', 'AND');
                            addProductSearchCriteria('EB_ProductType__c', '=', selectedProduct.EB_ProductType__c , '', '', ' ) OR');                      
                            PSQLWhere = '(' + searchProduct.buildWhereClause() + ')';
                            
                            debugsql=EB_UtilApplication.getProperty_DebugSQL();
                            if(debugsql=='TRUE'){
                                searchProduct.setTableName('EB_EntitledAccountProduct__c');
                                searchProduct.buildSelectClause();
                                debugProductSQL=searchProduct.buildSQL(PSQLWhere);
                            } 
                        }
                        else
                        {               
                            addProductSearchCriteria(' (EB_Product__c', '=', selectedProduct.Product_Name__c, '', '', 'AND');
                            addProductSearchCriteria('EB_ProductType__c', '=', selectedProduct.EB_ProductType__c , '', '', ' ) ');
                            
                            PSQLWhere = '(' + searchProduct.buildWhereClause() +  ')';
                          
                            debugsql=EB_UtilApplication.getProperty_DebugSQL();
                            if(debugsql=='TRUE'){
                                searchProduct.setTableName('EB_EntitledAccountProduct__c');
                                searchProduct.buildSelectClause();
                                debugProductSQL=searchProduct.buildSQL(PSQLWhere);
                            }
                        }
                    }
                    else
                    {
                        
                        if(selectedProductSize>=1 && i<(selectedProductSize))
                        {
                            addProductSearchCriteria(' (EB_ProductId__c', '=', selectedProduct.EB_ProductId__c , '', '', 'AND');
                            addProductSearchCriteria('EB_ProductType__c', '=', selectedProduct.EB_ProductType__c , '', '', ' ) OR');
                            PSQLWhere = '(' + searchProduct.buildWhereClause() + ' )';
                          
                            debugsql=EB_UtilApplication.getProperty_DebugSQL();
                            if(debugsql=='TRUE'){
                                searchProduct.setTableName('EB_EntitledAccountProduct__c');
                                searchProduct.buildSelectClause();
                                debugProductSQL=searchProduct.buildSQL(PSQLWhere);
                            }
                        }
                        else
                        {                   
                            addProductSearchCriteria(' (EB_ProductId__c', '=', selectedProduct.EB_ProductId__c , '', '', 'AND');
                            addProductSearchCriteria('EB_ProductType__c', '=', selectedProduct.EB_ProductType__c, '', '', ' ) ');
                            PSQLWhere = '(' + searchProduct.buildWhereClause() + ')';
                            
                            debugsql=EB_UtilApplication.getProperty_DebugSQL();
                            if(debugsql=='TRUE'){
                                searchProduct.setTableName('EB_EntitledAccountProduct__c');
                                searchProduct.buildSelectClause();
                                debugProductSQL=searchProduct.buildSQL(PSQLWhere);
                            }                       
                        }
                    }
                    i++;                            
                }
            }
            else
            {
                PSQLWhere='';  
              
            }
        }
        //end of changes by janantha for CR 1733044
    }

    /* ========================================================================
    descripion: this function validates the Account search criteria.
     It is called on the click of a Validate Account or Next on the VisualForce Search Page 
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
        2. 09/14/2010 - CR 794793: Implementing code review findings - Made this function virtual, so that it can be overriden by child class
    
    ======================================================================== */

    public virtual PageReference validateAccount()
    {
        Account a;
        ApexPages.Message myMsg;
        validateAccountFlag = 0;
        
        if(SQLWhere != null && SQLWhere != ''){

            searchAccount.setTableName('Account');
            String selectClauseAccount = searchAccount.buildSelectClause();
            finalSOQLAccount = searchAccount.buildSQL(SQLWhere);
            finalSOQLAccount = finalSOQLAccount + ' limit 1';
            try{
                a = Database.query(finalSOQLAccount);
                disableStatus = 'true';
            }
            catch(Exception e){
                validateAccountFlag = 1;
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()+' Error:Account '+finalSOQLAccount);              
                ApexPages.addMessage(myMsg);
            }
        }
        if(EB_UtilApplication.getProperty('ProductSearch')!='Product Catalog')
        { 
            validateProduct();
        }
        
        return null;
    }    
    
    /* ========================================================================
    descripion: this function validates the Product search criteria.
     It is called on the click of a Validate Product or Next on the VisualForce Search Page 
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    Modified on 06/25/2012 CR 1733044 CNotify: Enhancing the existing Account Product Search to Incorporate New Prod Catg Search
    code review:
    ======================================================================== */
    public PageReference validateProduct()
    {
        EB_AccountProductMap__c p;
        EB_EntitledAccountProduct__c p1;
        ApexPages.Message myMsg;
        validateProductFlag = 0;
        //start of changes by janantha for CR 1733044
        if(EB_UtilApplication.getProperty('ProductSearch')!='Product Catalog')
        {   
        //end of changes by janantha for CR 1733044
            if(PSQLWhere != null && PSQLWhere != ''){
                searchProduct.setTableName('EB_AccountProductMap__c');
                String selectClauseProduct = searchProduct.buildSelectClause();
                finalSOQLProduct = searchProduct.buildSQL(PSQLWhere);
                finalSOQLProduct = finalSOQLProduct + ' limit 1';
                try{
                    p = Database.query(finalSOQLProduct);
                    disableProduct = 'true';
                }
                catch(Exception e){
                    validateProductFlag = 1;
                    myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Error in the Product search criteria'+e.getMessage());
                    ApexPages.addMessage(myMsg);
                }
            }
        }
        else
        {
            if(PSQLWhere != null && PSQLWhere != ''){
                searchProduct.setTableName('EB_EntitledAccountProduct__c');
                String selectClauseProduct = searchProduct.buildSelectClause();
                finalSOQLProduct = searchProduct.buildSQL(PSQLWhere);
                finalSOQLProduct = finalSOQLProduct + ' limit 1';
                try{
                    p1 = Database.query(finalSOQLProduct);
                    disableProduct = 'true';
                }
                catch(Exception e){
                    validateProductFlag = 1;
                    myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Error in the Product search criteria'+e.getMessage());
                    ApexPages.addMessage(myMsg);
                }
            }
        }

        return null;
    }

/* ========================================================================
    descripion: this function returns the search fields for Account.
    The fields are stored in a custom setting.
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    ======================================================================== */
    public List<SelectOption> getPickListItems() 
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-Select-'));
        for (EBCS_AccountSearchFields__c objAccSearchFields : EBCS_AccountSearchFields__c.getAll().values()){
            options.add(new SelectOption(objAccSearchFields.Name_API__c, objAccSearchFields.Name));
                      
        }
        return options;
    }


    /* ========================================================================
    descripion: this function returns the list of connectors.
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    ======================================================================== */
    public List<SelectOption> getLogicalOperators() 
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-Select-'));
        options.add(new SelectOption(') AND (','AND'));
        options.add(new SelectOption('OR','OR'));
        return options;
    }
    
    /* ========================================================================
    descripion: this function returns the list of logical operators to 
    be used for forming the search criteria.
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    ======================================================================== */
    public List<SelectOption> getOperators() 
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('=','Equals'));
        options.add(new SelectOption('!=','Not Equals'));
        options.add(new SelectOption('%','Contains'));
        return options;
    }
    
    /* ========================================================================
    descripion: this function returns the search fields for Product.
    The fields are stored in a custom setting.
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    ======================================================================== */
    public List<SelectOption> getPickListItemsProduct() 
    {
        List<SelectOption> options = new List<SelectOption>();

        options.add(new SelectOption('','-Select-'));
        for (EBCS_ProductSearchFields__c objProdSearchFields : EBCS_ProductSearchFields__c.getAll().values()){
            options.add(new SelectOption(objProdSearchFields.Name_API__c, objProdSearchFields.Name));
        }

        return options;
    }
    
    /* ========================================================================
    descripion:This function clears the Account search criteria
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    ======================================================================== */
    public void clearSearch()
    {
        SQLWhere = '';
    }
    
    /* ========================================================================
    descripion:This function clears the Product search criteria
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    ======================================================================== */
    public void clearProductSearch()
    {
        PSQLWhere = '';
    }
    
    /* ========================================================================
    descripion:This function reads the values of the search field, search operator, 
    search values and forms the search criteria for Account
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    ======================================================================== */  
    public void addAccountSearchCriteria(String strField, String strOp, String strValue1, String strValue2, String strValue3, String strLOp)
    {
        if ((strField != '') && (strOp != ''))
            {
                if (strValue1 != '')
                    {
                        if (strValue2 != '')
                            {
                                if (strValue3 != '')
                                    {
                                        searchAccount.addSearchCriteria(strField, strOp, strValue1, 'OR',getDataType(strField));
                                        searchAccount.addSearchCriteria(strField, strOp, strValue2, 'OR',getDataType(strField));
                                        searchAccount.addSearchCriteria(strField, strOp, strValue3, strLOp,getDataType(strField));
                                    }
                                else{
                                        searchAccount.addSearchCriteria(strField, strOp, strValue1, 'OR',getDataType(strField));
                                        searchAccount.addSearchCriteria(strField, strOp, strValue2, strLOp,getDataType(strField));
                                    }
                            }
                        else{
                                searchAccount.addSearchCriteria(strField, strOp, strValue1, strLOp,getDataType(strField));
                            }
                }
            }
    }

    /* ========================================================================
    descripion:This function reads the values of the search field, search operator, 
    search values and forms the search criteria for Product
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    ======================================================================== */
    public void addProductSearchCriteria(String strField, String strOp, String strValue1, String strValue2, String strValue3, String strLOp){
        if ((strField != '') && (strOp != '')){
            if (strValue1 != ''){
                if (strValue2 != ''){
                    if (strValue3 != ''){
                        searchProduct.addSearchCriteria(strField, strOp, strValue1, 'OR',getPDataType(strField));
                        searchProduct.addSearchCriteria(strField, strOp, strValue2, 'OR',getPDataType(strField));
                        searchProduct.addSearchCriteria(strField, strOp, strValue3, strLOp,getPDataType(strField));
                    }
                    else{
                        searchProduct.addSearchCriteria(strField, strOp, strValue1, 'OR',getPDataType(strField));
                        searchProduct.addSearchCriteria(strField, strOp, strValue2, strLOp,getPDataType(strField));
                    }
                }
                else{
                    searchProduct.addSearchCriteria(strField, strOp, strValue1, strLOp,getPDataType(strField));
                }
            }
        }
    }
    
    public void setSOQL(String str)
    {
         /*
            Author: Vineet
            CR: 1685569
            Description: Setting my Variables OriginalSOQL and strTempSoql
         */
        strSOQL=strOriginalSOQL=str;
        
        strTempSOQL = str.split('limit')[0];
    }
   
   /*Overloading setSOQL method to accept 2 parameters
    Author:Samir Jha
    */
     public void setSOQL(String str,String str1)
    {
         /*
            Author: Vineet
            CR: 1685569
            Description: Setting my Variables OriginalSOQL and strTempSoql
         */
        strSOQL=strOriginalSOQL=str;
        strOriginalResellerSOQL=str1;
        strTempSOQL = str.split('limit')[0];
        if(str1!=Null)
        {
        getOmittedResellerAccounts(strOriginalResellerSOQL);
        }
    }
    
     /*Overloading setSOQL method to accept 2 parameters
    Author:Samir Jha
    */
    public void getOmittedResellerAccounts(String str)
    {
    
    ResellerAccountsOmitted=Database.query(str);
   
    }
    
    public List<EB_AccountWrapper> getAccounts()
    {
    /* ========================================================================
    descripion: this function returns list of Account records as per User's search criteria.It looks to the database.getQueryLocator(soql) to provide the set of records.
    It then adds the records into a list and returns the list.It also explicitly sets the check box to true when user moves from one set of records to next/previous set of records using pagination
    created by: Sharath K
    test class & test method:   
    modifications: date, by, description
        1. 6/-/2010 :created
        2. 6/23/2010: removed filtering criteria from getAccounts(). the filtering now happens in page2() and EB_UniqAccConList class.
        3. 9/9/2010: removed few lines of code as GetSelected function was modified
        4. 7/12/2013: CR 2286623: Sonia - Added filter on Account to remove all Inactive accounts
    code review:
    ======================================================================== */
        ApexPages.Message myMsg;
        accountList.clear();
        if(strSOQL==null || strSOQL==''){
            //CR 2286623 : SQl changed by Sonia - Added condition to filter out Inactive accounts
            //strSOQL='select Id, Name, AKAM_Account_ID__c, Phone, Customer_Tier__c, Support_Level__c, Type from Account where Account_Status__c != \'Lead\' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
            strSOQL='select Id, Name, AKAM_Account_ID__c, Phone, Customer_Tier__c, Support_Level__c, Type from Account where Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\') limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
        }
        try{
        for(Account a : (List<Account>)objController.getRecords()){
            accountList.add(new EB_AccountWrapper(a));
        } 
        }
        catch(QueryException q){
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,q.getMessage());
            ApexPages.addMessage(myMsg);
        }
        catch(Exception e){
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());
            ApexPages.addMessage(myMsg);
        }
        
    return accountList;
    }

   
    public PageReference getSelected()
    {   
    /* ========================================================================
    descripion: this function populates list of Account records that are selcted on the UI by the users.
    created by: Sharath K
    test class & test method:   
    modifications: date, by, description
        1. 6/-/2010 :created
        2. 9/9/2010: CR 791832:Customer Notification Accounts Pagination & Selection Fix - revamped whole function, changed logic to accomodate new object EB_Selected_Accounts
        
    code review:
    ======================================================================== */
        //CR 791832 - clear selection each time before you add to the temporary Set selectMore
        selectMore.clear();
        for(EB_AccountWrapper accwrapper : accountList){
            Integer dup=0;
            if(accwrapper.selected == true){
            selectMore.add(accwrapper.acc);
            }
            else{
            selectMore.remove(accwrapper.acc);
            }
        }
        return null;
    }
    
   

/*
Author: Sharath K
Created: 9/9/2010
Functionality: function gets all the selected accounts from UI & adds them to the custom object EB_SelectedAccounts__c. Created for CR 791832
*/    
    public PageReference getAdded()
    {
        //CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process - This is for AccountID/CP Code search
        String parentToken= ApexPages.currentPage().getParameters().get('token');
    // get all selected accounts from UI
    getSelected();
    List<EB_SelectedAccounts__c> insertRecs = new List<EB_SelectedAccounts__c>();

    for(Account listAcc:selectMore){
         EB_SelectedAccounts__c newRecord = new EB_SelectedAccounts__c();
        newRecord.EB_Account__c= listAcc.Id;
        //newRecord.Name=listAcc.Name;
        newRecord.AKAM_Account_Id__c=listAcc.AKAM_Account_Id__c;
        if(radioChoice=='DefaultSearch'){
        newRecord.EB_ParentToken__c= token;
        newRecord.EB_Unique_Row_Id__c= listAcc.AKAM_Account_Id__c + token;
        }
        //CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process - This is for AccountID/CP Code search
        else{
            newRecord.EB_ParentToken__c= parentToken;
            newRecord.EB_Unique_Row_Id__c= listAcc.AKAM_Account_Id__c + parentToken;
        }

        insertRecs.add(newRecord);
    }
    //insert acounts into custom object
    try{
        //upsert based on exteranl Id - EB_Unique_Row_Id__c. This way duplicates are handled. 'false' parameter is for OptAllOrNone i.e. if one record's upsert fails, carry on trying for the next record. (partial success is allowed)
        database.upsert(insertRecs,EB_SelectedAccounts__c.EB_Unique_Row_Id__c,false);
        }
    catch(Exception e){
        //ignore the excpetion 
        //system.assertEquals(e.getMessage(), null);
        }
    enableMailerButton(); 
    return null;
}
    
     //CR 1685605 -  CNotify: 2012 Jun-2012 Select All Across Pages in Customer Selection user interface
        /*
        Author: Vineet S    
        CR: 1685605 
        Functionality: function gets all the  accounts from UI & adds them to the custom object EB_SelectedAccounts__c. Created for CR 1685605
        */  
        public PageReference addAllAccounts() {
               
        String parentToken= ApexPages.currentPage().getParameters().get('token');
    List<EB_SelectedAccounts__c> insertRecs = new List<EB_SelectedAccounts__c>();

    for(Account listAcc:Database.query(strOriginalSOQL)){
         EB_SelectedAccounts__c newRecord = new EB_SelectedAccounts__c();
        newRecord.EB_Account__c= listAcc.Id;
        //newRecord.Name=listAcc.Name;
        newRecord.AKAM_Account_Id__c=listAcc.AKAM_Account_Id__c;
        if(radioChoice=='DefaultSearch'){
        newRecord.EB_ParentToken__c= token;
        newRecord.EB_Unique_Row_Id__c= listAcc.AKAM_Account_Id__c + token;
        }
        else{
            newRecord.EB_ParentToken__c= parentToken;
            newRecord.EB_Unique_Row_Id__c= listAcc.AKAM_Account_Id__c + parentToken;
        }

        insertRecs.add(newRecord);
    }
    //insert acounts into custom object
    try{
        //upsert based on exteranl Id - EB_Unique_Row_Id__c. This way duplicates are handled. 'false' parameter is for OptAllOrNone i.e. if one record's upsert fails, carry on trying for the next record. (partial success is allowed)
        database.upsert(insertRecs,EB_SelectedAccounts__c.EB_Unique_Row_Id__c,false);
        }
    catch(Exception e){
        //ignore the excpetion 
        //system.assertEquals(e.getMessage(), null);
        ApexPages.Message myMsg;
        myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());
        ApexPages.addMessage(myMsg);
        throw e;
            
        }
    enableMailerButton(); 
    return null;
       
    }
    //End CR - 1685605
    
    /* ========================================================================
    descripion:This function creates a new mailer, adds the selected accounts 
    and all the contacts for the corresponding accounts.
    created by:Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :5/-/2010
        2. 9/9/2010: CR 791832:Customer Notification Accounts Pagination & Selection Fix - clear the custom object EB_SelectedAccounts__c after creating mailer & changed soqls
    code review:
        3. 10/1/2010: CR 819957: Making the Create Mailer Batchable - remove the Mass mail functionality from this method & implement batchable logic here
        4. 3/25/2011 - CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation
        5. 9/26/2011 - CR 1302518 Adding Email !='' and Email !=null conditions in all Contact queries.
                6. 14/11/2011 - CR 1378172 CNotify: Superficial Fix, Accepting Issue Details & SI# in the first step of Mailer Creation
    ======================================================================== */

    public PageReference CreateMailer()
    {
        String strReturnURL= 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/';
        PageReference pageRef;
        List<EB_AkaMAccount__c> insertAkamAccount = new List<EB_AkaMAccount__c>();
        List<String> akamAccountList = new List<String>();
        EB_AkaMAccount__c akamAccount;
         List<EB_AkaMContact__c> insertAkamContact = new List<EB_AkaMContact__c>();
        List<EB_SelectedAccounts__c> updateList = new List<EB_SelectedAccounts__c>();
        EB_AkaMContact__c akamContact;
        EB_AkaMailer__c Mailer = new EB_AkaMailer__c();
        Map<String, String> objAccountAkamAccountMap = new Map<String, String>();
        ApexPages.Message myMsg;
        String templateId;
        String mail_type = ApexPages.currentPage().getParameters().get('type');
        String contacts_choice = ApexPages.currentPage().getParameters().get('choice');
        String parentToken = ApexPages.currentPage().getParameters().get('token');
        String ContactQuery;
        EB_Token__c tokenParameters;
        
        //3/25/2011 - CR 845804 - initialize the default email template
        if(token=='' || token==null ){
            token=parentToken;
        }
    
            try{
            String uToken= EBAccountDetails__c.getValues('AkamaiAsset').AccountAkamId__c.trim() + token;
            List<EB_SelectedAccounts__c> sAcc =[Select Id from EB_SelectedAccounts__c where EB_Unique_Row_Id__c=:uToken limit 1];
            if(sAcc.size() == 0)
            {
                EB_SelectedAccounts__c varSelectedAccountPerm = new EB_SelectedAccounts__c();
                varSelectedAccountPerm.EB_Account__c = EBAccountDetails__c.getValues('AkamaiAsset').EBAccountId__c.trim();
                varSelectedAccountPerm.AKAM_Account_Id__c = EBAccountDetails__c.getValues('AkamaiAsset').AccountAkamId__c.trim();
                varSelectedAccountPerm.EB_ParentToken__c = token;
                varSelectedAccountPerm.EB_Unique_Row_Id__c = EBAccountDetails__c.getValues('AkamaiAsset').AccountAkamId__c.trim() + token;
                insert varSelectedAccountPerm;
            }
          
        // CR 1378172 - retrieving the default values from Token
        tokenParameters = [select EB_ChatterNotification__c,EB_TokenEmailTemplate__c,EB_TokenAdditionalReason__c,EB_TokenIssueReason__c,EB_TokenImpactedProduct__c,EB_TokenImpactedRegion__c,EB_TokenEndDate__c,EB_TokenStartDate__c,EB_TokenSINumber__c from EB_Token__c where Id =:token];
        if(mailchoice=='singleMail' || mail_type=='single'){
        //CR 819957: Making the Create Mailer Batchable - create mailer using selected accounts for single mail
        createMailerDirect=false;
        //new code 07/21/2010 - logic to check if Default Template ID is Valid
        //create a new mailer

        try{
            templateId=[select Id from EB_EmailTemplate__c where  EB_IsDefault__c=true and EB_NotificationType__r.Name='Single Email'][0].Id;
            Mailer.Email_Template__c=templateId;
            }
         catch (Exception e){
                EB_MailerException__c excp = new EB_MailerException__c();
                excp.Exception_Message__c=' The default email template is INVALID. Please set a valid template ID as DEFAULT';
                excp.EB_Mailer__c=Mailer.Id;
                excp.EB_Type__c = 'Warning';
                insert(excp);
            }
        Mailer.EB_Status__c = 'New';
        // CR 1378172 - passing default values to mailer from 1st page.
        Mailer.EB_ImpactedAkamaiProduct__c = tokenParameters.EB_TokenImpactedProduct__c;
        Mailer.EB_IssueStartDateTime__c = tokenParameters.EB_TokenStartDate__c;
        Mailer.EB_IssueEndDateTime__c = tokenParameters.EB_TokenEndDate__c;
        Mailer.EB_ImpactedRegion__c = tokenParameters.EB_TokenImpactedRegion__c;
        Mailer.EB_IssueReason__c = tokenParameters.EB_TokenIssueReason__c;
        Mailer.EB_AdditionalIssueDescription__c = tokenParameters.EB_TokenAdditionalReason__c;
        Mailer.EB_SINumber__c = tokenParameters.EB_TokenSINumber__c;
        /*  CR 1367210 21/1/2011 - Chatter notification for internal account teams*/
        Mailer.EB_ChatterNotification__c = tokenParameters.EB_ChatterNotification__c;
        Mailer.EB_Type__c='Single Email';
        //Start of changes CR 1816825, SHARDUL
        Mailer.Search_Criteria__c=XML;
        //End of changes CR 1816825, SHARDUL
        // 3/25/2011 - CR 845804 chosenTemplate = 'null' when we navigate to accountID search page
        if(tokenParameters.EB_TokenEmailTemplate__c != null){
                        Mailer.Email_Template__c = tokenParameters.EB_TokenEmailTemplate__c;
                }
         //Start of Changes by Samir for AT&T 
       // system.assertEquals(ResellerAccountsOmitted,NULL);
         
         
         




        //End of changes by Samir for AT&T

          /*
    Start of changes - nov 09 2010 
    By- Sharath
    Description - contacts_choice is null when User uses Account/Product Search. But choice defaults to 'allContacts' when user moves to AccountID search page, irrespective of whether contacts_choice='allContacts' or 'selectedContacts'.
    hence removing the condition if(choice=='allContacts' || contacts_choice=='allContacts' ), since it was always became true
    */
        if(contacts_choice!=null){
            if(contacts_choice=='allContacts'){
                Mailer.EB_IsServiceIncidentNotification__c=false;
            }
            else{
                Mailer.EB_IsServiceIncidentNotification__c=true;
            }
        }
        else{
            if(choice=='allContacts'){
                Mailer.EB_IsServiceIncidentNotification__c=false;
            }
            else{
                Mailer.EB_IsServiceIncidentNotification__c = true;
            }
        }
        /*End of changes - nov 09 2010 */
        insert Mailer;
        
        //CR 819957: Making the Create Mailer Batchable - call the batchable class EB_BatchableCreateMailer and pass necessary parameters
        if(choice=='selectedContacts' || contacts_choice=='selectedContacts'){
            //CR 851546 changes- Nov 3rd 2010 - Removing HasOptedOutOfEmail filter from where clause of the SOQL - only for Service Incidents
        //CR 2611929 - Added Email Bounce to Query
        ContactQuery='SELECT id, EmailBouncedReason , Account.Id, Account.Name, lastname, firstname, Contact_Type__c, Phone, Email FROM Contact WHERE (Contact_Type__c INCLUDES (\'Technical Primary - 24X7\', \'Tech Secondary - 24X7\')) AND (AccountId IN (select EB_Account__c from EB_SelectedAccounts__c where EB_ParentToken__c = \'' + token + '\' AND EB_IsProcessed__c=false)) AND (Email != \'\' AND Email != null) order by AccountId' ;
        Id batchinstanceid1 = Database.executeBatch(new EB_BatchableCreateMailer(ContactQuery,Mailer,token,createMailerDirect,null,ResellerAccountsOmitted), 1000);
        }
        else{
            //CR 2611929 - Added Email Bounce to Query
            ContactQuery= 'SELECT id, EmailBouncedReason , Account.Id, Account.Name, lastname, firstname, Contact_Type__c, Phone, Email FROM Contact WHERE (AccountId IN (select EB_Account__c from EB_SelectedAccounts__c where EB_ParentToken__c = \'' + token + '\' AND EB_IsProcessed__c=false)) AND (HasOptedOutOfEmail=false) AND (Email != \'\' AND Email != null) order by AccountId' ;
            Id batchinstanceid1 = Database.executeBatch(new EB_BatchableCreateMailer(ContactQuery,Mailer,token,createMailerDirect,null,ResellerAccountsOmitted), 1000);
        }
    }
    // CR 819957: Making the Create Mailer Batchable - removing MASS mail functionality from this method. Mass mails shall be created directly without user having to Select Accounts. Hence commenting below code
     // 03/29/2011 - Sharath:  - removing commented code
     //CR 1029711 - pass extra parameters to the page "EB_VfpNotifyUsersAboutMailerCreation" 
        strReturnURL = strReturnURL + 'apex/EB_VfpNotifyUsersAboutMailerCreation?id='+Mailer.Id+'&type='+Mailer.EB_Type__c+'&incident_type='+Mailer.EB_IsServiceIncidentNotification__c;
        pageRef = new PageReference(strReturnURL);
    
        return pageRef;
        }
        catch(DmlException e){
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());
            ApexPages.addMessage(myMsg);
            throw e;
            return null;
        }
        catch(Exception e1){
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e1.getMessage());
            ApexPages.addMessage(myMsg);
            throw e1;
            return null;
        }
    }   
        
    public virtual PageReference page2() 
    {
    /* ========================================================================
    descripion:This is invoked when user clicks on "Next" button. In this method we frame the final SOQL queries that are supplied to getAccounts() through database.getQueryLoctor().
    
    created by: Sharath K
    test class & test method:   
    modifications: date, by, description
        1. 6/-/2010 :created
        2. 6/25/2010: removed filtering criteria from getAccounts(). the filtering now happens in page2() and EB_UniqAccConList class.
        3. 6/29/2010: Added logic to display error message if search criteria return no rows
        4. 7/14/2010: add try catch blocks
        5. 7/28/2010: removed UNiqAccConList class dependency. Using optimized SOQLs
        6. 9/9/2010: CR 791832:Customer Notification Accounts Pagination & Selection Fix -Clear custom object EB_SelectedAccounts__c before going to next page
        7. 09/14/2010 - CR 794793: Implementing code review findings - Made this function virtual, so that it can be overriden by child class
        8. 9/26/2011 - CR 1302518 Adding Email !='' and Email !=null conditions in all Contact queries.
        9. 06/25/2012 - CR 1733044 CNotify: Enhancing the existing Account Product Search to Incorporate New Prod Catg Search
        10.07/12/2013 - CR 2286623 CNotify: Added condition to remove all inactive accounts from all account queries
    code review:
    ======================================================================== */
        String tempResellerQuery;
        String selectClauseAccount;
        String selectClauseProduct;
        String fields = '';
        List<String> split_query;
        List<String> dispFields;
        Integer x=0;
        String debugFlag;
        ApexPages.Message myMsg;
        String listString;
        String userName= UserInfo.getUserId() ;
                
        searchAccount.clearSearchCriteria();
        if(editFlagAccount != true && editFlagProduct != true)
        {
            formSQLWhere();
        }
       
        //formSQLWhere();
        validateAccount();
        if(validateAccountFlag == 1 || validateProductFlag == 1)
        {
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Error in search criteria');
            ApexPages.addMessage(myMsg);
            return null;
        }
        dispFields = new List<String>();
            for (EBCS_DisplayFields__c displayFields : EBCS_DisplayFields__c.getAll().values()){
                dispFields.add(displayFields.Name_API__c);
            }
                 
            for( x=0;x<( dispFields.size()-1);x++){
                 fields= fields + dispFields.get(x) + ' , ';
            }
        fields= fields + dispFields.get(x) + ' '; 
        searchAccount.setTableName('Account');
        searchAccount.setFields(fields);
        selectClauseAccount = searchAccount.buildSelectClause();
        if(SQLWhere!=null)
        finalSOQLAccount = searchAccount.buildSQL(SQLWhere);
        //start of changes by janantha for CR 1733044
        if(EB_UtilApplication.getProperty('ProductSearch')!='Product Catalog')
        {   
        
            searchProduct.setTableName('EB_AccountProductMap__c');
        }
        else
        {
            searchProduct.setTableName('EB_EntitledAccountProduct__c'); 
        }
        //end of changes by janantha for CR 1733044
        searchProduct.setFields('EB_Account__c');
        selectClauseProduct = searchProduct.buildSelectClause();
        try
        {
        if(SQLWhere != null && SQLWhere != ''){
            finalSOQLAccount= finalSOQLAccount + 'AND (Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\'))';
             
             if(PSQLWhere != null && PSQLWhere != ''){
                //start of changes by janantha for CR 1733044
                if(EB_UtilApplication.getProperty('ProductSearch')!='Product Catalog')              
                    searchProduct.setTableName('EB_AccountProductMap__c');
                else
                    searchProduct.setTableName('EB_EntitledAccountProduct__c');
                //end of changes by janantha for CR 1733044
                searchProduct.setFields('EB_Account__c');
                // 8/26/2011 - CR 1279795  - adding the AND condition to filter out the logically deleted records
                if(EB_UtilApplication.getProperty('ProductSearch')!='Product Catalog')
                    finalSOQLProduct = searchProduct.buildSQL(PSQLWhere) + ' AND (EB_MarkedForDeletion__c = FALSE) ';
                else
                    finalSOQLProduct = searchProduct.buildSQL(PSQLWhere) + ') AND (EB_MarkedForDeletion__c = FALSE) ';
                if(choice == 'selectedContacts'){
                    //CR 851546 changes- Nov 3rd 2010 - Removing HasOptedOutOfEmail filter from where clause of the SOQL - only for Service Incidents
                    final_query = finalSOQLAccount + 'AND (Id not in :ResellerAccounts)' + ' AND (Id IN ( ' + finalSOQLProduct + '))' + ' AND (Id IN ( SELECT AccountId from Contact where (Contact_Type__c INCLUDES (' +'\'Technical Primary - 24X7\''+','+ '\'Tech Secondary - 24X7\''+')) AND (Email != \'\' AND Email != null))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL) ' ;
                    soql=final_query + ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL')) ;
                    tempResellerQuery=finalSOQLAccount + 'AND (Id in :ResellerAccounts)' + ' AND (Id IN ( ' + finalSOQLProduct + '))' + ' AND (Id IN ( SELECT AccountId from Contact where (Contact_Type__c INCLUDES (' +'\'Technical Primary - 24X7\''+','+ '\'Tech Secondary - 24X7\''+')) AND (Email != \'\' AND Email != null))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL) ' + ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL')) ;
                }
                else{
                    final_query = finalSOQLAccount + 'AND (Id not in :ResellerAccounts)' + ' AND (Id IN ( ' + finalSOQLProduct + '))' + ' AND (Id IN ( SELECT AccountId from Contact where (HasOptedOutOfEmail=false) AND (Email != \'\' AND Email != null))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)';
                    soql=final_query + ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
                    tempResellerQuery= finalSOQLAccount + 'AND (Id in :ResellerAccounts)' + ' AND (Id IN ( ' + finalSOQLProduct + '))' + ' AND (Id IN ( SELECT AccountId from Contact where (HasOptedOutOfEmail=false) AND (Email != \'\' AND Email != null))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)'+ ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
                }                           
                setSOQL(soql,tempResellerQuery);
            }
            else{
                if(choice == 'selectedContacts'){
                    //CR 851546 changes- Nov 3rd 2010 - Removing HasOptedOutOfEmail filter from where clause of the SOQL - only for Service Incidents
                    final_query = finalSOQLAccount + 'AND (Id not in :ResellerAccounts)' +  ' AND (Id IN ( SELECT AccountId from Contact where (Contact_Type__c INCLUDES (' +'\'Technical Primary - 24X7\''+','+ '\'Tech Secondary - 24X7\''+')) AND (Email != \'\' AND Email != null))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)' ;
                        soql= final_query+ ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL')); 
                        tempResellerQuery=finalSOQLAccount + 'AND (Id in :ResellerAccounts)' +' AND (Id IN ( SELECT AccountId from Contact where (Contact_Type__c INCLUDES (' +'\'Technical Primary - 24X7\''+','+ '\'Tech Secondary - 24X7\''+')) AND (Email != \'\' AND Email != null))) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)'+ ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL')); 
                }
                else{
                    final_query = finalSOQLAccount  + 'AND (Id not in :ResellerAccounts)' + ' AND (Id IN ( SELECT AccountId from Contact where (HasOptedOutOfEmail=false) AND (Email != \'\' AND Email != null) )) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)' ;
                    soql= final_query+ ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));         
                    tempResellerQuery= finalSOQLAccount +  'AND (Id in :ResellerAccounts)'+' AND (Id IN ( SELECT AccountId from Contact where (HasOptedOutOfEmail=false) AND (Email != \'\' AND Email != null) )) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)'+ ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));      
                }
                setSOQL(soql,tempResellerQuery);
            }
        }
        else if(PSQLWhere != '' && PSQLWhere != null){
            //start of changes by janantha for CR 1733044
            if(EB_UtilApplication.getProperty('ProductSearch')!='Product Catalog')
                searchProduct.setTableName('EB_AccountProductMap__c');
            else
                searchProduct.setTableName('EB_EntitledAccountProduct__c');
            // 8/26/2011 - CR 1279795  - adding the AND condition to filter out the logically deleted records
            if(EB_UtilApplication.getProperty('ProductSearch')!='Product Catalog')
                finalSOQLProduct = searchProduct.buildSQL(PSQLWhere) + ' AND (EB_MarkedForDeletion__c = FALSE) '; 
            else
                finalSOQLProduct = searchProduct.buildSQL(PSQLWhere) + ') AND (EB_MarkedForDeletion__c = FALSE) '; 
            if(choice == 'selectedContacts'){
                final_query = finalSOQLAccount + '  (Id IN ( ' + finalSOQLProduct + '))' + ' AND (Id IN ( SELECT AccountId from Contact where (Contact_Type__c INCLUDES (' +'\'Technical Primary - 24X7\''+','+ '\'Tech Secondary - 24X7\''+')) AND (Email != \'\' AND Email != null) ))' + 'AND (Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\')) AND (Id not in :ResellerAccounts) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)';
                soql=final_query +' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
                tempResellerQuery=finalSOQLAccount + '  (Id IN ( ' + finalSOQLProduct + '))' + ' AND (Id IN ( SELECT AccountId from Contact where (Contact_Type__c INCLUDES (' +'\'Technical Primary - 24X7\''+','+ '\'Tech Secondary - 24X7\''+')) AND (Email != \'\' AND Email != null) ))' + 'AND (Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\')) AND (Id in :ResellerAccounts) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)'+' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
                }
           else{
                final_query = finalSOQLAccount + '  ( Id IN ( ' + finalSOQLProduct + '))' + ' AND ( Id IN ( SELECT AccountId from Contact where (HasOptedOutOfEmail=false) AND (Email != \'\' AND Email != null)) )' + 'AND (Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\')) AND (Id not in :ResellerAccounts) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL) ';
                soql=final_query+ ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
                tempResellerQuery=finalSOQLAccount + '  ( Id IN ( ' + finalSOQLProduct + '))' + ' AND ( Id IN ( SELECT AccountId from Contact where (HasOptedOutOfEmail=false) AND (Email != \'\' AND Email != null)) )' + 'AND (Account_Status__c != \'Lead\' AND (NOT Account_Status__c LIKE \'% - Inactive\')) AND (Id in :ResellerAccounts) AND (AKAM_Account_ID__c!=\'\' AND AKAM_Account_ID__c!= NULL)'+ ' limit ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
            }
            setSOQL(soql,tempResellerQuery);   
            
        }        
        //else if(PSQLWhere=='' && SQLWhere==''){
        else{
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Please enter the search criteria');
            ApexPages.addMessage(myMsg);
            return null;
        }
        }
        catch(StringException s)
               {
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,s.getMessage());
                ApexPages.addMessage(myMsg);
                throw s;
                return null;
               }
        catch(Exception e)
               {
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());
                ApexPages.addMessage(myMsg);
                throw e;
                return null;
               }

        objController = null;
        debugFlag=EB_UtilApplication.getProperty_DebugSQL();
        if(debugFlag=='TRUE'){
            debugFinalSQL=final_query;
        }
        /*
        // 9/9/2010: CR 791832:Customer Notification Accounts Pagination & Selection Fix - clear all the selected Accounts from the custom Object Selected Accounts
        List<EB_SelectedAccounts__c> deleteAll = [select Id from EB_SelectedAccounts__c where CreatedById = :userName ];
        database.delete(deleteAll); 
        */
        if(((List<Account>)objController.getRecords()).size()==0){
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Search did not return any result');
            ApexPages.addMessage(myMsg);
            return null;
         }
         else{
            if(mailchoice=='singleMail'){
                return Page.EB_VfpMailerWizard3;
                }
            else{
                //CR 819957: Making the Create Mailer Batchable - Create mailer directly without having to select accounts individually
                enableMailerButton();
                return Page.Eb_SearchCriteria;
                }
            }
    } 



/*
        CR 819957: Making the Create Mailer Batchable - function that creates mailer directly without user having to select accounts on UI. User just specifies search criteria and mailers are created
        Author: Sharath
        Created: 10/1/2010
        Modified: 3/25/2011
        CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation
        9/26/2011 - CR 1302518 - Adding Email !='' and Email !=null conditions in all Contact queries.
                14/11/2011 - CR 1378172 CNotify: Superficial Fix, Accepting Issue Details & SI# in the first step of Mailer Creation
*/
    public PageReference createMailerDirectly(){
        String strReturnURL= 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/';
        PageReference pageRef;
        EB_AkaMAccount__c akamAccount;
         List<EB_AkaMContact__c> insertAkamContact = new List<EB_AkaMContact__c>();
        EB_AkaMailer__c Mailer = new EB_AkaMailer__c();
        Map<String, String> objAccountAkamAccountMap = new Map<String, String>();
        ApexPages.Message myMsg;
        String templateId;
        String mail_type = ApexPages.currentPage().getParameters().get('type');
        String contacts_choice = ApexPages.currentPage().getParameters().get('choice');
        String ContactQuery;
        
        List<String> allAccounts= new  List<String>();
        EB_Token__c tokenParameters;
        for(Account x:  Database.Query(strSOQL)){
            allAccounts.add(x.Id);
        }
        
        // 3/25/2011 - CR 845804 initilize the default email Template chosen on the UI
        if(token==null || token ==''){
            token= ApexPages.currentPage().getParameters().get('token');
        }
        try{
                        // CR 1378172 - retrieving the default values from Token
            tokenParameters = [select EB_ChatterNotification__c,EB_TokenEmailTemplate__c,EB_TokenIssueReason__c,EB_TokenAdditionalReason__c,EB_TokenImpactedProduct__c,EB_TokenImpactedRegion__c,EB_TokenEndDate__c,EB_TokenStartDate__c,EB_TokenSINumber__c from EB_Token__c where Id =:token];
            //CR 819957: Making the Create Mailer Batchable - single mails cant be created without selecting accounts. hence commmenting below code for single mails
            // 03/29/2011 : removing commented Code (Sharath)
             if (mailchoice=='massMail' || mail_type=='mass'){
            //mass mails
               //create mailer directly for mass mail
                createMailerDirect=true;
                
                Mailer.EB_Status__c = 'New';
                Mailer.EB_Type__c='Mass Email';
                // CR 1378172 - passing default values to mailer from 1st page.
                Mailer.EB_ImpactedAkamaiProduct__c = tokenParameters.EB_TokenImpactedProduct__c;
                Mailer.EB_IssueStartDateTime__c = tokenParameters.EB_TokenStartDate__c;
                Mailer.EB_IssueEndDateTime__c = tokenParameters.EB_TokenEndDate__c;
                Mailer.EB_ImpactedRegion__c = tokenParameters.EB_TokenImpactedRegion__c;
                Mailer.EB_IssueReason__c = tokenParameters.EB_TokenIssueReason__c;
                Mailer.EB_AdditionalIssueDescription__c = tokenParameters.EB_TokenAdditionalReason__c;
                Mailer.EB_SINumber__c = tokenParameters.EB_TokenSINumber__c;
                Mailer.Search_Criteria__c = XML;
                /*  CR 1367210 21/1/2011 - Chatter notification for internal account teams*/
                Mailer.EB_ChatterNotification__c = tokenParameters.EB_ChatterNotification__c;
                 try{
                    templateId=[select Id from EB_EmailTemplate__c where  EB_IsDefault__c=true and EB_NotificationType__r.Name='Mass Email'][0].Id;
                    Mailer.Email_Template__c=templateId;
                    }
                 catch (Exception e){
                           EB_MailerException__c excp = new EB_MailerException__c();
                           excp.Exception_Message__c=' The default email template is INVALID. Please set a valid template ID as DEFAULT';
                           excp.EB_Mailer__c=Mailer.Id;
                           excp.EB_Type__c = 'Warning';
                           insert(excp);
                    }
                 Mailer.EB_Status__c = 'New';
                 // 3/25/2011 - CR 845804 chosenTemplate = 'null' when we navigate to accountID search page
                 if(tokenParameters.EB_TokenEmailTemplate__c != null){
                  Mailer.Email_Template__c = tokenParameters.EB_TokenEmailTemplate__c;
                  } 
                /*
            Start of changes - nov 09 2010 
            By- Sharath
            Description - contacts_choice is null when User uses Account/Product Search. But choice defaults to 'allContacts' when user moves to AccountID search page, irrespective of whether contacts_choice='allContacts' or 'selectedContacts'.
            hence removing the condition if(choice=='allContacts' || contacts_choice=='allContacts' ), since it was always became true
            */
                if(contacts_choice!=null){
                    if(contacts_choice=='allContacts'){
                        Mailer.EB_IsServiceIncidentNotification__c=false;
                    }
                    else{
                        Mailer.EB_IsServiceIncidentNotification__c=true;
                    }
                }
                else{
                    if(choice=='allContacts'){
                        Mailer.EB_IsServiceIncidentNotification__c=false;
                    }
                    else{
                        Mailer.EB_IsServiceIncidentNotification__c=true;
                    }
                }
        /* End of changes - nov 09 2010 */
                insert Mailer;
                
                akamAccount = new EB_AkaMAccount__c();
                //akamAccount.EB_Account__c = selectedContact.Account.Id;
                akamAccount.EB_AkaMailer__c = Mailer.Id;
                akamAccount.EB_Status__c = 'New';
                akamAccount.EB_EnableValidationRules__c=false;
                insert akamAccount;
                
            /*
            Start of changes - nov 09 2010 
            By- Sharath
            Description - contacts_choice is null when User uses Account/Product Search. But choice defaults to 'allContacts' when user moves to AccountID search page, irrespective of whether contacts_choice='allContacts' or 'selectedContacts'.
            hence removing the condition if(choice=='allContacts' || contacts_choice=='allContacts' ), since it was always became true
            */
      //system.assertNotequals(ResellerAccountsOmitted,NULL);
            if(contacts_choice!=null){
                if(contacts_choice=='allContacts'){
                //CR 2611929 - Added Email Bounce to Query
                ContactQuery='SELECT id, EmailBouncedReason , Account.Id, Account.Name, Email FROM Contact WHERE (AccountId IN :allAccounts OR Account.Akam_Account_Id__c =\'1-599K\') AND (HasOptedOutOfEmail=false) AND (Email != \'\' AND Email != null) order by AccountId' ;
        Id batchinstanceid3 = Database.executeBatch(new EB_BatchableCreateMassMailer(ContactQuery,Mailer,token,akamAccount,createMailerDirect,allAccounts,ResellerAccountsOmitted), 1000);  
                }
            else{
                //CR 851546 changes- Nov 3rd 2010 - Removing HasOptedOutOfEmail filter from where clause of the SOQL - only for Service Incidents
                //CR 2611929 - Added Email Bounce to Query
                ContactQuery='SELECT id,EmailBouncedReason , Account.Id, Account.Name, lastname, firstname, Contact_Type__c, Phone, Email FROM Contact WHERE (Contact_Type__c INCLUDES (\'Technical Primary - 24X7\', \'Tech Secondary - 24X7\')) AND (AccountId IN :allAccounts OR Account.Akam_Account_Id__c =\'1-599K\') AND (Email != \'\' AND Email != null) order by AccountId' ;
                Id batchinstanceid4 = Database.executeBatch(new EB_BatchableCreateMassMailer(ContactQuery,Mailer,token,akamAccount,createMailerDirect,allAccounts,ResellerAccountsOmitted), 1000); 
                }
            }
            else{
                if(choice=='allContacts'){
                //CR 2611929 - Added Email Bounce to Query
                ContactQuery='SELECT id, Account.Id,EmailBouncedReason, Account.Name, Email FROM Contact WHERE (AccountId IN :allAccounts OR Account.Akam_Account_Id__c =\'1-599K\') AND (HasOptedOutOfEmail=false) AND (Email != \'\' AND Email != null) order by AccountId' ;
                Id batchinstanceid3 = Database.executeBatch(new EB_BatchableCreateMassMailer(ContactQuery,Mailer,token,akamAccount,createMailerDirect,allAccounts,ResellerAccountsOmitted), 1000);  
                }
            else{
                //CR 851546 changes- Nov 3rd 2010 - Removing HasOptedOutOfEmail filter from where clause of the SOQL - only for Service Incidents
                //CR 2611929 - Added Email Bounce to Query
                ContactQuery='SELECT id,EmailBouncedReason , Account.Id, Account.Name, lastname, firstname, Contact_Type__c, Phone, Email FROM Contact WHERE (Contact_Type__c INCLUDES (\'Technical Primary - 24X7\', \'Tech Secondary - 24X7\')) AND (AccountId IN :allAccounts OR Account.Akam_Account_Id__c =\'1-599K\') AND (Email != \'\' AND Email != null) order by AccountId' ;
                Id batchinstanceid4 = Database.executeBatch(new EB_BatchableCreateMassMailer(ContactQuery,Mailer,token,akamAccount,createMailerDirect,allAccounts,ResellerAccountsOmitted), 1000); 
                }
            }
            /* End of changes - nov 09 2010 */
            }
        //CR 1029711 - pass extra parameters to the page "EB_VfpNotifyUsersAboutMailerCreation" 
        strReturnURL = strReturnURL +  'apex/EB_VfpNotifyUsersAboutMailerCreation?id='+Mailer.Id+'&type='+Mailer.EB_Type__c+'&incident_type='+Mailer.EB_IsServiceIncidentNotification__c;
        pageRef = new PageReference(strReturnURL);
    
        return pageRef;
        }
        catch(DmlException e){
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());
            ApexPages.addMessage(myMsg);
            throw e;
            return null;
        }
        catch(Exception e1){
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e1.getMessage());
            ApexPages.addMessage(myMsg);
            throw e1;
            return null;
        }
    }
    
    public virtual PageReference page1()
    {
        // function redirects to the VfpMailerWizard2 page from VfpMailerWizard3
        selectMore.clear();
        selectedAccounts.clear();
        accountList.clear();
        //Added below line : Shardul : CR 1816825 
        deleteselected();
        return Page.EB_VfpMailerWizard2;
    }
    
    
     //Shardul : CR 1816825 : Start of changes
    public void deleteselected()
    {
        
        List<EB_SelectedAccounts__c> deleteRecs = [Select Id from EB_SelectedAccounts__c where EB_ParentToken__c =:token];
        database.delete(deleteRecs,false);
        disableMailerButton = 'true';
    }
    //Shardul : CR 1816825 : End of changes
    
    
    public PageReference main_page()
    {
        // function redirects to the VfpMailerWizard1 page from VfpMailerWizard2
        return Page.EB_VfpMailerWizard1;
    }
/*
Author: Sharath
Description: Navigate form 1st page of wizard to the Account/Product Search page or the Account ID/CP Code search page
Changes: Nov-9-2010 - Reorganized the function. Removed multiple return statements and replaced it with a single return statement.
- added the parameter 'token' to all CustomSearch-Acc & CustomSearch-Cp pages for 'mass mails'
 3/29/2011 -CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation 
        - pass chosenTemplate as parameter to all the pages
 14/11/2011 - CR 1378172 CNotify: Superficial Fix, Accepting Issue Details & SI# in the first step of Mailer Creation
        List of changes :
                 1. Removing dummyMailer. Using Token to capture default values for a mailer. Introduced 7-8 fields at token object for the same.
                 2. Removing chosentTemplate from queryString. Earlier, deafault template if was passed as query string. Now passed through token.

*/
 /*
Author: Sharath
Description: Navigate form 1st page of wizard to the Account/Product Search page or the Account ID/CP Code search page
Changes: Nov-9-2010 - Reorganized the function. Removed multiple return statements and replaced it with a single return statement.
- added the parameter 'token' to all CustomSearch-Acc & CustomSearch-Cp pages for 'mass mails'
 3/29/2011 -CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation 
        - pass chosenTemplate as parameter to all the pages
 14/11/2011 - CR 1378172 CNotify: Superficial Fix, Accepting Issue Details & SI# in the first step of Mailer Creation
        List of changes :
                 1. Removing dummyMailer. Using Token to capture default values for a mailer. Introduced 7-8 fields at token object for the same.
                 2. Removing chosentTemplate from queryString. Earlier, deafault template if was passed as query string. Now passed through token.

*/
    public PageReference goToSearchPage(){
    
    /*
    */
    if((newtoken.EB_TokenAdditionalReason__c == null || newtoken.EB_TokenAdditionalReason__c.trim() == '') && !Test.isRunningTest()){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter value in Additional Issue Description '));
        return null;
    }
    //CR 845804 change - initialize a dummy mailer , CR 1378172 - removing dummyMailer, using token object instead
    //setDummyMailer();
    //CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process - create a new token when to navigate to next page
    /*EB_Token__c newtoken=new EB_Token__c();
    */
    /* CR 1378172 - always performing the insert of a token, but test class throws an error when trying to insert - hence upserting*/
    
    database.upsert(newtoken);
    token= newtoken.Id;
    
    //Start of changes by ssawhney for CR 2499348  
    ValidateInternalEmailId();
    if(!isValidEmailId)
          return null;  
    
    //End of changes for CR 2499348  
    
    // function redirects to the VfpMailerWizard2 or EB_VfpMailerWizardByAccCPId1 page from VfpMailerWizard1 based on parameters
       if(radioChoice=='DefaultSearch')
       return Page.EB_VfpMailerWizard2;
       else{
            PageReference pg;
           if(choice=='selectedContacts'){
               if(radioChoice=='CustomSearch-Acc'){
                   if(mailchoice=='massMail'){
                      pg= new PageReference('/apex/EB_VfpMailerWizardByAccCPId1?choice=selectedContacts&basis=accId&type=mass&token='+token);
                      }
                      else{
                        //CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process - pass token as parameter for AccountId search
                      pg = new PageReference('/apex/EB_VfpMailerWizardByAccCPId1?choice=selectedContacts&basis=accId&type=single&token='+token);
                      }
                  }
                  else {
                      if(mailchoice=='massMail'){
                          pg = new PageReference('/apex/EB_VfpMailerWizardByAccCPId1?choice=selectedContacts&basis=CpId&type=mass&token='+token);
                          }
                       else{
                            //CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process - pass token as parameter for AccountId search
                           pg  = new PageReference('/apex/EB_VfpMailerWizardByAccCPId1?choice=selectedContacts&basis=CpId&type=single&token='+token);
                           }
                   }
              }
           else{ 
               if(radioChoice=='CustomSearch-Acc'){
                   if(mailchoice=='massMail'){
                      pg = new PageReference('/apex/EB_VfpMailerWizardByAccCPId1?choice=allContacts&basis=accId&type=mass&token='+token);
                      }
                      else{
                        //CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process - pass token as parameter for AccountId search
                      pg = new PageReference('/apex/EB_VfpMailerWizardByAccCPId1?choice=allContacts&basis=accId&type=single&token='+token);
                      }
                   }
               else {
                        if(mailchoice=='massMail'){
                          pg = new PageReference('/apex/EB_VfpMailerWizardByAccCPId1?choice=allContacts&basis=CpId&type=mass&token='+token);
                          }
                       else{
                            //CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process - pass token as parameter for AccountId search
                           pg = new PageReference('/apex/EB_VfpMailerWizardByAccCPId1?choice=allContacts&basis=CpId&type=single&token='+token);
                           }
                    }
               }
               return pg;
       }
    } 
    
    public String getAccountProductPage()
    {
        //function to disply the Entitled Products Report
        String redirectUrl= 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/' + EB_UtilApplication.getProperty('ProductsListReport');
        return redirectUrl; 
    }
    
    // 9/9/2010: CR 791832:Customer Notification Accounts Pagination & Selection Fix -function to View Enhanced List - Selected Accounts in a different page
    public String RedirectToSelectedAccounts() {
        String parentToken= ApexPages.currentPage().getParameters().get('token');
    //String redirectUrl= 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/' + 'apex/EB_VfpSelectedAccounts';
    //CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process - This is for for AccountId search
    if(token==null || token==''){
        token=parentToken;
    }
    String redirectUrl= 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/' + token;
        return redirectUrl;
    }
    
    /*
    Author: Sharath K
    Created: Nov 2nd 2010
    Descripion - Changes for CR 851564 - function to check if mailer creation process has completed or is still in-progress
    Modified: 3/29/2011
    CR 1029711 - CNotify: Standardize Action Poller Content, Create Mailer
        CR 1403947 - CNotify: Enhancement, Navigate directly to the Mailer post Mailer Creation
    */
     public PageReference getMailerStatus() {
        String currentMailerId= ApexPages.currentPage().getParameters().get('id');
        String userId=UserInfo.getUserId();
        try{
        // 3/14/2011 -CR 1029711-it becomes imperative that we redirect to the correct mailer after create mailer completeion. hence adding mailer id as parameter to identify the mailer
        EB_AkaMailer__c temp = [select Id,EB_AssociatedToken__c,EB_Type__c,EB_IsServiceIncidentNotification__c from EB_AkaMailer__c where Id =:currentMailerId limit 1 ];
        // EB_AssociatedToken__c is null initially. it is populated in the finish() method of the EB_BatchableMailerCreation/EB_BatchableMassMailCreation class
        if(temp.EB_AssociatedToken__c==null){
            MailerStatus='In Progress';
        }
        else{
            MailerStatus= 'Completed' ; 
            MailerLink = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/' + temp.Id;
            
            }
        }
        catch(Exception e){
            // this should never happen in Production. adding the catch block just in case - best practice.
            system.debug(e.getMessage());
        }
                /* 11/14/2011 - Sharath
                CR 1403947 change - redirect to mailer page when mailer craetion process is complete
                 */
        if(MailerLink != null){
            PageReference pg = new PageReference(MailerLink);
            return pg;
        }
        else{
            return null;
        }
    }
    
    /*
    Author: Sharath K
    Created: Nov 2nd 2010
    Descripion - Changes for CR 851564 - returns google images to the page. there are 2 images that are rendered based on whether the mailer creation process is in-progress /completed
    Modified: 3/29/2011
    CR 1029711 - CNotify: Standardize Action Poller Content, Create Mailer
        - we aren't refering to the google images anymore. we're using 2 images stored in Documents folder and retrieving it using custom settings
    */
     public String getMailerDetails() {
        /*if(MailerStatus=='In Progress'){
            return 'http://chart.apis.google.com/chart?chst=d_bubble_icon_text_small&chld=caution|bbT|Mailer Creation In Progress|FFBF00|000000';
        }
        return 'http://chart.apis.google.com/chart?chst=d_bubble_icon_text_small&chld=glyphish_todo|bbT|Mailer Creation Completed|58C461|000000';*/
        String var1;
        // retrieve the Organization Id, which is required to display the image placed in the Documents folder
        String var2 = [select Id from Organization limit 1 ][0].Id;
        // url to be returned, which will be rendered on Page
        String retVal = '';
        
        if(MailerStatus=='In Progress'){
            EBCS_CNProgressImages__c orgValues = EBCS_CNProgressImages__c.getOrgDefaults();
            var1 = orgValues.InProcess__c;
            StatusMessage = 'Processing Create Mailer.... Please do not close the browser window';
            retVal = '/servlet/servlet.ImageServer?id=' + var1 + '&oid=' + var2;
        }
        else{
            EBCS_CNProgressImages__c orgValues = EBCS_CNProgressImages__c.getOrgDefaults();
            var1 = orgValues.Processed2__c;
            StatusMessage = 'Create Mailer operation has been successfully completed. Please click on the link to navigate to the Mailer.';
            retVal = '/servlet/servlet.ImageServer?id=' + var1 + '&oid=' + var2;
        }
        return retVal ;
    }

    
    /*
    Author: Sharath K
    Created: Nov 2nd 2010
    Descripion - Changes for CR 851564 - function to return the mailer link to the VF page.
    */
    
    public String getCurrentMailerLink() {
        if(MailerLink==null || MailerLink=='')
        return null;
        else
            return MailerLink;
    }
    
    /*
    Author: Sharath K
    Created: Nov 2nd 2010
    Descripion - Changes for CR 851564 - functon to render the mailer link on VF page. Link is rendered on page only if mailer creation process has completed
    */
    
     public Boolean getRenderMailerLink() {
        if(MailerStatus!='Completed'){
            return false;
        }
        else{
            return true;
        }
    }
    /*
    Author: Vineet
    CR: 1685569
    Description: Clear The Filter
 */
    //CR 1685569 - CNotify: 2012 Jun-2012 Enhancement to the existing lists of Selection of Customers functionality
    public PageReference clearFilter()
    {
    accountName=accountID=supportLevel=customerTier='';
     strSOQL = strOriginalSOQL;
     strTempSoql = strSOQL.split('limit')[0];
     objController=null;
     getAccounts();
     return null;
    }
    /*
    Author: Vineet
    CR: 1685569
    Description: This Fuction is called on the Press of Apply Button
    */
    //ApplyFilter
    
  public PageReference applyFilter() {
           
    strTempSoql = strOriginalSOQL.split('limit')[0];
    if (accountName!= '' && accountName != null)
      strTempSoql += ' and Name LIKE \''+String.escapeSingleQuotes(accountName)+'%\'';
    if (accountId!= '' && accountId != null)
      strTempSoql += ' and AKAM_Account_ID__c LIKE \''+String.escapeSingleQuotes(accountId)+'%\'';
      if (supportLevel!= '' && supportLevel != null)
      strTempSoql += ' and Support_Level__c LIKE \''+String.escapeSingleQuotes(supportLevel)+'%\'';
      if (customerTier!= '' && customerTier != null)
      strTempSoql += ' and Customer_Tier__c LIKE \''+String.escapeSingleQuotes(customerTier)+'%\'';
  
  
    // run the query again
    runQuery();
        
    return null;
  }
  
  /*
    Author: Vineet
    CR: 1685569
    Description: The Function which runs the query
 */
  public void runQuery() {
 
    try {
      strSOQL = strTempSoql + ' order by ' + sortField + ' ' + sortOrder + ' limit  ' + Integer.valueof(EB_UtilApplication.getProperty('LimitSQL'));
    //    system.assertEquals(strSOQL,NULL);
     objController=null;
     getAccounts();
    
    } catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
    }
 
  }
  /*
    Author: Vineet
    CR: 1685569
    Description: Toggles the Sort Order on CLick on the columns
 */
 //toggleSOrtOrder
   
   public void toggleSortOrder() {
    // simply toggle the direction
    sortOrder = sortOrder.equals('asc') ? 'desc' : 'asc';
    // run the query again
    runQuery();
   
  }
  
  //End CR 1685569 
  
  /* 
    Author: Jayalakshmi A
    Description: Wrapper class that wraps EB_Product__c records of type Product, Module or Submodule with a check box 
    Created Date : 06/25/2012
*/

    public class EB_ProductWrapper 
    {
        public EB_Product__c product{get;set;}  
        public Boolean selected{get;set;}   
        public Boolean isModule{get;set;}
        public Boolean isSubModule{get;set;}
        
        public EB_ProductWrapper()
        {
            
        }
        
        public EB_ProductWrapper(EB_Product__c prd)
        {
            product = new EB_Product__c();
            if(prd.EB_ProductType__c == 'Module')
                isModule = true;
            else if(prd.EB_ProductType__c == 'Submodule')
                isSubModule = true;
                
            product = prd;
            selected = false;
        }     
    }
    
  
       
       //Start of changes CR 1816825, SHARDUL
       
     public PageReference showcriteria() {
    
     pageReference ref = Page.Eb_SearchCriteria;
     return ref;
     }
         //End of changes CR 1816825, SHARDUL

//Start of changes CR 1816825, SHARDUL 
//To display the XML searchcriteria

public String getreadXML()
{
Boolean Field = false;
Boolean Operator = false; 
Boolean Value = false;
Boolean LogicalOperator = false;
String temp='';

boolean PostMailerCreation = getextractxmldone();
//System.assertEquals(PostMailerCreation,null);
 
 if (PostMailerCreation)
 {
  EB_AkaMailer__c mailerc = getsearchcriteria();
 // System.assertEquals(mailerc,null);
 XML = mailerc.Search_Criteria__c;
 // System.assertEquals(XML,null);
 
 }
 
//start of changes for ssawhney CR 2463078 - CNotify: Exception in Preview Search functionality
 temp = temp + '<table class="gridtable" > <tr><th>Field</th><th>Operator</th><th>Value</th><th>Logical Operator</th></tr>';
 if(XML != null && XML != '')
 {
     XmlStreamReader reader = new XmlStreamReader(XML);
     while(reader.hasNext()) {
        if (reader.getEventType() == XmlTag.END_ELEMENT) {
          if(reader.getLocalName() == 'row')
            {
             temp = temp + '</tr>';
            }
            else if(reader.getLocalName() == 'Field')
            {
             temp = temp + '</td>';
            }
            else if(reader.getLocalName() == 'Operator')
            {
             temp = temp + '</td>';
            }
            if(reader.getLocalName() == 'Value')
            {
             temp = temp + '</td>';
            }
            if(reader.getLocalName() == 'LogicalOperator')
            {
             temp = temp + '</td>';
            }
        } 
        else if (reader.getEventType() == XmlTag.START_ELEMENT) {
        
            if(reader.getLocalName() == 'row')
            {
             temp = temp + '<tr>';
            }
            else if(reader.getLocalName() == 'Field')
            {
           
             temp = temp + '<td>';
            }
            else if(reader.getLocalName() == 'Operator')
            {
           
             temp = temp + '<td>';
            }
            if(reader.getLocalName() == 'Value')
            {
             temp = temp + '<td>';
            }
            if(reader.getLocalName() == 'LogicalOperator')
            {
             temp = temp + '<td>';
            }
        }
        else if (reader.getEventType() == XmlTag.CHARACTERS) {
           temp = temp + reader.getText(); 
        }
        reader.next();
     }
    }
    //end of changes for ssawhney CR 2463078 - CNotify: Exception in Preview Search functionality
    temp = temp + '</table>';
    return temp;
} 

 public PageReference gotoaccountspage() {
    
    return Page.EB_VfpMailerWizard3;
       }
       
//End of changes CR 1816825, SHARDUL
Public pagereference gotoPreviewPage()
{
    database.upsert(newtoken);
    EB_Token__c tokenParameters;
    String parentToken = ApexPages.currentPage().getParameters().get('token');
    token= newtoken.Id;
    if(token=='' || token==null ){
            token=parentToken;
        }
    tokenParameters = [select EB_ChatterNotification__c,EB_TokenEmailTemplate__c,EB_TokenEmailTemplate__r.Id,EB_TokenAdditionalReason__c,EB_TokenIssueReason__c,EB_TokenImpactedProduct__c,EB_TokenImpactedRegion__c,EB_TokenEndDate__c,EB_TokenStartDate__c,EB_TokenSINumber__c from EB_Token__c where Id =:token];
    templateId=(tokenParameters.EB_TokenEmailTemplate__c);
    //system.assertequals(templateId,null);
    
    PageReference pg;
    if(templateId!= NULL)
    pg= new PageReference('/apex/EB_VfpPreviewTemplate?token='+token+'&templateidParam='+templateId);
    else
    {
    ApexPages.Message myMsg;
                    myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'No value found in Email Template field');
                    ApexPages.addmessage(myMsg);
                    return null;
    }
    return pg;
}
public Boolean getextractxmldone()
    {
        xmldone = ApexPages.currentPage().getParameters().get('xmldone');
       // system.assertEquals(xmldone, null);
                if(xmldone == 'YES')
        {
            return true;
        }
        
        return false;
    }

public EB_AkaMailer__c  getsearchcriteria()
{try
        {
           strMailerId = ApexPages.currentPage().getParameters().get('mailer_Id');
                       
           return [select Search_Criteria__c from EB_AkaMailer__c where Id = :ApexPages.currentPage().getParameters().get('mailer_Id')][0];
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            
            return null;
        }
 }
 
  
 public virtual PageReference choosemailer()
 {
              if(mailchoice=='singleMail'){
                PageReference mailerPg=CreateMailer();
                return mailerPg;
                }
            else{
                //CR 819957: Making the Create Mailer Batchable - Create mailer directly without having to select accounts individually
                PageReference mailerPg=createMailerDirectly();
                return mailerPg;
                }   
 }
 
 
 public virtual PageReference backfromSearchCriteria()
 {
              if(mailchoice=='singleMail'){
                return Page.EB_VfpMailerWizard3;
                }
            else{
                //CR 819957: Making the Create Mailer Batchable - Create mailer directly without having to select accounts individually
                return Page.EB_VfpMailerWizard2;
                }   
 }
 
 //Start of changes by ssawhney for CR 2499348
  public PageReference ValidateInternalEmailId()
  {  
        if(mailchoice=='massMail')
        {
            string errorMsg = EB_UtilMailer.ValidateContactEmail();
            if(errorMsg != null && errorMsg != '')
            {
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, errorMsg));
                 isValidEmailId = false;
                 return null; 
            }
        }
        isValidEmailId = true;
        return null;
   }
   
   //End of changes for CR 2499348 
 
 }