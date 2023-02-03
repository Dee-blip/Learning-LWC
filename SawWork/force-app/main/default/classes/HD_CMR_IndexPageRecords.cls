/* 
* File Name: HD_CMR_IndexPageRecords
* Description : 
* @author : 
* Modification Log ===============================================================
* Date              Author          Modification
* Jan 20th, 2022    Aneesh Budnar   PRTORES-2372 - HD migrate CMR calendar listview
*/
public  class  HD_CMR_IndexPageRecords {
    public static List<Id> incIds;
   // public static Integer recordsPerPage {get;set;}
   // public static Integer currentPage {get; set;}
    public static String query;

    public class Response{
        @AuraEnabled
        public Integer noOfPages;
        @AuraEnabled
        public Integer noOfRecords;
        @AuraEnabled
        public List<BMCServiceDesk__Change_Request__c> records;
    }

    @AuraEnabled
    public static void updateSelectedColumns(Map<String, String> selectedColumns) {
        // try
        //{
        List<String> selCols = new List<String>();
        String field;
        for(String key : selectedColumns.keySet())
        {
            selCols.add(key+':::'+selectedColumns.get(key));
        }

        HD_User_Configuration_Change__c userConfig = HD_User_Configuration_Change__c.getValues(System.UserInfo.getUserId());
        if(userConfig == null)
        {
            userConfig = new HD_User_Configuration_Change__c();
        }
        for(Integer i=1;i<=selCols.size();i++)
        {
            field = 'Field'+i+'__c';
            userConfig.put(field, selCols[i-1]);

        }
        for(Integer i=selCols.size()+1;i<8;i++)
        {
            field = 'Field'+i+'__c';

            userConfig.put(field, null);
        }

        userConfig.SetupOwnerId = System.UserInfo.getUserId();
        upsert(userConfig);

    }


    public static String queryGenerator()
    {
        Map<String, String> userColumns = getUserColumns();
        List<Schema.FieldSetMember> defaultFields = SObjectType.BMCServiceDesk__Change_Request__c.FieldSets.HD_CMR_ViewFields.getFields();

        Set<String> fields = new Set<String>{
            'HD_Sponsor__r.Name',
            'HD_Sponsor__r.Alias',
            'BMCServiceDesk__FKInitiator__r.Name',
            'BMCServiceDesk__FKInitiator__r.Alias',
            'OwnerId',
            'BMCServiceDesk__FKInitiator__r.Name',
            'Change_Coordinator_Primary__r.Name'
            };

        String  fieldString = 'Select  ';

        //push all the fields from users configuration
        for(String key : userColumns.keySet())
        {
            fields.add(key);
        }

        /*for (Schema.FieldSetMember fsm : filesset1) {
            // System.debug('Field api names: '+fsm.getfieldpath());
            //cols.put((String) fsm.getLabel().substringBefore('~'),(String) fsm.getFieldPath());
            cols.put((String) fsm.getFieldPath(),(String) fsm.getLabel());
        } */

        //push all the fields from defaut fieldsets
        for(Schema.FieldSetMember fm : defaultFields){
            fields.add(fm.getFieldPath());
        }

        for(String s:fields)
        {
            fieldString+= s +',';
        }

        fieldString = fieldString.substring(0, fieldString.length()-1);
        fieldString+=' from BMCServiceDesk__Change_Request__c ';


        return fieldString;
    }//

    /*@AuraEnabled
    public static Response getChangeRecords(Id filterId){
        return getChangeList(filterId,'20',null,1,'name','asc');
    }*/

