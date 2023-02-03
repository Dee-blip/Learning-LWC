@isTest(SeeAllData=false)
public class HD_Test_CMR_IndexPageRecord {
    static TestMethod void getChangeListTest(){
        
       	List<ListView> lviews = HD_CMR_IndexPageRecords.getAllListViews();
        HD_CMR_IndexPageRecords.Response response = HD_CMR_IndexPageRecords.getChangeList(lviews[0].ID,'40',null,1,'name','asc');
        System.assert(lviews.size()>0,'list views is not empyt');
        
       
    }
     static TestMethod void getChangeListTestTicketNumber(){
        HD_CMR_IndexPageRecords obj = new HD_CMR_IndexPageRecords();
       	List<ListView> lviews = HD_CMR_IndexPageRecords.getAllListViews();
        HD_CMR_IndexPageRecords.Response response = HD_CMR_IndexPageRecords.getChangeList(lviews[0].ID,'40','1234',1,'name','asc');
        System.assert(lviews.size()>0,'list views is not empyt');
       
    }
    
    static TestMethod void getColumnsToConfigure(){
        HD_CMR_IndexPageRecords obj = new HD_CMR_IndexPageRecords();
       	Map<String,String> cols = HD_CMR_IndexPageRecords.getColumns();
        System.assert(cols.size()>0,'columns to configure is not empty');
        
    }
    
    static TestMethod void setUserColumns(){
        HD_CMR_IndexPageRecords obj = new HD_CMR_IndexPageRecords();
        Map<String,String> cols = new Map<String,String>{'HD_Sponsor_Name__c'=>'Sponsor Name','BMCServiceDesk__Scheduled_Start_Date__c'=>'Scheduled Start'};
        HD_CMR_IndexPageRecords.updateSelectedColumns(cols);
        Map<String,String> resp = HD_CMR_IndexPageRecords.getUserColumns();
        System.assert(resp.size()>0,'user column update was success');
      
    }
    
   
}