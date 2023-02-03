/**
 * This class contains unit tests for Language Detection Apex classes
 *
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Shivam Verma                Created Class
 ****/



@isTest

public class LanguageDetectionTestclass {
    

    public testMethod static void testEnglish() {

    	String englishText = 'Text is in English Language';

    	String languageCode = LanguageDetectionClass.getLanguage(englishText);

    	System.assertEquals(languageCode,'en');
    }
    
    public testMethod static void testJapanese() {

    	String japaneseText = 'Tテキストは日本語である';

    	String languageCode = LanguageDetectionClass.getLanguage(japaneseText);

    	System.assertEquals(languageCode,'ja');
    }

    public testMethod static void testKorean() {

    	String koreanText = '이 텍스트는 한국어 에';

    	String languageCode = LanguageDetectionClass.getLanguage(koreanText);

    	System.assertEquals(languageCode,'ko');
    }

    public testMethod static void testThai() {

        String thaiText = 'ข้อความ นี้อยู่ใน ไทย';

        String languageCode = LanguageDetectionClass.getLanguage(thaiText);

        System.assertEquals(languageCode,'th');
    }

    public testMethod static void testRussian() {

        String russianText = 'Этот текст находится в России';

        String languageCode = LanguageDetectionClass.getLanguage(russianText);

        System.assertEquals(languageCode,'ru');
    }

    public testMethod static void testHerbew() {

        String hebrewText = 'הטקסט כתוב בעברית';

        String languageCode = LanguageDetectionClass.getLanguage(hebrewText);

        System.assertEquals(languageCode,'hw');
    }

    public testMethod static void testChinese() {

        String chineseText = '本文是中国';

        String languageCode = LanguageDetectionClass.getLanguage(chineseText);

        System.assertEquals(languageCode,'zh_Hant');
    }

    public testMethod static void testOtherLanguage() {

        
        String spanishText = 'Este texto está en español';
        String frenchText = 'Ce texte est en français';
        String italianText = 'Questo testo è in italiano';
        String swedishText = 'Denna text är på svenska';

        
        String languageCode1 = LanguageDetectionClass.getLanguage(spanishText);
        System.assertEquals(languageCode1,'eu');

        String languageCode2 = LanguageDetectionClass.getLanguage(frenchText);
        System.assertEquals(languageCode2,'eu');

        String languageCode3 = LanguageDetectionClass.getLanguage(italianText);
        System.assertEquals(languageCode3,'eu');

        String languageCode4 = LanguageDetectionClass.getLanguage(swedishText);
        System.assertEquals(languageCode4,'eu');


    }


}