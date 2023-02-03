/***
    AddressValidationClass
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description :  This class contains static methods that are called by Account and Contact triggers.
                    If Validation Override is not checked, it makes sure the address entered in these objects are valid as per the following rules : 
                    1. Country field should not be left NULL if any other field is filled.
                    2. Street and City are defaulted to 'TBD', if they are null.
                    3. No user should be able to enter more than 3 lines in the street field.
                    4. The country should be a valid from the list of maintained countries.
                    5. Within the selected country, if 'CheckState checkbox is checked, then a valid state should be entered.
                    6. Users are directed to the "List of valid countries and states" link under FAQ, incase of invalid countries/states errors.    
                    7. Account.Primary Address is mandatory.
                    8. Contact.Primary Contact Address is mandatory.
                    
    @History
    --Developer           --Date            --Change
    Karteek Kumar M                         Created the class.
    Karteek Kumar M       18/04/10          Use contactenation of State:Country for uniqueness.
                                            Made Contact.Primary Contact Address is mandatory.  
    Karteek Kumar M       19/11/10          CR 866306 Remove upload restrcitions for Contact upload
                                            Providing Exception for Business Operations and System Administrators
                                            The override implementations is a little messy !!!  
    Vinayendra T N        28/12/10          CR 880040 Use Custom Settings on Address Validation Class
                                            - Moved frequently used hard coded values to Custom Settings            
    Vinayendra T N        21/01/11          CR 919522 Developments related to PRM
                                            - Added address validation in opportunities for Partners.
    Ali Km                21/03/11          CR 1013241 Country Mapping does not work with in Uppercase
                                            - Added code that formats the generic Country field. New method added:
                                                -> formatCountry() 
    Vinayendra T N        06/06/11          CR 1121880 Update fields from text fields to picklist
                                            - Commenting out validation rule for Oppty.
    Lakshmi Narayana R    10/07/13          CR 2295281  Primary Countries like *Ukraine* shows up as *UKRAINE* on Accounts
                                            - Changed the condition from indexOf to equals in the formatCountry() method    
                                            - Added the default code before validation_override__c condition check.                             
*/
public with sharing class AddressValidationClass 
{
  //public static Address_Validation_Class_Settings__c customSettings = Address_Validation_Class_Settings__c.getInstance('v1.0'); //SFDC-2304
  public static Boolean CallValidateAddressFirstRunFlag_Account = true;
  public static Boolean CallValidateAddressFirstRunFlag_ContactMailing = true;
  public static Boolean CallValidateAddressFirstRunFlag_ContactOther = true;
  public static Boolean CallValidateAddressFirstRunFlag_Opportunity = true;
  public static Boolean ValidateAddressFirstRunFlag_AccCreation = true;
  //static Map<String,Countries__c> countryMap = new Map<String,Countries__c>(); //SFDC-2304
  //static Map<String,States__c> stateMap = new Map<String,States__c>(); //SFDC-2304
  static Map<String,Country_List__mdt> countryMap = new Map<String,Country_List__mdt>(); //SFDC-2304
  static Map<String,State_List__mdt> stateMap = new Map<String,State_List__mdt>(); //SFDC-2304
  /**
     GetCountryMap(Set<String> p_Countries,Set<String> p_States)
     - Updates the static class members countryMap and StateMap, by querying only for the Coutnries and States that are needed.
  */
   public static void GetCountryMap(Set<String> p_Countries,Set<String> p_States)
  {
    /*for(Countries__c c:[Select Name, Id, Check_State__c From Countries__c where Name IN :p_Countries])
        countryMap.put(c.Name.toLowerCase(),c);
    // Use contactenation of State:Country for uniqueness.
    for(States__c s:[Select Name, Id, Associated_Country__c From States__c where Name IN :p_States])
        stateMap.put(s.Name.toLowerCase()+':'+s.Associated_Country__c.toLowerCase(), s);*/ //SFDC-2304
      for(Country_List__mdt c:[Select Label, Id, Check_State__c From Country_List__mdt where Country_Name__c IN :p_Countries]) //SFDC-2304
          countryMap.put(c.Label.toLowerCase(),c); //SFDC-2304
      // Use contactenation of State:Country for uniqueness.
      for(State_List__mdt s:[Select Label, Id, Associated_Country__c From State_List__mdt where Label IN :p_States]) //SFDC-2304
          stateMap.put(s.Label.toLowerCase()+':'+s.Associated_Country__c.toLowerCase(), s); //SFDC-2304
  }
  /**
     DefaultTBD(String p_Any)
     - returns 'TBD' if null, else return p_Any
  */
  private static String DefaultTBD(String p_Any)
  {
    if(p_Any==null)
        return GsmUtilClass.getGSMSettingValue('TBD'); //SFDC-2304
    else
        return p_Any;
  }
  /**
     ValidateAddress(String p_Street,String p_City,String p_State,String p_PostalCode,String p_Country)
     - This function validates the address that is passed as separated parameters.
     - All the logic to validate address is implemented in this function as per the rules in @Description.
     - This function is used to validate addresses in various objects i.e Accounts,Contacts,Leads.
     - This function returns a string array that holds all the errors in the form of 'FIELD:ERROR' i.e the field and the error are delimited by ':'.
  */
  public static String[] ValidateAddress(String p_Street,String p_City,String p_State,String p_PostalCode,String p_Country)
  {                 
        List<String> error_list = new List<String>();   
        // Address is empty.
        if(p_Country == null && p_City == null && p_State == null && p_Street == null && p_PostalCode==null)
        {
            error_list.add('All:EMPTY');
            return error_list;
        }                
        // Country field should not be left NULL if any other field is filled.        
        if(p_Country == null && !(p_City == null && p_State == null && p_Street == null && p_PostalCode==null))
            error_list.add('COUNTRY:'+GsmUtilClass.getGSMSettingValue('Country_Error')); //SFDC-2304
        // If any other address field is filled out, beside country, Street and City should be filled out at a minimum
        if(p_Street != null)
        {
            // No user should be able to enter more than 3 lines in the street field
            List<String> streetlines = new List<String>();
            streetlines = p_Street.split('\r\n');
            if(streetlines.size()>3)
                error_list.add('STREET:'+GsmUtilClass.getGSMSettingValue('Street_lines_error')); //SFDC-2304          
        }
        // The country should be a valid from the list of maintained countries.
        // SFDC-3943
        if(p_country!=null && p_country != 'TBD')
        {
            //Country__c[] country = [select Id,Name,Check_State__c from Country__c where Name=:p_Country];
            Country_List__mdt country = countryMap.get(p_Country.toLowerCase()); //SFDC-2304
            if(country == null)
                error_list.add('COUNTRY:'+GsmUtilClass.getGSMSettingValue('Country_Error_USA')); //SFDC-2304
            else 
            {
                if(country.Check_State__c == true)
                {
                    // Within the selected country, if 'CheckState checkbox is checked, then a valid state should be entered.
                    // Use contactenation of State:Country for uniqueness.
                    if(p_State!=null)
                    {
                        State_List__mdt state = stateMap.get(p_State.toLowerCase()+':'+p_Country.toLowerCase()); //SFDC-2304
                        if(state == null)
                            error_list.add('STATE:'+GsmUtilClass.getGSMSettingValue('country_valid_error')); //SFDC-2304        
                    }
                    else
                        error_list.add('STATE:'+GsmUtilClass.getGSMSettingValue('State_Mandatory_error')); //SFDC-2304
                }
            }
        }
        return error_list;          
  } 
  /**
     CallValidateAddress(Account[] accounts)
     - This function is overloaded to validate the BillingAddress and ShippingAddress fields in the Account object.
     - This function is called by the Account trigger.
     - Billing Address is made mandatory.
     - The errors are dispalyed next to the appropriate field.
  */
  public static void CallValidateAddress(Account[] accounts)
  {         
    if(!CallValidateAddressFirstRunFlag_Account)
        return;
    Boolean allEmptyFlag = false;
    
    // List of Profiles that override Address validation
    Boolean profileOverride = false;
    String profileExceptions =  GsmUtilClass.getGSMSettingValue('Profile_Exceptions'); //SFDC-2304
    String currentProfile = Userinfo.getProfileId();    
    // Take only the first 15 chars of the Profile Id
    currentProfile = currentProfile.substring(0, 15);
    if(profileExceptions.contains(currentProfile))
        profileOverride = true;
                
    // ---------- BULKAFYING --------------------------------
    Set<String> countriesSet = new Set<String>();
    Set<String> statesSet = new Set<String>();
    for(Account acc:accounts)
    {
        // Get Bulk Ids
        if(acc.BillingCountry!=null)
            countriesSet.add(acc.BillingCountry.toUpperCase()); //SFDC-2499
        if(acc.BillingState!=null)
            statesSet.add(acc.BillingState.toUpperCase()); //SFDC-2483
        if(acc.ShippingCountry!=null)
            countriesSet.add(acc.ShippingCountry.toUpperCase()); //SFDC-2499
        if(acc.ShippingState!=null)
            statesSet.add(acc.ShippingState.toUpperCase()); //SFDC-2483              
    } 
    GetCountryMap(countriesSet,statesSet);
    // ------------------------------------------------------   
    for(Account acc:accounts)
    {
        //CR 2295281  Primary Countries like *Ukraine* shows up as *UKRAINE* on Accounts
        //Added the default code before validation_override__c condition check
        acc.BillingStreet = DefaultTBD(acc.BillingStreet);
        acc.BillingCity= DefaultTBD(acc.BillingCity);
        if (acc.BillingCountry!=null)
            acc.BillingCountry = formatCountry(acc.BillingCountry);

        if(acc.Validation_Override__c == true)
            continue;
        //Billing Address
        String[] error_list = ValidateAddress(acc.BillingStreet,acc.BillingCity,acc.BillingState,acc.BillingPostalCode,acc.BillingCountry);
        String[] field_error = new String[2];
        for(String error:error_list)
        {
            field_error = error.split(':');
            if(field_error[0]=='ALL')
            {
                if(!profileOverride)
                    acc.BillingCountry.addError(GsmUtilClass.getGSMSettingValue('country_primary_address')); //SFDC-2304
                allEmptyFlag = true;
            }
            else
            {
                if(!profileOverride)
                {
                    if(field_error[0]=='STREET')
                           acc.BillingStreet.addError(field_error[1]);
                    if(field_error[0]=='STATE')
                           acc.BillingState.addError(field_error[1]);  
                    if(field_error[0]=='COUNTRY')
                           acc.BillingCountry.addError(field_error[1]);
                }
                allEmptyFlag = false;
            }            
        }
        
        //Shipping Address
        error_list = ValidateAddress(acc.ShippingStreet,acc.ShippingCity,acc.ShippingState,acc.ShippingPostalCode,acc.ShippingCountry);
        field_error = new String[2];
        for(String error:error_list)
        {
            field_error = error.split(':');
            if(field_error[0]=='ALL')
                allEmptyFlag = true;
            else
            {
                if(!profileOverride)
                {
                    if(field_error[0]=='STREET')
                        acc.ShippingStreet.addError(field_error[1]);
                    if(field_error[0]=='STATE')
                        acc.ShippingState.addError(field_error[1]);         
                    if(field_error[0]=='COUNTRY')
                        acc.ShippingCountry.addError(field_error[1]);
                }
                allEmptyFlag = false;                              
            }
        }
        if(!allEmptyFlag)
        {
            // Defaults
            acc.ShippingStreet = DefaultTBD(acc.ShippingStreet);
            acc.ShippingCity = DefaultTBD(acc.ShippingCity);
        }
    }
    CallValidateAddressFirstRunFlag_Account = false;       
  }

  //Contact Mailing Address Validation  
    public static void validateContactMailingAddress(Contact[] contacts){
        if(!CallValidateAddressFirstRunFlag_ContactMailing)
            return;
        Boolean allEmptyFlag = false;
        
        // List of Profiles that override Address validation
        Boolean profileOverride = false;
        String profileExceptions =  GsmUtilClass.getGSMSettingValue('Profile_Exceptions'); //SFDC-2304
        String currentProfile = Userinfo.getProfileId();    
        // Take only the first 15 chars of the Profile Id
        currentProfile = currentProfile.substring(0, 15);
        if(profileExceptions.contains(currentProfile))
            profileOverride = true;
        
        // ---------- BULKAFYING --------------------------------   
        Set<String> countriesSet = new Set<String>();
        Set<String> statesSet = new Set<String>();
        for(Contact con:contacts)
        {       
            // Get Bulk Ids         
            if(con.MailingCountry!=null)
                countriesSet.add(con.MailingCountry.toUpperCase()); 
            if(con.MailingState!=null)
                statesSet.add(con.MailingState.toUpperCase());    
        }
        GetCountryMap(countriesSet,statesSet);
        // ------------------------------------------------------               
        for(Contact con:contacts)
        {
            //CR 2295281  Primary Countries like *Ukraine* shows up as *UKRAINE* on Accounts
            //Added the default code before validation_override__c condition check
            con.MailingStreet = DefaultTBD(con.MailingStreet);
            con.MailingCity= DefaultTBD(con.MailingCity);
            //SFDC-1255 
            con.MailingCountry = DefaultTBD(con.MailingCountry);
            
            if (con.MailingCountry!=null)
                con.MailingCountry = formatCountry(con.MailingCountry);
            
            if(con.Validation_Override__c == true)
                continue;
            
            //Mailing Address
            String[] error_list = ValidateAddress(con.MailingStreet,con.MailingCity,con.MailingState,con.MailingPostalCode,con.MailingCountry);
            String[] field_error = new String[2];
            for(String error:error_list)
            {
                field_error = error.split(':');
                if(field_error[0]=='ALL')
                {
                    allEmptyFlag = true;
                    if(!profileOverride)
                        con.MailingCountry.addError(GsmUtilClass.getGSMSettingValue('country_primary_contact')); //SFDC-2304
                }               
                else
                {
                    if(!profileOverride)
                    {
                        if(field_error[0]=='STREET')
                            con.MailingStreet.addError(field_error[1]);
                        // MARIT-1598 
                        /*
                        if(field_error[0]=='STATE')
                            con.MailingState.addError(field_error[1]); 
						*/         
                        if(field_error[0]=='COUNTRY')
                            con.MailingCountry.addError(field_error[1]);
                    }
                    allEmptyFlag = false;                      
                }
            }             
        }    
        CallValidateAddressFirstRunFlag_ContactMailing = false;  
    }
    
    //Contact Other Address Validation  
    public static void validateContactOtherAddress(Contact[] contacts){
        if(!CallValidateAddressFirstRunFlag_ContactOther)
            return;
        Boolean allEmptyFlag = false;
        
        // List of Profiles that override Address validation
        Boolean profileOverride = false;
        String profileExceptions =  GsmUtilClass.getGSMSettingValue('Profile_Exceptions'); //SFDC-2304
        String currentProfile = Userinfo.getProfileId();    
        // Take only the first 15 chars of the Profile Id
        currentProfile = currentProfile.substring(0, 15);
        if(profileExceptions.contains(currentProfile))
            profileOverride = true;
        
        // ---------- BULKAFYING --------------------------------   
        Set<String> countriesSet = new Set<String>();
        Set<String> statesSet = new Set<String>();
        for(Contact con:contacts)
        {       
            // Get Bulk Ids  
            if(con.OtherCountry!=null)
                countriesSet.add(con.OtherCountry.toUpperCase()); //SFDC-2499
            if(con.OtherState!=null)
                statesSet.add(con.OtherState.toUpperCase()); //SFDC-2483           
        }
        GetCountryMap(countriesSet,statesSet);
        // ------------------------------------------------------               
        for(Contact con:contacts)
        {
            if(con.Validation_Override__c == true)
                continue;
            //Other Address
            String[] error_list = ValidateAddress(con.OtherStreet,con.OtherCity,con.OtherState,con.OtherPostalCode,con.OtherCountry);
            String[] field_error = new String[2];
            for(String error:error_list)
            {
                field_error = error.split(':');
                if(field_error[0]=='ALL')
                    allEmptyFlag = true;                
                else
                {
                    if(!profileOverride)
                    {
                        if(field_error[0]=='STREET')
                            con.OtherStreet.addError(field_error[1]);
                        if(field_error[0]=='STATE')
                            con.OtherState.addError(field_error[1]);            
                        if(field_error[0]=='COUNTRY')
                            con.OtherCountry.addError(field_error[1]);
                    }
                    allEmptyFlag = false;                                         
                }
            }   
            if(!allEmptyFlag)
            {
                // Defaults
                con.OtherStreet = DefaultTBD(con.OtherStreet);
                con.OtherCity = DefaultTBD(con.OtherCity);
            }              
        }     
        CallValidateAddressFirstRunFlag_ContactOther = false;  
    }

   /**
     CallValidateAddress(Opportunity[] Opportunity)
     - This function is overloaded to validate the End Customer Address fields in the Opportunity object.
     - This function is called by the Opportunity trigger.
     - The errors are dispalyed next to the appropriate field.
     CR 1121880 Update fields from text fields to picklist
     - Commenting the whole function
  */
  /*public static void CallValidateAddress(Opportunity[] Opportunities)
  {
    if(!CallValidateAddressFirstRunFlag_Opportunity)
        return;
    Boolean allEmptyFlag = false;
    
    // List of Profiles that override Address validation
    Boolean profileOverride = false;
    String profileExceptions =  GsmUtilClass.getGSMSettingValue('Profile_Exceptions'); 
    String currentProfile = Userinfo.getProfileId();    
    // Take only the first 15 chars of the Profile Id
    currentProfile = currentProfile.substring(0, 15);
    if(profileExceptions.contains(currentProfile))
        profileOverride = true;
            
    // ---------- BULKAFYING --------------------------------   
    Set<String> countriesSet = new Set<String>();
    Set<String> statesSet = new Set<String>();
    for(Opportunity opp:Opportunities)
    {       
        
        // Get Bulk Ids         
        if(opp.End_Customer_Country__c!=null)
            countriesSet.add(opp.End_Customer_Country__c);
        if(opp.End_Customer_State__c!=null)
            statesSet.add(opp.End_Customer_State__c);           
    }
    GetCountryMap(countriesSet,statesSet);
    // ------------------------------------------------------               
    for(Opportunity opp:Opportunities)
    {
        if(opp.Validation_Override__c == true)
            continue;
        //Mailing Address
        String[] error_list = ValidateAddress(opp.End_Customer_Street_Address__c,opp.End_Customer_City__c,opp.End_Customer_State__c,opp.End_Customer_Zip_Code__c,opp.End_Customer_Country__c);
        String[] field_error = new String[2];
        for(String error:error_list)
        {
            field_error = error.split(':');
            if(field_error[0]=='ALL')
            {
                allEmptyFlag = true;
                if(!profileOverride)
                    opp.End_Customer_Country__c.addError(GsmUtilClass.getGSMSettingValue('country_primary_contact'));
            }               
            else
            {
                if(!profileOverride)
                {
                    if(field_error[0]=='STREET')
                        opp.End_Customer_Street_Address__c.addError(field_error[1]);
                    if(field_error[0]=='STATE')
                        opp.End_Customer_State__c.addError(field_error[1]);          
                    if(field_error[0]=='COUNTRY')
                        opp.End_Customer_Country__c.addError(field_error[1]);
                }
                allEmptyFlag = false;                      
            }
        }
        if(!allEmptyFlag)
        {
            // Defaults        
            opp.End_Customer_Street_Address__c = DefaultTBD(opp.End_Customer_Street_Address__c);
            opp.End_Customer_City__c= DefaultTBD(opp.End_Customer_City__c);
        }
             
    }    
    CallValidateAddressFirstRunFlag_Opportunity = false;
  }*/
  
  /**
    formatCountry()
    - This method takes in a Country String and converts it to a standard Format
    - Example of the format; if country parameter is 'iNDIa'; return will be of format - 'India'
    - Exception to this rule is USA and UK. 
      -Sonali Tandon -CR 2703009 - "Tbd" as Primary Country. Adding TBD also as exception to this rule. 
    */
    public static String formatCountry(String countryuntrim)
    {
        String formattedCountry='';
        String country=countryuntrim.trim();
        String tempCountry = country.toUpperCase(); 
        
        if (tempCountry.indexof('USA') > -1 || tempCountry.equals('UK') || tempCountry.equals('TBD'))
            return tempCountry;
        
        List<String> countryWords = tempCountry.split('\\s');
        String firstLetter;
        String restOfTheWord;
        for (String c : countryWords)
        {       
            firstLetter = c.substring(0, 1);
            if (firstLetter.indexof('(')>-1)
            {
                firstLetter = c.substring(0,2);
                restOfTheWord = c.substring(2);                 
            }
            else
                restOfTheWord = c.substring(1);
            if (formattedCountry=='')
                formattedCountry = (firstLetter.toUpperCase() + restOfTheWord.toLowerCase());
            else
                formattedCountry += ' ' + (firstLetter.toUpperCase() + restOfTheWord.toLowerCase()); 
        }
        return formattedCountry;
    } 
    // Added By swati

    public static void CallValidateAddress(Account_Creation_Request__c[] accounts)
  {         
    if(!ValidateAddressFirstRunFlag_AccCreation)
        return;
    Boolean allEmptyFlag = false;
    
    // List of Profiles that override Address validation
    Boolean profileOverride = false;
    String profileExceptions =  GsmUtilClass.getGSMSettingValue('Profile_Exceptions'); //SFDC-2304
    String currentProfile = Userinfo.getProfileId();    
    // Take only the first 15 chars of the Profile Id
    currentProfile = currentProfile.substring(0, 15);
    if(profileExceptions.contains(currentProfile))
        profileOverride = true;
                
    // ---------- BULKAFYING --------------------------------
    Set<String> countriesSet = new Set<String>();
    Set<String> statesSet = new Set<String>();
    for(Account_Creation_Request__c acc:accounts)
    {
        // Get Bulk Ids
        if(acc.Country__c!=null)
            countriesSet.add(acc.Country__c.toUpperCase()); //SFDC-2499
        if(acc.State__c!=null)
            statesSet.add(acc.State__c.toUpperCase()); //SFDC-2483
  } 
    GetCountryMap(countriesSet,statesSet);
    // ------------------------------------------------------   
    for(Account_Creation_Request__c acc:accounts)
    {
        //CR 2295281  Primary Countries like *Ukraine* shows up as *UKRAINE* on Accounts
        //Added the default code before validation_override__c condition check
        acc.Street__c = DefaultTBD(acc.Street__c);
        acc.City__c= DefaultTBD(acc.City__c);
        if (acc.Country__c!=null)
            acc.Country__c = formatCountry(acc.Country__c);

        if(acc.Validation_Override__c == true)
            continue;
        //Billing Address
        String[] error_list = ValidateAddress(acc.Street__c,acc.City__c,acc.State__c,acc.Zip_Postal_Code__c,acc.Country__c);
        String[] field_error = new String[2];
        for(String error:error_list)
        {
            field_error = error.split(':');
            if(field_error[0]=='ALL')
            {
                if(!profileOverride)
                    acc.Country__c.addError(GsmUtilClass.getGSMSettingValue('country_primary_address')); //SFDC-2304
                allEmptyFlag = true;
            }
            else
            {
                if(!profileOverride)
                {
                    if(field_error[0]=='STREET')
                           acc.Street__c.addError(field_error[1]);
                    if(field_error[0]=='STATE')
                           acc.State__c.addError(field_error[1]);  
                    if(field_error[0]=='COUNTRY')
                           acc.Country__c.addError(field_error[1]);
                }
                allEmptyFlag = false;
            }            
        }
        
        
       
    }
    CallValidateAddressFirstRunFlag_Account = false;       
  }  
}