/***
    VF_HomepageControllerTestClass
    @version 1.0
    @author : Hitesh Chawda <hchawda@akamai.com>
    @Description : This class implements the test-cases for the Visual Force controller - "VF_HomepageController"
    
	@History
	--Developer		      --Date			--Change
	Hitesh Chawda	      31/01/2012		Created the class.
	
*/


@isTest
private class BillBoardFlashControllerTestClass{


    static testMethod void BillBoardFlashPositive(){

        Billboard_Alert_Rule__c billar1= new Billboard_Alert_Rule__c(Name='testbar1',isActive__c= true,Alert_Frequency__c = Decimal.valueOf('1'), Alert_Start_Date__c = DATE.TODAY()-2, Alert_End_Date__c= DATE.TODAY()+2, CurrencyIsoCode='USD',Alert_Type__c='BillBoard',Message__c='test_message');
        insert billar1;


        Test.startTest();
        PageReference pageRef = Page.VFPBillBoardFlash;
        Test.setCurrentPageReference(pageRef);
        BillBoardFlashController.condition();
        system.assertEquals('test_message',BillBoardFlashController.message);
        Test.stopTest();


    }
    static testMethod void BillBoardFlashNegative(){


        Billboard_Alert_Rule__c billar2= new Billboard_Alert_Rule__c(Name='testbar1',Alert_Frequency__c = Decimal.valueOf('1'), Alert_Start_Date__c = DATE.TODAY()-2, Alert_End_Date__c= DATE.TODAY()+2, CurrencyIsoCode='USD',Alert_Type__c='Billboard',Message__c='test_message');
        insert billar2;


        Test.startTest();
        PageReference pageRef = Page.VFPBillBoardFlash;
        Test.setCurrentPageReference(pageRef);
        BillBoardFlashController.condition();
        system.assertEquals(null,BillBoardFlashController.message);
        Test.stopTest();

    }


    static testMethod void BillBoardControlPositive(){


        Billboard_Alert_Rule__c billar3= new Billboard_Alert_Rule__c(isActive__c= true,URL_Frame_Width_Unit__c='px',URL_Frame_Width__c=Decimal.valueOf('600'),URL_Frame_Height_Unit__c='px',URL_Frame_Height__c=Decimal.valueOf('400'),Message__c='test_message',Alert_Type__c='Billboard',Name='testbar1',Alert_Frequency__c = Decimal.valueOf('1'), Alert_Start_Date__c = DATE.TODAY()-2, Alert_End_Date__c= DATE.TODAY()+2, CurrencyIsoCode='USD'); 
        insert billar3;



        Test.startTest();
        String returnvar = BillBoardFlashController.BillboardControl();
        Test.stopTest();



    }

}