/**
  History
    
    --Developer      --Date            --Description
    Shivam Verma     22 Oct 2014       Created this Class for laguage detection given any text input
    Shivam Verma     02 Dec 2014       Added the method detectLanguageForCombination to identify the language 
                                        for the combination of firstname and lastname

    Shivam Verma    29 Dec 2014         CR 2865954 PRM: Handling errors on First Name and Last Name
                               
*/



public class LanguageDetectionClass {

    public static String getLanguage(String inputValue) {
    
        /* Preprocessing the input
         * Remove the Numerals from the input string
         * Remove the Whitespaces from the inout String
         */
        String inputWithoutNumerals = inputValue.replaceAll('[0-9]','');
        String input = inputWithoutNumerals.replaceAll('\\s','');
        
        String languageCode;
        String englishCode = 'en';
        String japaneseCode = 'ja';
        String korenaCode = 'ko';
        String thaiCode = 'th';
        String russianCode = 'ru';
        String hebrewCode = 'hw';
        String chineseCode = 'zh_Hant';
        String otherLanguage = 'eu';


        if (isEnglish(input,inputValue)) {
            return englishCode;
        } else if (isJapanese(input)) {
            return japaneseCode;
        } else if (isKorean(input)) {
            return korenaCode;
        } else if (isThai(input)) {
            return thaiCode;
        } else if (isRussian(input)) {
            return russianCode;
        } else if (isHebrew(input)) {
            return hebrewCode;
        } else if (isChinese(input)) {
            return chineseCode;
        } else {
            return otherLanguage;
        }
        
    }

    public static boolean isEnglish(String input,String originalValue) {
        
        Boolean isEnglish = false;

        if (String.isEmpty(input) && !String.isEmpty(originalValue)) {
            return true;
        }

        String englishPattern = '[A-Za-z]';
        System.debug('The value of input inside isEnglish method'+input);
        Integer inputLength = input.length();

        for (Integer i=0; i<inputLength; i++) {

            String singleCharacter = input.substring(i,i+1);
            if (singleCharacter != ' ') {
                if (patternMatch(englishPattern, singleCharacter)) {
                isEnglish = true;
                } else {
                    isEnglish = false;
                    return false;
                }
            }
            
        }
            
        return isEnglish;

    }

    public static boolean isJapanese(String input) {
        String hirananaPattern = '.*[\\p{script=Hiragana}].*';
        String katakanaPattern = '.*[\\p{script=Katakana}].*';

        if (patternMatch(katakanaPattern,input) || patternMatch(hirananaPattern,input)) {
            return true;
        }
        return false;
    }

    public static boolean isKorean(String input) {
        String korenaPattern = '.*[\\p{script=Hangul}].*';

        if (patternMatch(korenaPattern, input)) {
            return true;
        }
        return false;
    }

    public static boolean isThai(String input) {
        String thaiPattern = '.*[\\p{script=Thai}].*';

        if (patternMatch(thaiPattern, input)) {
            return true;
        }
        return false;
    }

    public static boolean patternMatch(String languageRegex, String content) {
        Pattern languagePattern = Pattern.compile(languageRegex);
        Matcher languageMatcher = languagePattern.matcher(content);

        return languageMatcher.matches();
    }

    public static boolean isRussian(String input) {
        String russianPattern = '.*[\\p{script=Cyrillic}].*';

        if (patternMatch(russianPattern, input)) {
            return true;
        }
        return false;
    }

    public static boolean isHebrew(String input) {
        String hebrewPattern = '.*[\\p{script=Hebrew}].*';

        if (patternMatch(hebrewPattern, input)) {
            return true;
        }
        return false;
    }

    public static boolean isChinese(String input) {
        String chinesePattern = '.*[\\p{script=Han}].*';

        if (patternMatch(chinesePattern,input)) {
            return true;
        }
        return false;
    }

    /* CR 2841150 Detect language for the combination of firstname and lastname
     *            Foreign language will be given Priority over English
     */
    public static string detectLanguageForCombination(String firstname,String lastname) {

        String language = 'en';

        String lastNameLanguage;
        String firstnameLanguage;
        
        if (lastname != null) {
            lastNameLanguage = LanguageDetectionClass.getLanguage(lastName);
            if (lastNameLanguage != 'en') {
                return lastNameLanguage;
            }else if (firstname != null) {
                firstnameLanguage = LanguageDetectionClass.getLanguage(firstname);
                return firstnameLanguage;
            } else {
                return lastNameLanguage;
            }
        } else if (firstname != null) {
            firstnameLanguage = LanguageDetectionClass.getLanguage(firstname);
            return firstnameLanguage;
        }

        return language;
    }
    
}