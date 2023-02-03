@isTest(seeAllData=false)
public class TrialsTestClass{

    @TestSetup
    public static void testSetup(){
        insert new List<Trials__c>{
              new Trials__c(Name = 'TargetHttpDSD', Value__c = 'automation.gmap.edgesuite.net.'),
              new Trials__c(Name = 'EDNSDomain', Value__c = 'trials-automation.com'),
              new Trials__c(Name = 'FileName', Value__c = 'testQA.bin'),
              new Trials__c(Name = 'TargetHttpIon', Value__c = 'automation.rmap.edgesuite.net.'),
              new Trials__c(Name = 'SecretKey', Value__c = '2VN1y53kW504744iu1RbT0i1H0E590rur5z7Q8i8SLYAxX45645614T78'),
              new Trials__c(Name = 'FileUploadPath', Value__c = '/113275/trialsautomation/policies/'),
              new Trials__c(Name = 'TargetHttpsIon', Value__c = 'automation.rmap.edgekey.net.'),
              new Trials__c(Name = 'cnameNameHttpField', Value__c = 'http'),
              new Trials__c(Name = 'EdnsClientToken', Value__c = 'akaa-7avk4rpqjdd7fjlt-cpr33b6tn45ixqxgxu'),
              new Trials__c(Name = 'EdnsRelativePath', Value__c = '/config-dns/v1/zones/trialsautomation.com'),
              new Trials__c(Name = 'EdnsClientSecret', Value__c = 'X/buLInRmal74E3i5sa6456e0JBareIiROIlFD/fflkzr+Y='),
              new Trials__c(Name = 'EdnsAccessToken', Value__c = 'akab-ewrvchf2yrpy3h45645bb-l3w3nveevmbah3e2'),
              new Trials__c(Name = 'Edns_HostName', Value__c = 'akaa-55a32t56mjhzg6ivpo-jabj44znoccmammr.luna.akamaiapis.net'),
              new Trials__c(Name = 'TargetHttpsDSD', Value__c = 'automation.gmap.edgekey.net.'),
              new Trials__c(Name = 'TargetHttpsDSAWAA', Value__c = 'automation.bmap.edgekey.net.'),
              new Trials__c(Name = 'TargetHttpDSAWAA', Value__c = 'automation.bmap.edgesuite.net.'),
              new Trials__c(Name = 'cnameNameHttpsField', Value__c = 'https')
        };
        insert new List<Trials_Automation_Site_Analyser_Details__c>{
            new Trials_Automation_Site_Analyser_Details__c(Name='EmailPrefix',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SABackDateTime',Value__c='58'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SATimeout',Value__c='880000'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAmaxObjSize',Value__c='52428800'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SADownloadLimit',Value__c='52428800'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAURLRegEx',Value__c='^(https?\\\\:\\\\/\\\\/)(([a-zA-Z0-9\\\\.a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\\\-]+[a-zA-Z0-9])\\\\.)+([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\\\-]*[A-Za-z0-9])(.[\\\\S]*)?$'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SARegionId',Value__c='9304,6595'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAProdEndPoint',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAAppType',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SADomainNameRegEx',Value__c='^(([a-zA-Z0-9\\\\.a-zA-Z0-9]\\|[a-zA-Z0-9][a-zA-Z0-9\\\\-]*[a-zA-Z0-9])\\\\.)+([A-Za-z0-9]\\|[A-Za-z0-9][A-Za-z0-9\\\\-]*[A-Za-z0-9])$'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAAPACGroupId',Value__c='14601'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAFrequency',Value__c='3600'),
            new Trials_Automation_Site_Analyser_Details__c(Name='Base64TokenForSAProd',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='RecorderVersion',Value__c='1.39'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAStagingEndPoint',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='Base64TokenForSAStaging',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAManagedCustomer',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SABoundaryValue',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAMasterAcgId',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SASalesforceEmailAddress',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SATestType',Value__c='Test'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SANAGroupId',Value__c='14603'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAEUGroupId',Value__c='14602'),
            new Trials_Automation_Site_Analyser_Details__c(Name='SAGlobalGroupId',Value__c='14600')
        };
    }

    //static{
    //     List<Trials_Automation_Site_Analyser_Details__c> lCustomSetting = new List<Trials_Automation_Site_Analyser_Details__c>();
    //     Trials_Automation_Site_Analyser_Details__c varCustomSetting1 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting1.Name = 'Base64TokenForSAProd';
    //     varCustomSetting1.Value__c = 'dHJpYWxzYXV0b21hdGlvbjp0cmlhbHNhdXRvbWF0aW9uMTIzNA==';
    //     lCustomSetting.add(varCustomSetting1);
         
    //     Trials_Automation_Site_Analyser_Details__c varCustomSetting2 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting2.Name = 'Base64TokenForSAStaging';
    //     varCustomSetting2.Value__c = 'Y2NhcmUyOmFiYzEyMw';
    //     lCustomSetting.add(varCustomSetting2);
        
    //     Trials_Automation_Site_Analyser_Details__c varCustomSetting3 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting3.Name = 'RecorderVersion';
    //     varCustomSetting3.Value__c = '1.39';
    //     lCustomSetting.add(varCustomSetting3);
        
    //     Trials_Automation_Site_Analyser_Details__c varCustomSetting4 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting4.Name = 'SAAPACGroupId';
    //     varCustomSetting4.Value__c = '4';
    //     lCustomSetting.add(varCustomSetting4);
        
    //     Trials_Automation_Site_Analyser_Details__c varCustomSetting5 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting5.Name = 'SAAppType';
    //     varCustomSetting5.Value__c = 'siteanalyzer';
    //     lCustomSetting.add(varCustomSetting5);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting6 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting6.Name = 'SABoundaryValue';
    //     varCustomSetting6.Value__c = '----WebKitFormBoundarySm7nboJHI4QcZjiA';
    //     lCustomSetting.add(varCustomSetting6);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting7 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting7.Name = 'SADomainNameRegEx';
    //     varCustomSetting7.Value__c = 'string';
    //     lCustomSetting.add(varCustomSetting7);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting8 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting8.Name = 'SAEUGroupId';
    //     varCustomSetting8.Value__c = '3';
    //     lCustomSetting.add(varCustomSetting8);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting9 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting9.Name = 'SAFrequency';
    //     varCustomSetting9.Value__c = '3600';
    //     lCustomSetting.add(varCustomSetting9);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting10 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting10.Name = 'SAGlobalGroupId';
    //     varCustomSetting10.Value__c = '1';
    //     lCustomSetting.add(varCustomSetting10);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting11 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting11.Name = 'SAManagedCustomer';
    //     varCustomSetting11.Value__c = 'B-C-20G24H';
    //     lCustomSetting.add(varCustomSetting11);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting12 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting12.Name = 'SAMasterAcgId';
    //     varCustomSetting12.Value__c = 'C-20G24V';
    //     lCustomSetting.add(varCustomSetting12);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting13 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting13.Name = 'SANAGroupId';
    //     varCustomSetting13.Value__c = '2';
    //     lCustomSetting.add(varCustomSetting13);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting14 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting14.Name = 'SAProdEndPoint';
    //     varCustomSetting14.Value__c = 'https://control.akamai.com/PerfAnalytics/api/sa/';
    //     lCustomSetting.add(varCustomSetting14);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting15 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting15.Name = 'SARegionId';
    //     varCustomSetting15.Value__c = '13275';
    //     lCustomSetting.add(varCustomSetting15);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting16 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting16.Name = 'SASalesforceEmailAddress';
    //     varCustomSetting16.Value__c = 'trailsemailservice@g.com';
    //     lCustomSetting.add(varCustomSetting16);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting17 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting17.Name = 'SAStagingEndPoint';
    //     varCustomSetting17.Value__c = 'https://control.akamai.com/PerfAnalytics/api/sa/';
    //     lCustomSetting.add(varCustomSetting17);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting18 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting18.Name = 'SATestType';
    //     varCustomSetting18.Value__c = 't';
    //     lCustomSetting.add(varCustomSetting18);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting19 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting19.Name = 'SAURLRegEx';
    //     varCustomSetting19.Value__c = 'xxx';
    //     lCustomSetting.add(varCustomSetting19);
        
    //    Trials_Automation_Site_Analyser_Details__c varCustomSetting20 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting20.Name = 'SABackDateTime';
    //     varCustomSetting20.Value__c = '52';
    //     lCustomSetting.add(varCustomSetting20);
        
            
    //     Trials_Automation_Site_Analyser_Details__c varCustomSetting21 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting21.Name = 'EmailPrefix';
    //     varCustomSetting21.Value__c = 'SFTRF';
    //     lCustomSetting.add(varCustomSetting21);
        
    //     Trials_Automation_Site_Analyser_Details__c varCustomSetting22 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting22.Name = 'SATimeout';
    //     varCustomSetting22.Value__c = '880000';
    //     lCustomSetting.add(varCustomSetting22);
        
    //     Trials_Automation_Site_Analyser_Details__c varCustomSetting23 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting23.Name = 'SADownloadLimit';
    //     varCustomSetting23.Value__c = '52428800';
    //     lCustomSetting.add(varCustomSetting23);
       
    //     Trials_Automation_Site_Analyser_Details__c varCustomSetting24 = new Trials_Automation_Site_Analyser_Details__c();
    //     varCustomSetting24.Name = 'SAmaxObjSize';
    //     varCustomSetting24.Value__c = '52428800';
    //     lCustomSetting.add(varCustomSetting24);
        
    //    insert lCustomSetting;
        
    //     List<Trials__c> lCustomSettingEDNS = new List<Trials__c>();
    //     Trials__c varCustomSettingEDNS1 = new Trials__c();
    //     varCustomSettingEDNS1.Name = 'cnameNameHttpField';
    //     varCustomSettingEDNS1.Value__c = 'automation';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS1);
         
    //     Trials__c varCustomSettingEDNS2 = new Trials__c();
    //     varCustomSettingEDNS2.Name = 'cnameNameHttpsField';
    //     varCustomSettingEDNS2.Value__c = 'automation';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS2);
        
    //     Trials__c varCustomSettingEDNS3 = new Trials__c();
    //     varCustomSettingEDNS3.Name = 'EdnsAccessToken';
    //     varCustomSettingEDNS3.Value__c = 'akab-ewrvchf2yrpy3hbb-l3w3nveevmbah3e2';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS3);
        
    //     Trials__c varCustomSettingEDNS4 = new Trials__c();
    //     varCustomSettingEDNS4.Name = 'EdnsClientSecret';
    //     varCustomSettingEDNS4.Value__c = 'X/buLInRmal74E3i5sae0JBareIiR';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS4);
        
    //     Trials__c varCustomSettingEDNS5 = new Trials__c();
    //     varCustomSettingEDNS5.Name = 'EdnsClientToken';
    //     varCustomSettingEDNS5.Value__c = 'kaa-7avk4rpq';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS5);
        
    //    Trials__c varCustomSettingEDNS6 = new Trials__c();
    //     varCustomSettingEDNS6.Name = 'EDNSDomain';
    //     varCustomSettingEDNS6.Value__c = 'ajayapra.org';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS6);
        
    //    Trials__c varCustomSettingEDNS7 = new Trials__c();
    //     varCustomSettingEDNS7.Name = 'EdnsRelativePath';
    //     varCustomSettingEDNS7.Value__c = '/config-dns/v1/zones/ajayapra.org';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS7);
        
    //    Trials__c varCustomSettingEDNS8 = new Trials__c();
    //     varCustomSettingEDNS8.Name = 'Edns_HostName';
    //     varCustomSettingEDNS8.Value__c = 'akaa-55a32tmjhzg6ivpo-jabj44znoccmammr.luna.akamaiapis.net';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS8);
        
    //    Trials__c varCustomSettingEDNS9 = new Trials__c();
    //     varCustomSettingEDNS9.Name = 'FileName';
    //     varCustomSettingEDNS9.Value__c = 'testQA.bin';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS9);
        
    //    Trials__c varCustomSettingEDNS10 = new Trials__c();
    //     varCustomSettingEDNS10.Name = 'FileUploadPath';
    //     varCustomSettingEDNS10.Value__c = '/113275/trialsautomation/policies/';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS10);
        
    //    Trials__c varCustomSettingEDNS11 = new Trials__c();
    //     varCustomSettingEDNS11.Name = 'SecretKey';
    //     varCustomSettingEDNS11.Value__c = '2VN1y53kW5047iu1RbT0i1H0E590rur5z7Q8i8';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS11);
        
    //    Trials__c varCustomSettingEDNS12 = new Trials__c();
    //     varCustomSettingEDNS12.Name = 'TargetHttpDSAWAA';
    //     varCustomSettingEDNS12.Value__c = 'trialsautomation.dsa.ff.edgesuite.net.';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS12);
        
    //    Trials__c varCustomSettingEDNS13 = new Trials__c();
    //     varCustomSettingEDNS13.Name = 'TargetHttpDSD';
    //     varCustomSettingEDNS13.Value__c = 'trialsautomation.dsd.ff.edgesuite.net.';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS13);
        
    //    Trials__c varCustomSettingEDNS14 = new Trials__c();
    //     varCustomSettingEDNS14.Name = 'TargetHttpIon';
    //     varCustomSettingEDNS14.Value__c = 'trialsautomation.ion.ff.edgesuite.net.';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS14);
        
    //    Trials__c varCustomSettingEDNS15 = new Trials__c();
    //     varCustomSettingEDNS15.Name = 'TargetHttpsDSAWAA';
    //     varCustomSettingEDNS15.Value__c = 'trialsautomation.dsa.edgekey.net.';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS15);
        
    //    Trials__c varCustomSettingEDNS16 = new Trials__c();
    //     varCustomSettingEDNS16.Name = 'TargetHttpsDSD';
    //     varCustomSettingEDNS16.Value__c = 'trialsautomation.dsd.edgekey.net.';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS16);
        
    //    Trials__c varCustomSettingEDNS17 = new Trials__c();
    //     varCustomSettingEDNS17.Name = 'TargetHttpsIon';
    //     varCustomSettingEDNS17.Value__c = 'trialsautomation.ion.edgekey.net.';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS17);
        
    //     Trials__c varCustomSettingEDNS18 = new Trials__c();
    //     varCustomSettingEDNS18.Name = 'SATestType';
    //     varCustomSettingEDNS18.Value__c = 't';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS18);
        
    //     Trials__c varCustomSettingEDNS19 = new Trials__c();
    //     varCustomSettingEDNS19.Name = 'SAURLRegEx';
    //     varCustomSettingEDNS19.Value__c = 'xxx';
    //     lCustomSettingEDNS.add(varCustomSettingEDNS19);
        
    //    insert lCustomSettingEDNS;

    //    Gsm
    //}
    @isTest static void testCallout() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new TrialsMockSAResponseGenerator());
        Trials_Request_Form__c varTRF = CreateTrialsReqForm(); 
        ApexPages.StandardController sc = new ApexPages.standardController(varTRF);

