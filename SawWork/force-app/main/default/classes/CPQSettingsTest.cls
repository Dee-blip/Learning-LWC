/**
* This is test class for CPQSettings class
* @author  Shashank Hegade
* @version 1.0
* @since   2020-11-04
*/
@IsTest(seeAllData = false)
public without sharing class CPQSettingsTest {

    @TestSetup
    static void makeData(){
        
        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('targetUserAlias')
        .withValue('SHEGADE')
        .withActive(true)
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('targetEmailAddresses')
        .withValue('shegade@akamai.com,kimishra@akamai.com')
        .withActive(true)
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('testInteger')
        .withValue('1')
        .withActive(true)
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('testBoolean')
        .withValue('true')
        .withActive(true)
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('DefaultRegionGeoLocation')
        .withValue('{ "Region": "United States", "Geo Location": "North America" }')
        .withActive(true)
        .saveRecord();

    }

    @IsTest
    static void checkTheCustomSettings(){
        
        
        Test.startTest();
        String testString = CPQSettings.getValue('targetUserAlias');
        Set<String> testSet = CPQSettings.getValues('targetEmailAddresses');
        Integer testInt = CPQSettings.getInt('testInteger');
        Boolean testBool = CPQSettings.getBoolean('testBoolean');
        Boolean contains = CPQSettings.contains('targetEmailAddresses', 'shegade@akamai.com');
        Map<String,Object> testMap = CPQSettings.getValueMap('DefaultRegionGeoLocation');
        Test.stopTest();

        System.assert(contains, 'Test case failed');
        
    }

    @IsTest
    static void checkCustomMetadata(){
        
        Test.startTest();
        Map<String, Object> uomPluralMappings = CPQSettings.getMetadataValueMap('uomPluralMappings');
        String lapseString = CPQSettings.getMetadataValue('documentNameFormat');
        Set<String> lapseString1 = CPQSettings.getMetadataValues('documentNameFormat');
        Test.stopTest();

        System.assertEquals('OPP_NAME-QUOTE_NAME-CURR_DATETIME', lapseString, 'Test case failed');
        
    }
}