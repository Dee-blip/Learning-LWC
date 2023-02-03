@isTest 
private class SF1_AdvAccExtensionTest {   

    //Method to get SF1_AdvAccExtension object
    static SF1_AdvAccExtension getClassObject(){
        Account acc = new Account();
        ApexPages.StandardController controller = new ApexPages.StandardController(acc);
		SF1_AdvAccExtension sf1 = new  SF1_AdvAccExtension(controller); 
        return sf1;
    }

    @isTest static void testShowCreateAccForSF1(){
        SF1_AdvAccExtension sf1 = getClassObject();
        sf1.showCreateAccForSF1();
        System.assertEquals(true, sf1.SF1CreateAcc);
    }
        
    @isTest static void testHideCreateAccForSF1(){
        SF1_AdvAccExtension sf1 = getClassObject();
        sf1.hideCreateAccForSF1();
        System.assertEquals(false, sf1.SF1CreateAcc);
    }
}