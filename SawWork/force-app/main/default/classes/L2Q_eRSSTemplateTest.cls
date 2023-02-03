@isTest
(SeeAllData=false)
public class L2Q_eRSSTemplateTest {
    @testSetup static void setup() {
    L2Q_eRSSTemplate.createTemplate('__Unique__Template__', 'ao0bc0de0908smsd') ;
    }
    @isTest static void verifyPositivetest()
    {
        L2Q_eRSSTemplate.returnData('10','1','My Open Templates');
        L2Q_eRSSTemplate.returnData('10','1','Published Templates');
        L2Q_eRSSTemplate.returnData('10','1','Unknown');
        Id templateId = [Select id from Survey__c limit 1].Id;
        Id rec1 = L2Q_eRSSTemplate.createTemplate('__Unique__Template_01_', 'ao0bc0de0908smsd') ;
        Id rec2 = L2Q_eRSSTemplate.createTemplate('__Unique__Template_02', 'ao0bc0de0908smsd') ;
        L2Q_eRSSTemplate.convertWrapper c = new L2Q_eRSSTemplate.convertWrapper();
        c.label = 'Name';
        c.value = 'Unique';
        List<L2Q_eRSSTemplate.convertWrapper> ct = new List<L2Q_eRSSTemplate.convertWrapper>() ;
        ct.add(c);
        L2Q_eRSSTemplate.templateSearch(JSON.serialize(ct),'My Open Templates',1);
        L2Q_eRSSTemplate.templateSearch(JSON.serialize(ct),'tesrt',2);
        L2Q_eRSSTemplate.deleteTemplate(templateId);
        L2Q_eRSSTemplate.returnmetadataString('eRsstemplateQuery');
    }
    @isTest static void verifynegativetest() {
        try {
            L2Q_eRSSTemplate.deleteTemplate('00');  
        }
        catch(Exception ex)
        {
            
        }
    }
    

}