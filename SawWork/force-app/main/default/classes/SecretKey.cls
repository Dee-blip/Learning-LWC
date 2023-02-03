public without sharing class SecretKey 
{

    public static string getKey(String keyName)
    {
        Secret_Key__c sk = [select Secret_Key__c from Secret_Key__c where Name=:keyName];
        return sk.Secret_Key__c;

    }

    public static List<String> getKeys(String prefix )
    {
        List<String> keys = new List<String>();
        for(Secret_Key__c sk: [select Secret_key__c 
                from Secret_Key__c 
                where name like :prefix + '%' 
                order by Name asc])
        {
            keys.add(sk.Secret_Key__c);

        }


        return keys;
    }

    public static string getKeyWithPrefix(String prefix)
    {
        // parts will be number 01, 02, ... 99
        // eg. DSignPvtKey01 etc

        String consolidatedString = '';
        for(Secret_Key__c sk: [select Secret_key__c 
                from Secret_Key__c 
                where name like :prefix + '%' 
                order by Name asc])
        {
            consolidatedString += sk.Secret_Key__c;
        }

        return consolidatedString;
    }
  }