    @AuraEnabled(cacheable=true)
    public static Response getChangeList(Id filterId,String noOfRecs,String ticketNumber,Integer pageNo,String orderBy,String sortDirection){


        if(String.isNotBlank(ticketNumber))
        {
            String q = queryGenerator();
            q = q + 'where Name like  \'%'+ String.escapeSingleQuotes(ticketNumber) +'%\' LIMIT 10 '; //CS fix - PRTORES-1581 - shegade

            System.debug('printing the query  '+q);

            Response wc = new Response();
            wc.noOfPages = 1;

            wc.records = Database.query(q);
            wc.noOfRecords = wc.records.size();
            System.debug(wc);
            return wc;

        }

        String query = queryGenerator();

        System.debug('query: ' + query);
        initRecords(filterId);
        String q = query+' where id in :incIds ORDER BY '+orderBy+' '+sortDirection+' LIMIT 9000 ' ;
        System.debug(q);
        //List<BMCServiceDesk__Change_Request__c>
        ApexPages.StandardSetController srmObject2 = new ApexPages.StandardSetController(Database.getQueryLocator(q));

        Integer pageSize = Integer.valueOf(noOfRecs);
        srmObject2.setPageSize(pageSize);
        Integer page_number = Integer.valueOf(pageNo);

        srmObject2.setPageNumber(page_number);

        Response wc = new Response();
        wc.noOfPages = (Integer)Math.ceil((Decimal)srmObject2.getResultSize()/(Decimal)pageSize);
        wc.noOfRecords = srmObject2.getResultSize();
        wc.records = srmObject2.getRecords();

        return wc;
    }

   // public Integer rec { get; set; }

  //  public Integer tot { get; set; }

    integer totalRecs = 0;
    integer count= 0;
    integer LimitSize= 1;

   /* public HD_IndexPageRecords(){
        tot=totalRecs = [select count() from account limit 1000];
    }*/

    @AuraEnabled
    public static void initRecords(Id filterId){
        query = queryGenerator();

        Integer count = 0;

        Integer pageNum =1;
        String q = query+' limit 1';
        List<BMCServiceDesk__Change_Request__c> qr = [SELECT id FROM BMCServiceDesk__Change_Request__c LIMIT 1];
        ApexPages.StandardSetController srmObject = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        srmObject.setPageSize(2000);
        srmObject.setPageNumber(pageNum);
        srmObject.setFilterID(filterId);
        incIds = new List<Id>();

        for(SObject inc: srmObject.getRecords())
        {
            System.debug('test');
            incIds.add(inc.Id);
            count++;
        }

        while(srmObject.getHasNext())
        {
            srmObject.next();
            for(SObject inc: srmObject.getRecords()){


                incIds.add(inc.Id);
                count++;
            }

        }



    }


   /* public static List<BMCServiceDesk__Change_Request__c> getChangeRequest(ID ListViewId){

        List<Id> incIds;
        ApexPages.StandardSetController x = new ApexPages.StandardSetController(Database.getQueryLocator([select id from BMCServiceDesk__Change_Request__c]));
        x.setPageSize(2000);
        x.setPageNumber(1);
        x.setFilterID(ListViewId);
        incIds = new List<Id>();
        Integer count = 0;
        for(SObject c: x.getRecords())
        {

            incIds.add(c.Id);
            count++;
        }

        System.debug(count);
        return null;
    }*/

    @AuraEnabled(cacheable=true)
    public static List<ListView> getAllListViews(){
        List<ListView> listViews = new List<ListView>();
        listViews = [SELECT Id, Name, DeveloperName FROM ListView WHERE SObjectType = 'BMCServiceDesk__Change_Request__c'];
        return listViews;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getColumns() {
        Map<String, String> cols = new Map<String, String>();
        List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Change_Request__c.FieldSets.HD_Change_Lightning_Columns.getFields();
        for (Schema.FieldSetMember fsm : filesset1) {
            // System.debug('Field api names: '+fsm.getfieldpath());
            //cols.put((String) fsm.getLabel().substringBefore('~'),(String) fsm.getFieldPath());
            cols.put((String) fsm.getFieldPath(),(String) fsm.getLabel());
        }
        return cols;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,String> getUserColumns() {
        Map<String,String> cols = new Map<String,String>();
        String field;
        try
        {


            HD_User_Configuration_Change__c  userConfig = HD_User_Configuration_Change__c.getValues(System.UserInfo.getUserId());

            if(userConfig==null)
            {
                userConfig = HD_User_Configuration_Change__c.getOrgDefaults();

            }

            String value;
            for(Integer i=1;i<15;i++)
            {
                field = 'Field'+i+'__c';
                value = (String)userConfig.get(field);
                if(value!=null)
                {
                    cols.put(value.split(':::')[0].trim(), value.split(':::')[1].trim());
                }
            }
        }

        catch(Exception e)
        {
            System.debug(e);
        }
        return cols;
    }
    
    @AuraEnabled
    public static List<String> getUserType(){
       return HD_CMR_ChangeCalendar.getUserType();
    }
}