        TrialsRequestFormCtrl trialsReq = new TrialsRequestFormCtrl(sc);
        trialsReq.mainMethod();
        trialsReq.mainMethod();
        trialsReq.submit();
        varTRF.Origin_Binary_Response__c = TrialsUtilClass.convertIntToBinary('10');
        varTRF.Trials_Akamai_Binary_Response__c = '000000000000000000';
        varTRF.Trials_Origin_Provisioned_Test_Id__c = '123';
        varTRF.Trials_Akamai_Provisioned_Test_Id__c = '321';
        varTRF.Trials_Email_Provisioned__c = false;
        update varTRF;
        TrialsUtilClass.provisionTest(varTRF.Id);
        Test.startTest();
        TrialsUtilClass.deleteTestFromSA(varTRF.Id);
        Test.stopTest();
    }
    
        @isTest static void testCalloutProvision() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new TrialsMockSAResponseGenerator());
        Trials_Request_Form__c varTRF = CreateTrialsReqForm();
        ApexPages.StandardController sc = new ApexPages.standardController(varTRF);

        TrialsRequestFormCtrl trialsReq = new TrialsRequestFormCtrl(sc);
        //EdnsRequest ednsReq = new EdnsRequest();
        trialsReq.mainMethod();
        trialsReq.mainMethod();
        trialsReq.submit();
        varTRF.Origin_Binary_Response__c = TrialsUtilClass.convertIntToBinary('10');
        varTRF.Trials_Akamai_Binary_Response__c = '000000000000000000';
        varTRF.Trials_Origin_Provisioned_Test_Id__c = '123';
        varTRF.Trials_Akamai_Provisioned_Test_Id__c = '321';
        varTRF.Trials_Email_Provisioned__c = false;
        update varTRF;
            Test.startTest();
        trialsReq.deleteTestFromSA();
            Test.stopTest();
    }
    
    @isTest static void testCalloutProvisionAgain() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new TrialsMockSAResponseGenerator());
        Trials_Request_Form__c varTRF = CreateTrialsReqForm();
         
        ApexPages.StandardController sc = new ApexPages.standardController(varTRF);

        TrialsRequestFormCtrl trialsReq = new TrialsRequestFormCtrl(sc);
        //EdnsRequest ednsReq = new EdnsRequest();
        trialsReq.mainMethod();
        system.currentPageReference().getParameters().put('Id', varTRF.Id);
        trialsReq.mainMethod();
        trialsReq.submit();
        
        varTRF.Origin_Binary_Response__c = TrialsUtilClass.convertIntToBinary('10');
        varTRF.Trials_Akamai_Binary_Response__c = '000000000000000000';
        varTRF.Trials_Origin_Provisioned_Test_Id__c = '123';
        varTRF.Trials_Akamai_Provisioned_Test_Id__c = '321';
        varTRF.Trials_Email_Provisioned__c = true;
        varTRF.Trials_Protocol__c = 'Freeflow';
        varTRF.Trials_Product__c = 'Ion';
        varTRF.Trials_Cacheable_URLs__c = 'hello.com';
        update varTRF;
            Test.startTest();
        //trialsReq.provisionTest();
            Test.stopTest();
    }
    
    @isTest static void testCalloutDelete() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new TrialsMockSAResponseGenerator());
        Trials_Request_Form__c varTRF = CreateTrialsReqForm();
        ApexPages.StandardController sc = new ApexPages.standardController(varTRF);

        TrialsRequestFormCtrl trialsReq = new TrialsRequestFormCtrl(sc);
        //EdnsRequest ednsReq = new EdnsRequest();
        trialsReq.mainMethod();
        varTRF.Origin_Binary_Response__c = '1111111111111111111';
        varTRF.Trials_Akamai_Binary_Response__c = '1111111111111111111';
        varTRF.Trials_Origin_Provisioned_Test_Id__c = null;
        varTRF.Trials_Akamai_Provisioned_Test_Id__c = null;
        varTRF.Trials_Email_Provisioned__c = false;
        update varTRF;
        //insert trialsReq;
        TrialsUtilClass.provisionTest(varTRF.Id);
        Test.startTest();
        TrialsUtilClass.deleteTestFromSA(varTRF.Id);
        Test.stopTest();
        
    }
    
     public static testmethod Trials_Request_Form__c CreateTrialsReqForm(){
        Trials_Request_Form__c objTRF = new Trials_Request_Form__c();
        // try{
             
             objTRF.Trials_Trials_Request_Name__c = 'Test Class Form';
             objTRF.Trials_Protocol__c = 'Freeflow';
             objTRF.Trials_Product__c = 'DSA';
             objTRF.Trials_Hostnames_Digital_Properties__c = 'google.com';
             objTRF.Trials_URLs__c = 'https://google.com';
             objTRF.Trials_Frequency_for_Running_Test__c = '60';
             objTRF.Trials_Location_of_Test_Agents__c = 'APAC';
             objTRF.Trials_Test_Duration_In_Days__c = '1';
             objTRF.Trials_Origin__c = 'google.com';
             objTRF.Trials_SRTO__c = '/';
             objTRF.Trails_File_Extension__c = 'ttl';
             objTRF.Trials_TTL__c = '0 sec';
             objTRF.Trials_DNS_Created__c = true;
             objTRF.Trials_JSON_Received_For_Akamai_XML__c = true;
             objTRF.Trials_JSON_Received_For_Origin_XML__c = true;
             objTRF.Origin_Binary_Response__c = '000000000000000000';
             objTRF.Trials_Akamai_Binary_Response__c = '000000000000000000';
             objTRF.Trials_Third_Party_Exclusions__c = true;
             objTRF.Trials_Additional_Email_Addresses__c = 'abc@g.com';
             objTRF.TrialsTestNamePrefix__c = 'TestPrefix';
            
            return objTRF;
     }
     
     public static testmethod void restServiceTest(){
    
         JSONGenerator responseJSON = JSON.createGenerator(true);
         Trials_Request_Form__c varTRF = CreateTrialsReqForm();
         ApexPages.StandardController sc = new ApexPages.standardController(varTRF);
         TrialsRequestFormCtrl trialsReq = new TrialsRequestFormCtrl(sc);
        //EdnsRequest ednsReq = new EdnsRequest();
        trialsReq.mainMethod();
        //insert varTRF;
        Trials_XML__c objTXML = [SELECT Id FROM Trials_XML__c WHERE Trials_Request_Form__c = :varTRF.Id][0];
        Trials_XML__c objTXMLAkamai = [SELECT Id FROM Trials_XML__c WHERE Trials_Request_Form__c = :varTRF.Id][1]; 
        responseJSON.writeStartObject();             
            responseJSON.writeFieldName('receivedJSON');
           
            responseJSON.writeStartArray();
                responseJSON.writeStartObject();
                    responseJSON.writeFieldName('tranSummary');
                        responseJSON.writeStartObject();
                        responseJSON.writeStringField('numUrls', '1');
                        responseJSON.writeStringField('totalBytes', '1430');
                        responseJSON.writeStringField('regionId', '123');
                        responseJSON.writeStringField('transactionTime', '100');
                        responseJSON.writeStringField('hasErrors', '257');
                        responseJSON.writeStringField('numPages', '1');
                responseJSON.writeEndObject();
        
                responseJSON.writeStringField('regionId', '13275');
                responseJSON.writeStringField('regionName', 'Queretaro,Uninet SA');
                responseJSON.writeStringField('testType', 'tran');

                responseJSON.writeFieldName('pages');
                    responseJSON.writeStartArray();
                    responseJSON.writeStartObject();
                        responseJSON.writeFieldName('pageObjects');
                            responseJSON.writeStartArray();
                            responseJSON.writeStartObject();
                                responseJSON.writeStringField('path', 'https');
                                responseJSON.writeStringField('protocol', 'https');
                                responseJSON.writeStringField('port', '123');
                                responseJSON.writeStringField('objectType', 'b');
                                responseJSON.writeStringField('serverIp', '74.125'+'.227.177');
                                responseJSON.writeStringField('isConnectionAlive', '1');
                                responseJSON.writeStringField('contentLen', 'https');
                                responseJSON.writeStringField('checkSum', 'https');
                                responseJSON.writeStringField('dnsTime', '123');
                                responseJSON.writeStringField('handshakeTime', 'b');
                                responseJSON.writeStringField('dataStartTime', '74.125.'+'227.177');
                                responseJSON.writeStringField('dataDownloadTime', '1');
                                responseJSON.writeStringField('totalTime', 'https');
                                responseJSON.writeStringField('isReconnect', 'https');
                                responseJSON.writeStringField('connectTime', '123');
                                responseJSON.writeStringField('errorCode', 'b');
                                responseJSON.writeStringField('startTime', '74.125.'+'227.177');
                                responseJSON.writeStringField('responseCode', '1');
                                responseJSON.writeStringField('domain', 'www.google.com');
                            responseJSON.writeEndObject();
                            responseJSON.writeEndArray();
                
                responseJSON.writeFieldName('pageSummary');
                    responseJSON.writeStartObject();
                        responseJSON.writeStringField('totalBaseUrls', '1');
                        responseJSON.writeStringField('domLoading', '1430');
                        responseJSON.writeStringField('domComplete', '123');
                        responseJSON.writeStringField('loadEventStartTime', '100');
                        responseJSON.writeStringField('loadEventEndTime', '257');
                        responseJSON.writeStringField('totalUrls', '1');
                        responseJSON.writeStringField('totalBytes', '1');
                        responseJSON.writeStringField('stepNum', '1430');
                        responseJSON.writeStringField('totalDownloadTime', '123');
                        responseJSON.writeStringField('baseDownloadTime', '100');
                        responseJSON.writeStringField('hasErrors', '257');
                    responseJSON.writeEndObject();
                responseJSON.writeEndObject();
                responseJSON.writeEndArray();
                

    responseJSON.writeEndObject();
    responseJSON.writeEndArray();
    JSONParser parser = JSON.createParser(responseJSON.getAsString());
    TrialsResponseFromSA.JSONFromSA responseProvisioning = (TrialsResponseFromSA.JSONFromSA)parser.readValueAs(TrialsResponseFromSA.JSONFromSA.class);
       TrialsResponseFromSA.JSONFromSA classInstance = new TrialsResponseFromSA.JSONFromSA();
       TrialsResponseFromSA.PageObjects varPageObj = new TrialsResponseFromSA.PageObjects();
       TrialsResponseFromSA.Pages varPages = new TrialsResponseFromSA.Pages();
       TrialsResponseFromSA.PageSummary varPageSum = new TrialsResponseFromSA.PageSummary();
       TrialsResponseFromSA.TranSummary varTranSum  = new TrialsResponseFromSA.TranSummary();  
       list<TrialsResponseFromSA.JSONFromSA> lnewlistforTest = new list<TrialsResponseFromSA.JSONFromSA>();
       lnewlistforTest.add(responseProvisioning);
       TrialsResponseFromSA.attachResponseToChildObject(objTXML.Id,lnewlistforTest);
       TrialsResponseFromSA.attachResponseToChildObject(objTXMLAkamai.Id,lnewlistforTest);
    }
    
    public static testmethod void restEDNSServiceTest(){
        Trials_Request_Form__c varTRF = CreateTrialsReqForm(); 
        insert varTRF;
        ApexPages.StandardController sc = new ApexPages.standardController(varTRF);
        TrialsRequestFormCtrl trialsReq = new TrialsRequestFormCtrl(sc);
        //EdnsRequest ednsReq = new EdnsRequest();
        trialsReq.mainMethod();
        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();        
        gen.writeStringField('token', 'DummyToken');
        gen.writeFieldName('zone');
        gen.writeStartObject();
        gen.writeStringField('name','audupi.in');
        gen.writeFieldName('soa');
        gen.writeStartObject();
        gen.writeStringField('contact', 'hostmaster.akamai.com.');
        gen.writeNumberField('expire', 604800);
        gen.writeNumberField('minimum', 180);
        gen.writeStringField('originserver', 'asia3.akam.net.');
        gen.writeNumberField('refresh', 43200);
        gen.writeNumberField('retry', 7200);
        gen.writeNumberField('serial', 1234);
        gen.writeNumberField('ttl', 86400);
        gen.writeEndObject();
        gen.writeFieldName('ns');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeBooleanField('active', true);
        gen.writeStringField('name', '');
        gen.writeStringField('target', 'asia3.akam.net.');
        gen.writeNumberField('ttl', 3600);
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeBooleanField('active', true);
        gen.writeStringField('name', '');
        gen.writeStringField('target', 'use2.akam.net.');
        gen.writeNumberField('ttl', 3600);
        gen.writeEndObject();
        gen.writeEndArray();
        
        gen.writeFieldName('a');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeBooleanField('active', true);
        gen.writeStringField('name', '');
        gen.writeStringField('target', 'asia3.akam.net.');
        gen.writeNumberField('ttl', 3600);
        gen.writeEndObject();
        gen.writeEndArray();
        
        gen.writeFieldName('cname');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeBooleanField('active', true);
        gen.writeStringField('name', 'origin-testing100.automation.');
        gen.writeStringField('target', '1.2.3.4.');
        gen.writeNumberField('ttl', 3600);
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeEndObject();
        //sc = new ApexPages.standardController(varTRF);
        EdnsResponse varEdns = new EdnsResponse();
        EdnsResponse.Zone varEdnsZone = new EdnsResponse.Zone();
        EdnsResponse.A varEdnsA = new EdnsResponse.A();
        EdnsResponse.Cname varEdnsCname = new EdnsResponse.Cname();
        EdnsResponse.Soa varEdnsSoa = new EdnsResponse.Soa();
        TrialsUtilClass.ResponseForAddingTest varResponse = new TrialsUtilClass.ResponseForAddingTest();
        EdnsResponse.Ns varNs = new EdnsResponse.Ns();
        
        JSONParser parser = JSON.createParser(gen.getAsString());
        EdnsResponse responseProvisioning = (EdnsResponse)parser.readValueAs(EdnsResponse.class);
        TrialsRequestFormCtrl instanceOfCtrl = new TrialsRequestFormCtrl();
        String resp = trialsReq.generatePostBody(responseProvisioning);
        Test.startTest();
        //trialsReq.doInstantCheck();
        Test.stopTest();
    }
    
    public static testmethod void restEDNSServiceTestESSL(){
        Trials_Request_Form__c varTRF = CreateTrialsReqForm(); 
        varTRF.Trials_Protocol__c = 'ESSL';
        varTRF.Trials_Product__c = 'DSA';
        insert varTRF;
        ApexPages.StandardController sc = new ApexPages.standardController(varTRF);
        TrialsRequestFormCtrl trialsReq = new TrialsRequestFormCtrl(sc);
        //EdnsRequest ednsReq = new EdnsRequest();
        trialsReq.mainMethod();
        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();        
        gen.writeStringField('token', 'DummyToken');
        gen.writeFieldName('zone');
        gen.writeStartObject();
        gen.writeStringField('name','audupi.in');
        gen.writeFieldName('soa');
        gen.writeStartObject();
        gen.writeStringField('contact', 'hostmaster.akamai.com.');
        gen.writeNumberField('expire', 604800);
        gen.writeNumberField('minimum', 180);
        gen.writeStringField('originserver', 'asia3.akam.net.');
        gen.writeNumberField('refresh', 43200);
        gen.writeNumberField('retry', 7200);
        gen.writeNumberField('serial', 1234);
        gen.writeNumberField('ttl', 86400);
        gen.writeEndObject();
        gen.writeFieldName('ns');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeBooleanField('active', true);
        gen.writeStringField('name', '');
        gen.writeStringField('target', 'asia3.akam.net.');
        gen.writeNumberField('ttl', 3600);
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeBooleanField('active', true);
        gen.writeStringField('name', '');
        gen.writeStringField('target', 'use2.akam.net.');
        gen.writeNumberField('ttl', 3600);
        gen.writeEndObject();
        gen.writeEndArray();
        
        gen.writeFieldName('a');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeBooleanField('active', true);
        gen.writeStringField('name', '');
        gen.writeStringField('target', 'asia3.akam.net.');
        gen.writeNumberField('ttl', 3600);
        gen.writeEndObject();
        gen.writeEndArray();
        
        gen.writeFieldName('cname');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeBooleanField('active', true);
        gen.writeStringField('name', 'origin-testing100.automation.');
        gen.writeStringField('target', '1.2.3.4.');
        gen.writeNumberField('ttl', 3600);
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeEndObject();
        //sc = new ApexPages.standardController(varTRF);
        EdnsResponse varEdns = new EdnsResponse();
        EdnsResponse.Zone varEdnsZone = new EdnsResponse.Zone();
        EdnsResponse.A varEdnsA = new EdnsResponse.A();
        EdnsResponse.Cname varEdnsCname = new EdnsResponse.Cname();
        EdnsResponse.Soa varEdnsSoa = new EdnsResponse.Soa();
        TrialsUtilClass.ResponseForAddingTest varResponse = new TrialsUtilClass.ResponseForAddingTest();
        EdnsResponse.Ns varNs = new EdnsResponse.Ns();
        
        JSONParser parser = JSON.createParser(gen.getAsString());
        EdnsResponse responseProvisioning = (EdnsResponse)parser.readValueAs(EdnsResponse.class);
        TrialsRequestFormCtrl instanceOfCtrl = new TrialsRequestFormCtrl();
        String resp = trialsReq.generatePostBody(responseProvisioning);
        
        varTRF.Trials_Protocol__c = 'ESSL';
        varTRF.Trials_Product__c = 'DSD';
        varTRF.Trials_TTL__c = '7 Days';
        trialsReq.mainMethod();
        
        resp = trialsReq.generatePostBody(responseProvisioning);
        
        varTRF.Trials_Protocol__c = 'Freeflow';
        varTRF.Trials_Product__c = 'WAA';
        varTRF.Trials_TTL__c = '6 Hours';
        trialsReq.mainMethod();
        
        resp = trialsReq.generatePostBody(responseProvisioning);
        
        varTRF.Trials_Protocol__c = 'Freeflow';
        varTRF.Trials_Product__c = 'Ion';
        varTRF.Trials_TTL__c = '5 Mins';
        trialsReq.mainMethod();
        
        resp = trialsReq.generatePostBody(responseProvisioning);
        
        varTRF.Trials_Protocol__c = 'ESSL';
        varTRF.Trials_Product__c = 'ION';
        varTRF.Trials_TTL__c = '0 sec';
        update varTRF;
        
        resp = trialsReq.generatePostBody(responseProvisioning);
        
        varTRF.Trials_Protocol__c = 'Freeflow';
        varTRF.Trials_Product__c = 'DSD';
        update varTRF;
        
        resp = trialsReq.generatePostBody(responseProvisioning);
    }
    
    static testMethod void trialsEmailServiceTest() { 
      
        Trials_Request_Form__c varTRF = CreateTrialsReqForm(); 
        varTRF.Trials_Protocol__c = 'ESSL';
        varTRF.Trials_Product__c = 'DSA';
        insert varTRF;
        ApexPages.StandardController sc = new ApexPages.standardController(varTRF);
        TrialsRequestFormCtrl trialsReq = new TrialsRequestFormCtrl(sc);
        //EdnsRequest ednsReq = new EdnsRequest();
        trialsReq.mainMethod();
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
        //List of text attachments
        List<Messaging.InboundEmail.BinaryAttachment> tList = new List<Messaging.InboundEmail.BinaryAttachment>();
        Messaging.Inboundemail.BinaryAttachment tAttachment1 = new Messaging.Inboundemail.BinaryAttachment();
        
        Trials_Request_Form__c varForEmail = [SELECT Id, Name From Trials_Request_Form__c LIMIT 1][0];
    
      // setup the data for the email
      system.debug('####' + varForEmail.Name);
      email.subject = varForEmail.Name + ':';
      email.fromAddress = 'someaddress@email.com';
      email.plainTextBody  = 'TEST Body';
      tAttachment1.fileName = 'testAttach1.txt';
      tAttachment1.body = blob.valueOf('my attachment text');
      tList.add(tAttachment1);
      email.binaryAttachments = tList;
      
      // call the email service class and test it with the data in the testMethod
      TrailsEmailService  testInbound = new TrailsEmailService();
      testInbound.handleInboundEmail(email, env);
      
    } 
}