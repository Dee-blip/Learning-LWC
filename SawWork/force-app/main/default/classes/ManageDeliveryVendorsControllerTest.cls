/* Created By: Vivek Baidya
* Created Date: 06-June-2019
* Description: Test class for manageDeliveryVendorsController. 
*/
@isTest(seeAllData=false)
public class ManageDeliveryVendorsControllerTest {
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @isTest static void testManageDeliveryVendorsControllerMethods() {
        System.runAs(dmlUser) {
            //Account Creation
            List<Account> accList = new List<Account>();
            Account acc1 = utilTestClass.CreateAccount('Test Account1');
            accList.add(acc1);
            Account acc2 = utilTestClass.CreateAccount('Test Account2');
            accList.add(acc2);
            Account acc3 = utilTestClass.CreateAccount('Test Account3');
            accList.add(acc3);
            insert accList;
            
            //Traffic_Share__c Creation
            List<Traffic_Share__c> tShareList = new List<Traffic_Share__c>();
            Traffic_Share__c tShare1 = new Traffic_Share__c();
            tShare1.Account__c = acc1.Id;
            tShareList.add(tShare1);
            Traffic_Share__c tShare2 = new Traffic_Share__c();
            tShare2.Account__c = acc2.Id;
            tShareList.add(tShare2);
            Traffic_Share__c tShare3 = new Traffic_Share__c();
            tShare3.Account__c = acc3.Id;
            tShareList.add(tShare3);
            insert tShareList;
            
            //Delivery_Vendor__c Creation
            List<Delivery_Vendor__c> dVendorList = new List<Delivery_Vendor__c>();
            Delivery_Vendor__c dVendor1 = new Delivery_Vendor__c();
            dVendor1.Traffic_Share__c = tShare1.Id;
            dVendor1.Vendor_Traffic_Share__c = 10;
            dVendorList.add(dVendor1);
            Delivery_Vendor__c dVendor2 = new Delivery_Vendor__c();
            dVendor2.Traffic_Share__c = tShare2.Id;
           dVendor1.Vendor_Traffic_Share__c = 11;
           dVendor2.Delivery_Vendor_Unique_Key__c='Akamai';
            dVendorList.add(dVendor2);
            
            
            insert dVendorList;
            
            
            list<Delivery_Vendor__c> dvlist=new list<Delivery_Vendor__c>();
            Delivery_Vendor__c dVendor3 = new Delivery_Vendor__c();
            dVendor3.Traffic_Share__c = tShare1.Id;
            dVendor3.Vendor_Traffic_Share__c = 10;
            dVendor3.Delivery_Vendor_Unique_Key__c='Akamai';
            //insert dVendor3;
            dvlist.add(dVendor3);
           // dvlist.add(dVendor3);
            Delivery_Vendor__c dVendor4 = new Delivery_Vendor__c();
            dVendor4.Traffic_Share__c = tShare3.Id;
            dVendor4.Vendor_Traffic_Share__c = 10;
            dVendor4.Can_Akamai_get_more_traffic__c ='No';
            insert dVendor4;
            
            //Calling manageDeliveryVendorsController methods
            manageDeliveryVendorsController.fetchDeliveryVendors(tShare1.Id);
            manageDeliveryVendorsController.saveVendors(new List<Delivery_Vendor__c>{dVendor1}, new List<Delivery_Vendor__c>{dVendor2});
            dVendor1.Delivery_Vendor_Unique_Key__c='Akamai';
            update dVendor1;
            dvlist.add(dVendor1);
            manageDeliveryVendorsController.saveVendors(dvlist,new List<Delivery_Vendor__c>{dVendor4});
            manageDeliveryVendorsController.fetchVendorList();
        }
    }
}